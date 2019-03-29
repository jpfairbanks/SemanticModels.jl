---
title: 'SEIR model'
permalink: 'chapters/seir/intro'
previouschapter:
  url: chapters/sir/js_observable
  title: 'Javascript using Observable'
nextchapter:
  url: chapters/seir/julia
  title: 'Julia'
redirect_from:
  - 'chapters/seir/intro'
---

## SEIR model

*Author*: Simon Frost

*Date*: 2018-07-12

The susceptible-exposed-infected-recovered (SEIR) model extends the SIR model to include an exposed but non-infectious class. The implementation in this section considers proportions of susceptibles, exposed, infectious individuals in an open population, with no additional mortality associated with infection (such that the population size remains constant and $R$ is not modelled explicitly).

$$
\frac{dS(t)}{dt}  = \mu-\beta S(t) I(t) - \mu S(t)\\
\frac{dE(t)}{dt}  = \beta S(t) I(t)- (\sigma + \mu) E(t)\\
\frac{dI(t)}{dt}  = \sigma E(t)- (\gamma + \mu) I(t)\\
\frac{dR(t)}{dt}  = \gamma I(t) = \mu R
$$

### References

- [https://en.wikipedia.org/wiki/Compartmental_models_in_epidemiology](https://en.wikipedia.org/wiki/Compartmental_models_in_epidemiology)