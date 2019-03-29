# Examples

This folder contains examples of how to use SemanticModels.jl

The top level folder contains several examples of different modeling tasks that
can be performed with Semanticmodels.jl. Of particular interest are the
following:


## Prerequisites

The examples require the some dependencies, they are pre-installed in the
docker container, and you can install them with 

```julia
using Pkg
Pkg.add(["LsqFit",
  "Polynomials",
  "DifferentialEquations",
  "Plots",
  "LightGraphs",
  "MetaGraphs"])`
```

You will also need the graphviz program `dot` in order to draw graphs as SVG
images. To install the graphviz program you should use your system package
manager, such as `apt install graphviz` or `homebrew graphviz`

The examples are best viewed in the following order.

## Model Augmentation

These examples illustrate model augmentation with ModelTools
1. [agentbased.jl](github.com/jpfairbanks/SemanticModels.jl/blob/master/examples/agentbased.jl)
1. [agentgraft.jl](github.com/jpfairbanks/SemanticModels.jl/blob/master/examples/agentgraft.jl)
1. [odegraft.jl](github.com/jpfairbanks/SemanticModels.jl/blob/master/examples/odegraft.jl)

## Algebraic Model Transformation
These examples illustrate how model transformations can be algebraic structures
and how to exploit that to develop new models
1. [monomial_regression.jl](github.com/jpfairbanks/SemanticModels.jl/blob/master/examples/monomial_regression.jl)
1. [multivariate_regression.jl](github.com/jpfairbanks/SemanticModels.jl/blob/master/examples/multivariate_regression.jl)
1. [pseudo_polynomial_regression.jl](github.com/jpfairbanks/SemanticModels.jl/blob/master/examples/pseudo_polynomial_regression.jl)
1. [polynomial_regression.jl](github.com/jpfairbanks/SemanticModels.jl/blob/master/examples/polynomial_regression.jl)

## Model Synthesis
The workflow example combines `agentgraft.jl` and `polynomial_regression.jl` to
build a modeling pipeline. This is the most important example for understanding
the power of SemanticModels for model augmentation and synthesis.

[workflow.jl](github.com/jpfairbanks/SemanticModels.jl/blob/master/examples/workflow.jl)

## Programming the type system
These examples show how the Julia type systems is a strong ally in bringing
order to the chaos that is scientific modeling code. 
1. [agentbased2.jl](github.com/jpfairbanks/SemanticModels.jl/blob/master/examples/agentbased2.jl)
1. [agenttypes.jl](github.com/jpfairbanks/SemanticModels.jl/blob/master/examples/agenttypes.jl)
1. [agenttypes2.jl](github.com/jpfairbanks/SemanticModels.jl/blob/master/examples/agenttypes2.jl)

## Knowledge Representation with Knowledge Graphs
1. [semanticClustering](github.com/jpfairbanks/SemanticModels.jl/blob/master/examples/semanticClustering)
1. [dataflow.jl](github.com/jpfairbanks/SemanticModels.jl/blob/master/examples/dataflow.jl)
1. [Code Embeddings](github.com/jpfairbanks/SemanticModels.jl/blob/master/doc/src/notebooks/autoencoding_julia.ipynb)

The examples are run as part of the test suite in `SemanticModels/test/runtests.jl`

Additional subfolders exist for storing collections of programs from the wild
include epicookbook and stats.

Each subfolder contains a README.md and should have the same layout in terms of 

  - src/
  - data/
  - notebooks/
  - docs/
