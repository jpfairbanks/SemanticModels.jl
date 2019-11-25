module GraphModels
using LightGraphs

using SemanticModels.ModelTools
using SemanticModels.ModelTools.CategoryTheory
import SemanticModels.ModelTools.CategoryTheory: ⊔, FinSetMorph, dom, codom, func
import SemanticModels.ModelTools: model
export GraphModel, model, ⊔, GraphMorph, dom, codom, func, verify

struct GraphModel <: AbstractModel
  model::AbstractGraph
end
  
function model(::Type{GraphModel}, g::AbstractGraph)
    return GraphModel(g)
end

⊔(g::GraphModel, h::GraphModel) = GraphModel(blockdiag(g.model,h.model))


function (f::FinSetMorph)(gModel::G) where G <: GraphModel
    g = gModel.model
    dom(f) == vertices(g) || throw(DomainError(vertices(g), "dom(f) = $(dom(f)) but nv(g) = $(nv(g))"))
    ϕ = func(f)
    GraphModel(map(edges(g)) do e
        s,t = e.src, e.dst
        LightGraphs.Edge(ϕ(s), ϕ(t))
      end |> Graph)
end

"""    GraphMorph{T,F} <: Morph

morphisms in the category of Finite Graphs. The objects must be a subtype of AbstractGraph.

You can take a `FinSetMorph` and lift it to a graph homomorphism. This is the functor that
takes the finite set `1:n`, to the empty graph with `n` vertices.

"""
struct GraphMorph{T, F} <: AbstractMorph
    dom::T
    codom::T
    fun::F
end

"""    GraphMorph(g::AbstractGraph, f::FinSetMorph)

is defined to be the graph homomorphism you get by functorially lifting `f`.
That is, `f` acts on the vertex set of `g` as an `Int->Int` function, and then
must act on the edges consistently.
"""
GraphMorph(g::GraphModel, f::FinSetMorph) = GraphMorph(g, f(g), f)

dom(m::GraphMorph) = m.dom
codom(m::GraphMorph) = m.codom
func(m::GraphMorph) = begin
    f = func(m.fun)
    return i->f(i)
end

"""    verify(m::GraphMorph)

validate a graph homomorphism by checking that all the edges in `dom(m)` and map to edges in `codom(m)`.
"""
verify(m::GraphMorph) = begin
    dom(m.fun) == vertices(dom(m)) || return false
    codom(m.fun) == vertices(codom(m)) || return false
    E = Set(edges(codom(m)))
    f = func(m)
    map(edges(dom(m))) do e
        u,v = f(e.src), f(e.dst)
        if u > v
            u,v = v,u
        end
        LightGraphs.Edge(u,v) in E
    end |> all
end

end