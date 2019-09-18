# -*- coding: utf-8 -*-
# ---
# jupyter:
#   jupytext:
#     text_representation:
#       extension: .jl
#       format_name: light
#       format_version: '1.4'
#       jupytext_version: 1.2.1
#   kernelspec:
#     display_name: Julia 1.0.3
#     language: julia
#     name: julia-1.0
# ---

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

# +
function createWiring(vertices, dag, base_hom, vars, vIDtoSymbol_dict) 
    wiringObjList = []
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
        end
    end
    return wiringObjList
end


function bindvar(x)
    ex = quote
       $(x.args[1]) = $x
        println(typeof($(x.args[1])))
    end
    dump(ex)
end


function build(dict, y)
    push!(dict, codom(y)=>compose(typeof(dom(y)) == FreeSymmetricMonoidalCategory.Ob{:generator} ? dict[dom(y)] : otimes(map(x->dict[x], dom(y).args)), y))
end

function getWiringDiagram(bayesNet)
    vIDtoSymbol_dict = Dict()

    for entry in bayesNet.name_to_index;    
        vIDtoSymbol_dict[bayesNet.name_to_index[entry[1]]] = entry[1]
    end
    
    g = bayesNet.dag
    
    vars = map(vertices(g)) do v
        mapping = (vIDtoSymbol_dict[v])
        mapping = Ob(FreeSymmetricMonoidalCategory, Symbol("M_$mapping"))
    end
    I = Ob(FreeSymmetricMonoidalCategory, Symbol("I"))
    
    
    base_hom = Hom(Symbol(vIDtoSymbol_dict[1]), I, vars[1])

    homList = createWiring(outneighbors(bayesNet.dag, 1), bayesNet.dag, base_hom, vars, vIDtoSymbol_dict)
    homList = append!([base_hom], homList)
    
    dict = Dict()
    push!(dict, I=>id(I))

    map((x)->build(dict, x), homList)
    
    top_sort = topological_sort_by_dfs(bn2.dag)
    lastElement = top_sort[end]
    
    return dict[vars[lastElement]]


end

# -


