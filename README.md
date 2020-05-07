![SemanticModels.jl](doc/src/assets/full-logo.png)

---

A julia package for representing and manipulating models at the semantic level.

[![Documentation](https://github.com/jpfairbanks/SemanticModels.jl/workflows/Documentation/badge.svg)](https://aske.gtri.gatech.edu/docs/latest/)
[![Tests](https://github.com/jpfairbanks/SemanticModels.jl/workflows/Tests/badge.svg)](https://github.com/jpfairbanks/SemanticModels.jl/actions)
[![DOI](https://zenodo.org/badge/155782638.svg)](https://zenodo.org/badge/latestdoi/155782638)

Traditional scientific computing happens by translating conceptual models of natural phenomena into mathematical models
on a chalkboard and then implementing those models in code that is then compiled into executable instructions and run on
a machine. However, changes to these models traditionally require modelers to go back to the drawing board and change
the conceptual and mathematical model before implementing new software to analyze the new model. The new software is
always built by changing the old software until you build up enough cruft to declare it legacy code and start over.
SemanticModels changes this by representing models at a semantic level and allowing programs to be expressed as
transformations on these models.

<!-- ![SemanticModels Diagram](https://aske.gtri.gatech.edu/docs/latest/img/semanticmodels_jl.dot.svg) -->

The domains of software security and programming language theory (PLT) have spent a lot of time developing software and
theory for the analysis of computer programs, but these tools have not been adopted by the scientific community. This is
because the tools understand the programs as software, without consideration of the conceptual and mathematical
structure above them. SemanticModels.jl addresses this problem.

General purpose solvers such as [Jump](http://www.juliaopt.org/JuMP.jl/v0.19.0/) and [Stan](https://mc-stan.org/)
introduce domain specific languages to describe the problems that they can solve. This is a great step in the right
direction because the DSL often contains the semantic structures of the modeling domain embedded in the language.
If all scientific software was written in these DSLs we would be able to apply program analysis to the models and enable
powerful program transformations to build better systems for scientists and enable AI algorithms to write scientific codes.
Packages like [ModelingToolkit.jl](https://github.com/JuliaDiffEq/ModelingToolkit.jl), which builds a tools to design
these DSLs will help achieve that vision.

SemanticModels takes an alternative approach, which is to learn the DSL from actual usage of the libraries.
Every software library defines an implicit embedded DSL for its users. We aim to leverage that fact, along with large
collections of open source software to learn the modeling frameworks from the corpus of code.


## Getting Started

Install this package with

```julia
Pkg.add("SemanticModels")
Pkg.test("SemanticModels")

```

Then you can load it at the julia REPL with `using SemanticModels`

You should start exploring the notebooks in the examples folder. These notebooks are represented in jupytext format,
and are stored as julia programs you can run at the repl or in the notebook interface after installing the jupytext plugin for jupyter.

1. Model augmentation: an example script `examples/decorations/graphs.jl` shows how to augment an agent based simulation to add new
   modeling components using an API for changing models at the semantic level.

2. Model Representations: SemanticModels supports extracting diagram representations of scripts and creating scripts from wiring diagram representations. See the `examples/malaria/malaria.ipynb` notebook for a demonstration, as well as expanding on model augmentation by combining and composing models to build a more complex simulation.


There are scripts in the folder `SemanticModels/bin` which provide command line access to some functionality of the
package. For example `julia --project bin/extract.jl examples/epicookbook/notebooks/SimpleDeterministicModels/SEIRmodel.jl` will extract code based knowledge elements from the julia source code file `examples/epicookbook/notebooks/SimpleDeterministicModels/SEIRmodel.jl`.

See the tests and documentation for more example usage.

### Docker

You can easily spin up a `SemanticModels.jl` Jupyterlab instance with docker.

1. `docker run -it --rm -p 88889:8888 jpfa/semanticmodels:stretch`
1. Navigate to the link it returns: `localhost:8888/?token=...`
1. From there you can run the examples included in this repository, or write your own code to explore the functionality of `SemanticModels.jl`

Note: to open a `.jl` file as a notebook in the jupyterlab interface right click and select "Open in > Notebook".

## Documentation

There is a docs folder which contains the documentation, including reports sent to our sponsor, DARPA.

Documentation is currently published https://aske.gtri.gatech.edu/docs/latest

Our documentation and examples are built with Jupyter notebooks. We use
[jupytext](https://github.com/mwouts/jupytext) to support diff friendly outputs in the repo.
Please follow the jupytext readme to install this jupyter plugin. If you use the docker container, jupytext is already
installed.


### Examples

In addition to the examples in the documentation, there are fully worked out examples in the folder
https://github.com/jpfairbanks/SemanticModels.jl/tree/master/examples/. Each subdirectory represents one self contained
example, starting with `epicookbook`.

## Model Augmentation

The primary usecase for SemanticModels.jl is to assist scientists in what we call *model augmentation*. This is the
process of taking a known model developed by another researcher (potentially a past version of yourself) and
transforming the model to create a novel model. This process can help fit an existing theory to new data, explore
alternative hypotheses about the mechanisms of a natural phenomena, or conduct counterfactual thought experiments.

SemanticModels is the current home for this capability.
You can call `m = model(PetriModel, model)` to lift a `Petri.jl` based model up to the semantic level, then apply
transformations on that `m` and then call `solve(m)` to generate code for that new model. This allows you to compare
different variations on a theme to conduct your research.

1. a struct `T` that holds a structured representation of instances of the model class
2. extend `model(::DataType{T}, model::Model{R})` to extract that information from a model generated by a specific DSL, and lift it to the semantic level
3. a set of *valid transforms* that can be done to your model.

SemanticModels.jl provides library functions to help with steps 2 and 3 and functions for executing and comparing then
outputs of different variations of the model.

We think of SemanticModels as a _post hoc_ modeling framework the enters the scene after scientific code has been
written. As opposed to a standard modeling framework that you develop before you write the scientific code.

## Acknowledgements

This material is based upon work supported by the Defense Advanced Research Projects Agency (DARPA) under Agreement No. HR00111990008.
