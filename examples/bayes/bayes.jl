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
println(fieldnames(Dict))

vIDtoSymbol_dict = Dict()



for entry in bn2.name_to_index;    
    vIDtoSymbol_dict[bn2.name_to_index[entry[1]]] = entry[1]
end

println(vIDtoSymbol_dict.keys)

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
I = Ob(FreeSymmetricMonoidalCategory, Symbol("I"))

# +
verticesList = []
for edge in LightGraphs.edges(bn2.dag)
    if !(edge.src in verticesList)
        push!(verticesList, edge.src)
    end   
    if !(edge.dst in verticesList)
        push!(verticesList, edge.dst)
    end
end


for vertex in vertices(bn2.dag)
    if size(inneighbors(bn2.dag, vertex),1) != 0
        createHomConnections(vertex, outneighbors(bn2.dag, vertex), inneighbors(bn2.dag, vertex))

    end
end
# + {}
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

function createHomConnections(vertex, outneighbors, inneighbors) 
    retList = []
    if size(outneighbors,1) > 0
#         println("Multiple OutNeighbors")
        for neighbor in outneighbors
#             println("Creating Connection for " * string(vIDtoSymbol_dict[vertex])  * " to " * string(vIDtoSymbol_dict[neighbor]))
            wiring_obj = Hom(Symbol(vIDtoSymbol_dict[neighbor]), vars[vertex], vars[neighbor])
            push!(retList, WiringDiagram(wiring_obj))
        end
    end

    return retList
end

# +
base_hom = Hom(Symbol(vIDtoSymbol_dict[1]), vars[1], OUT)
baseWiring = WiringDiagram(base_hom)



for vertex in vertices(bn2.dag)
    if size(outneighbors(bn2.dag, vertex),1) > 0
        
        temp = createHomConnections(vertex, outneighbors(bn2.dag, vertex), inneighbors(bn2.dag, vertex))
        
        println(temp)
#         baseWiring = baseWiring ⊚ temp
    end

    
end

to_graphviz(baseWiring)
# -

function createWiring(vertices, dag, base_hom) 
    wiringObjList = []
    dependencyList = []
    retHom = base_hom
    for vertex in vertices
#         println(vertex)
#         println(inneighbors(dag, vertex))
        
        
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

@show typeof(homList[1]
#=
count = 0
composeList = []
for indxList in depList   
    count += 1
    
    homTemp = []
    if size(indxList, 1) > 0
        
        for indx in indxList
             push!(homTemp, homList[indx])
        end
#         push!(homTemp, homList[count])
        println(homTemp)
        push!(composeList, foldl(⊚,homTemp))       
    end  
    
end
println(composeList)
println(count)
wiringDiagram = foldl(⊗,composeList)
wiringDiagram = wiringDiagram ⊚ homList[count]



to_graphviz(wiringDiagram, labels=true)
=#

# +
function build(dict, y)
    push!(dict, codom(y)=>compose(typeof(dom(y)) == FreeSymmetricMonoidalCategory.Ob{:generator} ? dict[dom(y)] : otimes(map(x->dict[x], dom(y).args)), y))
end

dict = Dict()
push!(dict, I=>id(I))

map((x)->build(dict, x), homList)
to_graphviz(dict[vars[3]], labels=true)
# -


