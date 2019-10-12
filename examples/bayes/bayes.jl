# -*- coding: utf-8 -*-
using Random
Random.seed!(0) # seed the random number generator to 0, for a reproducible demonstration
using BayesNets
using Pkg
using LightGraphs

# +
using Catlab.WiringDiagrams
using Catlab.Doctrines
import Catlab.Doctrines.⊗
import Catlab.Graphics: to_graphviz
import Catlab.Graphics.Graphviz: run_graphviz
⊗(a::WiringDiagram, b::WiringDiagram) = otimes(a,b)
import Base: ∘
∘(a::WiringDiagram, b::WiringDiagram) = compose(b, a)
⊚(a,b) = b ∘ a

⊚(a...) = foldl(⊚,a)
# -

a_equation = randn(100)
b_equation = randn(100) .+ 2*a_equation .+ 3
c_equation = randn(100) .+ 2*b_equation .+ 3

#Build Example BayesNet
data = DataFrame(rain=a_equation, sprinkler=b_equation, grasswet=c_equation)
cpdA = fit(StaticCPD{Normal}, data, :rain)
cpdB = fit(LinearGaussianCPD, data, :sprinkler, [:rain])
cpdC = fit(LinearGaussianCPD, data, :grasswet, [:rain,:sprinkler])

bn2 = BayesNet([cpdA, cpdB, cpdC])

# +


vIDtoSymbol_dict = Dict()

for entry in bn2.name_to_index;    
    vIDtoSymbol_dict[bn2.name_to_index[entry[1]]] = entry[1]
end


# +
function bindvar(x)
    ex = quote
       $(x.args[1]) = $x
        println(typeof($(x.args[1])))
    end
    dump(ex)
end

g = bn2.dag
vars = map(vertices(g)) do v
        mapping = (vIDtoSymbol_dict[v])
        mapping = Ob(FreeSymmetricMonoidalCategory, Symbol("M_$mapping"))
end

print(typeof(vars))
I = Ob(FreeSymmetricMonoidalCategory, Symbol("I"))

# +
#discoverBaseHOM

# base_hom = Hom(Symbol(vIDtoSymbol_dict[1]), vars[1], OUT)
list = []
push!(list, vars[1])
push!(list, vars[2])

base_hom = WiringDiagram(Hom(Symbol(vIDtoSymbol_dict[1]), I, vars[1]))
sprinkler = WiringDiagram(Hom(Symbol(vIDtoSymbol_dict[2]), vars[1], vars[2]))
grassWet = WiringDiagram(Hom(Symbol(vIDtoSymbol_dict[3]), foldl(⊗,list), vars[3]))


sprinkler_given_rain = ⊚(base_hom, sprinkler)
# finalWiring = (sprinkler_given_rain ⊗ base_hom)
finalWiring = (sprinkler_given_rain ⊗ base_hom) ⊚  grassWet



to_graphviz(finalWiring, labels=true)



# -

function createWiring(vertices, dag, base_hom) 
    wiringObjList = []
    dependencyList = []
    retHom = base_hom
    for vertex in vertices
        in_neighbors = inneighbors(dag, vertex)
        varsList = []
        if size(in_neighbors,1) > 0
            for neighbor in in_neighbors
                push!(varsList, vars[neighbor])
            end
            
            wiring_obj = Hom(Symbol(vIDtoSymbol_dict[vertex]), foldl(⊗,varsList), vars[vertex])
            push!(wiringObjList, wiring_obj)
            push!(dependencyList, inneighbors(dag, vertex))
        end
    end
    return wiringObjList, dependencyList
end

# +
base_hom = Hom(Symbol(vIDtoSymbol_dict[1]), I, vars[1])

homList, depList = createWiring(outneighbors(bn2.dag, 1), bn2.dag, base_hom)
homList = append!([base_hom], homList)
depList = append!([[]], depList)


# +
function build(dict, y)
    push!(dict, codom(y)=>compose(typeof(dom(y)) == FreeSymmetricMonoidalCategory.Ob{:generator} ? dict[dom(y)] : otimes(map(x->dict[x], dom(y).args)), y))
end

dict = Dict()
push!(dict, I=>id(I))

map((x)->build(dict, x), homList)
to_graphviz(dict[vars[3]], labels=true)
# -


