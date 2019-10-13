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
function createWiring(vertices, dag, vars, vIDtoSymbol_dict) 
    wiringObjList = []
    sink_nodes = []
    
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
        if size(outneighbors(dag, vertex),1) == 0
            if !(vertex in sink_nodes)
                push!(sink_nodes, vertex)
            end

        end
                
    end
    return wiringObjList, sink_nodes
end


function bindvar(x)
    ex = quote
       $(x.args[1]) = $x
    end
    dump(ex)
end


function build(dict, y)
    push!(dict, codom(y)=>compose(typeof(dom(y)) == FreeSymmetricMonoidalCategory.Ob{:generator} ? dict[dom(y)] : otimes(map(x->dict[x], dom(y).args)), y))
end

# +
#Returns fully construted Wiring Diagram from BayesNet Input
function getWiringDiagram(bayesNet)
    #Dict to store BayesNet ID to Name
    vIDtoSymbol_dict = Dict()
    nodesList = Int64[]

    for entry in bayesNet.name_to_index;    
        vIDtoSymbol_dict[bayesNet.name_to_index[entry[1]]] = entry[1]
        if bayesNet.name_to_index[entry[1]] != 1
            push!(nodesList, bayesNet.name_to_index[entry[1]])
        end
    end
    g = bayesNet.dag
    
    #Mapping of Created Hom Object to Graph Vertices
    vars = map(vertices(g)) do v
        mapping = (vIDtoSymbol_dict[v])
        mapping = Ob(FreeSymmetricMonoidalCategory, Symbol("M_$mapping"))
    end
    #Creates the Identity Hom Object for initial input
    I = Ob(FreeSymmetricMonoidalCategory, Symbol("I"))
    Out = Ob(FreeSymmetricMonoidalCategory, Symbol("Out"))
    
    
    #Initial Hom Object created from the source of the BayesNet
    base_hom = Hom(Symbol(vIDtoSymbol_dict[1]), I, vars[1])
    
    #Creates Hom from the OutNeighbors of the Source
    homList, sink_nodes = createWiring(nodesList, bayesNet.dag, vars, vIDtoSymbol_dict)
    
    homList = append!([base_hom], homList)
    
    dict = Dict()
    push!(dict, I=>id(I))
    map((x)->build(dict, x), homList)

    
    
    wiringDiagramSinks = []
    wiringDiagram = dict[vars[sink_nodes[1]]]
    out_hom = Hom(:Out, vars[sink_nodes[1]], Out)
    wiringDiagram = wiringDiagram ⊚ out_hom

    for i = 2:length(sink_nodes)
        out_hom = Hom(:Out, vars[sink_nodes[i]], Out)
        tempWiringDiagram = dict[vars[sink_nodes[i]]] ⊚ out_hom
        wiringDiagram = wiringDiagram ⊗ tempWiringDiagram

    end
    
    
    return wiringDiagram 
    

end
# -
function getCombinedWiringDiagram(vIDtoSymbol_dict, bayesNet, nodesList)
    g = bayesNet.dag
    
    #Mapping of Created Hom Object to Graph Vertices
    vars = map(vertices(g)) do v
        mapping = (vIDtoSymbol_dict[v])
        mapping = Ob(FreeSymmetricMonoidalCategory, Symbol("M_$mapping"))
    end
    #Creates the Identity Hom Object for initial input
    I = Ob(FreeSymmetricMonoidalCategory, Symbol("I"))
    Out = Ob(FreeSymmetricMonoidalCategory, Symbol("Out"))
    #Initial Hom Object created from the source of the BayesNet
    base_hom = Hom(Symbol(vIDtoSymbol_dict[1]), I, vars[1])
    
    #Creates Hom from the OutNeighbors of the Source
    homList, sink_nodes = createWiring(nodesList, bayesNet.dag, vars, vIDtoSymbol_dict)
    
    homList = append!([base_hom], homList)
    
    dict = Dict()
    push!(dict, I=>id(I))
    map((x)->build(dict, x), homList)

    
    
    wiringDiagramSinks = []
    wiringDiagram = dict[vars[sink_nodes[1]]]
    out_hom = Hom(:Out, vars[sink_nodes[1]], Out)
    wiringDiagram = wiringDiagram ⊚ out_hom

    for i = 2:length(sink_nodes)
        out_hom = Hom(:Out, vars[sink_nodes[i]], Out)
        tempWiringDiagram = dict[vars[sink_nodes[i]]] ⊚ out_hom
        wiringDiagram = wiringDiagram ⊗ tempWiringDiagram

    end
    return wiringDiagram 
end

# +
function mergeNode(nodeName::Symbol, mergeList::Array{Array{String,1},1})
    retNode = "merged"
    retFlag = false
    
    for group in mergeList
        if String(nodeName) in group
            retFlag = true        
            for element in group
                retNode *= " " * element
            end           
        end     
    end

    return retFlag, Symbol(retNode)
end


function combineBayesNets(bayesList::Array{BayesNet{CPD},1}, mergeList::Array{Array{String,1},1})    
    vIDtoSymbol_dict = Dict()
    nodesList = Int64[]
    combinedWiringList = []
    wiring = NaN


    for bayesNet in bayesList
        for entry in bayesNet.name_to_index;   
            flag, newNodeName = mergeNode(entry[1], mergeList)
            if bayesNet.name_to_index[entry[1]] != 1
                push!(nodesList, bayesNet.name_to_index[entry[1]])
            end
            if flag == true
                vIDtoSymbol_dict[bayesNet.name_to_index[entry[1]]] = newNodeName
            else
                vIDtoSymbol_dict[bayesNet.name_to_index[entry[1]]] = entry[1]
            end
        end
        wiring = getCombinedWiringDiagram(vIDtoSymbol_dict, bayesNet, nodesList)
        push!(combinedWiringList, wiring)
    end
        
        
        
    return foldl(⊗,combinedWiringList)
end
# -


