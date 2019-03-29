---
title: 'One host, one vector'
permalink: 'chapters/1host1vector/intro'
previouschapter:
  url: chapters/hostvector
  title: 'Host-vector models'
nextchapter:
  url: chapters/1host1vector/julia
  title: 'Julia'
redirect_from:
  - 'chapters/1host1vector/intro'
---
## One host SEIR, one vector SEI model

*Author*: Carl A. B. Pearson @pearsonca
*Date*: 2018-10-02

For this simple model, we represent a single host, $H$, and single vector, $V$, which each start as susceptible ($S$ compartment for both species) to an infectious agent.  When infected, each species enters an incubation period ($E$) before becoming infectious ($I$).  The host species can clear the infection, after which we assume is subsequently immune to infection (which is typical for viral pathogens, though decidely not accurate for other important infections, like malaria).  We represent population turnover in both the host and vector species.  Lastly, we assume that the probabilty of infection is the same for both host and vector - i.e., a susceptible host being bit by an infectious vector becomes infected with the same probabilty as a susceptible vector biting an infectious host.

The model parameters are:

 - $\sigma_H$, $\sigma_V$: the incubation rates for hosts & vectors (units: per time)
 - $\mu_H$, $\mu_V$: the mortality rates for hosts & vectors (units: per time)
 - $\lambda$: the clearance (or recovery) rate for hosts (units: per time)
 - $\beta$: the infection rate (units: per capita per time)

The infection rate is the combination of two factors: the number of bites per vector per time ($c$), the probability of infection per bite ($p$).

Another way to think about this factor:

host infections per time = new infections (infectious bites) per mosquito per time * # of $I$ mosquitos * fraction striking susceptible hosts ($S_H/N_H$)

mosquito infections per time = new infections (infectious bites) per mosquito per time * # of S mosquitos * fraction striking infectious hosts ($I_H/N_H$)

The state equations are:

$$
N_H = S_H + E_H + I_H + R_H, \dot{N_H}=0
\dot{S_H} = \mu_H N_H - \frac{\beta}{N_H} S_H I_V - \mu_H S_H = \mu_H(E_H + I_H + R_H) - \frac{\beta}{N_H} S_H I_V
\dot{E_H} = \frac{\beta}{N_H} S_H I_V - (\sigma_H + \mu_H) E_H
\dot{I_H} = \sigma_H E_H - (\lambda + \mu_H) I_H
\dot{R_H} = \lambda I_H - \mu_H R_H
\dot{S_V} = \mu_V N_V - \frac{\beta}{N_H} S_V I_H - \mu_V S_V = \mu_V(E_V + I_V) - \frac{\beta}{N_H} S_V I_H
\dot{E_V} = \frac{\beta}{N_H} S_V I_H - (\sigma_V + \mu_V) E_V
\dot{I_V} = \sigma_V E_V - \mu_V I_V
$$
