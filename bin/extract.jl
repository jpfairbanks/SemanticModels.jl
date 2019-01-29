module Edges
include("../src/graph.jl")
include("../src/definitions.jl")

using DataFrames
using GraphDataFrameBridge
using MetaGraphs
using CSV
using LightGraphs
using Random
using DataFramesMeta
using Colors
using ParserCombinator
using GraphIO

export edgetype, edges, create_kg_from_code_edges, create_kg_from_markdown_edges, format_edges_dataframe, assign_vertex_colors_by_key, write_graph_to_dot_file


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
        e = (scope, typ, var, val)
        push!(edg, e)
        if typeof(val) <: Expr && val.head == :vect
            push!(edg, (scope, :has, var, :prop_collection))
        end
        if typeof(val) <: Expr && val.head == :call
            push!(edg, (scope, :input, val.args[2], Symbol.(val.args[3:end])))
        end
        if typ == :destructure
            @debug var.args
            for lhs in var.args
                push!(edg, (scope, :comp, val, lhs))
            end
        end
        if typ == :structure
            @debug var, val
            for rhs in val.args
                push!(edg, (scope, :comp, var, rhs))
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

function format_edges_dataframe(code_edges, output_path::String)
    
    edges_df = []
    
    for e in code_edges
        
        src_vname = e[1]
        dst_vname = e[3]
        
        src_vhash = Graphs.gen_vertex_hash("$src_vname", "missing")
        dst_vhash = Graphs.gen_vertex_hash("$dst_vname", "missing")
        
        edge_attrs = (src_vhash = "$src_vhash",
            src_name = src_vname,
            src_vtype = "missing",
            dst_vhash = "$dst_vhash",
            dst_name = dst_vname,
            dst_vtype = "missing",
            edge_relation = e[2],
            edge_description = e[2],
            value = e[4]
         )
               
        push!(edges_df, edge_attrs)
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

function create_kg_from_markdown_edges()
    
    G = Extraction.definitiongraph("../examples/epicookbook/epireceipes_Automates_GTRI_ASKE_2rules_output/json", Extraction.sequentialnamer())
    
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


"""    assign_vertex_colors_by_key(G::MetaDiGraph, color_by::Symbol)

Takes as input an existing MetaDiGraph, and a group_by, which is assumed to correspond to an existing vertex prop.
Groups the vertices in G by the group_by field, computes the number of unique colors needed, and generates a hash table, with key equal to the vertex hash, and value equal to the assigned color.

see also: [`assign_edge_styles_by_key`](@ref), [1write_graph_to_dot_file1](@ref)
"""
function assign_vertex_colors_by_key(G::MetaDiGraph, group_by::Symbol)
    
    cols = distinguishable_colors(length(unique([get_prop(G, v, group_by) for v in vertices(G)]))+1, [RGB(1,1,1)])[2:end]
    pcols = map(col -> (red(col), green(col), blue(col)), cols)
    
    color_type_lookup = Dict()
    
    for (i, v_type) in enumerate(unique([get_prop(G, v, group_by) for v in vertices(G)]))
        color_type_lookup[v_type] = pcols[i]
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
    
    head = ("digraph") * graph_name * " {"
 
     open(output_path, "w") do io
        
        println(io, head)
        
        for v in vertices(G)
            v_color = v_color_lookup[get_prop(G, v, :v_hash)]
            println(io, string(get_prop(G, v, :v_name), " [color=", "$v_color", "];"))
        end

        for e in LightGraphs.edges(G)

            println(io, string("$string(get_prop(G, e.src, :v_name)", " -- ", "$get_prop(G, e.dst, :v_name)", "[label=", get_prop(G, e, :e_rel), "];"))
            
        end
        
        println(io, "}")
        
        final_str = "" *  "\n}\n"
        println(io, final_str)

    end
    
    # Example dot file
    #     Graph("""
    #         graph graphname {
    #          // The label attribute can be used to change the label of a node
    #          a [label="Foo"];
    #          // Here, the node shape is changed.
    #          b [shape=box];
    #          // These edges both have different line properties
    #          a -- b -- c [color=blue];
    #          b -- d [style=dotted];
    #      }
    #     """)
    end

end



# command-line usage 
# julia -i --project ../bin/extract.jl ../examples/epicookbook/src/ScalingModel.jl 
# julia -i --project ../bin/extract.jl ../examples/epicookbook/src/SEIRmodel.jl

using SemanticModels.Parsers
@debug "Done Loading Package"
include("../src/graph.jl")
include("../src/definitions.jl")
using DataFrames
using MetaGraphs

if length(ARGS) < 1
    error("You must provide a file path to a .jl file", args=ARGS)
end
path = ARGS[1]
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
for e in edg
    println(e)
end

output_path = "../examples/epicookbook/data/edges_from_code_1.jl"

@info("Generating a knowledge graph from parsed Epicookbook markdown files.")
G_markdown = Edges.create_kg_from_markdown_edges()
G_code_and_markdown = Edges.create_kg_from_code_edges(output_path, G_markdown)
vcolors = Edges.assign_vertex_colors_by_key(G_code_and_markdown, :v_type)

dot_file_path = "../examples/epicookbook/data/dot_file_ex1.dot"
Edges.write_graph_to_dot_file(G_code_and_markdown, dot_file_path, "G_code_and_markdown", vcolors)

# TODO: this doesn't work because the dot file is not correctly formatted yet
#G_from_dot_file = loadgraph(dot_file_path, "G_code_and_markdown", DOTFormat())

