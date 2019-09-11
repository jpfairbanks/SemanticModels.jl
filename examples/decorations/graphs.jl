# -*- coding: utf-8 -*-
using LightGraphs
import Catlab.Doctrines: dom, codom

⊔(a::UnitRange, b::UnitRange) = 1:(length(a)+length(b))
⊔(a::AbstractVector{Int}, b::AbstractVector{Int}) = vcat(a,b)
⊔(g::AbstractGraph, h::AbstractGraph) = blockdiag(g,h)

"""    AbstractMorph

an abstract type for representing morphisms. The essential API for subtypes of AbstractMorph are

1. dom(m)::T
2. codom(m)::T
3. func(m)::Function

where T is the type of the objects in the category. See FinSetMorph for an example.
"""
abstract type AbstractMorph end

# +
"""    FinSetMorph{T,F}

morphisms in the category of Finite Sets. The objects are of type UnitRange{Int}.
func(m::FinSetMorph) is a function that takes `Int -> Int`. FinSetMorphs can be constructed
from a list of numbers. For example, `FinSetMorph([1,3,2,3])` is the morphism that takes
`1->1, 2->3, 3->2, 4->3` on domain `1:4` with codomain `1:3`. When you define a morphism from
a list of integers, the codomain is inferred from the largest element of the list. The domain must always be the `1:l` where `l` is the length of the input list.
"""
struct FinSetMorph{T,F} <: AbstractMorph
    codom::T
    fun::F
end

FinSetMorph(v::AbstractVector{Int}) = FinSetMorph(1:maximum(v), v)

dom(m::FinSetMorph) = 1:length(m.fun)
codom(m::FinSetMorph) = m.codom
func(m::FinSetMorph) = i->m.fun[i]

"""    ⊔(f::FinSetMorph, g::FinSetMorph)

the union of two morphisms in a finite set.
"""
function ⊔(f::FinSetMorph, g::FinSetMorph)
    Y = codom(f) ⊔ codom(g)
    h = f.fun ⊔ g.fun
    FinSetMorph(Y, h)
end

"""    f(g::AbstractGraph)

lift a finite set morphism (list of integers) to a graph homomorphism by its action on the vertex set. The graph `h = f(g)` is defined by taking the edges of `g` and relabeling their src and dst according to the function of `f`.

This method computes a valid graph homomorphism by definition.
"""
function (f::FinSetMorph)(g::G) where G <: AbstractGraph
    dom(f) == vertices(g) || throw(DomainError(vertices(g), "dom(f) = $(dom(f)) but nv(g) = $(nv(g))"))
    ϕ = func(f)
    map(edges(g)) do e
        s,t = e.src, e.dst
        Edge(ϕ(s), ϕ(t))
    end |> Graph
end

# +
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
GraphMorph(g::AbstractGraph, f::FinSetMorph) = GraphMorph(g, f(g), f)

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
        Edge(u,v) in E
    end |> all
end

# +
"""    Decorated{M,T}

a decoration applied to the objects of a morphism, where M is a type of morphism and type T is the category of the decoration
"""
struct Decorated{M,T}
    f::M
    d::T
end

# Get the domain or codomain of a decorated morphism
dom(m::Decorated) = dom(m.f)
codom(m::Decorated) = codom(m.f)
# Get the decoration of a decorated morphism
decoration(m::Decorated) = m.d
# Remove the decoration of a decorated morphism, and return the original morphism
undecorate(m::Decorated) = m.f

# +
"""    AbstractSpan

an abstract type for representing spans. The essential API for subtypes of AbstractSpan are

1. left(s)::M
2. right(s)::M
3. pushout(s)::C

where M is the type of morphisms in the span, and C is the type of cospan that solves a pushout of span s. See Span for an example.
"""
abstract type AbstractSpan end

leftob(s::AbstractSpan) = codom(left(s))

rightob(s::AbstractSpan) = codom(right(s))

function apexob(s::AbstractSpan)
    a = dom(left(s))
    b = dom(right(s))
    a == b || error("Inconsistent span")
    return a
end

# +
"""    Span{F,G} <: AbstractSpan

a general span type where types F and G are types of morphisms in the span
"""
struct Span{F,G} <: AbstractSpan
    f::F
    g::G
end

function left(s::Span)
    return s.f
end

function right(s::Span)
    return s.g
end

"""    undecorate(s::Span{T,T}) where T <: Decorated

remove decorations of a span of decorated morphisms
"""
function undecorate(s::Span{T,T}) where T <: Decorated
    return Span(undecorate(left(s)), undecorate(right(s)))
end

# +
struct DoublePushout{S<:AbstractSpan, T<:NTuple{3,AbstractMorph}}
    rule::S
    morphs::T
    application::S
end

# TODO DPO CONSTRUCTOR TO SOLVE UNKNOWN DOUBLEPUSHOUT

# +
"""    AbstractCospan

an abstract type for representing cospans. The essential API for subtypes of AbstractCospan are

1. left(c)::M
2. right(c)::M
3. pullback(c)::S

where M is the type of morphisms in the cospan, and S is the type of span that solves the pullback defined by c. See Cospan for an example.
"""
abstract type AbstractCospan end

leftob(c::AbstractCospan) = codom(left(c))

rightob(c::AbstractCospan) = codom(right(c))

function apexob(c::AbstractCospan)
    a = dom(left(c))
    b = dom(right(c))
    a == b || error("Inconsistent cospan")
    return a
end

# +
"""    Cospan{F,G} <: AbstractCospan

a general cospan type where types F and G are types of morphisms in the cospan
"""
struct Cospan{F,G} <: AbstractCospan
    f::F
    g::G
end

function left(c::Cospan)
    return c.f
end

function right(c::Cospan)
    return c.g
end

"""    undecorate(s::Copan{T,T}) where T <: Decorated

remove decorations of a cospan of decorated morphisms
"""
function undecorate(c::Cospan{T,T}) where T <: Decorated
    return Cospan(undecorate(left(c)), undecorate(right(c)))
end

# +
"""    pushout(s::Span{T,T}) where T <: FinSetMorph

treat f,g as a span and compute the pushout that is, the cospan of f=(f⊔g) and g=(a⊔b)
"""
function pushout(s::Span{T,T}) where T <: FinSetMorph
    f_dict = Dict(a=>i for (i, a) in enumerate(left(s).fun))
    g′ = map(n->n in keys(f_dict) ? func(right(s))(f_dict[n]) : n+length(rightob(s)), leftob(s))
    
    g_dict = Dict(a=>i for (i, a) in enumerate(right(s).fun))
    f′ = map(n->n in keys(g_dict) ? g′[func(left(s))(g_dict[n])] : n, rightob(s))

    u = union(f′, g′)
    u_dict = Dict(a=>i for (i, a) in enumerate(u))
    f′ = FinSetMorph(1:length(u), map(n->u_dict[n], f′))
    g′ = FinSetMorph(1:length(u), map(n->u_dict[n], g′))

    return Cospan(f′, g′)
end

"""    pushout(s::Span{T, T}) where T <: Decorated

treat f,g as a decorated span and compute the pushout that is, the cospan of f=(f⊔g) and g=(a⊔b), with the decoration of (f⊔g)(d)
"""
function pushout(s::Span{T, T}) where T <: Decorated
    cs = pushout(undecorate(s))
    D = decoration(left(s)) ⊔ decoration(right(s))
    return Decorated(cs, (right(cs) ⊔ left(cs))(D))
end
# -

# explicit pushout definition for testing and verification of span implementation
function pushout(a::AbstractGraph, b::AbstractGraph, f::AbstractVector{Int}, g::AbstractVector{Int})
    l = f ⊔ g
    G = a ⊔ b
    map(edges(G)) do e
        s,t = e.src, e.dst
        return Edge(l[s], l[t])
    end |> Graph
end

# # Example

n = 3
a = smallgraph(:house)
b = StarGraph(n)

f = FinSetMorph([5,3,4])
F = GraphMorph(b, a, f)
@assert verify(F) == true
@assert FinSetMorph([5,4,3,2,1])(a) |>
    adjacency_matrix |>
    collect == [0 1 1 0 0;
                1 0 1 1 0;
                1 1 0 0 1;
                0 1 0 0 1;
                0 0 1 1 0]

# +
H  = pushout(a, b, 1:5, [5, 6, 4])

# Create a decorated morphism for a
g = FinSetMorph(1:5, [5,4])
# Add graph a as decoration of morphism f
dec_g = Decorated(g, a)
# Create a decorated morphism for b
f = FinSetMorph(1:3, [1,2])
# Add graph b as decoration of morphism g
dec_f = Decorated(f, b)
# Create the span of decorated morphisms
s = Span(dec_f,dec_g)
# Solve for the decorated cospan that solves the pushout defined by the span
H′ = pushout(s)

@assert H == decoration(H′)
