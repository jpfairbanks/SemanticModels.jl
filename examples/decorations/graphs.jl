# -*- coding: utf-8 -*-
using LightGraphs
using SemanticModels
using SemanticModels.ModelTools.CategoryTheory
using SemanticModels.ModelTools.PetriModels
using SemanticModels.ModelTools.GraphModels
using ModelingToolkit
using Petri

# # Example

n = 3
a = smallgraph(:house)
b = StarGraph(n)

f = FinSetMorph([5,3,4])
@assert FinSetMorph([5,4,3,2,1])(model(GraphModel, a)).model |>
    adjacency_matrix |>
    collect == [0 1 1 0 0;
                1 0 1 1 0;
                1 1 0 0 1;
                0 1 0 0 1;
                0 0 1 1 0]

# +
# Create a decorated morphism for a
g = FinSetMorph(1:5, [5,4])
# Add graph a as decoration of morphism f
dec_g = Decorated(g, model(GraphModel, a))
# Create a decorated morphism for b
f = FinSetMorph(1:3, [1,2])
# Add graph b as decoration of morphism g
dec_f = Decorated(f, model(GraphModel, b))
# Create the span of decorated morphisms
s = Span(dec_f,dec_g)
# Solve for the decorated cospan that solves the pushout defined by the span
H = CategoryTheory.pushout(s)

dec = decorations(H, GraphModel)[1]

@show collect(edges(dec.model))

# +
@variables S, I, R, I′

# Create S -> I -> R model
sir = Petri.Model([S, I, R], [(S+I, 2I), (I,R)])
sir_model = model(PetriModel, sir)

# Create Susceptible to 2 diseases model
sii = Petri.Model([S, I, I′], [(S+I,  2I ), (S+I′, 2I′)])
sii_model = model(PetriModel, sii)

# Decorate a finite set with SIR
f = FinSetMorph(1:3, [1, 2])
dec_f = Decorated(f, sir_model)

# Decorate a finite set with SII
g = FinSetMorph(1:3, [1, 2])
dec_g = Decorated(g, sii_model)

# Create a span of decorated morphisms
s = Span(dec_f, dec_g)

# Solve the pushout that combines the two Petri decorations
H = CategoryTheory.pushout(s)

map(petri->println(petri.model.S, "\n", petri.model.Δ), decorations(H, PetriModel))
# -


