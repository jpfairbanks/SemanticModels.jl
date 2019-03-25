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
using Random
using DataFrames
using Distributions

function continuous_time_SIR(β,γ,N,S0,I0,R0,tf)   
    #Temp Variables for Time, Susceptible Individuals, Infected Individuals, Recovery
    t = 0
    S = S0
    I = I0
    R = R0
    #Array to store SIR and Time
    ta= Float64[]
    Sa= Float64[]
    Ia= Float64[]
    Ra= Float64[]
    
    while t < tf
        push!(ta,t)
        push!(Sa,S)
        push!(Ia,I)
        push!(Ra,R)
        pf1 = β*S*I
        pf2 = γ*I
        pf = pf1+pf2
        dt = rand(Exponential(1/pf))
        t = t+dt
        if t>tf
            break
        end
        ru = rand()
        if ru<(pf1/pf)
            S=S-1
            I=I+1
        else
            I=I-1
            R=R+1
        end
    end
    results = DataFrame()
    results[:time] = ta
    results[:S] = Sa
    results[:I] = Ia
    results[:R] = Ra
    return(results)
end


function main()
    Random.seed!(42);

    #continuous_time_SIR(Infected Rate, Recover Rate, Sample Size ,
    #Initial Susceptible Individuals, Initial Infected Rate, Initial Recovery Rate, Max Time Increment)
    sir_out = continuous_time_SIR(0.1/1000,0.05,1000,999,1,0,200);

    head_size = 6
    first(sir_out,head_size)

end


