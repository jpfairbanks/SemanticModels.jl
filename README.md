# Semantics.jl
A julia package for representing and manipulating model semantics

## Getting Started

Install this package with 

```julia
Pkg.develop("git@github.com:jpfairbanks/Semantics.jl.git")
Pkg.test("Semantics")
```

Then you can load it with `using Semantics`

See the tests for example usage.

## Documentation

There is a docs folder which contains the documentation, including reports sent to our sponsor, DARPA.

## Concepts

This package enables representation of complex and diverse model structure in the type system of julia. This will allow generic programing and API development for these complex models.

### ModelStructures

The following concepts are defined in Semantics.jl

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

