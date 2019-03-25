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

function main()

#Susceptible-exposed-infected-recovered model function
function seir_ode(dY,Y,p,t)
    #Infected per-Capita Rate
    β = p[1]
    #Incubation Rate
    σ = p[2]
    #Recover per-capita rate
    γ = p[3]
    #Death Rate
    μ = p[4]
    
    #Susceptible Individual
    S = Y[1]
    #Exposed Individual
    E = Y[2]
    #Infected Individual
    I = Y[3]
    #Recovered Individual
    #R = Y[4]
    
    dY[1] = μ-β*S*I-μ*S
    dY[2] = β*S*I-(σ+μ)*E
    dY[3] = σ*E - (γ+μ)*I
end

#Pram (Infected Rate, Incubation Rate, Recover Rate, Death Rate)
pram=[520/365,1/60,1/30,774835/(65640000*365)]
#Initialize Param(Susceptible Individuals, Exposed Individuals, Infected Individuals)
init=[0.8,0.1,0.1]
tspan=(0.0,365.0)

seir_prob = ODEProblem(seir_ode,init,tspan,pram)

sol=solve(seir_prob);

end


