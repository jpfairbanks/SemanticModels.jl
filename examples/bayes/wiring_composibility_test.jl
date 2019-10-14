# -*- coding: utf-8 -*-
# + {}
using Random
Random.seed!(0) # seed the random number generator to 0, for a reproducible demonstration
using BayesNets
# Pkg.add("Catlab")
using Catlab
using Pkg
using LightGraphs
using Catlab.WiringDiagrams
# Pkg.add("DataStructures"); 
using DataStructures;
import Catlab.Graphics: to_graphviz

# Pkg.add("TikzPictures")
using TikzPictures
# Pkg.add("TikzGraphs")
using TikzGraphs
import Catlab.Graphics: to_tikz
include("bayesUtil.jl")

⊗(a::WiringDiagram, b::WiringDiagram) = otimes(a,b)
import Base: ∘
∘(a::WiringDiagram, b::WiringDiagram) = compose(b, a)
⊚(a,b) = b ∘ a
⊚(a...) = foldl(⊚,a)
# -

#Create Equations
a_equation = randn(100)
b_equation = randn(100) .+ 2*a_equation .+ 3
c_equation = randn(100) .+ 2*b_equation .+ 3

#Build Rain, Sprinkler, GrassWet Example BayesNet
data = DataFrame(rain=a_equation, sprinkler=b_equation, grasswet=c_equation)
cpdA = fit(StaticCPD{Normal}, data, :rain)
cpdB = fit(LinearGaussianCPD, data, :sprinkler, [:rain])
cpdC = fit(LinearGaussianCPD, data, :grasswet, [:rain,:sprinkler])

bn1 = BayesNet([cpdA, cpdB, cpdC])

wiringDiagram_1 = getWiringDiagram(bn1)
to_graphviz(wiringDiagram_1, labels=true)

a_equation = randn(100)
flood_equation = randn(100) .+ 2*a_equation .+ 3
grasswet_b_equation = randn(100) .+ 2*b_equation .+ 3

data = DataFrame(rain=a_equation, flood=flood_equation, grasswet_b=grasswet_b_equation)
cpdA_2 = fit(StaticCPD{Normal}, data, :rain)
cpdB_2 = fit(LinearGaussianCPD, data, :flood, [:rain])
cpdC_2 = fit(LinearGaussianCPD, data, :grasswet_b, [:flood])

bn2 = BayesNet([cpdA_2, cpdB_2, cpdC_2])

wiringDiagram_2 = getWiringDiagram(bn2)
to_graphviz(wiringDiagram_2, labels=true)

bnList = [bn1, bn2]
mergeList = [["grasswet_b", "grasswet"]]
combinedWiring = combineBayesNets(bnList , mergeList )
# to_graphviz(combinedWiring[1], labels=true)
to_graphviz(combinedWiring, labels=true)

nodeNames = ["merged_grasswet_b_grasswet", "rain", "sprinkler", "flood", "I", "Out"]
newg, graphDictionary = getDagFromWiringD(combinedWiring, nodeNames)
println(collect(edges(newg)))
println(graphDictionary)
plot(newg)


