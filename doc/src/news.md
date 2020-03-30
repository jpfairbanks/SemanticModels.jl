# News

## Release v0.3.0

Release v0.3.0 is a major enhancement to the new model augmentation tools introduced the the last release. This includes a more robust design, easier model implementation, and more built in features to augment and compose models.

- New submodules
    - ModelTools
        - `SemanticModels.ModelTools.CategoryTheory` the main module that contains the category theory based building blocks for model augmentation
            - `SemanticModels.ModelTools.CategoryTheory.AbstractMorph` abstract type for representing morphisms
            - `SemanticModels.ModelTools.CategoryTheory.FinSetMorph` morphism in the category of finite sets
            - `SemanticModels.ModelTools.CategoryTheory.GraphMorph` morphism in the category of graphs
            - `SemanticModels.ModelTools.CategoryTheory.⊔` get the union of two categorically defined models or morphisms
            - `SemanticModels.ModelTools.CategoryTheory.Decorated` a type representing a decoration applied to the objects of a morphism
            - `SemanticModels.ModelTools.CategoryTheory.AbstractSpan` an abstract type for representing spans
            - `SemanticModels.ModelTools.CategoryTheory.Span` general span of two morphisms
            - `SemanticModels.ModelTools.CategoryTheory.AbstractCospan` an abstract type for representing cospans
            - `SemanticModels.ModelTools.CategoryTheory.Cospan` general cospan of two morphisms
            - `SemanticModels.ModelTools.CategoryTheory.pushout` solve the pushout defined by a span
        - `SemanticModels.ModelTools.PetriModels` Extends ModelTools and the new CategoryTheory API to support models defined in [Petri.jl](https://github.com/mehalter/Petri.jl)
        - `SemanticModels.ModelTools.OpenModels` module for defining an open model where there are defined inputs and outputs, domain and codomain
        - `SemanticModels.ModelTools.OpenPetris` module for implementing the open petri model, and converting a PetriModel to an OpenPetri
            - `SemanticModels.ModelTools.OpenPetris.otimes` combine two open petri models in parallel
            - `SemanticModels.ModelTools.OpenPetris.compose` combine two open petri models in series
- New examples
    - `decorations/graphs.jl` example of using the new Category Theory based Morphism API to combine graphs and Petri models
    - `petri/malaria.ipynb` example of utilizing the new OpenModel API to combine a Lotka Volterra model and an Epidemiology model to simulate Malaria spreading between a population
    - `petri/rewrite_demo.jl` example of using rewrite rules to augment a Petri model
    - `petri/rewrite.jl` more detailed example of using rewrite rules to augment a Petri model and then solving the new models using both agent based models and differential equations
    - `petri/wiring_petri.jl` example of creating a model using wiring diagrams, converting that to a Petri model, and solving
- New docs pages
    - Removed Dubstep
    - Updates to ModelTools
    - Updates to Theory
    - Replaced Flu Model walkthrough with Malaria example

## Release v0.2.0

Release v0.2.0 include an inital version of our new model augmentation tools and program analysis features.

- New submodules
    - ModelTools
        - `SemanticModels.ModelTools.model` the main constructor for building model instances
        - Tools for accessing parts of expressions
            - `SemanticModels.ModelTools.head` gets the head of an Expr or nothing for LineNumberNodes
            - `SemanticModels.ModelTools.bodyblock` gets the body of the func
            - `SemanticModels.ModelTools.argslist` get the array of args representing the arguments of a defined function
            - `SemanticModels.ModelTools.funcname` get the function name from an expression object return :nothing for non function expressions
            - `SemanticModels.ModelTools.callsites` collects func calls
            - `SemanticModels.ModelTools.structured` extract the expressions that use structuring
        - Tools for modifying expressions
            - `SemanticModels.ModelTools.pusharg!` push a new argument onto the definition of a function.
            - `SemanticModels.ModelTools.setarg!` replace the argument in a function call
        - Predicates useful for manipulating expressions
            - `SemanticModels.ModelTools.or` or
            - `SemanticModels.ModelTools.and` and
            - `SemanticModels.ModelTools.issome` predicate for being neither missing or nothing
            - `SemanticModels.ModelTools.isblock` predicate for an expression being a block node
            - `SemanticModels.ModelTools.isfunc` predicate for an expression being a function
            - `SemanticModels.ModelTools.isexpr` checks if expr
            - `SemanticModels.ModelTools.iscall` checks if func call
            - `SemanticModels.ModelTools.isusing` checks for using statement
            - `SemanticModels.ModelTools.isimport` checks for import
        - Prebuilt model types
            - `SemanticModels.ModelTools.AbstractModel` the abstract type for generic models
            - `SemanticModels.ModelTools.SimpleModels.SimpleModel` represents generic models with just blocks and functions
            - `SemanticModels.ModelTools.ExpStateModels.ExpStateModel` represents a simple Agent Based Modeling (ABM) framework
            - `SemanticModels.ModelTools.ExpStateModels.ExpStateTransition` represents ABM transitions
            - `SemanticModels.ModelTools.ExpODEModels.ExpODEModel` represents ODEProblems as code expressions
        - Type Graphs
            - `SemanticModels.ModelTools.typegraph` annotate a code expression so that when you eval it, you get the typegraph
            - `SemanticModels.ModelTools.@typegraph` extract a typegraph from a block of code
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
    - `SemanticModels.Dubstep.TraceCtx` builds dynamic analysis traces of a model for information extraction.
    - `SemanticModels.Dubstep.LPCtx` allows you to modify the norms used in a model.
    - `SemanticModels.Dubstep.GraftCtx` allows grafting components of one model onto another.
  - Parsers
    - `Parsers.parsefile` reads in a julia source file as an expression.
    - `Parsers.defs` extracts  all of the code definitions from a module definition expression.
    - `Parsers.edges` extracts edges for the knowledge graph from code.
  - Graphs
    - A knowledge graph schema Knowledge Graphs.
    - `Graphs.insert_edges_from_jl` builds a knowledge graph from extracted edges.
- Examples
  - `test/transform/ode.jl` shows how to perturb an ODE with overdub.
  - `test/transform/varextract.jl` shows how to use a compiler pass to extract dynamic analysis information.
- Scripts
  - `bin/extract.jl` extracts knowledge elements from parsed markdown and source code files.
  - `bin/graft.jl` performs metamodeling by grafting a component of one model onto another.

- New docs pages
  - Intended Use Cases
  - Dubstep
  - Knowledge Graphs
  - Knowledge Extraction
  - Model Validation with Dynamic Analysis
  - Semantic Modeling Theory
  - Developer Guidelines

## Release v0.0.1

Initial release with documentation and some examples designed to illustrate the inteded scope of the software.
