# -*- coding: utf-8 -*-
# + {}
module PetriModels
import Base: show
using Petri
using ModelingToolkit
import ModelingToolkit: Constant, Variable
using MacroTools
import MacroTools: postwalk
using Catlab.WiringDiagrams

using SemanticModels.ModelTools
import SemanticModels.ModelTools: model

export PetriModel, model, rewrite!, Span, DPOProblem, solve, pushout, dropdown, equnion

const PetriModel = Petri.Model

OpVar(s::Symbol) = Operation(Variable(s), [])

function model(::Type{PetriModel}, m::Petri.Model)
    return m
end

function model(::Type{PetriModel}, d::WiringDiagram)::PetriModel
    # TODO design Multiple Dispatch Lens API
    vars = ModelTools.WiringDiagrams.wirenames(d)
    symvars = OpVar.(vars)
    byvar = Dict{Symbol, Operation}()
    homnames = Vector{Symbol}()
    transitions = map(enumerate(boxes(d))) do (i, box)
        invars = input_ports(box)
        outvars = output_ports(box)
        homname = box.value
        push!(homnames, homname)
        δ_in  =  length(invars)  > 1 ? +(OpVar.( invars)...) : OpVar.(invars[1])
        δ_out =  length(outvars) > 1 ? +(OpVar.(outvars)...) : OpVar.(outvars[1])
        return (δ_in, δ_out)
    end
    return PetriModel(symvars, unique(transitions))
end

function rewrite!(pm::PetriModel, pm2::PetriModel)
    rewrite!(pm, pm2, Dict())
end

function rewrite!(pm::PetriModel, pm2::PetriModel, f::Dict)
    vars = map(pm.S) do s
        s.op
    end
    @show
    for i in 1:length(pm2.S)
        s = pm2.S[i]
        found = findfirst(vars .== (haskey(f, s) ? f[s].op : s.op))
        if typeof(found) == Nothing
            push!(pm.S, s)
            push!(pm.Δ, pm2.Δ[i])
            push!(pm.Λ, pm2.Λ[i])
            push!(pm.Φ, pm2.Φ[i])
        else
            pm.Δ[found] = pm2.Δ[i] == Nothing ? m.Δ[found] : m2.Δ[i]
            pm.Λ[found] = pm2.Λ[i] == Nothing ? m.Λ[found] : m2.Λ[i]
            pm.Φ[found] = pm2.Φ[i] == Nothing ? m.Φ[found] : m2.Φ[i]
        end
    end
end

struct Span{L,C,R}
    l::L
    c::C
    r::R
end

struct DPOProblem
    rule::Span
    c′::PetriModel
end

solve(p::DPOProblem) = pushout(p.rule.r, p.c′)

function equnion(a::Vector, b::Vector)
    x = copy(a)
    for item in b
        if !any(item2 -> isequal(item2, item), x)
            push!(x, item)
        end
    end
    return x
end


"""    pushout(m1::Model, m2::Model)

compute the CT pushout of two models.
"""
function pushout(pm::PetriModel, pm2::PetriModel)
    states = equnion(pm.S, pm2.S)
    Δ = equnion(pm.Δ, pm2.Δ)
    Λ = equnion(pm.Λ, pm2.Λ)
    Φ = equnion(pm.Φ, pm2.Φ)
    return PetriModel(states, Δ, Λ, Φ)
end


"""
    dropdown(l::Model, c::Model, l′::Model)

compute c′ given l, c, l′, the formula for petrinets is

T_{c'} = T_{l'} \\setdiff f(T_l) \\cup a(T_c)
"""
function dropdown(pl::PetriModel, pc::PetriModel, pl′::PetriModel)
    states = union(pl′.S, pc.S)
    Δ = union(setdiff(pl′.Δ, pl.Δ), pc.Δ)
    Λ = union(setdiff(pl′.Λ, pl.Λ), pc.Λ)
    Φ = union(setdiff(pl′.Φ, pl.Φ), pc.Φ)
    return PetriModel(states, Δ, Λ, Φ)
end

end
