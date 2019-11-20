# -*- coding: utf-8 -*-
using SemanticModels
using SemanticModels.ModelTools.PetriModels
using SemanticModels.ModelTools.RelOlogModels
using SemanticModels.ModelTools.CategoryTheory
using SemanticModels.ModelTools.OpenPetris
using ModelingToolkit
using Petri
using Catlab
using Catlab.Doctrines
import TikzPictures
import Catlab.Graphics: to_tikz
import Petri: Graph
import MacroTools: postwalk

function devar(p::Petri.Model)
    println(p.S)
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

# # Example

# ### SIR Petri Model

# +
@variables S, I, R, I′

# Create S -> I -> R model
sir_petri = Petri.Model([:S, :I, :R], [(S+I, 2I), (I,R)])

println(sir_petri.S)
println(sir_petri.Δ)
Graph(sir_petri)
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
sii_petri = Petri.Model([:S, :I, :I′], [(S+I,  2I ), (S+I′, 2I′)])

println(sii_petri.S)
println(sii_petri.Δ)
Graph(sii_petri)

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
sir_petri = Petri.Model([S, I, R], [(S+I, 2I), (I,R)])
sii_petri = Petri.Model([S, I, I′], [(S+I,  2I ), (S+I′, 2I′)])

# ### Decorate the Morphisms with a Petri Model
# Decorate a finite set with SIR Petri Model
dec_f_petri = Decorated(f, sir_petri)

# Decorate a finite set with SII Petri Model
dec_g_petri = Decorated(g, sii_petri)
# -
# ### Decorate the Same Morphisms with a Relational Olog

double_f = Decorated(dec_f_petri, sir_relolog)
double_g = Decorated(dec_g_petri, sii_relolog)

# ### Create Span and Solve Pushout

# +
S = Span(double_f, double_g)

H = CategoryTheory.pushout(S)
# -

# ### View New Models

# +
H_relolog = decoration(H)
H_petri = decoration(undecorate(H))

println(H_petri.S)
println(H_petri.Δ)

Graph(devar(decoration(H_petri)))
# -

# +
to_tikz(reduce(⊗, generators(H_relolog, FreeBicategoryRelations.Hom)); arrowtip="Stealth", labels=true)
# -