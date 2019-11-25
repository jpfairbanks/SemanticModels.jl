# -*- coding: utf-8 -*-
# + {}
using SemanticModels
using SemanticModels.ModelTools.PetriModels
using SemanticModels.ModelTools.RelOlogModels
using SemanticModels.ModelTools.CategoryTheory
using ModelingToolkit
using Petri
using Catlab
using Catlab.Doctrines
import TikzPictures
import Catlab.Graphics: to_tikz

import MacroTools: postwalk
function devar(p::Petri.Model)
    vars = Symbol[]
    map(p.S) do S
        postwalk(convert(Expr, S)) do ex
            if typeof(ex) == Symbol
                push!(vars, ex)
                return ex
            end
        end
    end
    return Petri.Model(vars, p.Δ)
end
# -

# # Example

# ### SIR Petri Model

# +
@variables S, I, R, I′

# Create S -> I -> R model
sir_petri = Petri.Model([S, I, R], [(S+I, 2I), (I,R)])

Petri.Graph(devar(sir_petri))
# -
# ### SIR Relational Olog

# +
@present sir_relolog(FreeBicategoryRelations) begin
    S::Ob
    I::Ob
    R::Ob
    
    infects::Hom(I, S)
    recovers_to::Hom(I, R)
end

to_tikz(reduce(⊗, generators(sir_relolog, FreeBicategoryRelations.Hom)); arrowtip="Stealth", labels=true)
# -

# ### SII Petri Model

# +
# Create Susceptible to 2 diseases model
sii_petri = Petri.Model([S, I, I′], [(S+I,  2I ), (S+I′, 2I′)])

Petri.Graph(devar(sii_petri))
# -
# ### SII Relational Olog

# +
@present sii_relolog(FreeBicategoryRelations) begin
    S::Ob
    I::Ob
    I_p::Ob
    
    infects::Hom(I, S)
    infects_p::Hom(I_p, S)
end

to_tikz(reduce(⊗, generators(sii_relolog, FreeBicategoryRelations.Hom)); arrowtip="Stealth", labels=true)
# -

# ### Define a Morphisms between the SIR and SII

f = FinSetMorph(1:3, [1, 2])
g = FinSetMorph(1:3, [1, 2])
# ### Decorate the Morphisms with a Petri Model
# + {}

sii_petriModel = model(PetriModel, sii_petri)
sir_petriModel = model(PetriModel, sir_petri)

sii_relModel = model(RelOlogModel, sii_relolog)
sir_relModel = model(RelOlogModel, sir_relolog)
# -
# ### Decorate the Same Morphisms with a Relational Olog

dec_f = Decorated(f, [sii_petriModel, sii_relModel])
dec_g = Decorated(g, [sir_petriModel, sir_relModel])

# ### Create Span and Solve Pushout

# +

S = Span(dec_f, dec_f)


H = CategoryTheory.pushout(S)
# -

# ### View New Models

# +

H_relolog = decorations(H, RelOlogModel)
H_petri = decorations(H, PetriModel)

map(x->display(Petri.Graph(devar(x.model))), H_petri)

map(x->display(to_tikz(reduce(⊗, generators(x.model, FreeBicategoryRelations.Hom)); arrowtip="Stealth", labels=true)), H_relolog)
