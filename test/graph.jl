using SemanticModels
using SemanticModels.Graphs

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
