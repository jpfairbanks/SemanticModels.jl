---
title: 'Scaling model'
permalink: 'chapters/deleo1996/intro'
previouschapter:
  url: chapters/sis/js_observable
  title: 'Javascript using Observable'
nextchapter:
  url: chapters/deleo1996/julia
  title: 'Julia'
redirect_from:
  - 'chapters/deleo1996/intro'
---

## Basic microparasite model

*Author*: Christopher Davis

*Date*: 2018-10-02

### Description

A basic microparasite model of susceptibles and infecteds with the force of infection density dependent. $\beta_{\text{min}}$ is the minimum value of the transmission rate $\beta$, such that the disease will spread.

### Equations

$$
\frac{dS(t)}{dt}  = (\nu - \mu)\left(1- \frac{S(t)}{K}\right) S(t)- \beta S(t) I(t)\\
\frac{dI(t)}{dt}  = \beta S(t) I(t)- (\mu +\ \alpha) I(t)\\
$$

### References

- [De Leo GA, Dobson AP (February, 1996). "Allometry and simple epidemic models for microparasites". Nature. 379(6567):720](https://doi.org/10.1038/379720a0)