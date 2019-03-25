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

# # Model Specifications

# ## Host Specifications
#
# The host may be in one of 4 states:
#
# - susceptible (S_H)
#
# - incubation period (E_H)
#
# - infectious (I_H)
#
# - recovered (R_H)
#
# ## Vector Specifications 
#
# The vector may be in one of 3 states:
#
# - susceptible (S_V)
#
# - incubation period (E_V)
#
# - infectious (I_V)

# # Model Parameters
#
# σ_H, σ_V: the incubation rates for hosts & vectors (units: per time)
#
# μ_H, μ_V: the mortality rates for hosts & vectors (units: per time)
#
# λ: the clearance (or recovery) rate for hosts (units: per time)
#
# β: the infection rate (units: per capita per time)

# +
using DifferentialEquations
using IterableTables, DataFrames

function main()
    
function F(du,u,p,t)
    S_H, E_H, I_H, R_H, S_V, E_V, I_V = u
    
    # host dynamics
    host_infection = (p.β*S_H*I_V)/p.N_H
    host_mortality = p.μ_H .* u[1:4] # include S_H, so easier to remove mortality
    host_births = sum(host_mortality)
    host_progression = p.σ_H*E_H
    recovery = p.λ*I_H
    
    du[1] = -host_infection + host_births
    du[2] = host_infection - host_progression
    du[3] = host_progression - recovery
    du[4] = recovery
    du[1:4] -= host_mortality
    
    # vector dynamics
    vec_infection = (p.β*S_V*I_H)/p.N_H
    vec_mortality = p.μ_V .* u[5:7] # include S_V, so easier to remove mortality
    vec_births = sum(vec_mortality)
    vec_progression = p.σ_V*E_V
    
    du[5] = -vec_infection + vec_births
    du[6] = vec_infection - vec_progression
    du[7] = vec_progression
    du[5:7] -= vec_mortality
    
end

# +

u0 = [
    100.0,  0.0, 1.0, 0.0,
    10000.0, 0.0, 0.0
]
p = (
  μ_H=1/365, μ_V=1/30, σ_H=1/3, σ_V=1/7, λ=1/14,
  β=0.05, N_H = sum(u0[1:4])
)
tspan = (0.0, 365.0)
prob = ODEProblem(F, u0, tspan, p)
sol = @time solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8,saveat=range(0,stop = 365,length = 365*10+1))

df = DataFrame(sol')
rename!(df,:x1 => :S_H,:x2 => :E_H, :x3 => :I_H, :x4 => :R_H,
  :x5 => :S_V, :x6 => :E_V, :x7 => :I_V)
df.t = collect(range(0,stop = 365,length = 365*10+1));
# -

first(df,10)

end
