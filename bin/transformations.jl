# -*- coding: utf-8 -*-
# + {}
module Transformations

using SemanticModels.Parsers
using SemanticModels.ModelTools

abstract type Transformation end

struct ExprTransformation <: Transformation
    func::Symbol
    state::Symbol
    expr::Expr
end

struct ConcatTransformation
  seq::Vector{Transformation}
end

promote(::ConcatTransformation, ::Transformation) = ConcatTransformation
convert(::ConcatTransformation, t::Transformation) = ConcatTransformation([t])

function ∘(f::ConcatTransformation, g::ConcatTransformation)
    append!(g.seq, f.seq)
    return g
end

function ∘(f::Transformation, g::ConcatTransformation)
    append!(g.seq, [f])
    return g
end

function (t::ExprTransformation)(m::AbstractProblem)
    getfield(ModelTools, t.func)(m, ExpStateTransition(t.state, t.expr))
    return m
end

function (f::ConcatTransformation)(m::AbstractProblem)
    return foldl((m, t)->t(m), [m; f.seq])
end

expr = parsefile("../examples/agentbased.jl")
m = model(ExpStateModel, expr)
T = ConcatTransformation([])
T = ExprTransformation(:put!, :D, :((x...)->:D)) ∘ T
T = ExprTransformation(:replace!, :I, :((x...)->rand(Bool) ? :R : :D)) ∘ T
@show m
@show T.seq
T(m)
@show m
#M = eval(Expr(m))
#sol = M.solve()

end
# -


