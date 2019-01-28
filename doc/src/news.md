# News

## Release v0.2

- New submodules
  - Dubstep
    - [`Dubstep.TraceCtx`](@ref) builds dynamic analysis traces of a model for information extraction
    - [`Dubstep.LPCtx`](@ref) allows you to modify the norms used in a model
    - [`Dubstep.GraftCtx`](@ref) allows grafting components of one model onto another
  - Parsers
    - [`Parsers.parsefile`](@ref) reads in a julia source file as an expression
    - [`Parsers.defs`](@ref) extracts from a module definition expression, all the code definitions
    - [`Parsers.edges`](@ref) extracts edges for the knowledge graph
  - Graphs
    - A knowledge graph schema [Knowledge Graphs](@ref)
    - [`Graphs.insert_edges_from_jl`](@ref) builds a knowledge graph from extracted edges
- Examples
  - `test/transform/ode.jl` shows how to perturb an ODE with overdub
  - `test/transform/varextract.jl` shows how to use a compiler pass to extract dynamic analysis information
- Scripts
  - `bin/extract.jl` extracts knowledge elements from source code files
  - `bin/graft.jl` performs metamodeling by grafting a component of one model onto another
  

- New docs pages
  - Dubstep
  - Knowledge Graphs
  - Knowledge Extractions
  - Validation
  - Theory
  - Contributing

## Release v0.1

Initial release
