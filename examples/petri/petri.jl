# -*- coding: utf-8 -*-
# + {}
module PetriModel
using Petri
using ModelingToolkit
import ModelingToolkit: Constant, Variable
using MacroTools
import MacroTools: postwalk
using Catlab.WiringDiagrams

using SemanticModels.ModelTools
import SemanticModels.ModelTools: model

struct PetriModel <: AbstractModel
    model::Petri.Model
end

wirenames(d::WiringDiagram) = foldr(union,
    map(box->union(input_ports(box), output_ports(box)),
        boxes(d)))

OpVar(s::Symbol) = Operation(Variable(s), [])

function model(::Type{PetriModel}, d::WiringDiagram)
    # TODO design Multiple Dispatch Lens API
    vars = wirenames(d)
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
    return PetriModel(Petri.Model(symvars, unique(transitions)))
end

function rewrite!(pm::PetriModel, pm2::PetriModel)
    rewrite!(pm, pm2, Dict())
end

function rewrite!(pm::PetriModel, pm2::PetriModel, f::Dict)
    m = pm.model
    m2 = pm2.model
    vars = map(m.S) do s
        s.op
    end
    @show
    for i in 1:length(m2.S)
        s = m2.S[i]
        found = findfirst(vars .== (haskey(f, s) ? f[s].op : s.op))
        if typeof(found) == Nothing
            push!(m.S, s)
            push!(m.Δ, m2.Δ[i])
            push!(m.Λ, m2.Λ[i])
            push!(m.Φ, m2.Φ[i])
        else
            m.Δ[found] = m2.Δ[i] == Nothing ? m.Δ[found] : m2.Δ[i]
            m.Λ[found] = m2.Λ[i] == Nothing ? m.Λ[found] : m2.Λ[i]
            m.Φ[found] = m2.Φ[i] == Nothing ? m.Φ[found] : m2.Φ[i]
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


"""    pushout(m1::Model, m2::Model)

compute the CT pushout of two models.
"""
function pushout(pm::PetriModel, pm2::PetriModel)
    m = pm.model
    m2 = pm2.model
    states = union(m.S, m2.S)
    Δ = union(m.Δ, m2.Δ)
    Λ = union(m.Λ, m2.Λ)
    Φ = union(m.Φ, m2.Φ)
    return PetriModel(Petri.Model(states, Δ, Λ, Φ))
end


"""
    dropdown(l::Model, c::Model, l′::Model)

compute c′ given l, c, l′, the formula for petrinets is

T_{c'} = T_{l'} \\setdiff f(T_l) \\cup a(T_c)
"""
function dropdown(pl::PetriModel, pc::PetriModel, pl′::PetriModel)
    l = pl.model
    c = pc.model
    l′ = pl′.model
    states = union(l′.S, c.S)
    Δ = union(setdiff(l′.Δ, l.Δ), c.Δ)
    Λ = union(setdiff(l′.Λ, l.Λ), c.Λ)
    Φ = union(setdiff(l′.Φ, l.Φ), c.Φ)
    return PetriModel(Petri.Model(states, Δ, Λ, Φ))
end

end
# -

# using Petri
import Base.show
using DiffEqBase
using ModelingToolkit
# using DiffEqBiological

macro grounding(ex)
    return ()
end

mutable struct SIRState{T,F}
    S::T
    I::T
    R::T
    β::F
    γ::F
    μ::F
end

mutable struct ParamSIR{T, P}
    S::T
    I::T
    R::T
    params::P
end

mutable struct ParamSEIR{T, P}
    S::T
    E::T
    I::T
    R::T
    params::P
end

mutable struct SEIRState{T,F}
    S::T
    I::T
    R::T
    β::F
    γ::F
    μ::F
    E::T
    η::F
end


mutable struct SEIRDState{T,F}
    S::T
    I::T
    R::T
    β::F
    γ::F
    μ::F
    E::T
    η::F
    D::T
    ψ::F
end

function show(io::IO, s::SIRState)
    t = (S=s.S, I=s.I, R=s.R, β=s.β, γ=s.γ, μ=s.μ)
    print(io, "$t")
end
