# -*- coding: utf-8 -*-
using LightGraphs
using SemanticModels
using SemanticModels.ModelTools.PetriModels
using SemanticModels.ModelTools.CategoryTheory
using ModelingToolkit
using Petri

# explicit pushout definition for testing and verification of span implementation
function pushout(a::AbstractGraph, b::AbstractGraph, f::AbstractVector{Int}, g::AbstractVector{Int})
    l = f ⊔ g
    G = a ⊔ b
    map(edges(G)) do e
        s,t = e.src, e.dst
        return Edge(l[s], l[t])
    end |> Graph
end

# # Example

n = 3
a = smallgraph(:house)
b = StarGraph(n)

f = FinSetMorph([5,3,4])
F = GraphMorph(b, a, f)
@assert verify(F) == true
@assert FinSetMorph([5,4,3,2,1])(a) |>
    adjacency_matrix |>
    collect == [0 1 1 0 0;
                1 0 1 1 0;
                1 1 0 0 1;
                0 1 0 0 1;
                0 0 1 1 0]

# +
H  = pushout(a, b, 1:5, [5, 6, 4])

# Create a decorated morphism for a
g = FinSetMorph(1:5, [5,4])
# Add graph a as decoration of morphism f
dec_g = Decorated(g, a)
# Create a decorated morphism for b
f = FinSetMorph(1:3, [1,2])
# Add graph b as decoration of morphism g
dec_f = Decorated(f, b)
# Create the span of decorated morphisms
s = Span(dec_f,dec_g)
# Solve for the decorated cospan that solves the pushout defined by the span
H′ = CategoryTheory.pushout(s)

@assert H == decoration(H′)

@show collect(edges(decoration(H′)))

# +
@variables S, I, R, I′

# Create S -> I -> R model
sir = Petri.Model([S, I, R], [(S+I, 2I), (I,R)])

# Create Susceptible to 2 diseases model
sii = Petri.Model([S, I, I′], [(S+I,  2I ), (S+I′, 2I′)])

# Decorate a finite set with SIR
f = FinSetMorph(1:3, [1, 2])
dec_f = Decorated(f, sir)

# Decorate a finite set with SII
g = FinSetMorph(1:3, [1, 2])
dec_g = Decorated(g, sii)

# Create a span of decorated morphisms
s = Span(dec_f, dec_g)

# Solve the pushout that combines the two Petri decorations
H = CategoryTheory.pushout(s)

@show decoration(H).S
@show decoration(H).Δ

#@show typeof(H)

#@show collect(edges(decoration(H)))
# -


