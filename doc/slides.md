---
author: James Fairbanks
title: SemanticModels.jl
date: Apr 31, 2019
---


![SemanticModels Logo](src/img/semanticmodels_jl.png)

## Introduction

- Teaching computers to do science
- Model Augmentation and Synthesis
- Arbitrary models are complex, but transformations are simpler

## Modeling Frameworks

Most frameworks are designed before the models are written

| Framework | Math | Input Specification  | Description |
|-----------|------|----------|-------------|
| <img width="50px" src ="https://www.mathworks.com/content/dam/mathworks/mathworks-dot-com/images/ico_membrane_128.png"><br>Matlab/Scipy</img> | x = A\b | BLAS + scripting | Sci/Eng math is all BLAS| 
| <img src="https://camo.githubusercontent.com/31d60f762b44d0c3ea47cc16b785e042104a6e03/68747470733a2f2f7777772e6a756c69616f70742e6f72672f696d616765732f6a756d702d6c6f676f2d776974682d746578742e737667" alt="jump"></img> | $\min_{x\perp C(x)} f(x)$ | AMPL based DSL| Optimization Problems |
| <img width="50px" src="https://mc-stan.org/docs/2_18/stan-users-guide/img/logo-tm.png" alt="Stan Logo">Stan</img> | $ y \sim \mathcal{N}(x \beta + \alpha, \sigma)$ | StanML | Bayesian Inference|
| ![TensorFlow](https://www.gstatic.com/devrel-devsite/v64b99e7856b375caf4161a35932fd71b47bddc412a7c2f9ddea443380406e780/tensorflow/images/lockup.svg) | $y\approx f(x)$ | TF.Graph| Differentiable Programming|
| <img width="50px" src="https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/Mathematica_Logo.svg/1920px-Mathematica_Logo.svg.png"> Mathematica</img> |$p(x)=0$|Symbolic Math Expressions| Computer Algebra Systems|
| <img width="75px" src="http://aske.gtri.gatech.edu/docs/latest/img/semanticmodels_jl.dot.svg">SemanticModels.jl<img> | All Computable Domains| Julia Programs | $Models \subset Code$ |

SemanticModels is a post hoc modeling framework


<!-- ## Scientific Modeling vs ML -->

<!-- ML is about finding the models that minimize generalization error, scientific model parameter estimation uses a lot of -->
<!-- the same mathematical fundamentals but is aimed at learning the "true parameters" for the model system. -->


## Science as nested optimization

### We can think of fitting the data as a regression problem:

$$h^* = \min_{h\in {H}} \ell(h(x), y)$$ 

### The institutional process of discovery as

$$\max_{{H}\in \mathcal{M}} expl(h^*)$$ where $expl$ is the explanatory power of a class of models $H$. The explanatory power is some combination of generalization, parsimony, and consistency with the fundamental principles of the field.


## Scientific Models are Mechanistic
Mechanistic models are more explainable than black box or statistical models. They posit driving forces and natural laws
that drive the evolution of systems over time.

We call these *simulations* when necessary to distinguish from *model*


## SIR model of disease

### ODE based simulation

### Agent based simulations


## Category Theory

CT is the mathematics of structure preserving maps. Every field of math has a notion of *homomorphism* where two objects
in that category *have similar structure*

1. Sets, Groups, Fields, Rings
2. Graphs
3. Databases

CT is the study of structure in its most general form.


### Graphs as Categories

Figure of two homomorphic graphs

Each graph is a category, and there is a category of graphs.


### Models as Categories

Figure of a model structure


### Functor between models

Define Functor between models

### The category of models

While each model can be represented as a category, there is a category of all models.

Functors between models are the morphisms in this category.


## Semantic Models applies Category Theory

We have built a novel modeling environment that builds and manipulates models in this category theory approach.

Contributions: 
1. We take general code as input
2. Highly general and extensible framework
3. Goal: Transformations obey the functor laws.


### Example

Show the Agent based simulation demo


### Free Monoid of Transformations

Figure of free monoid over a transformation alphabet acting on a model to produce an orbit.

### Cyclic Group Acting on polynomial formulas

Example 


## Knowledge Graphs

To build this system we use
1. Call Graphs
2. Type Graphs
3. Concept Graphs

### Graph Construction

1. Base.Meta.Parse
2. @code_typed
3. AllenNLP text models

### Graph construction results


## Conclusion
