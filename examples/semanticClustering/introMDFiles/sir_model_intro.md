---
title: 'SIR model'
permalink: 'chapters/sir/intro'
previouschapter:
  url: chapters/simple
  title: 'Simple deterministic models'
nextchapter:
  url: chapters/sir/python
  title: 'Python using SciPy'
redirect_from:
  - 'chapters/sir/intro'
---

## SIR model

*Author*: Simon Frost

*Date*: 2018-07-12

### Description

The susceptible-infected-recovered (SIR) model in a closed population was proposed by Kermack and McKendrick as a special case of a more general model, and forms the framework of many compartmental models. Susceptible individuals, $S$, are infected by infected individuals, $I$, at a per-capita rate $\beta I$, and infected individuals recover at a per-capita rate $\gamma$ to become recovered individuals, $R$.

### Equations

$$
\frac{dS(t)}{dt}  = -\beta S(t) I(t)\\
\frac{dI(t)}{dt}  = \beta S(t) I(t)- \gamma I(t)\\
\frac{dR(t)}{dt}  = \gamma I(t)
$$

### References

1. [Kermack WO, McKendrick AG (August 1, 1927). "A Contribution to the Mathematical Theory of Epidemics". Proceedings of the Royal Society A. 115 (772): 700–721](https://doi.org/10.1098/rspa.1927.0118)
1. [https://en.wikipedia.org/wiki/Compartmental_models_in_epidemiology](https://en.wikipedia.org/wiki/Compartmental_models_in_epidemiology)