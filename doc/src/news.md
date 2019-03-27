# News

## Release v0.2.0

Release v0.2.0 include an inital version of our new model augmentation tools and program analysis features
- New submodules
    - ModelTools
        - [`SemanticModels.ModelTools.ExpODEModels.ExpODEModel`](@ref) tool kit for manipulating odes
        - [`SemanticModels.ModelTools.model`](@ref) tool kit for manipulating models
        - [`SemanticModels.ModelTools.ExpStateModels.ExpStateModel`](@ref) tool kit for manipulating abm
        - [`SemanticModels.ModelTools.ExpStateModels.ExpStateTransition`](@ref) tool kit for manipulating abm transitions
        - [`SemanticModels.ModelTools.callsites`](@ref) collects func calls
        - [`SemanticModels.ModelTools.structured`](@ref) extract the expressions that use structuring
        - [`SemanticModels.ModelTools.AbstractModel`](@ref) a placeholder struct to dispatch on how to parse the expression tree into a model.
        - [`SemanticModels.ModelTools.pusharg!`](@ref) push a new argument onto the definition of a function.
        - [`SemanticModels.ModelTools.SimpleModels.SimpleModel`](@ref) generic simple model
        - [`SemanticModels.ModelTools.setarg!`](@ref) replace the argument in a function call
        - [`SemanticModels.ModelTools.bodyblock`](@ref) gets the body of the func
        - [`SemanticModels.ModelTools.argslist`](@ref) get the array of args representing the arguments of a defined function
        - [`SemanticModels.ModelTools.issome`](@ref) predicate for being neither missing or nothing
        - [`SemanticModels.ModelTools.head`](@ref) gets the head of an Expr or nothing for LineNumberNodes
        - [`SemanticModels.ModelTools.isblock`](@ref) predicate for an expression being a block node
        - [`SemanticModels.ModelTools.isfunc`](@ref) predicate for an expression being a function
        - [`SemanticModels.ModelTools.or`](@ref) or
        - [`SemanticModels.ModelTools.and`](@ref) and
        - [`SemanticModels.ModelTools.isexpr`](@ref) checks if expr
        - [`SemanticModels.ModelTools.iscall`](@ref) checks if func call
        - [`SemanticModels.ModelTools.isusing`](@ref) checks for using statement
        - [`SemanticModels.ModelTools.isimport`](@ref) checks for import 
        - [`SemanticModels.ModelTools.funcname`](@ref) get the function name from an expression object return :nothing for non function expressions
        - [`SemanticModels.ModelTools.typegraph`](@ref) annotate a code expression so that when you eval it, you get the typegraph
        - [`SemanticModels.ModelTools.@typegraph`](@ref) extract a typegraph        
- Examples
    - `agentbased.jl` we define a modeling microframework for ABM
    - `agentbased2.jl` another ABM example
    - `agentgraft.jl` an example of model augmentation 
    - `agenttype.jl` example of how to reverse engineer a model structure
    - `defintions.jl` 
    - `diffeq.jl` 
    - `macromodel.jl` example of using modeltools
    - `monomial_regression.jl` transformations on regression
    - `multivariate_regression.jl` product group to manipulate a multivariate regression model
    - `odegraft.jl` updated version of our old graft script
    - `polynomial_regression.jl` manipulate a univariate regression model
    - `pseudo_polynomial_regression.jl` transformation on regression model
    - `regression.jl` basic regression script 
    - `workflow.jl` overview of how the semanticmodels workflow goes
    
- New docs pages


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
