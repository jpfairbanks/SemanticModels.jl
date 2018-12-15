# SemanticModels.jl
A julia package for representing and manipulating model semantics

## Getting Started

Install this package with 

```julia
Pkg.develop("git@github.com:jpfairbanks/SemanticModels.jl.git")
Pkg.test("SemanticModels")
```

Then you can load it with `using SemanticModels`

See the tests for example usage.

## Documentation

There is a docs folder which contains the documentation, including reports sent to our sponsor, DARPA.

Documentation is currently published at jpfairbanks.com/doc/aske and jpfairbanks.com/doc/aske/slides.pdf

### Examples

In addition to the examples in the documentation, there are fully worked out examples in the folder
https://github.com/jpfairbanks/SemanticModels.jl/tree/master/examples/. Each subdirectory represents one self contained
example, starting with `epicookbook`.

## Concepts

This package enables representation of complex and diverse model structure in the type system of julia. This will allow generic programing and API development for these complex models.

### ModelStructures

The following concepts are defined in SemanticModels.jl

- Model
- EpiModel <: Model 
- NumberClass 
- Amount <: NumberClass 
- Rate <: NumberClass 
- BirthRate <: Rate 
- DeathRate <: Rate 
- TransitionRate <: Rate 
- Equation 
- Expression 
- Variable 

A number class is like a Unit in that it can be used to check compatibility of numeric values for various operations.

### Knowledge Graph

We will use MetaGraphs.jl to model the relationships between models and concepts in a knowledge graph

### Knowledge Graph Extraction

You can use the `Extractor` type to pull knowledge elements from an artifact. The following are subtypes of `Artifact`

- Docs
- Code
- Model
- Paper
