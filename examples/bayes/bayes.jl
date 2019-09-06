# -*- coding: utf-8 -*-
using Random
Random.seed!(0) # seed the random number generator to 0, for a reproducible demonstration
using BayesNets
using Pkg
using LightGraphs

using Catlab.WiringDiagrams
using Catlab.Doctrines
import Catlab.Doctrines.⊗
import Catlab.Graphics: to_graphviz
import Catlab.Graphics.Graphviz: run_graphviz

a_equation = randn(100)
b_equation = randn(100) .+ 2*a_equation .+ 3
c_equation = randn(100) .+ 2*b_equation .+ 3

data = DataFrame(rain=a_equation, sprinkler=b_equation, grasswet=c_equation)
cpdA = fit(StaticCPD{Normal}, data, :rain)
cpdB = fit(LinearGaussianCPD, data, :sprinkler, [:rain])
cpdC = fit(LinearGaussianCPD, data, :grasswet, [:rain,:sprinkler])

bn2 = BayesNet([cpdA, cpdB, cpdC])

# +
# println(fieldnames(BayesNet))
println(fieldnames(Dict))

vIDtoSymbol_dict = Dict()



for entry in bn2.name_to_index;    
    vIDtoSymbol_dict[bn2.name_to_index[entry[1]]] = entry[1]
end

println(vIDtoSymbol_dict)

# +
verticesList = []
edgeList = collect(LightGraphs.edges(bn2.dag))
for edge in edgeList;
    if !(edge.src in verticesList);
        push!(verticesList, edge.src)
    end
    
    if !(edge.dst in verticesList);
        push!(verticesList, edge.dst)
    end
    
end

println(verticesList)
# -

println(fieldnames(LightGraphs.SimpleGraphs.SimpleEdge{Int64}))

# +
MonoidalExprString = "Ob(FreeSymmetricMonoidalCategory"
for vertex in verticesList;    
    MonoidalExprString *= ", :" * (string(vIDtoSymbol_dict[vertex])) * "_m"
end
MonoidalExprString *= ", :I)"
Meta.parse(MonoidalExprString)
eval(MonoidalExprString)


# -



