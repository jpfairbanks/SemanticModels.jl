---
title: 'Deterministic SEIR'
permalink: 'chapters/lloydjansen2004/intro'
previouschapter:
  url: chapters/metapopulation
  title: 'Metapopulation models'
nextchapter:
  url: chapters/lloydjansen2004/r_odin
  title: 'R using odin'
redirect_from:
  - 'chapters/lloydjansen2004/intro'
---

## Metapopulation SEIR model

*Author*: Constanze Ciavarella @ConniCia

*Date*: 2018-10-02

This code combines two deterministic metapopulation SEIR models as described in [Lloyd & Jansen (2004)](https://doi.org/10.1016/j.mbs.2003.09.003).

### Cross-coupling between patches - Equations (8-10)

Cross-coupling is controlled through matrix $\beta$, describing the effective contact rates acting within and between patches.

Setting the off-diagonal elements of $\beta$ to zero, we switch off cross-coupling across patches.


### Migration between patches - Equations (11-13)

Matrix $C$ must be such that the elements on the diagonal, denoting outflow of each patch, are negative. Element $c_{ij}$ describes the flow from patch $i$ to patch $j$. For each row, the sum all elements on the row is 0.

Setting all elements of $C$ to zero, we switch off migration between patches.

### Model description

This model consists of many SEIR models connected through between-patch contact and/or migration of individuals between patches. The model has a constant total population size, which means that births and deaths correspond at each time step.

- $n$ = number of patches
- $S_1, ..., S_n$ = susceptibles in patches $1, ..., n$
- $E_1, ..., E_n$ = exposed in patches $1, ..., n$
- $I_1, ..., I_n$ = infectious in patches $1, ..., n$
- $R_1, ..., R_n$ = recovered in patches $1, ..., n$
- $\beta_{ij}$ = effective contact rate of infected individuals of patch $i$ to susceptible individuals of patch $j$
- $c_{ii}$ = outflow of patch $i$
- $c_{ij}, i \neq j$ = flow from patch $i$ to patch $j$
- $\sigma$ = rate of breakdown to active (and infectious) disease
- $\gamma$ = rate of recovery from active disease
- $\mu$ = background mortality/birth rate

The model will be written as
$$
\begin{aligned}
&S_i' = \mu - \mu S_i - S_i \, \sum_{j=1}^n \, \beta_{ij} \, I_j + \, m_S * (S_1 * c_{1i} \, + ... + \, S_n * c_{ni})\\
&E_i' = S_i \sum_{j=1}^n \beta_{ij} \, I_j - (\mu + \sigma) \, E_i + \, m_E * (E_1 * c_{1i} \, + ... + \, E_n * c_{ni})\\
&I_i' = \sigma \, E_i - (\mu + \gamma) \, I_i + \, m_I * (I_1 * c_{1i} \, + ... + \, I_n * c_{ni})\\
&R_i' = \gamma \, I_i - \mu \, R_i + \, m_R * (R_1 * c_{1i} \, + ... + \, R_n * c_{ni})
\end{aligned}
$$

### References

- [Lloyd & Jansen (2004)](https://doi.org/10.1016/j.mbs.2003.09.003)