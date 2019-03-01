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

# # Model Specifications
# - SH num of high risk susceptible
# - IH num of high risk infected 
# - SL num of low risk susceptible
# - IL num of low risk infected
# # Parameters
# - beta represents the determines the contact and transmission rates
# - gamma the rate at which treatment is sought

function sis_ode(du,u,p,t)
        SH,IH,SL,IL = u
        betaHH,betaHL,betaLH,betaLL,gamma=p
        du[1]=-(betaHH*IH+betaHL*IL)*SH+gamma*IH
        du[2]=+(betaHH*IH+betaHL*IL)*SH-gamma*IH
        du[3]=-(betaLH*IH+betaLL*IL)*SL+gamma*IL
        du[4]=+(betaLH*IH+betaLL*IL)*SL-gamma*IL
end

parms =[10,0.1,0.1,1,1]
init=[0.19999,0.00001,0.799,0.001]
tspan=tspan = (0.0,15.0)

sis_prob = ODEProblem(sis_ode,init,tspan,parms)
sis_sol = solve(sis_prob,saveat=0.1);

end