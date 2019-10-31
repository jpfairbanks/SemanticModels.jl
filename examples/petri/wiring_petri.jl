# -*- coding: utf-8 -*-
using Catlab
using MacroTools
import MacroTools: postwalk, striplines
using ModelingToolkit
import ModelingToolkit: Constant
using Test
using Petri
using SemanticModels.ModelTools.PetriModels

using Catlab.WiringDiagrams
using Catlab.Doctrines
import Catlab.Doctrines.⊗
import Catlab.Graphics: to_graphviz, to_tikz
import Catlab.Graphics.Graphviz: run_graphviz
⊗(a::WiringDiagram, b::WiringDiagram) = otimes(a,b)
import Base: ∘
∘(a::WiringDiagram, b::WiringDiagram) = compose(b, a)
⊚(a,b) = b ∘ a

# Generators
S, E, I, R, D, G= Ob(FreeSymmetricMonoidalCategory, :S, :E, :I, :R, :D, :G)

# +
infecting = Hom(:infection, S ⊗ I, I⊗I)

ss = mcopy(Ports([S]), 2)

function build(dict, y)
    push!(dict, codom(y)=>compose(typeof(dom(y)) == FreeSymmetricMonoidalCategory.Ob{:generator} ? dict[dom(y)] : otimes(map(x->dict[x], dom(y).args)), y))
end

dict = Dict()
push!(dict, I=>id(I))

rain = Hom(Symbol("rain"), I, R)
sprinkler = Hom(Symbol("sprinkler"), R, S)
grasswet = Hom(Symbol("grasswet"), S⊗R, G)
whatever = Hom(Symbol("whatever"), G⊗S, D)
set = [rain, sprinkler, grasswet, whatever]

map((x)->build(dict, x), set)

to_graphviz(dict[D], labels=true)

#to_graphviz(WiringDiagram()⊚(ss⊗WiringDiagram(Hom(:id, I, I))), labels=true)
#=
s1 = WiringDiagram(Hom(:id, S, S))

s_split = s1 ⊚ ss

to_graphviz(s_split, labels=true)
=#

# +
inf  = WiringDiagram(infecting)
expo = WiringDiagram(Hom(:exposure, S⊗I, E⊗I))
rec  = WiringDiagram(Hom(:recovery, I,   R))
wan  = WiringDiagram(Hom(:waning,   R,   S))



rain = Hom(:rain, I, R)
sprinkler = Hom(:sprinkler, R, S)
grasswet = Hom(Symbol("grasswet"), S⊗R, G)

set = [rain, sprinkler, grasswet]

foldl((x, y)->println(y), set)
# -

si    = WiringDiagram(Hom(:infection,   S⊗I, I⊗I))
se    = WiringDiagram(Hom(:exposure,    S⊗I, E⊗I))
prog  = WiringDiagram(Hom(:progression, E,   I))
fatal = WiringDiagram(Hom(:die,  I, D))
rip   = WiringDiagram(Hom(:rest, D, D))

sir    = si    ⊚ (rec   ⊗ rec)
seir   = se    ⊚ (prog  ⊗ rec)
seirs  = seir  ⊚ (wan   ⊗ wan)
seird  = seir  ⊚ (fatal ⊗ WiringDiagram(Hom(:id, R, R)))
seirds = seird ⊚ (rip   ⊗ wan)


model(PetriModel, sir)


models = [sir, seir, seirs, seird, seirds]
nets   = model.(PetriModel, models)

modelnames = ["sir",
         "seir",
         "seirs",
         "seird",
         "seirds",
         ]
map(zip(nets, modelnames)) do (net, name)
    Δ = reverse(net.model.Δ)
    println("Model: $name\n  Connections:")
    println("    $Δ\n")
    Δ
end

function writesvg(f::Union{IO,AbstractString}, d::WiringDiagram)
    write(f, to_graphviz(d, labels=true)
          |>g->run_graphviz(g, format="svg")
          )
end

writesvg(x) = writesvg(x...)


try
    mkpath("img")
    writesvg.(zip(["img/$f.svg"
                   for f in modelnames],
                  models))
catch e
    error("Could not write images, does ./img exist?\n $e")
end
println("Model Drawings are in ./img")
