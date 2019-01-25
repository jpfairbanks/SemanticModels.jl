# -*- coding: utf-8 -*-
# ---
# jupyter:
#   jupytext:
#     formats: ipynb,jl:light
#     text_representation:
#       extension: .jl
#       format_name: light
#       format_version: '1.3'
#       jupytext_version: 0.8.6
#   kernel_info:
#     name: julia-1.0
#   kernelspec:
#     display_name: Julia 1.0.0
#     language: julia
#     name: julia-1.0
# ---

# +
using Pkg
Pkg.activate(".")
using SemanticModels
using SemanticModels.Unitful: DomainError, s, d, C, uconvert, NoUnits
using DifferentialEquations
using DataFrames
using Unitful
using Test

using Distributions: Uniform
using GLM
using DataFrames

# -

using Plots

stripunits(x) = uconvert(NoUnits, x)

# +
function flusim(tfinal)
    # annual cycle of temperature control flu infectiousness
    springmodel = SpringModel([u"(1.0/(365*8))d^-2"], # parameters (frequency)
                              (u"0d",tfinal), # time domain
                              [u"25.0C", u"0C/d"]) # initial_conditions T, T'
    function create_sir(m, solns)
        sol = solns[1]
        initialS = u"10000person"
        initialI = u"1person" 
        initialpop = [initialS, initialI, u"0.0person"]
        β = u"1.0/18"/u"d*C" * sol(sol.t[end-2])[1] #infectiousness
        @show β
        sirprob = SIRSimulation(initialpop, #initial_conditions S,I,R
                                (u"0.0d", u"20d"), #time domain
                                SIRParams(β, u"40.0person/d")) # parameters β, γ
        return sirprob
    end

    function create_flu(cm, solns)
        sol = solns[1]
        finalI = stripunits(sol(u"8.0d")[2]) # X
        population = stripunits(sol(sol.t[end])[2])
        # population = stripunits(sum(sol.u[end]))
        df = SemanticModels.generate_synthetic_data(population, 0,100)
        f = @formula(vaccines_produced ~ flu_patients)
        model =  lm(f,
            df[2:length(df.year),
            [:year, :flu_patients, :vaccines_produced]])
        println("GLM Model:")
        println(model)

        year_to_predict = 1
        num_flu_patients_from_sim = finalI
        vaccines_produced = missing
        targetDF = DataFrame(year=year_to_predict,
            flu_patients=num_flu_patients_from_sim, 
            vaccines_produced=missing)
        @show targetDF


        return RegressionProblem(f, model, targetDF, missing)
    end
    cm = CombinedModel([springmodel], create_sir)
    flumodel = CombinedModel([cm], create_flu)
    return flumodel
end

tfinal = 240π*u"d" #(~2 yrs)
flumodel = flusim(tfinal)

# -

springmodel = flumodel.deps[1].deps[1]
sirmodel = flumodel.deps[1]
sol = solve(springmodel)
plot(sol.t./d, map(x->x[1], sol.u) ./ C)

sirsol = solve(sirmodel)

plot(sirsol.t./d,map(x->stripunits.(x)[2], sirsol.u))

sol = solve(flumodel)

print(typeof(sol.u))


