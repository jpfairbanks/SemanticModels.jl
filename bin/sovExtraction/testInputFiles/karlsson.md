---
title: 'An individual based model of pneumococcal transmission'
permalink: 'chapters/karlsson/intro'
previouschapter:
  url: chapters/sircn/js_observable
  title: 'Javascript using Observable'
nextchapter:
  url: chapters/karlsson/r
  title: 'R'
redirect_from:
  - 'chapters/karlsson/intro'
---
## Contact network model of Karlsson et al.

This section implements the contact network model of [Karlsson et al.](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2442080/), used to evaluate the efficacy of interventions aiming to control pneumococcal transmission. Individuals are assigned several features: an age, a household, and potentially a class in school/day care. These features then influence the rate of transmission between individuals in the population. Together this defines a stochastic process of the number of people infected.


### Reference

- [Karlsson et al. (2008)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2442080/)