# -*- coding: utf-8 -*-
# ---
# jupyter:
#   jupytext:
#     formats: ipynb,jl:light,md:markdown
#     text_representation:
#       extension: .jl
#       format_name: light
#       format_version: '1.3'
#       jupytext_version: 0.8.6
#   kernelspec:
#     display_name: Julia 1.0.0
#     language: julia
#     name: julia-1.0
# ---

using DataFrames
using GraphDataFrameBridge
using MetaGraphs
using CSV
using LightGraphs
using GraphPlot
#using SemanticModels

# ### Objective 1: 
#
# Build a toy knowledge graph that can represent the component pieces of our flu example, and (when traversed) can output a sequence of function calls capable of reproducing our manually produced metamodel.

# In metagraphs you can make a DataFrame with columns you want like ```src,dst,eprop1,eprop2,eprop3```... with an arbitrary number of columns and then ```g = MetaGraph(dataframe)``` will populate all the edges with those properties. Then we could add the vertex properties with a loop to set those vertex properties from a second dataframe ```vertex, vprop1, vprop2, vprop3```...
#
# The properties are stored in a dictionary so we can change them at run time without making new types. The knowledge graph will have

# ##### Vertex Types:
#
# - Code symbols
# - Functions
# - Variables
# - Symbols
#
# ##### Math/Science Concepts:
# - Math Expressions
# - Concept
# - Unit

# ##### Edge Types: SourceType -> DestinationType
# - IsCalledBy: function -> function
# - Co-occurs with: Any -> Any
# - IsComponentOf: {Symbol,Function,Variable} -> {Function, Expression}
# - IsMeasuredIn: Any -> Unit
# - Implements: Function -> {Math Expression, Concept}
# - VERB: Any -> Any
# - IsSubClassOf: SpecificConcept -> More General Concept

'''
function create_sir(m, solns)
        sol = solns[1]
        initialS = u"10000person"
        initialI = u"1person" 
        initialpop = [initialS, initialI, u"0.0person"]
        β = u"1.0/18"/u"d*C" * sol(sol.t[end-2])[1] #infectiousness
        @show β
        sirprob = SIRSimulation(initialpop, #initial_conditions S,I,R
                                (u"0.0d", u"20d"), #time domain
                                SIRParams(β, u"40.0person/d")) # parameters β, γ
        return sirprob
    end
'''

function create_bidirectional_edges(edges_df)
    for edge in eachrow(edges_df)
        if edge.CoOccursWith == 1
            push!(edges_df, [edge.dst_vid, 
                    edge.dst_name, 
                    edge.src_vid, 
                    edge.src_name,
                    edge.IsCalledBy,
                    edge.CoOccursWith,
                    edge.IsComponentOf,
                    edge.IsMeasuredIn,
                    edge.Implements,
                    edge.IsSubClassOf,
                    edge.Verb,
                    edge.VerbToken])
        end
    end
    return edges_df
end
        

function generate_kg(vertices, edges)
    n_vertices = size(vertices,1)
    g = MetaDiGraph(n_vertices)


    for vertex in eachrow(vertices)
        set_props!(g, vertex.v_id, 
            Dict(:v_name=>vertex.v_name, :v_type=>vertex.v_type, :v_math_sci_concept=> vertex.v_math_sci_concept))
    end

    for edge in eachrow(edges)
        add_edge!(g, edge.src_vid, edge.dst_vid)

        edge_attrs = Dict(
            :IsCalledBy=>edge.IsCalledBy, 
            :CoOccursWith=>edge.CoOccursWith, 
            :IsComponentOf=>edge.IsComponentOf,
            :IsMeasuredIn=>edge.IsMeasuredIn,
            :Implements=>edge.Implements,
            :IsSubClassOf=>edge.IsSubClassOf,
            :Verb=>edge.Verb,
            :VerbToken=>edge.VerbToken)
        
        set_props!(g, Edge(edge.src_vid, edge.dst_vid), edge_attrs)

    end

    nodelabel = [vertices.v_name]
    
    return g
end


schema = CSV.read("./data/kg_schema.csv")

vertices = CSV.read("./data/kg_vertices.csv")

edges = CSV.read("./data/kg_edges.csv")
edges = edges[1:5, [:src_vid, :src_name, :dst_vid, :dst_name, :IsCalledBy, :CoOccursWith, :IsComponentOf, :IsMeasuredIn, :Implements, :IsSubClassOf, :Verb, :VerbToken]]

edges_full = create_bidirectional_edges(edges)

g = generate_kg(vertices, edges_full)
display(g)

gplot(g, nodelabel=vertices.v_name, layout=circular_layout)


