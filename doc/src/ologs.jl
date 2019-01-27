using CSV
using MetaGraphs
using GraphDataFrameBridge
using LightGraphs

path = "examples/knowledge_graph/data/kg_vertex_types.csv"
edgepath = "examples/knowledge_graph/data/kg_edge_types.csv"
vf = CSV.read(path)
ef = CSV.read(edgepath)
g = GraphDataFrameBridge.metagraph_from_dataframe(MetaDiGraph, ef, :src_type, :dst_type)
set_indexing_prop!(g, :name)
println(g)
for v in vertices(g)
    name = props(g, v)[:name]
    set_prop!(g, v, :label, name)
end

for row in eachrow(ef)
    @show row
    @show v, u = g[row.src_type, :name], g[row.dst_type, :name]
    @show set_prop!(g, v,u, :label, row.edge_relation)
end

open("doc/src/img/olog.dot", "w") do fp
    MetaGraphs.savedot(fp, g)
end
