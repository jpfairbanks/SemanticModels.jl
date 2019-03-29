---
title: 'Discrete time SEIRD'
permalink: 'chapters/seird-stochastic-discretestate-discretetime/intro'
previouschapter:
  url: chapters/sir-stochastic-discretestate-discretetime/julia
  title: 'Julia'
nextchapter:
  url: chapters/seird-stochastic-discretestate-discretetime/r_odin
  title: 'R using odin'
redirect_from:
  - 'chapters/seird-stochastic-discretestate-discretetime/intro'
---

## Stochastic SEIRD model

The model is SEIRD model, where infected individuals can survive or die at different rates, with waning immunity. The full model specification is:

- $S$: susceptibles
- $E$: exposed, i.e. infected but not yet contagious
- $I_R$: infectious who will survive
- $I_D$: infectious who will die
- $R$: recovered
- $D$: dead


There are no birth of natural death processes in this model. Parameters are:

- $\beta$: rate of infection
- $\delta$: rate at which symptoms appear (i.e inverse of mean incubation
period)
- $\gamma_R$: recovery rate
- $\gamma_D$: death rate
- $\mu$: case fatality ratio (proportion of cases who die)
- $\epsilon$: import rate of infected individuals (applies to $E$ and $I$)
- $\omega$: rate waning immunity


The model will be written as:

$$
S_{t+1} = S_t - \beta \frac{S_t (I_{R,t} + I_{D,t})}{N_t} + \omega R_t
$$

$$
E_{t+1} = E_t + \beta \frac{S_t (I_{R,t} + I_{D,t})}{N_t} - \delta E_t + \epsilon
$$

$$
I_{R,t+1} = I_{R,t} + \delta (1 - \mu) E_t - \gamma_R I_{R,t} + \epsilon
$$

$$
I_{D,t+1} = I_{D,t} + \delta \mu E_t - \gamma_D I_{D,t} + \epsilon
$$

$$
R_{t+1} = R_t + \gamma_R I_{R,t} - \omega R_t
$$

$$
D_{t+1} = D_t + \gamma_D I_{D,t}
$$

