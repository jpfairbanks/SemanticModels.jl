# News

## Release v0.1

Release v0.1 includes an initial version of every step in the SemanticModels pipeline. 
Users can now extract information, build knowledge graphs, and generate new models.

The following is a summary of the most important new features and updates:

- New submodules
  - Dubstep
    - [`SemanticModels.Dubstep.TraceCtx`](@ref) builds dynamic analysis traces of a model for information extraction.
    - [`SemanticModels.Dubstep.LPCtx`](@ref) allows you to modify the norms used in a model.
    - [`SemanticModels.Dubstep.GraftCtx`](@ref) allows grafting components of one model onto another.
  - Parsers
    - [`Parsers.parsefile`](@ref) reads in a julia source file as an expression.
    - [`Parsers.defs`](@ref) extracts  all of the code definitions from a module definition expression.
    - [`Parsers.edges`](@ref) extracts edges for the knowledge graph from code.
  - Graphs
    - A knowledge graph schema [Knowledge Graphs](@ref).
    - [`Graphs.insert_edges_from_jl`](@ref) builds a knowledge graph from extracted edges.
- Examples
  - `test/transform/ode.jl` shows how to perturb an ODE with overdub.
  - `test/transform/varextract.jl` shows how to use a compiler pass to extract dynamic analysis information.
- Scripts
  - `bin/extract.jl` extracts knowledge elements from parsed markdown and source code files.
  - `bin/graft.jl` performs metamodeling by grafting a component of one model onto another.
  

- New docs pages
  - [Intended Use Cases](@ref)
  - [Dubstep](@ref)
  - [Knowledge Graphs](@ref)
  - [Knowledge Extraction](@ref)
  - [Model Validation with Dynamic Analysis](@ref)
  - [Semantic Modeling Theory](@ref)
  - [Developer Guidelines](@ref)

## Release v0.0.1

Initial release with documentation and some examples designed to illustrate the inteded scope of the software.
