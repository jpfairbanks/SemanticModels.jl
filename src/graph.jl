using DataFrames
using GraphDataFrameBridge
using MetaGraphs
using CSV
using LightGraphs
using GraphPlot
using Random
using DataFramesMeta

function load_graph_data(input_data)
    
    return input_data
end
    
"""    generate_synthetic_vertices(vertex_type_defs::String, output_path::String)

Generate synthetic test data. The synthetic vertices are returned as a dataframe 
that can be used for testing/debugging/developing the knowledge graph.

see also: generate_synthetic_edges
"""
function generate_synthetic_vertices(vertex_type_defs::String, output_path::String)

    
    vertex_types = CSV.read(vertex_type_defs)
    
    synth_vertices_df = []
    
    for vertex in eachrow(vertex_types)
        
        # Generate a synthetic name; hash the concatenation of name||type to get a unique vertex id
        v_name = string("synth_", vertex.v_type, "_", randstring(MersenneTwister(), 'a':'z', 6)) 
        v_hash = hash(string(v_name, vertex.v_type))       
        synth_v_attrs = NamedTuple{(:v_hash, :v_name, :v_type)}(("$v_hash", v_name, vertex.v_type))
        
        push!(synth_vertices_df, synth_v_attrs)
        
    end
    
    open(output_path, "w") do io
        print(io, repr(load_graph_data(synth_vertices_df)))
    end

    #CSV.write(output_path, synth_vertices_df)
    @info "Synthetic vertex dataframe generated and saved as a Julia file."
    
    return DataFrame(synth_vertices_df)

end


function generate_synthetic_edges(edge_type_defs::String, synth_vertex_df::DataFrame, output_path::String)
    
    """
    This function ingests a synthetic vertex data frame and generates synthetic edges that are consistent with edge src/dst vertex type constraints. 
    This synthetic vertex dataframe can be used for testing/debugging/developing the knowledge graph.
    """
    
    edge_types = CSV.read(edge_type_defs)

    synth_edges_df = []
    
    for edge_row in eachrow(edge_types)

        src_row = @linq synth_vertex_df |> 
            where(:v_type .== edge_row.src_type) |> 
            select(:v_hash, :v_name, :v_type)
        
        dst_row = @linq synth_vertex_df |> 
            where(:v_type .== edge_row.dst_type) |>
            select(:v_hash, :v_name, :v_type)
        
        if size(src_row)[1] >=1 && size(dst_row)[1] >= 1
            src_vhash = src_row.v_hash[1]
            src_name = src_row.v_name[1]
            src_vtype = src_row.v_type[1]

            dst_vhash = dst_row.v_hash[1]
            dst_name = dst_row.v_name[1]
            dst_vtype = dst_row.v_type[1]
            
            if edge_row.value_field != "nothing"
                edge_val = ("placeholder")
            else
                edge_val = nothing
            end

            synth_edge_attrs = NamedTuple{(:src_vhash, :src_name, :src_vtype, :dst_vhash, :dst_name, :dst_vtype, :edge_relation, :edge_description, :value)}(("$src_vhash", src_name, src_vtype, "$dst_vhash", dst_name, dst_vtype, edge_row.edge_relation, edge_row.description, edge_val))
            push!(synth_edges_df, synth_edge_attrs)
            
        else
            continue
        end
    end
    
    open(output_path, "w") do io
        print(io, repr(load_graph_data(synth_edges_df)))
    end

    #CSV.write(output_path, synth_edges_df)
    @info "Synthetic edge dataframe generated and saved as a Julia file."
    
    return DataFrame(synth_edges_df)

end

function insert_vertices_from_jl(vertices_file::String, input_graph::Union{MetaDiGraph, Nothing})
    
    # Ingest data frame containing vertex information; each row represents a vertex name and type
    # vertex_id is computed upon insertion via a hash function, and is assumed to be unique 
    # The tuple {vertex_name, vertex_type} is assumed to be unique 

    v_df = DataFrame(include(vertices_file))
    
    # Case 1: the graph is currently empty; objective is to create it from the input vertex and edge files.
    if isa(input_graph, Nothing)
        
        n_vertices = size(v_df,1)
        G = MetaDiGraph(n_vertices)
        counter = 1::Int64

        set_indexing_prop!(G, :v_hash)
        
        for v in eachrow(v_df)
        
            v_hash = hash(string(v.v_name, v.v_type)) 
            
            v_attrs = Dict(
                :v_name=>v.v_name,
                :v_type=>v.v_type,
                :used=>true)
            
            set_indexing_prop!(G, counter, :v_hash, "$v_hash")
            set_props!(G, counter, v_attrs)
            @info "Inserting new vertex into graph: $v"
            counter += 1
        end
    
    # Case 2: the graph already exists (as a graph object); objective is to add new vertices/edges, and increment weights when existing edges are encountered.
    else
        
        g_input = copy(input_graph)
        n_vertices_input = nv(g_input)
        n_vertices = size(v_df,1) + n_vertices_input
        
        counter = nv(g_input) + 1

        G = MetaDiGraph(n_vertices)
        
        # insert vertices (with properties) from the input graph
        for i in 1:nv(g_input)
            
            v_props = props(g_input, i)
            
            set_indexing_prop!(G, i, :v_hash, v_props[:v_hash])
            
            set_props!(G, i, 
                Dict(:v_name=>v_props[:v_name], 
                    :v_type=>v_props[:v_type],
                    :used=>true))
        end
        
        @info "$n_vertices_input from input graph have been inserted."
        
        for v in eachrow(v_df)
        
            v_hash = hash(string(v.v_name, v.v_type)) 

            try 
                G["$v_hash", :v_hash]
                
                @info "A vertex with this hash value already exists"
                
                # Set the "used" attribute to false, so we can remove this vertex before returning G
                 v_attrs = Dict(
                        :v_name=>v.v_name,
                        :v_type=>v.v_type,
                        :used=>false)
            
                    set_indexing_prop!(G, counter, :v_hash, string("$v_hash", "_copy"))
                    set_props!(G, counter, v_attrs)
                    
            catch error
                if isa(error, KeyError) || isa(error, ExceptionError)
                
                v_attrs = Dict(
                        :v_name=>v.v_name,
                        :v_type=>v.v_type,
                        :used=>true)
            
                    set_indexing_prop!(G, counter, :v_hash, "$v_hash")
                    set_props!(G, counter, v_attrs)
                    
                    @info "Inserting new vertex into graph: $v."

                    counter += 1
                end
            end
        end
    end
    
    G = G[filter_vertices(G, :used, true)]
    n_vertices_final = nv(G)
    
    @info "Returning graph G; G has $n_vertices_final vertices."
        
    return G

end


function insert_edges_from_jl(edges_file::String, input_graph::MetaDiGraph)
    
    # Ingest MetaDiGraph containing vertices, and a file containing edges.
    # Edges are not assumed to be unique; a counter is incremented each time an edge is encountered.
    # Edges may contain vertices that are \notin G (e.g. v \in E_1 \bigcup E_0 may be \emptyset)

    e_df = DataFrame(include(edges_file))

    vertices_already_in_G = [get_prop(input_graph, v, :v_hash) for v in vertices(input_graph)]
    vertices_in_edgelist = cat(dims=1, unique(e_df.src_vhash), unique(e_df.dst_vhash))
    refs_to_existing_vertices  = intersect(Set(vertices_already_in_G), Set(vertices_in_edgelist))
    
    num_vertices_g = nv(input_graph)
    num_vertices_el = length(vertices_in_edgelist)
    inter_cardinality = length(refs_to_existing_vertices)
    union_cardinality = length(union(Set(vertices_already_in_G), Set(vertices_in_edgelist)))
    
    if inter_cardinality != num_vertices_g
        counter = num_vertices_g + 1
    end
    
    G = MetaDiGraph(union_cardinality)

    # Insert vertices (with properties) from the input graph
    for i in 1:nv(input_graph)

        v_props = props(input_graph, i)

        set_indexing_prop!(G, i, :v_hash, v_props[:v_hash])

        set_props!(G, i, 
            Dict(:v_name=>v_props[:v_name], 
                :v_type=>v_props[:v_type],
                :used=>true))
    end   
    
    
    @info "The input graph contains $num_vertices_g unique vertices. \n The input edge list refers to $num_vertices_el unique vertices. \n The size of the intersection of these two sets is: $inter_cardinality."

    set_indexing_prop!(G, :v_hash)

    for e in eachrow(e_df)

        edge_attrs = Dict(
                        :e_rel=>e.edge_relation,
                        :e_desc=>e.edge_description,
                        :e_value=>e.value,
                        :counter=>1)

        # The src vertex is \notin G; we need to insert it before we can insert the edge
        if !issubset([e.src_vhash], vertices_already_in_G)

            src_v_hash = e.src_vhash
                
            src_v_attrs = Dict(
                :v_name=>e.src_name,
                :v_type=>e.src_vtype,
                :used=>true)

            set_indexing_prop!(G, counter, :v_hash, "$src_v_hash")
            set_props!(G, counter, src_v_attrs)
                
            counter += 1
            vertices_already_in_G = cat(dims=1, "$src_v_hash", vertices_already_in_G)
            
            @info "src vertex $src_v_hash was not in G, and has been inserted."
        end
        
        # The dst vertex is \notin G; we need to insert it before we can insert the edge
        if !issubset([e.dst_vhash], vertices_already_in_G)
            
            dst_v_hash = e.dst_vhash
                
            dst_v_attrs = Dict(
                :v_name=>e.dst_name,
                :v_type=>e.dst_vtype,
                :used=>true)

            set_indexing_prop!(G, counter, :v_hash, "$dst_v_hash")
            set_props!(G, counter, dst_v_attrs)
                
            counter += 1
            vertices_already_in_G = cat(dims=1, "$dst_v_hash", vertices_already_in_G)
            @info "dst vertex $dst_v_hash was not in G, and has been inserted."
        end
        
        # All vertices referenced are now \in G; we can insert the edge or increment an existing edge's counter
        src_int_id = G[e.src_vhash, :v_hash]
        dst_int_id = G[e.dst_vhash, :v_hash]
            
        # Add a new edge to the graph
        if !has_edge(G, src_int_id, dst_int_id)


            add_edge!(G, src_int_id, dst_int_id)
            set_props!(G, Edge(src_int_id, dst_int_id), edge_attrs)

        #  This edge already exists \in G; increment the (frequency) counter (currently used for weight; we will probably want to think about how to best normalize these counts)
        else
            cur_weight = get_prop(G, Edge(src_int_id, dst_int_id), :counter)
            set_prop!(G, Edge(src_int_id, dst_int_id), :counter, cur_weight+1)

        end

        
    end
    
    weightfield!(G, :counter)
    num_edges_final = length([e for e in edges(G)])
    
    @info "Returning graph G; G has $union_cardinality vertices and $num_edges_final edges."

    return G

end


function main(path_to_v_types="../examples/knowledge_graph/data/kg_vertex_types.csv", path_to_edge_types="../examples/knowledge_graph/data/kg_edge_types.csv")
    
    @info "Generating dataframe of synthetic vertices (vertex types reflect our schema)"
    synth_vdf = generate_synthetic_vertices(path_to_v_types,"../examples/knowledge_graph/data/synth_kg_vertices.jl")
    
    @info "Generating dataframe of synthetic edges (edge types reflect our schema)"
    synth_edf = generate_synthetic_edges(path_to_edge_types, synth_vdf, "../examples/knowledge_graph/data/synth_kg_edges.jl")
    
    @info "Example of inserting vertices to instantiate a KG from scratch"
    g1 = insert_vertices_from_jl("../examples/knowledge_graph/data/synth_kg_vertices.jl", nothing)
    
    @info "Example of inserting vertices to an existing KG"
    g2 = insert_vertices_from_jl("../examples/knowledge_graph/data/synth_kg_vertices.jl", g1) 
    
    @info "Example of inserting edges to an existing KG"
    g3 = insert_edges_from_jl("../examples/knowledge_graph/data/synth_kg_edges.jl", g2)
end

main()


