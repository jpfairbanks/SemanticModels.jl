---
title: 'SIS model'
permalink: 'chapters/sis/intro'
previouschapter:
  url: chapters/seir/r_desolve
  title: 'R using deSolve'
nextchapter:
  url: chapters/sis/js_observable
  title: 'Javascript using Observable'
redirect_from:
  - 'chapters/sis/intro'
---

## SIS model

*Author*: Simon Frost

*Date*: 2018-07-12

### Description

The susceptible-infected-susceptible (SIS) model is one of the simplest models that has an endemic equilibrium. Susceptible individuals, $S$, are infected by infected individuals, $I$, at a per-capita rate $\beta I$, and infected individuals recover at a per-capita rate $\gamma$ to become susceptible again.

### Equations

$$
\frac{dS(t)}{dt}  = -\beta S(t) I(t)+\gamma I(t)\\
\frac{dI(t)}{dt}  = \beta S(t) I(t)- \gamma I(t)\\
$$

### References

1. [https://en.wikipedia.org/wiki/Compartmental_models_in_epidemiology](https://en.wikipedia.org/wiki/Compartmental_models_in_epidemiology)