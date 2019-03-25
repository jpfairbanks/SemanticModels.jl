# +
using Pkg
try
    using DataFrames
catch
    Pkg.add("DataFrames")
end
try
    using GraphDataFrameBridge
catch
    Pkg.add("GraphDataFrameBridge")
end
try
    using MetaGraphs
catch
    Pkg.add("MetaGraphs")
end
try
    using LightGraphs
catch
    Pkg.add("LightGraphs")
end
try
    using CSV
catch
    Pkg.add("CSV")
end
try
    using DataFramesMeta
catch
    Pkg.add("DataFramesMeta")
end

using DataFrames
using GraphDataFrameBridge
using MetaGraphs
using CSV
using LightGraphs
using Random
using DataFramesMeta
# -

"""    load_graph_data(input_data::Array{Any,1})

Helper function that allows a synthetic set of vertices or edges to be represented as an array for the purpose of serialization.
"""
function load_graph_data(input_data)

    return input_data
end

"""    gen_rand_vertex_name(vertex_type::String, tag::String)

This function outputs a vertex name that reflects the provided type and tag, and includes a random component to ensure uniqueness.

see also: [`Graphs.generate_synthetic_vertices`](@ref), [`gen_vertex_hash`](@ref)
"""
function gen_rand_vertex_name(vertex_type::String, tag="synth")
    return string(tag, "_", vertex_type, "_", randstring(MersenneTwister(), 'a':'z', 6))
end

"""    gen_vertex_hash(vertex_name::String, vertex_type::String)

This function computes the hash of a vertex's name and type; this combination is assumed to be unique within the graph.

see also: [`generate_synthetic_vertices`](@ref), [`gen_rand_vertex_name`](@ref)
"""
function gen_vertex_hash(vertex_name::String, vertex_type::String)
    return hash(string(vertex_name, vertex_type))
end

# +
"""    generate_synthetic_vertices(vertex_type_defs::String, output_path::String)

Generate synthetic test data. The synthetic vertices are returned as a dataframe
that can be used for testing/debugging/developing the knowledge graph.

see also: [`generate_synthetic_edges`](@ref)
"""
function generate_synthetic_vertices(vertex_type_defs::String, output_path::String)
    vertex_types = CSV.read(vertex_type_defs)
    synth_vertices_df = []
    for vertex in eachrow(vertex_types)
        # Generate a synthetic name
        v_name = gen_rand_vertex_name(vertex.v_type, "synth")
        # Get an id for that name
        v_hash = gen_vertex_hash(v_name, vertex.v_type)
        synth_v_attrs = (v_hash="$v_hash", v_name=v_name, v_type=v_type)
        push!(synth_vertices_df, synth_v_attrs)

    end
    open(output_path, "w") do io
        print(io, repr(load_graph_data(synth_vertices_df)))
    end
    @info("Synthetic vertex dataframe generated and saved as a Julia file.")
    return DataFrame(synth_vertices_df)

end
# -

# """    generate_synthetic_edges(edge_type_defs::String, synth_vertex_df::DataFrame, output_path::String)
#
# Generate synthetic test data. The synthetic edges are returned as a dataframe
# that can be used for testing/debugging/developing the knowledge graph.
#
# see also: [`generate_synthetic_vertices`](@ref)
# """
# function generate_synthetic_edges(edge_type_defs::String, synth_vertex_df::DataFrame, output_path::String)
#
#     edge_types = CSV.read(edge_type_defs)
#
#     synth_edges_df = []
#
#     for edge_row in eachrow(edge_types)
#
#         src_row = @linq synth_vertex_df |>
#             where(:v_type .== edge_row.src_type) |>
#             select(:v_hash, :v_name, :v_type)
#
#         dst_row = @linq synth_vertex_df |>
#             where(:v_type .== edge_row.dst_type) |>
#             select(:v_hash, :v_name, :v_type)
#
#         if size(src_row)[1] >=1 && size(dst_row)[1] >= 1
#             src_vhash = src_row.v_hash[1]
#             src_name = src_row.v_name[1]
#             src_vtype = src_row.v_type[1]
#
#             dst_vhash = dst_row.v_hash[1]
#             dst_name = dst_row.v_name[1]
#             dst_vtype = dst_row.v_type[1]
#
#             if edge_row.value_field != "nothing"
#                 edge_val = ("placeholder")
#             else
#                 edge_val = nothing
#             end
#
#             synth_edge_attrs = (src_vhash="$src_vhash",
#                                 src_name=src_name,
#                                 src_vtype=src_vtype,
#                                 dst_vhash="$dst_vhash",
#                                 dst_name=dst_name,
#                                 dst_vtype=dst_vtype,
#                                 edge_relation=edge_row.edge_relation,
#                                 edge_description=edge_row.description,
#                                 value=edge_val),
#             push!(synth_edges_df, synth_edge_attrs)
#         else
#             continue
#         end
#     end
#
#     open(output_path, "w") do io
#         print(io, repr(load_graph_data(synth_edges_df)))
#     end
#     @info("Synthetic edge dataframe generated", file=output_path)
#     return DataFrame(synth_edges_df)
#
# end

# +
"""    insert_vertices_from_jl(vertices_file::String, input_graph::Nothing)

Ingests and evaulates a Julia file containing vertex information; instantiates an empty knowledge graph and inserts each unique vertex into this graph.

see also: [`insert_edges_from_jl`](@ref)
"""
function insert_vertices_from_jl(vertices_file::String, input_graph::Nothing)
    # The graph is currently empty;
    # objective is to create it from the input vertex and edge files.
    v_df = DataFrame(include(vertices_file))

    G = MetaDiGraph()
    counter = 1::Int64
    set_indexing_prop!(G, :v_hash)
    for v in eachrow(v_df)
        v_hash = gen_vertex_hash(v.v_name, v.v_type)
        v_attrs = Dict(
            :v_name=>v.v_name,
            :v_type=>v.v_type)
        add_vertex!(G)
        set_indexing_prop!(G, counter, :v_hash, "$v_hash")
        set_props!(G, counter, v_attrs)
        @info("Inserting new vertex into graph:", vertex=v)
        counter += 1
    end
    n = nv(G)
    @info("Returning graph G", nv=nv(G))
    return G

end
# -

"""    insert_vertices_from_jl(vertices_file::String, input_graph::MetaDiGraph)

Ingests and evaulates a Julia file containing vertex information; instantiates
an empty knowledge graph and inserts each unique vertex into this graph.

see also: [`insert_edges_from_jl`](@ref)
"""
function insert_vertices_from_jl(vertices_file::String, input_graph::MetaDiGraph)
    v_df = DataFrame(include(vertices_file))
    n_vertices_input = nv(input_graph)
    n_vertices = size(v_df,1) + n_vertices_input

    counter = nv(input_graph) + 1

    G = MetaDiGraph()

    # insert vertices (with properties) from the input graph
    for i in 1:nv(input_graph)
        v_props = props(input_graph, i)
        add_vertex!(G)
        set_indexing_prop!(G, i, :v_hash, v_props[:v_hash])
        set_props!(G, i,
            Dict(:v_name=>v_props[:v_name],
                 :v_type=>v_props[:v_type]))
    end
    @info("input graph have been inserted.", nv=n_vertices_input)
    for v in eachrow(v_df)
        v_hash = gen_vertex_hash(v.v_name, v.v_type)
        try
            G["$v_hash", :v_hash]
            @info("A vertex with this hash value already exists in the graph.", vhash=v_hash)
        catch error
            if isa(error, KeyError) || isa(error, ExceptionError)
            v_attrs = Dict(
                    :v_name=>v.v_name,
                    :v_type=>v.v_type)
                add_vertex!(G)
                set_indexing_prop!(G, counter, :v_hash, "$v_hash")
                set_props!(G, counter, v_attrs)
                @info("Inserting new vertex into graph", v=v)
                counter += 1
            end
        end
    end
    @info("Returning graph G.", nv=nv(G))
    return G
end


"""    copy_input_graph_to_new_graph(input_graph::MetaDiGraph)

Helper function that instantiates a new MetaDiGraph and inserts vertices/edges
from an (existing) input graph.

see also: [`insert_edges_from_jl`](@ref)
"""
function copy_input_graph_to_new_graph(input_graph::MetaDiGraph)
    G = MetaDiGraph()
    # Insert vertices (with properties) from the input graph
    for i in 1:nv(input_graph)
        v_props = props(input_graph, i)
        add_vertex!(G)
        set_indexing_prop!(G, i, :v_hash, v_props[:v_hash])
        set_props!(G, i,
            Dict(:v_name=>v_props[:v_name],
                 :v_type=>v_props[:v_type]))
    end

    # Insert edges (with properties) from the input graph
    for edge in edges(input_graph)
        e_props = props(input_graph, edge)
        add_edge!(G, edge.src, edge.dst)
        set_props!(G, Edge(edge.src, edge.dst), e_props)
    end
    return G
end



# +
"""    insert_edges_from_jl(edges_file::String, input_graph::MetaDiGraph)

Takes as input an existing graph and an edge file. Each edge in the file is
either inserted (if new) or (if already in G), an associated integer weight is
incremented.

see also: [`insert_vertices_from_jl`](@ref), [`copy_input_graph_to_new_graph`](@ref)
"""
function insert_edges_from_jl(edges_file::String, input_graph::MetaDiGraph)
    # Edges may contain vertices that are \notin G (e.g. v \in E_1 \bigcup E_0 may be \emptyset)
    e_df = DataFrame(include(edges_file))
    
    if nv(input_graph) > 0
        vertices_already_in_G = [get_prop(input_graph, v, :v_hash) for v in vertices(input_graph)]
        G = copy_input_graph_to_new_graph(input_graph)
        set_indexing_prop!(G, :v_hash)
    else
        vertices_already_in_G = []
        G = copy(input_graph)
    end
    
    vertices_in_edgelist = cat(dims=1, unique(e_df.src_vhash), unique(e_df.dst_vhash))
    refs_to_existing_vertices  = intersect(Set(vertices_already_in_G), Set(vertices_in_edgelist))

    num_vertices_g = nv(input_graph)
    num_vertices_el = length(vertices_in_edgelist)
    inter_cardinality = length(refs_to_existing_vertices)
    union_cardinality = length(union(Set(vertices_already_in_G), Set(vertices_in_edgelist)))

    if num_vertices_g == 0
        counter = 1
    elseif inter_cardinality != num_vertices_g
        counter = num_vertices_g + 1
    end

    @info("The input graph contains $num_vertices_g unique vertices")
    @info("The input edge list refers to $num_vertices_el unique vertices.", nv=num_vertices_el)
    @info("The size of the intersection of these two sets is: $inter_cardinality.", nv=inter_cardinality)

    set_indexing_prop!(G, :v_hash)
    
    for e in eachrow(e_df)
        edge_attrs = Dict(
                        :e_rel=>e.edge_relation,
                        :e_desc=>e.edge_description,
                        :e_value=>e.value,
                        :weight=>1)

        # The src vertex is \notin G; we need to insert it before we can insert the edge
        if !(e.src_vhash in vertices_already_in_G)
            src_v_hash = e.src_vhash
            src_v_attrs = Dict(
                        :v_name=>e.src_name,
                        :v_type=>e.src_vtype
            )

            add_vertex!(G)
            set_indexing_prop!(G, counter, :v_hash, "$src_v_hash")
            set_props!(G, counter, src_v_attrs)

            counter += 1
            vertices_already_in_G = cat(dims=1, "$src_v_hash", vertices_already_in_G)
            vname = e.src_name
            @info("src vertex $vname was not in G, and has been inserted.", vname=vname)
        end

        # The dst vertex is \notin G; we need to insert it before we can insert the edge
        if !(e.dst_vhash in vertices_already_in_G)
            dst_v_hash = e.dst_vhash
            dst_v_attrs = Dict(
                :v_name=>e.dst_name,
                :v_type=>e.dst_vtype
            )

            add_vertex!(G)
            set_indexing_prop!(G, counter, :v_hash, "$dst_v_hash")
            set_props!(G, counter, dst_v_attrs)

            counter += 1
            vertices_already_in_G = cat(dims=1, "$dst_v_hash", vertices_already_in_G)
            vname = e.dst_name
            @info("dst vertex $vname was not in G, and has been inserted.", vname=vname)
        end

        # All vertices referenced are now \in G; we can insert the edge or increment an existing edge's counter
        src_int_id = G[e.src_vhash, :v_hash]
        dst_int_id = G[e.dst_vhash, :v_hash]

        edge_type = e.edge_relation
        src_name = e.src_name
        dst_name = e.dst_name

        # Add a new edge to the graph
        if !(has_edge(G, src_int_id, dst_int_id))
            add_edge!(G, src_int_id, dst_int_id)
            set_props!(G, Edge(src_int_id, dst_int_id), edge_attrs)
            @info("Inserting directed edge of type $edge_type from $src_name to $dst_name.")
        #  This edge already exists \in G; increment the (frequency) counter
        #  (currently used for weight; we will probably want to think about how
        #  to best normalize these counts)
        else
            new_weight = get_prop(G, Edge(src_int_id, dst_int_id), :weight) + 1
            set_prop!(G, Edge(src_int_id, dst_int_id), :weight, new_weight)
            @info("Incrementing weight of existing directed edge",
                  edge_type=edge_type, weight=new_weight,
                  type=edge_type, src=src_name, dst=dst_name)
        end

    end

    weightfield!(G, :weight)
    num_edges_final = ne(G)
    @info("Returning graph G", nedges=num_edges_final, cardinality=union_cardinality)
    return G

end

# +
"""    insert_edges_from_jl(edges_file::String, input_graph::MetaDiGraph)

Takes as input an existing graph and an edge file. Each edge in the file is
either inserted (if new) or (if already in G), an associated integer weight is
incremented.

see also: [`insert_vertices_from_jl`](@ref), [`copy_input_graph_to_new_graph`](@ref)
"""
function insert_edges_from_jl(edges_file::DataFrame, input_graph::MetaDiGraph)
    # Edges may contain vertices that are \notin G (e.g. v \in E_1 \bigcup E_0 may be \emptyset)
    e_df = DataFrame(edges_file)
            
        if nv(input_graph) > 0
        vertices_already_in_G = [get_prop(input_graph, v, :v_hash) for v in vertices(input_graph)]
        G = copy_input_graph_to_new_graph(input_graph)
        set_indexing_prop!(G, :v_hash)
    else
        vertices_already_in_G = []
        G = copy(input_graph)
    end
    
    vertices_in_edgelist = cat(dims=1, unique(e_df.src_vhash), unique(e_df.dst_vhash))
    refs_to_existing_vertices  = intersect(Set(vertices_already_in_G), Set(vertices_in_edgelist))

    num_vertices_g = nv(input_graph)
    num_vertices_el = length(vertices_in_edgelist)
    inter_cardinality = length(refs_to_existing_vertices)
    union_cardinality = length(union(Set(vertices_already_in_G), Set(vertices_in_edgelist)))

    if num_vertices_g == 0
        counter = 1
    elseif inter_cardinality != num_vertices_g
        counter = num_vertices_g + 1
    end

    @info("The input graph contains $num_vertices_g unique vertices")
    @info("The input edge list refers to $num_vertices_el unique vertices.", nv=num_vertices_el)
    @info("The size of the intersection of these two sets is: $inter_cardinality.", nv=inter_cardinality)

    set_indexing_prop!(G, :v_hash)
            
    for e in eachrow(e_df)
        edge_attrs = Dict(
                        :e_rel=>e.edge_relation,
                        :e_desc=>e.edge_description,
                        :e_value=>e.value,
                        :weight=>1)

        # The src vertex is \notin G; we need to insert it before we can insert the edge
        if !(e.src_vhash in vertices_already_in_G)
            src_v_hash = e.src_vhash
            src_v_attrs = Dict(
                        :v_name=>e.src_name,
                        :v_type=>e.src_vtype
            )

            add_vertex!(G)
            set_indexing_prop!(G, counter, :v_hash, "$src_v_hash")
            set_props!(G, counter, src_v_attrs)

            counter += 1
            vertices_already_in_G = cat(dims=1, "$src_v_hash", vertices_already_in_G)
            vname = e.src_name
            @info("src vertex $vname was not in G, and has been inserted.", vname=vname)
        end

        # The dst vertex is \notin G; we need to insert it before we can insert the edge
        if !(e.dst_vhash in vertices_already_in_G)
            dst_v_hash = e.dst_vhash
            dst_v_attrs = Dict(
                :v_name=>e.dst_name,
                :v_type=>e.dst_vtype
            )

            add_vertex!(G)
            set_indexing_prop!(G, counter, :v_hash, "$dst_v_hash")
            set_props!(G, counter, dst_v_attrs)

            counter += 1
            vertices_already_in_G = cat(dims=1, "$dst_v_hash", vertices_already_in_G)
            vname = e.dst_name
            @info("dst vertex $vname was not in G, and has been inserted.", vname=vname)
        end

        # All vertices referenced are now \in G; we can insert the edge or increment an existing edge's counter
        src_int_id = G[e.src_vhash, :v_hash]
        dst_int_id = G[e.dst_vhash, :v_hash]

        edge_type = e.edge_relation
        src_name = e.src_name
        dst_name = e.dst_name

        # Add a new edge to the graph
        if !(has_edge(G, src_int_id, dst_int_id))
            add_edge!(G, src_int_id, dst_int_id)
            set_props!(G, Edge(src_int_id, dst_int_id), edge_attrs)
            @info("Inserting directed edge of type $edge_type from $src_name to $dst_name.")
        #  This edge already exists \in G; increment the (frequency) counter
        #  (currently used for weight; we will probably want to think about how
        #  to best normalize these counts)
        else
            new_weight = get_prop(G, Edge(src_int_id, dst_int_id), :weight) + 1
            set_prop!(G, Edge(src_int_id, dst_int_id), :weight, new_weight)
            @info("Incrementing weight of existing directed edge",
                  edge_type=edge_type, weight=new_weight,
                  type=edge_type, src=src_name, dst=dst_name)
        end

    end

    weightfield!(G, :weight)
    num_edges_final = ne(G)
    @info("Returning graph G", nedges=num_edges_final, cardinality=union_cardinality)
    return G

end

# +
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
