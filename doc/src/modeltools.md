# ModelTools


## Using ModelTools

![ModelTools](http://localhost:8100/img/semanticmodels_jl.dot.svg)

ModelTools provides the functionality for model augmentation. It is named after the great metaprogramming package
[MacroTools.jl](https://github.com/MikeInnes/MacroTools.jl/). With ModelTools, you treat models as code and metaprogram
on them like Lisp programs. This part of SemanticModels really shows how Julia could have been named HPC Lisp.

1. Introduce a new class of models to analyze by writing a struct to represent models from class $\mathcal{C}$ along
   with a constructor `model(::C, ex::Expr)`.
1. Define a set of transformations (`T<:ModelTools.Transformation`) that are valid on that class of models
1. Use SemanticModels functions to implement the constructor and transforms.
1. Write programs that take models (as ASTs) and returns novel models (`<:ModelTools.AbstractModel`)
1. Analyze compositions of transformations and compare new models with old models (Metamodeling)

Under this workflow SemanticModels is more of a framework than a library, but it is extensible and can be used to take
real world modeling code and build a modeling framework around it, rather than building a modeling framework and then
porting the models into the framework.

See the examples folder for usage of how to build model types and use transformations for common metamodeling tasks.
A complete [ModelTools Library Reference](@ref) can be found below.

## Model Tools Examples

The following examples are found in the folder `SemanticModels/examples` as julia files that can be viewed as
notebooks with jupytext or as rendered HTML pages in the docs.

### Model Augmentation

These examples illustrate model augmentation with ModelTools
1. [agentbased.jl](examples/html/agentbased.html)
1. [agentgraft.jl](examples/html/agentgraft.html)
1. [odegraft.jl](examples/html/odegraft.html)

### Algebraic Model Transformation
These examples illustrate how model transformations can be algebraic structures
and how to exploit that to develop new models
1. [monomial_regression.jl](examples/html/monomial_regression.html)
1. [multivariate_regression.jl](examples/html/multivariate_regression.html)
1. [pseudo_polynomial_regression.jl](examples/html/pseudo_polynomial_regression.html)
1. [polynomial_regression.jl](examples/html/polynomial_regression.html)

### Model Synthesis
The workflow example combines `agentgraft.jl` and `polynomial_regression.jl` to
build a modeling pipeline. This is the most important example for understanding
the power of SemanticModels for model augmentation and synthesis.

[workflow.jl](examples/html/workflow.html)

### Programming the type system
These examples show how the Julia type systems is a strong ally in bringing
order to the chaos that is scientific modeling code. 
1. [agentbased2.jl](examples/html/agentbased2.html)
1. [agenttypes.jl](examples/html/agenttypes.html)
1. [agenttypes2.jl](examples/html/agenttypes2.html)

### Knowledge Representation with Knowledge Graphs
1. [semanticClustering](https://github.com/jpfairbanks/SemanticModels.jl/blob/masterexamples/semanticClustering)
1. [dataflow.jl](examples/html/dataflow.html)
1. [Code Embeddings](https://github.com/jpfairbanks/SemanticModels.jl/blob/master/doc/src/notebooks/autoencoding_julia.ipynb)

## Pre hoc vs post hoc frameworks

A normal modeling framework, is a software package that defines a set of modeling constructs for representing problems
and a set of algorithms that solve those problem.

A typical modeling framework is developed when: 

1. A library author (LA) decides to write a library for solving models of a specific class $\mathcal{C}$
1. LA develops a DSL for representing models in $\mathcal{C}$
1. LA develops solvers for models in $\mathcal{C}$
1. Scientist (S) uses LA's macros to write new models and pass them to the solvers
1. S publishes many great papers with the awesome framework

[ModelingToolkit.jl](https://github.com/JuliaDiffEq/ModelingToolkit.jl) is a framework for building DSLs for expressing
mathematical models of scientific phenomena. And so you could think of it as a meta-DSL a language for describing
languages that describe models. Their workflow is:

1. A library author (LA) decides to write a library for solving models of a specific class $\mathcal{C}$
1. LA develops a DSL for representing models in $\mathcal{C}$ using ModelingToolkit (MT).
1. LA develops solvers for models in $\mathcal{C}$ using the intermediate representations provided by MT. 
1. Scientist (S) uses $LA$'s macros to write new models and pass them to the solvers
1. S publishes many great papers with the awesome framework

This is a great idea and I hope it succeeds because it will revolutionize how people develop scientific software and
really benefit many communities.

One of the assumptions of the SemanticModels is that we can't make scientists use a modeling language. This is
reasonable because the really interesting models are pushing the boundaries of the solvers and the libraries, so if you
have to change the modeling language every time you add a novel model, what is the modeling language getting you?

Another key idea inspiring ModelTools is that every software library introduces a miniature DSL for using that library.
You have to set up the problem in some way, pass the parameters and options to to the solver, and then interpret the
solution. These miniDSLs form through idiomatic usage instead of through an explicit representation like ModelingToolkit
provides.

SemanticModels actually can address this as the inverse problem of ModelingToolkit. We are saying, given a corpus of
usage for a given library, what is the implicit DSL that users have developed?

Our workflow is:

1. Identify a widely used library
1. Gather code samples that use that library
1. Process the corpus to build a representation of how that library "should" be used
1. Build a DSL for that class of problems
1. New researchers and AI scientists can use the new DSL for representing the novel models
1. Generate new models in the DSL using transformations that are valid in the DSL.

In this line of inquiry the DSL plays the role of the "structured semantic representation" of the model. We could use
ModelingToolkit DSLs as the backend.

## ModelTools Library Reference

```@autodocs
Modules = [SemanticModels.ModelTools]
```

### Transformations

The following transformations ship with ModelTools, you can use them as templates for defining your own model classes.

```@autodocs
Modules = [SemanticModels.ModelTools.Transformations]
```

### Model Classes 

The following model class ship with ModelTools, you can use them as templates for defining your own model classes.
```@autodocs
Modules = [SemanticModels.ModelTools.SimpleModels,
SemanticModels.ModelTools.ExpStateModels, SemanticModels.ModelTools.ExpODEModels]
```

## Index

```@index
```
