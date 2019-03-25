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

using DifferentialEquations

using Plots

function main()
# +
function macroParasiteModelFunction(dY,Y,p,t)
    #Host Birth Rate
    a = p[1]
    #Parasite Influence on host birth rate
    b = p[2]
    #Parasite induced host mortality
    α = p[3]
    #Parasite induced decrease in host reproduction
    β = p[4]
    #Intrinsic death rate of parasites
    μ = p[5]
    #dispersion aggregation parameter
    k = p[6]
    #Rate of production of new free-living stages
    λ = p[7]
    #Death Rate of Free-Living Stages
    γ = p[8]
    
    #Host Population
    H = Y[1]
    #Parasite Population
    P = Y[2]
    #Infective Stages
    W = Y[3]
    
dY[1] = (a-b)*H - α*P
dY[2] = β*H*W - (μ + α + b) * P - (α*((P^2)/H)*((k+1)/k)) 
dY[3] = λ*P - (γ*W) - (β*H*W)
end

# -

par=[1.4,1.05,0.0003,0.01,0.5,0.1,10.0,10.0]
init=[100.0,10.0,10.0]
tspan=(0.0,100.0)


macro_odeProblem = ODEProblem(macroParasiteModelFunction,init,tspan,par)


sol=solve(macro_odeProblem);


plot(sol,xlabel="Time",yscale=:log10)


end
