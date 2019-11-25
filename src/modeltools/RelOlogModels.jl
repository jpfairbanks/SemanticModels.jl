# -*- coding: utf-8 -*-
# + {}
module RelOlogModels
using Catlab
using Catlab.Syntax
using Catlab.WiringDiagrams
using Catlab.Doctrines
import Catlab.Doctrines.⊗

using SemanticModels.ModelTools
using SemanticModels.ModelTools.CategoryTheory
import SemanticModels.ModelTools.CategoryTheory: ⊔, FinSetMorph
import SemanticModels.ModelTools: model

export RelOlogModel, model, ⊔


struct RelOlogModel <: AbstractModel
  model::Presentation
end
  
function model(::Type{RelOlogModel}, r::Presentation)
    return RelOlogModel(r)
end

function ⊔(gModel::RelOlogModel, hModel::RelOlogModel)
    g = gModel.model
    h = hModel.model
    dict = Dict(i => any(isequal.(i, generators(g, FreeBicategoryRelations.Ob))) ? Ob(FreeBicategoryRelations, Symbol(i.args[1], "_2")) : i for i in generators(h, FreeBicategoryRelations.Ob))
    temp = Presentation()
    map(x->begin if !has_generator(temp, x.args[1]) add_generator!(temp, x) end end, map(x->functor((FreeBicategoryRelations.Ob, FreeBicategoryRelations.Hom), x; generators=dict), generators(h)))
    map(z->add_equation!(temp, z[1], z[2]), map(y->map(x->functor((FreeBicategoryRelations.Ob, FreeBicategoryRelations.Hom), x; generators=dict), y), equations(h)))

    out = deepcopy(g)
    merge_presentation!(out, temp)
    return RelOlogModel(out)
end

function (f::FinSetMorph)(gModel::G) where G <: RelOlogModel
    g = gModel.model
    states = generators(g, FreeBicategoryRelations.Ob)
    # check if length of states = codomain
    length(dom(f)) == length(states) || throw(DomainError(states))
    ϕ = func(f)
    # build renaming dictionary
    outS = Array{FreeBicategoryRelations.Ob}(undef, length(Set(f.fun)))
    for i in dom(f)
        if !isassigned(outS, ϕ(i)) outS[ϕ(i)] = states[i] end
    end
    dict = Dict(states[i] => outS[ϕ(i)] for i in dom(f))
    # map renaming functor to relations
    g′ = Presentation()

    # get the states in the correct order
    add_generators!(g′, outS)
    map(x->begin if !has_generator(g′, x.args[1]) add_generator!(g′, x) end end, map(x->functor((FreeBicategoryRelations.Ob, FreeBicategoryRelations.Hom), x; generators=dict), generators(g)))
    map(z->add_equation!(g′, z[1], z[2]), map(y->map(x->functor((FreeBicategoryRelations.Ob, FreeBicategoryRelations.Hom), x; generators=dict), y), equations(g)))
    return RelOlogModel(g′)
end

end
