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

using RandomNumbers
using DataFrames

@inline @fastmath function randbn(n,p,rng)
    q = 1.0 - p
    s = p/q
    a = (n+1)*s
    r = exp(n*log(q))
    x = 0
    u = rand(rng)
    while true
        if (u < r)
            return x
        end
        u -= r
        x += 1
        r *= (a/x)-s
    end
end

@inline @fastmath function sir(u, prams, rng)
     
    (S, I, R, Y) = u
    (β, γ, ι, N, δt) = prams
    λ = β * (I + ι) / N
    ifrac = 1.0 - exp(-λ * δt)
    rfrac = 1.0 - exp(-γ * δt)
    infection = randbn(S, ifrac, rng)
    recovery = randbn(I, rfrac, rng)
    return (S - infection, I + infection - recovery, R + recovery, Y + infection)
end

function simulate(r)
    prams = (0.1, 0.05, 0.01, 1000.0, 0.1)
    tf = 200
    t = 0:0.1:tf
    tl = length(t)
    S = zeros(tl)
    I = zeros(tl)
    R = zeros(tl)
    Y = zeros(tl)
    u0 = (999, 1, 0, 0)
    (S[1],I[1],R[1],Y[1]) = u0
    u = u0
    for i in 2:tl
        u = sir(u, prams, r)
        (S[i],I[i],R[i],Y[i]) = u
    end
    return DataFrame(Time=t,S=S,I=I,R=R,Y=Y)
end

seed = 42
r = Xorshifts.Xorshift128Plus(seed);

sir_out = simulate(r);

if(size(sir_out)[1] >= 6)
    first(sir_out,6)
else
    first(sir_out,size(sir_out)[1]) 
end

using Plots
using StatPlots

@df sir_out plot(:Time, [:S :I :R], colour = [:red :green :blue], xlabel="Time",ylabel="Number")
