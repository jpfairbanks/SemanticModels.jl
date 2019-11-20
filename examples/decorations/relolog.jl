# -*- coding: utf-8 -*-
using Catlab
using Catlab.Doctrines
import TikzPictures
import Catlab.Graphics: to_tikz
import SemanticModels.ModelTools.RelOlogModels: RelOlogModel, model, ⊚, ⊗
using SemanticModels.ModelTools.CategoryTheory
import SemanticModels.ModelTools.CategoryTheory: ⊔, FinSetMorph

# ### Defining a Relational Olog For SEIR

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

for i in equations(seir)
    display(i[1])
    display(to_tikz(i[2]; arrowtip="Stealth", labels=true))
end
