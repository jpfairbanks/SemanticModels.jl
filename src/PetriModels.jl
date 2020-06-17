# -*- coding: utf-8 -*-
# + {}
module PetriModels
import Base: show
using Petri
using MacroTools
import MacroTools: prewalk
using Catlab.WiringDiagrams
import Catlab.Graphics.Graphviz: Graph

using SemanticModels
using SemanticModels.CategoryTheory
import SemanticModels.CategoryTheory: ⊔, FinSetMorph, pushout
import SemanticModels: model

export PetriModel, model, rewrite!, PetriSpan, DPOProblem, solve, dropdown, equnion, ⊔

struct PetriModel <: AbstractModel
  model::Petri.Model
end

function model(::Type{PetriModel}, m::Petri.Model)
    return PetriModel(m)
end

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
    dict = Dict(i => any(isequal.(i, g.S)) ? i : Symbol(i, "′") for i in h.S)
    newS = [dictReplace(n, dict) for n in h.S]
    newΔ = [(dictReplace(first(n), dict), dictReplace(last(n), dict)) for n in h.Δ]
    PetriModel(Petri.Model(union(g.S, newS),
                           equnion(g.Δ, newΔ)))
end

function (f::FinSetMorph)(gModel::G) where G <: PetriModel
    g = gModel.model
    length(dom(f)) == length(g.S) || throw(DomainError(g.S))
    ϕ = func(f)
    outS = 1:length(Set(ϕ.m.fun))
    outΔ = Vector{Tuple{Vector{Int}, Vector{Int}}}()
    for t in g.Δ
        ins = ϕ.(t[1])
        outs = ϕ.(t[2])
        push!(outΔ, (ins,outs))
     end
    out = deepcopy(g)
    PetriModel(Petri.Model(outS, outΔ))
end

# TODO: this version uses model toolkit variables, we want to delete it
# function (f::FinSetMorph)(gModel::G) where G <: PetriModel
#     g = gModel.model
#     length(dom(f)) == length(g.S) || throw(DomainError(g.S))
#     ϕ = func(f)
#     outS = Array{Operation}(undef, length(Set(ϕ.m.fun)))
#     for i in dom(f)
#         outS[ϕ(i)] = g.S[i]
#     end
#     out = deepcopy(g)
#     PetriModel(Petri.Model(outS, out.Δ, out.Λ, out.Φ))
# end

# TODO: this looks like coproduct not pushout.

"""    pushout(m1::Model, m2::Model)

compute the CT pushout of two models.
"""
function pushout(pModel::PetriModel, pModel2::PetriModel)
    pm = pModel.model
    pm2 = pModel2.model
    states = equnion(pm.S, pm2.S)
    Δ = equnion(pm.Δ, pm2.Δ)
    return model(PetriModel, Petri.Model(states, Δ))
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
    return model(PetriModel, Petri.Model(states, Δ))
end

end
