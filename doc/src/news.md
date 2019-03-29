# News

## Release v0.2.0

Release v0.2.0 include an inital version of our new model augmentation tools and program analysis features.

- New submodules
    - ModelTools
        - [`SemanticModels.ModelTools.model`](@ref) the main constructor for building model instances
        - Tools for accessing parts of expressions
            - [`SemanticModels.ModelTools.head`](@ref) gets the head of an Expr or nothing for LineNumberNodes
            - [`SemanticModels.ModelTools.bodyblock`](@ref) gets the body of the func
            - [`SemanticModels.ModelTools.argslist`](@ref) get the array of args representing the arguments of a defined function
            - [`SemanticModels.ModelTools.funcname`](@ref) get the function name from an expression object return :nothing for non function expressions
            - [`SemanticModels.ModelTools.callsites`](@ref) collects func calls
            - [`SemanticModels.ModelTools.structured`](@ref) extract the expressions that use structuring
        - Tools for modifying expressions
            - [`SemanticModels.ModelTools.pusharg!`](@ref) push a new argument onto the definition of a function.
            - [`SemanticModels.ModelTools.setarg!`](@ref) replace the argument in a function call
        - Predicates useful for manipulating expressions
            - [`SemanticModels.ModelTools.or`](@ref) or
            - [`SemanticModels.ModelTools.and`](@ref) and
            - [`SemanticModels.ModelTools.issome`](@ref) predicate for being neither missing or nothing
            - [`SemanticModels.ModelTools.isblock`](@ref) predicate for an expression being a block node
            - [`SemanticModels.ModelTools.isfunc`](@ref) predicate for an expression being a function
            - [`SemanticModels.ModelTools.isexpr`](@ref) checks if expr
            - [`SemanticModels.ModelTools.iscall`](@ref) checks if func call
            - [`SemanticModels.ModelTools.isusing`](@ref) checks for using statement
            - [`SemanticModels.ModelTools.isimport`](@ref) checks for import 
        - Prebuilt model types
            - [`SemanticModels.ModelTools.AbstractModel`](@ref) the abstract type for generic models
            - [`SemanticModels.ModelTools.SimpleModels.SimpleModel`](@ref) represents generic models with just blocks and functions
            - [`SemanticModels.ModelTools.ExpStateModels.ExpStateModel`](@ref) represents a simple Agent Based Modeling (ABM) framework
            - [`SemanticModels.ModelTools.ExpStateModels.ExpStateTransition`](@ref) represents ABM transitions
            - [`SemanticModels.ModelTools.ExpODEModels.ExpODEModel`](@ref) represents ODEProblems as code expressions
        - Type Graphs
            - [`SemanticModels.ModelTools.typegraph`](@ref) annotate a code expression so that when you eval it, you get the typegraph
            - [`SemanticModels.ModelTools.@typegraph`](@ref) extract a typegraph from a block of code
- Examples
    - `agentbased.jl` we define a modeling microframework for Agent Based Modeling (ABM)
    - `agentbased2.jl` a more refined version of agentbased.jl that uses singleton types
    - `agentgraft.jl` an example of model augmentation for ABM
    - `agenttype.jl` example of how to reverse engineer a model structure with the typegraph function
    - `defintions.jl` 
    - `diffeq.jl` 
    - `macromodel.jl` example of using modeltools as a macro
    - `regression.jl` basic regression script 
    - `monomial_regression.jl` transformations on linear regression build nonlinear regression
    - `multivariate_regression.jl` product group to manipulate a multivariate regression model
    - `odegraft.jl` updated version of our old graft.jl script
    - `pseudo_polynomial_regression.jl` transforms linear regression into a 1 degree of freedom polynomial regression
    - `polynomial_regression.jl` manipulate a univariate linear regression model into polynomial regression
    - `workflow.jl` model synthesis with a pipeline of agentgraft.jl and polynomial_regression.jl
    
- New docs pages
    - ModelTools
    - Updates to Theory
    - Updated examples
    
- Removed Functionality
    - SemanticModels.Graph, replaced by `SemanticModels.ModelTools.typegraph`
    - Parsers.edges, replaces by `typegraph` and `MetaGraphs.edges(g)`

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
    - `Parsers.edges` extracts edges for the knowledge graph from code.
  - Graphs
    - A knowledge graph schema [Knowledge Graphs](@ref).
    - `Graphs.insert_edges_from_jl` builds a knowledge graph from extracted edges.
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
