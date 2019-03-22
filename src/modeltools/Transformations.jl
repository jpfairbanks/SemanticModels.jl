# -*- coding: utf-8 -*-
# + {}
module Transformations
import Base: ∘, show, convert, promote, one, zero, inv, *, ^, -

using SemanticModels.Parsers
using SemanticModels.ModelTools
import SemanticModels.ModelTools: model

export Transformation, ConcatTransformation, Product, Pow

postwalk(f, x) = walk(x, x -> postwalk(f, x), f)

abstract type Transformation end

struct ConcatTransformation
    seq::Vector{Transformation}
end

promote(a::ConcatTransformation, b::Transformation) = (a, ConcatTransformation([b]))
convert(::ConcatTransformation, t::Transformation) = ConcatTransformation([t])

function ∘(f::ConcatTransformation, g::ConcatTransformation)
    append!(g.seq, f.seq)
    return g
end

function (f::ConcatTransformation)(m::AbstractModel)
    return foldl((m, t)->t(m), [m; f.seq])
end

"""    Pow{T}

Pow{T} represents raising terms in an equation to a power. The type Pow{Int} forms
a group that is isomorphic to the Integers (Z, +, 0). The group operation is ∘ to
match the notation that they are compositions of functions that act on models.

This is an example of encoding meaning into the type system. We are saying
"treat this number `inc` as a function on models, but also remember that instances
of this type form a group isomorphic to the integers.
"""
struct Pow{T} <: Transformation
    inc::T
end

# this is the group operation for the Pow transformation group
∘(p::Pow, q::Pow) = Pow(p.inc + q.inc)

# we implement these algebra functions to make Pow{Int} feel more like Int.
one(::Type{Pow}) = Pow(1)
zero(::Type{Pow}) = Pow(0)
inv(p::Pow) = Pow(-p.inc)

"""    ^(p::Transformation, n::Int)

the universal definition of ^ as repeated application of ∘.
"""
^(p::Transformation, n::Int) = begin
    n >= 0 || error("cannot compute negative powers in monoid/group")
    n == 0 && return zero(p)
    s = p
    for i in 1:n-1
        s = p∘s
    end
    return s
end

function show(io::IO, p::Pow)
    write(io, "Pow($(p.inc))")
end

struct Product{T} <: Transformation
    dims::T
end

function (f::Product)(m::AbstractModel)
    return foldl((m, t)->t(m), [m; f.dims])
end

function show(io::IO, p::Product)
    write(io, "$(p.dims)")
end

∘(p::Transformation, args...) = ∘(promote(p, args...)...)
∘(p::Product, q::Product) = Product(p.dims .∘ q.dims)
promote(p::Product{T}, t::T) where T= (p, Product(t))

# TODO make tests
Product((Pow(1),Pow(2))) ∘ (Pow(1),Pow(2))

end
# -


