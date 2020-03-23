using Catlab
using Catlab.Doctrines
using Catlab.Graphics
using Catlab.WiringDiagrams
using Catlab.Programs
import Base.Multimedia: display
import Catlab.Graphics: to_graphviz, LeftToRight
println("Done Importing Catlab")
import Base: (==), length, show
using Test
using Petri
using SemanticModels.ModelTools.CategoryTheory
import SemanticModels.ModelTools.CategoryTheory: undecorate, ⊔
using SemanticModels.ModelTools.PetriModels
using SemanticModels.ModelTools.PetriCospans
import SemanticModels.ModelTools.PetriCospans: otimes_ipm, compose_pushout

println("Done Importing SemanticModels")

import Catlab.Doctrines:
  Ob, Hom, dom, codom, compose, ⋅, ∘, id, oplus, otimes, ⊗, ⊕, munit, mzero, braid,
  dagger, dunit, dcounit, mcopy, Δ, delete, ◊, mmerge, ∇, create, □,
  plus, zero, coplus, cozero, meet, top, join, bottom

wd = to_wiring_diagram
draw(d::WiringDiagram) = to_graphviz(add_junctions(d), orientation=LeftToRight, labels=true)
draw(d::HomExpr) = draw(wd(d))


println("Making COVID Model")

@present Disease(FreeEpidemiology) begin
    S::Ob
    E::Ob
    I::Ob
    R::Ob
end

S,E,I,R = generators(Disease)
# draw(spontaneous(E,I)⋅spontaneous(I,R)⊗(spontaneous(E,I)))
sei = compose(exposure(S,I,E), otimes(spontaneous(E,I), id(I)), mmerge(I))
# draw(sei)
seir = sei⋅Δ(I)⋅(id(I)⊗spontaneous(I, R))
# draw(seir)
seir2 = compose(mcopy(S)⊗id(I), id(S)⊗seir)
# draw(seir2)

# draw(death(S))

d = @program Disease (s::S, e::E, i::I) begin
    e1, i1 = exposure{S,I,E}(s,i)
    i2 = spontaneous{E,I}(e1)
    e = [e, e1]
    e_out = spontaneous{E,E}(e)
    i1 = [i1, i2]
    r = spontaneous{I,R}(i1)
    s_out = spontaneous{S,S}(s)
    return s_out, e_out, spontaneous{I,I}(i1)
end
# draw(d)

# draw(d⋅d)

seirdef = to_hom_expr(FreeEpidemiology, d)
try
    add_definition!(Disease, :seir, seirdef)
catch
    println("INFO: definition already added.")
end

# if the disease is fatal, we need to add a death component
seird = @program Disease (s::S, e::E, i::I) begin
    e1, i1 = exposure{S,I,E}(s,i)
    i2 = spontaneous{E,I}(e1)
    e = [e, e1]
    e_out = spontaneous{E,E}(e)
    i1 = [i1, i2]
    r = spontaneous{I,R}(i1)
    s_out = spontaneous{S,S}(s)
    death{I}(i1)
    return s_out, e_out, spontaneous{I,I}(i1)
end
#TODO: This does not get translated correctly, bug?
seirddef = to_hom_expr(FreeEpidemiology, seird)
try
    add_definition!(Disease, :seird, seirddef)
catch
    println("INFO: definition already added.")
end

seirgen = generator(Disease, :seir)
seirdgen = generator(Disease, :seird)


ncities(city,n::Int) = compose([city for i in 1:n]...)
city³ = ncities(seirgen, 3)
# draw(city³)

dcity³ = wd(city³)
dc3 = substitute(dcity³, box_ids(dcity³), [d,d,d])
@show dc3 == ncities(d, 3)
# draw(dc3)

import Base: repeat
repeat(d::WiringDiagram, n::Int) = compose([d for i in 1:n]...)
repeat(d::FreeEpidemiology.Hom, n::Int) = compose([d for i in 1:n]...)

# draw(ncities(seirdgen, 3))
# draw(repeat(seird, 3))

# draw(seirddef)
#
# using TikzPictures
# using Catlab.Graphics.TikZWiringDiagrams
# using Convex
# using SCS
#
# to_tikz(seirddef, labels=true)
X = FinSet(1)
F(ex) = functor((FinSet, FinSetMorph),
                ex,
                generators=Dict(S=>X, I=>X, E=>X, R=>X))

Fseir = compose(exposure(X,X,X),otimes(spontaneous(X,X),id(X)),mmerge(X),mcopy(X),otimes(id(X),spontaneous(X,X)))
# states are [S, I, E, R]
seir_petri = left(Fseir.f).d[1]
f = FinSetMorph(1:4, [1, 2, 3])
g = FinSetMorph(1:4, [1, 2, 3])
Fseir′ = PetriCospan(Cospan(Decorated(f,seir_petri), Decorated(g, seir_petri)))
s = spontaneous(X,X)
Fflow = otimes(s, s, s)
Fcity = Fseir′ ⋅ Fflow
Fcity³ = Fcity⋅Fcity⋅Fcity
@test left(Fcity³.f).d[1].model.S == 1:15
@test left(Fcity³.f).d[1].model.Δ == [([1, 2], [3, 2]),
                                      ([3], [2]),
                                      ([2], [4]),
                                      #outflow 1
                                      ([1], [5]),
                                      ([2], [6]),
                                      ([3], [7]),
                                      # SEIR 2
                                      ([5, 6], [7, 6]),
                                      ([7], [6]),
                                      ([6], [8]),
                                      #outflow 2
                                      ([5], [9]),
                                      ([6], [10]),
                                      ([7], [11]),
                                      # SEIR 3
                                      ([9, 10], [11, 10]),
                                      ([11], [10]),
                                      ([10], [12]),
                                      #outflow 3
                                      ([9], [13]),
                                      ([10], [14]),
                                      ([11], [15])
                                      ]
Fcity₀ = Fseir′ ⋅ Fflow
Fcity₁ = Fflow ⋅ Fseir′ ⋅ Fflow
Fcityₑ = Fflow ⋅ Fseir′
Fcity³ = Fcity₀⋅Fcity₁⋅Fcityₑ

@test left(Fcity³.f).d[1].model.S == 1:18
@test left(Fcity³.f).d[1].model.Δ == [
    # SEIR 1
     ([1, 2], [3, 2]),
     ([3], [2]),
     ([2], [4]),
     # outflow 1→2
     ([1], [5]),
     ([2], [6]),
     ([3], [7]),
     # inflow 1→2
     ([5], [8]),
     ([6], [9]),
     ([7], [10]),
    # SEIR 2
     ([8, 9], [10, 9]),
     ([10], [9]),
     ([9], [11]),
     # outflow 2→3
     ([8], [12]),
     ([9], [13]),
     ([10], [14]),
     # inflow 2→3
     ([12], [15]),
     ([13], [16]),
     ([14], [17]),
    # SEIR 3
     ([15, 16], [17, 16]),
     ([17], [16]),
     ([16], [18])
]

Fcity₀ = Fseir′ ⋅ Fflow
Fcity₁ = Fseir′ ⋅ Fflow
Fcityₑ = Fseir′
Fcity³ = Fcity₀⋅Fcity₁⋅Fcityₑ

@test left(Fcity³.f).d[1].model.S == 1:12
@test left(Fcity³.f).d[1].model.Δ == [
    # City 1 SEIR
    ([1, 2], [3, 2]),
    ([3], [2]), # E→I
    ([2], [4]), # I→R
    # outflow 1→2
    ([1], [5]), # S→S′
    ([2], [6]), # I→I′
    ([3], [7]), # E→E′
    # City 2 SEIR
    ([5, 6], [7, 6]),
    ([7], [6]), # E→I
    ([6], [8]), # I→R
    # outflow 2→3
    ([5], [9]), # S→S′
    ([6], [10]),# I→I′
    ([7], [11]),# E→E′
    # City 3 SEIR
    ([9, 10], [11, 10]),
    ([11], [10]), # E→I
    ([10], [12]) # I→R
    ]

Pseird = PetriModel(
          Petri.Model(1:5,[
            ([1,2],[3,2]), # exposure
            ([3],[2]),     # onset
            ([2],[4]),     # recovery
            ([2],[5]),     # death
            ], missing, missing))
inputs = FinSetMorph(1:5, [1,2,3])
outputs = FinSetMorph(1:5, [1,2,3])
Fcityd = PetriCospan(Cospan(Decorated(inputs, Pseird),
                            Decorated(outputs, Pseird)))
Fcity₀ = Fcityd ⋅ Fflow
Fcity₁ = Fcityd ⋅ Fflow
Fcityₑ = Fcityd
Fcity³ = Fcity₀⋅Fcity₁⋅Fcityₑ

left(Fcity³.f).d[1].model.S == 1:15
length(left(Fcity³.f).d[1].model.Δ) == 18
