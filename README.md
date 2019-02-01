# SemanticModels.jl
A julia package for representing and manipulating model semantics

[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://jpfairbanks.com/doc/aske)

## Getting Started

Install this package with 

```julia
Pkg.develop("git@github.com:jpfairbanks/SemanticModels.jl.git")
Pkg.develop("Cassette")
Pkg.test("SemanticModels")
```

Note that loading this package for the first time can take a while because `DifferentialEquations` is a large library that
requires a long precompilation step. Various functions in the `SemanticModels.Dubstep` module can also have long
precompile times, due to heavy use of generated functions.

Then you can load it at the julia REPL with `using SemanticModels`

There are scripts in the folder `SemanticModels/bin` which provide command line access to some functionality of the
package. For example `julia --project bin/extract.jl
examples/epicookbook/notebooks/SimpleDeterministicModels/SEIRmodel.jl` will extract code based knowledge elements from
the julia source code file `examples/epicookbook/notebooks/SimpleDeterministicModels/SEIRmodel.jl`. 

See the tests and documentation for example usage.


## Documentation

There is a docs folder which contains the documentation, including reports sent to our sponsor, DARPA.

Documentation is currently published aske.gtri.gatech.edu

Many of our documentation and examples are built with Jupyter notebooks. We use
[jupytext](https://github.com/mwouts/jupytext) to support diff friendly outputs in the repo.
Please follow the jupytext readme to install this jupyter plugin.


### Examples

In addition to the examples in the documentation, there are fully worked out examples in the folder
https://github.com/jpfairbanks/SemanticModels.jl/tree/master/examples/. Each subdirectory represents one self contained
example, starting with `epicookbook`.

## Concepts

Here is a preview of the concepts used in SemanticModels, please see the full documentation for a more thorough description.

### Knowledge Graph

We will use MetaGraphs.jl to model the relationships between models and concepts in a knowledge graph

### Knowledge Graph Extraction

You can use the `Extractor` type to pull knowledge elements from an artifact. The following are subtypes of `Artifact`

- Docs
- Code
- Model
- Paper

### Overdubbing

You can modify a program's execution using `Cassette.overdub` and replace function calls with your own functions. For an example, see `test/transform/ode.jl`. Or you can use a new compiler pass if you need more control over the values that you want to manipulate. 

## Acknowledgements

This material is based upon work supported by the Defense Advanced Research Projects Agency (DARPA) under Agreement No. HR00111990008.
