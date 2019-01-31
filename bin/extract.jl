module Edges
#using Pkg
#Pkg.update()
using DataFrames
using GraphDataFrameBridge
using MetaGraphs
using CSV
using LightGraphs
using Random
using DataFramesMeta
using Colors
using Logging

using SemanticModels.Graphs
using SemanticModels.Extraction

export edgetype,
    edges,
    create_kg_from_code_edges,
    create_kg_from_markdown_edges,
    format_edges_dataframe,
    assign_vertex_colors_by_key,
    write_graph_to_dot_file

function edgetype(var, val::Expr)
    if val.head == :call
        return :output
    elseif length(val.args) >=2 && typeof(val.args[2]) <: Expr && val.args[2].head == :tuple
        @show val.args
        return :structure
    else
        return :takes
    end
end

edgetype(var, val::Symbol) = :destructure
edgetype(var, val) = :takes
edgetype(var::Symbol, val::Symbol) = :takes
edgetype(args...) = @show args


function edges(mc, subdef, scope)
    @info("Making edges",scope=scope)
    edg = Any[]
    for ( var,val ) in mc.vc
        @show var, val
        typ = edgetype(var, val)
        val = typ==:structure ? val.args[2] : val
        e = (scope, typ, :var, var, :val, val)
        push!(edg, e)
        if typ == :output
            e = (scope, typ, :var, var, :exp, val)
            push!(edg, e)
        end
        if typ == :structure
            e = (scope, typ, :var, var, :tuple, val.args[2])
            push!(edg, e)
        end

        if typeof(val) <: Expr && val.head == :vect
            push!(edg, (scope, :has, :value, var, :property, :collection))
        end
        if typeof(val) <: Expr && val.head == :call
            push!(edg, (scope, :input, :func, val.args[1], :args, Symbol.(val.args[2:end])))
        end
        if typ == :destructure
            @debug var.args
            for lhs in var.args
                push!(edg, (scope, :comp, :var, val, :var, lhs))
            end
        end
        if typ == :structure
            @debug var, val
            for rhs in val.args
                push!(edg, (scope, :comp, :var, var, :val, rhs))
            end
        end

    end
    for (funcname, smc) in subdef
        @debug "Recursing"
        # @show funcname, smc
        subedges = edges(smc, [], "$scope.$funcname")
        for e in subedges
            push!(edg, e)
        end
    end
    return edg
end

function preprocess_vertex_name(orig_str_rep)
    clean_str = replace(replace(replace(replace(orig_str_rep, "^" => "exp"), "*" => "star"), "-" => "neg"), "\"" => " ")
    return clean_str
end

function format_edges_dataframe(code_edges, output_path::String)
    
    edges_df = []
    
    for e in code_edges
        
        # Going from left to right, there are two edges we need to create (?)
        
        # Edge one
        src_1_vname = "$(e[1])"
        src_1_vtype = "missing"
        #dst_1_vname = preprocess_vertex_name(("\""*"\""*"$(e[4])"*"\""*"\""))
        dst_1_vname = "$(e[4])"
        #dst_1_vtype = e[3] # this is the data type; we'll use it once we have reconciliation rules in place
        dst_1_vtype = "missing"
        
        src_1_vhash = Graphs.gen_vertex_hash("$src_1_vname", "src_1_vtype")
        dst_1_vhash = Graphs.gen_vertex_hash("$dst_1_vname", "dst_1_vtype")
        
        edge_1_relation = e[2]
        edge_1_description = e[2]
        edge_1_value = e[6] # check this; unclear if we want to (only) store as metadata or actually create edge 2
            
        edge_1_attrs = (src_vhash = "$src_1_vhash",
            src_name = src_1_vname,
            src_vtype = src_1_vtype,
            dst_vhash = "$dst_1_vhash",
            dst_name = dst_1_vname,
            dst_vtype = dst_1_vtype,
            edge_relation = edge_1_relation,
            edge_description = edge_1_description,
            value = "$edge_1_value"
         )
        
        push!(edges_df, edge_1_attrs)
        
        # Edge two 
        src_2_vname = dst_1_vname
        src_2_vtype = dst_1_vtype
        #dst_2_vname = preprocess_vertex_name(("\""*"\""*"$(e[6])"*"\""*"\""))
        dst_2_vname = "$(e[6])"
        dst_2_vtype = "missing"
               
        src_2_vhash = dst_1_vhash
        dst_2_vhash = Graphs.gen_vertex_hash("$dst_2_vname", "dst_2_vtype")
        
        edge_2_relation = string(e[5])
        edge_2_description = string(e[5])
        edge_2_value = string(e[6])
        
        edge_2_attrs = (src_vhash = "$src_2_vhash",
            src_name = src_2_vname,
            src_vtype = src_2_vtype,
            dst_vhash = "$dst_2_vhash",
            dst_name = dst_2_vname,
            dst_vtype = dst_2_vtype,
            edge_relation = edge_2_relation,
            edge_description = edge_2_description,
            value = "$edge_2_value"
         )
        
        push!(edges_df, edge_2_attrs)
    end
    
    open(output_path, "w") do io
        print(io, repr(Graphs.load_graph_data(edges_df)))
    end
    
    return edges_df
    
end


function create_kg_from_code_edges(code_edges)   
    
    G = MetaDiGraph()
    G_prime = Graphs.insert_edges_from_jl(code_edges, G)
    return G_prime    
end

function create_kg_from_code_edges(code_edges, G::MetaDiGraph)    
    
    G_prime = Graphs.insert_edges_from_jl(code_edges, G)
    return G_prime   
end

function create_kg_from_markdown_edges(path)
    
    G = Extraction.definitiongraph(path, Extraction.sequentialnamer())

    # this is a hack for now..
    # TODO: modify the markdown definitions.jl script to ensure vertex/edge props match the schema
    for v in vertices(G)     

        v_hash = Graphs.gen_vertex_hash(get_prop(G, v, :name), "missing")
        set_indexing_prop!(G, v, :v_hash, "$v_hash")

        set_props!(G, v,
            Dict(:v_name=>get_prop(G, v, :name),
                 :v_type=>"missing"))
    end

    for e in LightGraphs.edges(G)  

        src_vhash = Graphs.gen_vertex_hash(get_prop(G, e.src, :name), "missing")
        dst_vhash = Graphs.gen_vertex_hash(get_prop(G, e.dst, :name), "missing")

        set_props!(G, Edge(e.src, e.dst), Dict(:e_rel=>"verb",
                                                :e_desc=>"Verb",
                                                :e_value=>"is defined as",
                                                :weight=>1))
    end
    
    return G
end


function create_kg_from_markdown_edges(path, extraction_rule="definition")
    
    G = Extraction.definitiongraph(path, Extraction.sequentialnamer())
    
#     vertex_df = DataFrame(vertex=String[], 
#                           v_hash=String[],
#                           v_name=String[], 
#                           v_type=String[], 
#                           v_text=String[])
    
#     edges_df = DataFrame(src_vhash = String[],
#                         src_name = String[],
#                         src_vtype = String[],
#                         dst_vhash = String[],
#                         dst_name = String[],
#                         dst_vtype = String[],
#                         edge_relation = String[],
#                         edge_description = String[],
#                         value = String[])

    # this is a hack for now..
    # TODO: modify the markdown definitions.jl script to ensure vertex/edge props match the schema
    for v in vertices(G)     

        v_hash = Graphs.gen_vertex_hash(get_prop(G, v, :name), "concept")
        set_indexing_prop!(G, v, :v_hash, "$v_hash")

        set_props!(G, v,
            Dict(:v_name=>get_prop(G, v, :name),
                 :v_type=>"concept",
                 :v_text=>length(get_prop(G, v, :text))==0 ? "no_text" : get_prop(G, v, :text)))
        
#         push!(vertex_df, (vertex="$v", v_hash="$v_hash", v_name=get_prop(G, v, :name), v_type="concept",  v_text=length(get_prop(G, v, :text))==0 ? "no_text" : get_prop(G, v, :text)))
        
    end

    for e in LightGraphs.edges(G)  

        src_vhash = Graphs.gen_vertex_hash(get_prop(G, e.src, :name), "concept")
        dst_vhash = Graphs.gen_vertex_hash(get_prop(G, e.dst, :name), "concept")


        set_props!(G, Edge(e.src, e.dst), Dict(:e_rel=>"verb",
                                                :e_desc=>"Verb",
                                                :e_value=>"is defined as",
                                                :weight=>1))
        
#         push!(edges_df, (src_vhash="$src_vhash", src_name = get_prop(G, e.src, :name), src_vtype="concept",
#                 dst_vhash="$dst_vhash", dst_name = get_prop(G, e.dst, :name), dst_vtype = "concept",
#                 edge_relation= "verb", edge_description="Verb", value="is defined as"))
    end
    
    # for debugging 
    #CSV.write("../examples/epicookbook/data/markdown_vertices.csv",vertex_df) 
    #CSV.write("../examples/epicookbook/data/markdown_edges.csv",edges_df) 
    return G
end


"""    assign_vertex_colors_by_key(G::MetaDiGraph, color_by::Symbol)

Takes as input an existing MetaDiGraph, and a group_by, which is assumed to correspond to an existing vertex prop.
Groups the vertices in G by the group_by field, computes the number of unique colors needed, and generates a hash table, with key equal to the vertex hash, and value equal to the assigned color.

see also: [`assign_edge_styles_by_key`](@ref), [1write_graph_to_dot_file1](@ref)
"""
function assign_vertex_colors_by_key(G::MetaDiGraph, group_by::Symbol)
    
    # element 1 = white; element 2 = black; for sake of making graph easier to read, add +2 buffer and start indexing colors at 3 
    cols = distinguishable_colors(length(unique(get_prop(G, v, group_by) for v in vertices(G)))+2, [RGB(1,1,1)])[3:end]    

    color_type_lookup = Dict()
    
    for (i, v_type) in enumerate(unique([get_prop(G, v, group_by) for v in vertices(G)]))
        color_type_lookup[v_type] = "#$(hex(cols[i]))"
    end
    
    vertex_color_lookup = Dict()
    
    for v in vertices(G)
        vertex_color_lookup[get_prop(G, v, :v_hash)] = color_type_lookup[get_prop(G, v,group_by)]
    end
    
    return vertex_color_lookup

end


"""    assign_edge_styles_by_key(G::MetaDiGraph, group_by::Symbol)

Takes as input an existing MetaDiGraph, and a group_by field, which is assumed to correspond to an existing edge prop.
Groups the directed edges in G by the group_by field, computes the number of unique edge styles needed, and generates a hash table, with key equal to the edge id, and value equal to the assigned (line) style.

see also: [`assign_edge_styles_by_key`](@ref), [1write_graph_to_dot_file1](@ref)
"""
function assign_edge_style_by_key(G::MetaDiGraph, groupy_by::Symbol)
    # TODO; need to figure out how to generate arbitrary styles, or put a cap on number based on schema
end


# TODO: fix syntax and puncutuation errors so the graph can be loaded from a dot file
function write_graph_to_dot_file(G::MetaDiGraph, output_path::String, graph_name::String, v_color_lookup)

    head = "digraph " * graph_name * " {"
 
     open(output_path, "w") do io
        
        println(io, head)
        
        for v in vertices(G)
            v_color = v_color_lookup[get_prop(G, v, :v_hash)]
            vname = preprocess_vertex_name(get_prop(G, v, :v_name))
            println(io, string("$v" *  " [color=" * "\"" * "$v_color" *  "\"" * " ," * " label=" * "\"" * "$vname" * "\"" * "];"))
           
        end

        for e in LightGraphs.edges(G)
            
            src_vname = preprocess_vertex_name(get_prop(G, e.src, :v_name))
            dst_vname = preprocess_vertex_name(get_prop(G, e.dst, :v_name))
            e_rel = get_prop(G, e, :e_rel)
            #e_value = get_prop(G, e, :e_value)

            println(io, string("$(e.src)" * " -> " * "$(e.dst)" * " [label=" * "\"" * "$(e_rel)" * "\""  * "];"))
            
        end
        
        println(io, "}")
        
    end
    
    # Example dot file
    #         digraph graphname {
    #          // The label attribute can be used to change the label of a node
    #          a [label="Foo"];
    #          // Here, the node shape is changed.
    #          b [shape=box];
    #          // These edges both have different line properties
    #          a -- b -- c [color=blue];
    #          b -- d [style=dotted];
    #      }
    end

end


# command-line usage 
# julia -i --project ../bin/extract.jl ../examples/epicookbook/src/ScalingModel.jl ../examples/epicookbook/src/SEIRmodel.jl

using SemanticModels.Parsers
using SemanticModels.Graphs
using SemanticModels.Extraction
@debug "Done Loading Package"
using DataFrames
using MetaGraphs
using LightGraphs

if length(ARGS) < 1
    error("You must provide a file path to a .jl file", args=ARGS)
end

mdown_path = "../examples/epicookbook/epireceipes_Automates_GTRI_ASKE_2rules_output/json"

G_markdown = MetaDiGraph()
G_markdown = Edges.create_kg_from_markdown_edges(mdown_path, "definition")

@info("Graph created from markdown has v vertices and e edges.", v=nv(G_markdown), e=ne(G_markdown))

num_files = length(ARGS)
global G_temp = MetaDiGraph()

for i in 1:num_files
    
    output_path = "../examples/epicookbook/data/edges_from_code_$i.jl"

    path = ARGS[i]
    @info "Parsing julia script" file=path
    expr = parsefile(path)
    mc = defs(expr.args[3].args)
    @info "script uses modules" modules=mc.modc
    @info "script defines functions" funcs=mc.fc.defs
    @info "script defines glvariables" funcs=mc.vc
    subdefs = recurse(mc)
    @info "local scope definitions" subdefs=subdefs

    for func in subdefs
        funcname = func[1]
        mc = func[2]
        @info "$funcname uses modules" modules=mc.modc
        @info "$funcname defines functions" funcs=mc.fc.defs
        @info "$funcname defines variables" funcs=mc.vc
    end

    edg = Edges.edges(mc, subdefs, expr.args[2])
    @info("Edges found", path=path)
    #for e in edg
        #println(e)
    #end

    code_edges_df = Edges.format_edges_dataframe(edg, output_path)
    
    if i == 1
        # We only need to ingest the markdown info once.
        G_code = Edges.create_kg_from_code_edges(output_path, G_markdown)
    else
        G_code = Edges.create_kg_from_code_edges(output_path, G_temp)
    end

    @info("Code graph $i has v vertices and e edges.", v=nv(G_code), e=ne(G_code))

    global vcolors = Edges.assign_vertex_colors_by_key(G_code, :v_type)
    global G_temp = copy(G_code)
    
end

@info("All markdown and code files have been parsed; writing final knowledge graph to dot file")
dot_file_path = "../examples/epicookbook/data/dot_file_ex1.dot"
Edges.write_graph_to_dot_file(G_temp, dot_file_path, "G_code_and_markdown", vcolors)

# Generate svg file
run(`dot -Tsvg -O $dot_file_path`)

