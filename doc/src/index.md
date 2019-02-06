# SemanticModels.jl Documentation

```@meta
CurrentModule = SemanticModels
```

SemanticModels is a system for representing scientific knowledge inherent to scientific model structure.
Our philosophy is that over the next few decades, the adoption of computation as a first class pillar of scientific
thought will be complete, and scientists will do a majority of their thinking about and communicating of ideas in the
form of writing and using code. Attempts to teach machines science based on reading texts intended for human consumption
is overwhelming, so we use text written for computers as a starting point. This involves extracting meaning from code, 
and reconciling such information with exogenous sources of information about the world.

Scientists typically write procedural code based on libraries for solving mathematical models. When this procedural
code is expressed in data-oriented pipelines or workflows, such workflows have limited composability. The most mature scientific
field in terms of data-oriented workflows is bioinformatics, where practicing informaticists spend a great deal of time
plumbing together procedural scripts and adapting data formats. Automatic adaptation of modeling codes requires a
semantic understanding of the model that the code implements/computes. ```SemanticModels.jl``` is intended to augment 
scientists' modeling capabilities by extracting semantic information and facilitating different types of model 
manipulation and generation.

We focus on three problems:

1. **Model modification:** taking an existing model and modifying its components to add features or make comparisons.
2. **Metamodel construction:** combining models or components of models to automatically generate scientific computing workflows.
3. **Model Verification:** given a model, corpus of previous applications of that model, and an input to the model, detect if the model is properly functioning.
   
SemanticModels leverages technology from program analysis and natural language processing in order to build a knowledge
graph representing the connections between elements of code (variables, values, functions, and expressions) and elements
of scientific understanding (concepts, terms, relations). This knowledge graph supports reasoning about how to modify
models, construct metamodels, and verify models.

The most mature aspects of the library at this point are [Knowledge Extraction](@ref) and
modification ([Dubstep](@ref)).

## Table of Contents
```@contents
Pages = [
     "index.md",
     "usecases.md",
     "news.md",
     "example.md",
     "dubstep.md",
     "graph.md",
     "extraction.md",
     "validation.md",
     "library.md",
     "theory.md",
     "approach.md",
     "slides.md",
     "FluModel.md",
     "contributing.md"]
Depth = 3
```

This material is based upon work supported by the Defense Advanced Research Projects Agency (DARPA) under Agreement No. HR00111990008.
