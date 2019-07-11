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
    β, γ = parms
    
    S, I = u

    dS = -β * S * I +  γ * I
    dI = β * S * I - γ * I
    du = [dS,dI]
    
end
# -


function main()
    parms = [0.1,0.05]
    init = [0.99,0.01]
    tspan = (0.0,200.0)

    sis_prob = ODEProblem(sis_ode, init, tspan,parms)

    sis_sol = solve(sis_prob);
end

end
