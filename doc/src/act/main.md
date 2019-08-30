---
title: Model Augmentation with Transformations on Categories
author: James Fairbanks
date: May 3, 2019
header-includes: |
  \usepackage{fullpage}
...

# Introduction
We introduce SemanticModels.jl, a practical library for scientific model augmentation based on category theoretic representations of models.


# Functors on Models

Given a transformation $t\in T$ and a model $m\in M$ we apply that transformation to the model to define $m' = t(m)$. This transformation induces a functor $\phi: m' \to m$. We study what the properties of $\phi$ say about the relationship between $m$ and $m'$.

## Preimage Transformation

# Conclusion

1. Category Theory provides a framework for analyzing scientific models and relationships between them
2. This framework is implemented in a practical software library scientists can use.
3. Category theory notions on functors translate to scientifically meaningful relationships between models.
