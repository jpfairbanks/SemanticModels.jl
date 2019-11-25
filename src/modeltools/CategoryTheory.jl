# -*- coding: utf-8 -*-
module CategoryTheory

using SemanticModels
using SemanticModels.ModelTools
import Catlab.Doctrines: dom, codom
using MacroTools: prewalk, postwalk
using ModelingToolkit
import Base: append!, push!, deleteat!, delete!


export ⊔, AbstractMorph, FinSetMorph, dom, codom, verify, func, Decorated, decorations, undecorate, AbstractSpan, leftob, rightob, apexob, Span, left, right, DoublePushout, AbstractCospan, Cospan, pushout

import MacroTools.walk
walk(x::Operation, inner, outer) = outer(Operation(x.op, map(inner, x.args)))


⊔(a::UnitRange, b::UnitRange) = 1:(length(a)+length(b))
⊔(a::AbstractVector{Int}, b::AbstractVector{Int}) = vcat(a,b)


"""    AbstractMorph

an abstract type for representing morphisms. The essential API for subtypes of AbstractMorph are

1. dom(m)::T
2. codom(m)::T
3. func(m)::Function

where T is the type of the objects in the category. See FinSetMorph for an example.
"""
abstract type AbstractMorph end

"""    FinSetMorph{T,F}

morphisms in the category of Finite Sets. The objects are of type UnitRange{Int}.
func(m::FinSetMorph) is a function that takes `Int -> Int`. FinSetMorphs can be constructed
from a list of numbers. For example, `FinSetMorph([1,3,2,3])` is the morphism that takes
`1->1, 2->3, 3->2, 4->3` on domain `1:4` with codomain `1:3`. When you define a morphism from
a list of integers, the codomain is inferred from the largest element of the list. The domain
must always be the `1:l` where `l` is the length of the input list.

```(f::FinSetMorph)(g::G) where G <: AbstractGraph```

lift a finite set morphism (list of integers) to a graph homomorphism by its action on the vertex
set. The graph `h = f(g)` is defined by taking the edges of `g` and relabeling their src and dst
according to the function of `f`.

This method computes a valid graph homomorphism by definition.
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

"""    Decorated{M,T}

a decoration applied to the objects of a morphism, where M is a type of morphism and
type T is the category of the decoration
"""
struct Decorated{M}
    f::M
    d::AbstractArray{AbstractModel}
end

# Handle creating a decorated morphism with an array of a single type
Decorated(f, d::AbstractArray{T}) where T<:AbstractModel = Decorated(f, Vector{AbstractModel}(d))
# Handle creating a decorated morphism from a single decoration
Decorated(f, d::T) where T<:AbstractModel = Decorated(f, Vector{AbstractModel}([d]))

# Get the domain or codomain of a decorated morphism
dom(m::Decorated) = dom(m.f)
codom(m::Decorated) = codom(m.f)

# Get the decorations of a decorated morphism
function decorations(m::Decorated)
  return m.d
end
# Get the decorations of AbstractModel T of a decorated morphism
function decorations(m::Decorated, ::Type{T}) where T<:AbstractModel
  filter(x -> isa(x,T), decorations(m))
end

# Remove the decoration of a decorated morphism, and return the original morphism
function undecorate(m::Decorated)
  return m.f
end

# Add a decoration to a decorated morphism
function push!(m::Decorated, decoration::AbstractModel)
  push!(decorations(m), decoration)
end

# Add a collection of decorations to a decorated morphism
function append!(m::Decorated, decorations)
    append!(m.d, decorations)
end

# remove a decoration from a decorated morphism
function deleteat!(m::Decorated, i)
  deleteat!(decorations(m), i)
end

# Remove the decorations of AbstractModel T from a decorated morphism
function delete!(m::Decorated, ::Type{T}) where T<:AbstractModel
  filter!(x -> !isa(x,T), decorations(m))
end

function left(d::Decorated)
  return left(d.f)
end

function right(d::Decorated)
  return right(d.f)
end

"""    AbstractSpan

an abstract type for representing spans. The essential API for subtypes of AbstractSpan are

1. left(s)::M
2. right(s)::M
3. pushout(s)::C

where M is the type of morphisms in the span, and C is the type of cospan that solves
a pushout of span s. See Span for an example.
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

struct DoublePushout{S<:AbstractSpan, T<:NTuple{3,AbstractMorph}}
    rule::S
    morphs::T
    application::S
end

# TODO DPO CONSTRUCTOR TO SOLVE UNKNOWN DOUBLEPUSHOUT OF FINSET
# take in Span `top` (l, c, r) and finset `l′ `, f: l -> l′
# Solve for c′ using dropdown
#     c′ = setdiff(l′, f(l)) ⊔ c
# Solve pushout for span of c′ ← c → r to get r′

# function pullback

# +
"""    AbstractCospan

an abstract type for representing cospans. The essential API for subtypes of AbstractCospan are

1. left(c)::M
2. right(c)::M
3. pullback(c)::S

where M is the type of morphisms in the cospan, and S is the type of span that solves the
pullback defined by c. See Cospan for an example.
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

treat f,g as a decorated span and compute the pushout that is, the cospan of f=(f⊔g) and g=(a⊔b),
with the decoration of (f⊔g)(d)
"""
function pushout(s::Span{T, T}) where T <: Decorated
    cs = pushout(undecorate(s))
    decorations = map(x->x[1] ⊔ x[2], zip(left(s).d, right(s).d))
    return Decorated(cs, map((right(cs) ⊔ left(cs)), decorations))
end

end
