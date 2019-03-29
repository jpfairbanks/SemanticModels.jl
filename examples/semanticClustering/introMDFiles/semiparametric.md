---
title: 'Semiparametric SIR model'
permalink: 'chapters/semiparametric/intro'
previouschapter:
  url: chapters/sirforced/js_observable
  title: 'Javascript using Observable'
nextchapter:
  url: chapters/semiparametric/julia
  title: 'Julia'
redirect_from:
  - 'chapters/semiparametric/intro'
---

## Semi-parametric models

*Author*: Erik M Volz @emvolz

*Date*: 2018-10-02

Flexibility can be built into compartmental models by allowing parameters such as transmission or recovery rates to vary through time. One way to do this is to specify a stochastic process for these parameters and to compute their evolution as if they are state variables with a system of SDEs; when fitted to data, these models can fit time-changing parameter values while being 'vague' about exactly how these parameters change over time. The models presented here are related to models which have been used for forecasting of the 2014 Ebola epidemic in Western Africa. We define a stochastic process for the transmission rate. This accounts for changing epidemic conditions through time, such as public health interventions and changing behaviour, without explicitly building such variables into the model. 

These models have the following form: 

$
\frac{d}{dt} S = -\beta(t) I S / N
$

$
\frac{d}{dt} I = \beta(t) I S / N - \gamma I
$

$
\frac{d}{dt} R =  \gamma I
$

where $S(t)$ and $I(t)$ are the number of susceptible and infected individuals through time and $N(t) = S + I + R$

We  show alternative forms for the process governing $\beta(t)$

1) Brownian motion. Note that we truncate this process so that $\beta(t)>0$ 

$
d \beta(t) = \beta(t) d W(t)
$

2) BM in log space

$
d log(\beta(t)) = log(\beta(t)) d W(t) 
$

We further consider a model including state-dependent drift: 

$
d log(\beta(t)) = -\alpha I(t) dt +  log(\beta(t)) d W(t) 
$

This has the effect of generating downward drift on the transmission rate when there are large numbers of infected. 

### References

Compartmental model making use of a the BM $\beta(t)$ process: 

- S Funk et al, [Real-time forecasting of infectious disease dynamics with a stochastic semi-mechanistic model](https://doi.org/10.1016/j.epidem.2016.11.003), Epidemics 2018.

This Ebola model included state-dependent drift:

- J Asher, [Forecasting Ebola with a regression transmission model](https://doi.org/10.1016/j.epidem.2017.02.009), Epidemics 2018.

This reference describes models with a Gaussian Process for $\beta(t)$ and/or the total transmission rate:

- X Xu, T Kypraios, and P.D. O'Neill; [Bayesian non-parametric inference for stochastic epidemic models using Gaussian Processes](https://doi.org/10.1093/biostatistics/kxw011), Biostatistics, Volume 17, Issue 4, 1 October 2016.

Some related work on semiparametric ecological models

- S Wood. [Partially specified ecological models](https://doi.org/10.2307/3100042), Ecological Monographs
Volume 71, Issue 1, 2001, pp. 1-25.
