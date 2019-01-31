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

module SISModel
using DifferentialEquations

# +
function sis_ode(du, u, parms, t)
    beta = parms[1]
    gamma = parms[2]
    susceptible = init[1]
    infected_ind = init[2]

    du[1] = -beta * susceptible * infected_ind + gamma * infected_ind
    du[2] = beta * susceptible * infected_ind - parms[2] * init[2]

end
# -

parms = [0.1,0.05]
init = [0.99,0.01,0.0]
tspan = (0.0,200.0)

sis_prob = ODEProblem(sis_ode, init, tspan,parms)

sis_sol = solve(sis_prob);

#Visualization
using Plots
plot(sis_sol,xlabel="Time",ylabel="Number")

end
