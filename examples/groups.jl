module Transformations
using SemanticModels.Parsers
using SemanticModels.ModelTools
import Base: ∘, show, convert, promote, one, zero, inv, *, ^, -
import SemanticModels.ModelTools: AbstractProblem, model

export Transformation, ConcatTransformation, Product, Pow, MonomialRegression

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

function (f::ConcatTransformation)(m::AbstractProblem)
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

function (f::Product)(m::AbstractProblem)
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

struct MonomialRegression <: AbstractProblem
    expr
    f
    coefficient
    objective
    interval
end

function funcarg(ex::Expr)
    return ex.args[1].args[2]
end

isexpr(x) = isa(x, Expr)

# eval(m::MonomialRegression) = eval(m.expr)

function model(::Type{MonomialRegression}, ex::Expr)
    if ex.head == :block
        return model(MonomialRegression, ex.args[2])
    end

    objective = callsites(ex, :optimize)[end].args[2]
    f = filter(isexpr, findfunc(ex, :f))[1]
    interval = findassign(ex, :a₀)[1]
    ldef = filter(isexpr, findfunc(ex, objective))
    coeff = funcarg(ldef[1])
    return MonomialRegression(ex,
                              f,
                              coeff,
                              objective,
                              interval)
end

function show(io::IO, m::MonomialRegression)
    write(io, "MonomialRegression(\n  f=$(repr(m.f)),\n  objective=$(repr(m.objective)),\n  coefficient=$(repr(m.coefficient)),\n  interval=$(repr(m.interval)))")
end

function (t::Pow)(m::MonomialRegression)
    x = m.f.args[1].args[3]
    replacer(a::Any) = a
    replacer(ex::Expr) = begin
        if ex.head == :call && ex.args[1] == :(^)
            # increment the power
            try
                ex.args[3]+=t.inc
            catch
                @warn "Possible invalid xform"
                @show ex
            end
        end
        return ex
    end
    m.f.args[2] = postwalk(replacer, m.f.args[2])
end

end
