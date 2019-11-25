# -*- coding: utf-8 -*-
# + {}
module PetriModels
import Base: show
using Petri
using ModelingToolkit
import ModelingToolkit: Constant, Variable
using MacroTools
import MacroTools: prewalk, postwalk
using Catlab.WiringDiagrams

using SemanticModels.ModelTools
using SemanticModels.ModelTools.CategoryTheory
import SemanticModels.ModelTools.CategoryTheory: ⊔, FinSetMorph
import SemanticModels.ModelTools: model

export PetriModel, model, rewrite!, PetriSpan, DPOProblem, solve, pushout, dropdown, equnion, ⊔

struct PetriModel <: AbstractModel
  model::Petri.Model
end

OpVar(s::Symbol) = Operation(Variable(s), [])

function model(::Type{PetriModel}, m::Petri.Model)
    return PetriModel(m)
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
    return PetriModel(Petri.Model(symvars, unique(transitions)))
end

function rewrite!(pm::PetriModel, pm2::PetriModel)
    rewrite!(pm, pm2, Dict())
end

function rewrite!(pModel::PetriModel, pModel2::PetriModel, f::Dict)
    pm = pModel.model
    pm2 = pModel2.model
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

struct PetriSpan{L,C,R}
    l::L
    c::C
    r::R
end

struct DPOProblem
    rule::PetriSpan
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


dictReplace(item, dict) = prewalk(i -> i in keys(dict) ? dict[i] : i, item)

function ⊔(gModel::PetriModel, hModel::PetriModel)
    g = gModel.model
    h = hModel.model
    dict = Dict(i => any(isequal.(i, g.S)) ? i : Operation(i.op, Expression[ModelingToolkit.Constant(2)]) for i in h.S)
    newS = [dictReplace(n, dict) for n in h.S]
    newΔ = [(dictReplace(n[1], dict), dictReplace(n[2], dict)) for n in h.Δ]
    newΛ = [dictReplace(n, dict) for n in h.Λ]
    newΦ = [dictReplace(n, dict) for n in h.Φ]
    PetriModel(Petri.Model(union(g.S, newS), 
                equnion(g.Δ, newΔ), 
                equnion(g.Λ, newΛ),
                equnion(g.Φ, newΦ)))
end



function (f::FinSetMorph)(gModel::G) where G <: PetriModel
    g = gModel.model
    length(dom(f)) == length(g.S) || throw(DomainError(g.S))
    ϕ = func(f)
    outS = Array{Operation}(undef, length(Set(ϕ.m.fun)))
    for i in dom(f)
        outS[ϕ(i)] = g.S[i]
    end
    out = deepcopy(g)
    PetriModel(Petri.Model(outS, out.Δ, out.Λ, out.Φ))
end


"""    pushout(m1::Model, m2::Model)

compute the CT pushout of two models.
"""
function pushout(pModel::PetriModel, pModel2::PetriModel)
    pm = pModel.model
    pm2 = pModel2.model
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
function dropdown(pL::PetriModel, pC::PetriModel, pL′::PetriModel)
    pl = pL.model
    pc = pC.model
    pl′ = pL′.model
    states = union(pl′.S, pc.S)
    Δ = union(setdiff(pl′.Δ, pl.Δ), pc.Δ)
    Λ = union(setdiff(pl′.Λ, pl.Λ), pc.Λ)
    Φ = union(setdiff(pl′.Φ, pl.Φ), pc.Φ)
    return PetriModel(states, Δ, Λ, Φ)
end

end
