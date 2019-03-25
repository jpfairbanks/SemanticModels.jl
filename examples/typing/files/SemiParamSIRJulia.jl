# -*- coding: utf-8 -*-
# ---
# jupyter:
#   jupytext:
#     text_representation:
#       extension: .jl
#       format_name: light
#       format_version: '1.3'
#       jupytext_version: 0.8.6
#   kernelspec:
#     display_name: Julia 1.0.3
#     language: julia
#     name: julia-1.0
# ---

using Random
using DifferentialEquations

function main()

# BM model for beta(t): d beta(t) = beta(t) d W(t)
# Function to compute rates of change 
spsir_bm = function(du, u, p, t)
    #Susceptible Individuals
    S = u[1]
    #Infected Individuals
    I = u[2]
    #Recovered Individuals
    R = u[3]
    
    β = max(0., u[4])
    
    N = S + I + R
    γ = p[1] 
    
    du[1] = -β * S * I / N
    du[2] = β * S * I / N - γ * I
    du[3] = γ * I
    du[4] = 0.
end

# Function to add noise
sigma_spsir = function(du, u, p, t )
    σ = p[2]
    
    du[1] = 0.
    du[2] = 0.
    du[3] = 0.
    du[4] = σ 
end

# +
# BM for logbeta(t), with drift 
spsir_logbm_drift = function(du, u, p, t)
    S = u[1]
    I = u[2]
    R = u[3]
    β = exp( u[4] )
    
    N = S + I + R
    γ = p[1] 
    α = p[3]
    
    du[1] = -β * S * I / N
    du[2] = β * S * I / N - γ * I
    du[3] = γ * I
    du[4] = -α * I
end



# +
# set random seed
Random.seed!( 1111 )

## Simulation of BM model 
# starting conditions
u0 = [50.;1.0;0.0;2.0]
tspan = (0.0,10.0)
# parameters gamma sigma 
p = [1.; 1.]
spsir_bm_prob = SDEProblem(spsir_bm, sigma_spsir, u0, tspan, p)
spsir_bm_sol = solve(spsir_bm_prob)


# +
## Simulation of log-BM with drift model 

# starting condtions 
u0 = [50.;1.0;0.0;log(3.) ]
tspan = (0.0,10.0)
# parameters gamma sigma alpha
p = [1.; 1.; 0.1]
spsir_logbm_drift_prob = SDEProblem(spsir_logbm_drift, sigma_spsir, u0, tspan, p)
spsir_logbm_drift_sol = solve(spsir_logbm_drift_prob)

# -

end



