# SemanticModels.jl

computational representations of model semantics with knowledge graphs for
metamodel reasoning.

## Goals

1. Extract a knowledge graph from Scientific Artifacts (code, papers, datasets)
2. Represent scientific models in a high level way, (code as data)
3. Build metamodels by combining models in hierarchical expressions using reasoning over KG (1).

## Running Example: Influenza

Modeling the cost of treating a flu season taking into account weather effects.

1. Seasonal temperature is a dynamical system
2. Flu infectiousness γ is a function of temperature

## Running Example: Modeling types

Modeling the cost of treating a flu season taking into account weather effects.

1. Seasonal temperature is approximated by 2nd order linear ODE
2. Flu cases is an SIR model 1st oder nonlinear ode
3. Mitigation cost is Linear Regression on vaccines and cases

## Scientific Domain

We focus on Susceptible Infected Recovered model of epidemiology.

1. Precise, concise mathematical formulation
2. Diverse class of models, ODE vs Agent based, determinstic vs stochastic
3. FOSS implementations are available in all three Scientific programming languages

## Knowledge Graph

Picture of KG sample

## Knowledge Graph Schema

Picture of KG schema

## Knowledge Graph Schema

Picture of Flu example

## Conclusions
