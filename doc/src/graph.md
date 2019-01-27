# Knowledge Graphs

We use MetaGraphs.jl `MetaDiGraph`s to represent the knowledge we have extracted from the
code and test. 
## Schema

Here we define the schema for our knowledge graph. The vertices and edges have types and
the metadata associated with the vertex or edge depends on its type.

Here is a diagramatic overview of the schema for the knowledge graph. 
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
df = CSV.read("../../examples/knowledge_graph/data/kg_edges.csv")
mdtable(df,latex=false)
```
## API reference

```@autodocs
Modules = [SemanticModels.Graphs]
```
