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
 
function seird(du, u, parms, t) 
    S,E,Ir,Id,R,D = u 
    β,δ,γ,Γ,μ,ϵ,ω = parms 
    I = Ir + Id 
    N = S + E + I + R + D 
    dS = S - β*S*I/N + ω*R 
    dE = E + β*S*I/N - γ*E + ϵ 
    dIr = Ir + γ*(1-μ)E - γ*Ir + ϵ 
    dId = Id + γ*μ*E - Γ*Id + ϵ 
    dR = R + γ*Ir - ω*R 
    dD = D + Γ*Id 
    du = [dS, dE, dIr, dId, dR, dD] 
end 
 
 

end 
