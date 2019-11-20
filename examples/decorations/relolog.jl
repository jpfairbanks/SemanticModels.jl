# -*- coding: utf-8 -*-
# + {}
# using Pkg
# Pkg.add("TikzPictures")
# Pkg.update()
# Pkg.free("GeneralizedGenerated")
# -

using Catlab
using Catlab.Doctrines
import TikzPictures
import Catlab.Graphics: to_tikz
import SemanticModels.ModelTools.RelOlogModels: RelOlogModel, model, ⊚, ⊗
using SemanticModels.ModelTools.CategoryTheory
import SemanticModels.ModelTools.CategoryTheory: ⊔, FinSetMorph


# +
@present seir(FreeBicategoryRelations) begin
    S::Ob
    E::Ob
    I::Ob
    R::Ob
    
    exposes::Hom(I, S)
    becomes_exposed::Hom(S, E)
    falls_ill::Hom(E, I)
    recovers_to::Hom(I, R)
    
    illness := compose(becomes_exposed, falls_ill)
    exposure := compose(exposes, becomes_exposed)
end

to_tikz(reduce(⊗, generators(seir, FreeBicategoryRelations.Hom)); arrowtip="Stealth", labels=true)
# -

to_tikz(reduce(⊗, [x[2] for x in equations(seir)]); arrowtip="Stealth", labels=true)

# +
f = FinSetMorph(1:4, [3,2,4,1]) # S->I, E->E, I->R, R->R
seir′ = f(seir)

println(generators(seir′, FreeBicategoryRelations.Ob))

to_tikz(reduce(⊗, generators(seir′, FreeBicategoryRelations.Hom)); arrowtip="Stealth", labels=true)
# -

to_tikz(reduce(⊗, [x[2] for x in equations(seir′)]); arrowtip="Stealth", labels=true)

# +
# Generators
@present sir(FreeBicategoryRelations) begin
    S::Ob
    I::Ob
    R::Ob
    
    infects::Hom(I, S)
    recovers_to::Hom(I, R)
end

to_tikz(reduce(⊗, generators(sir, FreeBicategoryRelations.Hom)); arrowtip="Stealth", labels=true)

# +
# Generators
@present sii(FreeBicategoryRelations) begin
    S::Ob
    I::Ob
    I_p::Ob
    
    infects::Hom(I, S)
    infects_p::Hom(I_p, S)
end

to_tikz(reduce(⊗, generators(sii, FreeBicategoryRelations.Hom)); arrowtip="Stealth", labels=true)

# +
F = FinSetMorph(1:3, [1, 2])
G = FinSetMorph(1:3, [1, 2])

dec_F = Decorated(F, sir)
dec_G = Decorated(G, sii)

s = Span(dec_F, dec_G)

H = CategoryTheory.pushout(s)
out = decoration(H)

println(generators(out, FreeBicategoryRelations.Ob))
to_tikz(reduce(⊗, generators(out, FreeBicategoryRelations.Hom)); arrowtip="Stealth", labels=true)
# -




