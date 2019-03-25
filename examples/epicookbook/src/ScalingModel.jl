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

module ScalingModel
using DifferentialEquations

function micro_1(du, u, parms, time)
    # PARAMETER DEFS
    # β transmition rate
    # r net population growth rate
    # μ hosts' natural mortality rate
    # Κ population size
    # α disease induced mortality rate

    β, r, μ, K, α = parms
    S, I = u
    dS = r*(1-S/K)*S - β*S*I
    dI = β*S*I-(μ+α)*I
    du = [dS,dI]
end

# +
# PARAMETER DEFS
# w and m are used to define the other parameters allometrically


function main()
    w = 1;
    m = 10;
    β = 0.0247*m*w^0.44;
    r = 0.6*w^-0.27;
    μ = 0.4*w^-0.26;
    K = 16.2*w^-0.7;
    α = (m-1)*μ;
    # -

    parms = [β,r,μ,K,α];
    init = [K,1.];
    tspan = (0.0,10.0);

    sir_prob = ODEProblem(micro_1,init,tspan,parms)

    sir_sol = solve(sir_prob);
    return sir_sol
end


# using Plots

# plot(sir_sol,xlabel="Time",ylabel="Number")

# m = [5,10,20,40]
# ws = 10 .^collect(range(-3,length = 601,3))
# βs = zeros(601,4)
# for i = 1:4
#     βs[:,i] = 0.0247*m[i]*ws.^0.44
# end
# plot(ws,βs,xlabel="Weight",ylabel="\\beta_min", xscale=:log10,yscale=:log10, label=["m = 5" "m = 10" "m = 20" "m = 40"],lw=3)

end
