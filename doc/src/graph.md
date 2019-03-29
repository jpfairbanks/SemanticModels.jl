# Knowledge Graphs

We use MetaGraphs.jl `MetaDiGraph`s to represent the knowledge we have extracted from code and text. 

## Schema

To construct our knowledge graph, we have developed a schema with defined vertex and edge types; the metadata associated with a given vertex or edge will depend on its type. The diagram below visually represents this schema:


![Schema Diagram](img/olog.dot.svg)

### Vertex Types

```@eval
using CSV
using Latexify
df = CSV.read("../../examples/knowledge_graph/data/kg_vertex_types.csv")
mdtable(df,latex=false)
```

### Edge Types

```@eval
using CSV
using Latexify
df = CSV.read("../../examples/knowledge_graph/data/kg_edge_types.csv")
mdtable(df,latex=false)
```

Since those types are abstract, here are some examples that should make clear what is happening.
### Example Vertices

```@eval
using CSV
using Latexify
df = CSV.read("../../examples/knowledge_graph/data/kg_vertices.csv")
mdtable(df,latex=false)
```

### Example Edges
```@eval
using CSV
using Latexify
df = CSV.read("../../examples/knowledge_graph/data/synth_kg_edges.csv")
mdtable(df,latex=false)
```
<!-- ## API reference -->

<!-- ```@autodocs -->
<!-- Modules = [SemanticModels.Graphs] -->
<!-- ``` -->
