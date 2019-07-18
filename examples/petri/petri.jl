# -*- coding: utf-8 -*-
# + {}
module Petri
using ModelingToolkit
import ModelingToolkit: Constant, Variable
using MacroTools
import MacroTools: postwalk

struct Model{G,S,D,L,P}
    g::G  # grounding
    S::S  # states
    Δ::D  # transition function
    Λ::L  # transition rate
    Φ::P  # if state should happen
end


Model(s::S, δ::D, λ::L, ϕ::P) where {S,D,L,P} = Model{Any,S,D,L,P}(missing, s, δ, λ, ϕ)

Model(s::S, δ::D) where {S<:Vector,D<:Vector{Tuple{Operation, Operation}}} = Model(s, δ, [],[])

struct Problem{M<:Model, S, N}
    m::M
    initial::S
    steps::N
end

sample(rates) = begin
    s = cumsum(rates)
    #@show s
    #@show s[end]
    r = rand()*s[end]
    #@show r
    nexti = findfirst(s) do x
        x >= r
    end
    return nexti
end

function rewrite!(m::Model, m2::Model)
    rewrite!(m, m2, Dict())
end

function rewrite!(m::Model, m2::Model, f::Dict)
    vars = map(m.S) do s
        s.op
    end
    @show
    for i in 1:length(m2.S)
        s = m2.S[i]
        found = findfirst(vars .== (haskey(f, s) ? f[s].op : s.op))
        if typeof(found) == Nothing
            push!(m.S, s)
            push!(m.Δ, m2.Δ[i])
            push!(m.Λ, m2.Λ[i])
            push!(m.Φ, m2.Φ[i])
        else
            m.Δ[found] = m2.Δ[i] == Nothing ? m.Δ[found] : m2.Δ[i]
            m.Λ[found] = m2.Λ[i] == Nothing ? m.Λ[found] : m2.Λ[i]
            m.Φ[found] = m2.Φ[i] == Nothing ? m.Φ[found] : m2.Φ[i]
        end
    end
end

function solve(p::Problem)
    state = p.initial
    for i in 1:p.steps
        state = step(p, state)
    end
    state
end

function step(p::Problem, state)
    #@show state
    n = length(p.m.Δ)
    rates = map(p.m.Λ) do λ
        apply(λ, state)
    end
    #@show rates
    nexti = sample(rates)
    #@show nexti
    if apply(p.m.Φ[nexti], state)
        newval = apply(p.m.Δ[nexti], state)
        eqns = p.m.Δ[nexti]
        for i in 1:length(eqns)
            lhs = eqns[i].lhs
            # rhs = eqns[i].rhs
            setproperty!(state, lhs.op.name, newval[i])
        end
    end
    state
end

eval(m::Model) = Model(m.g, m.S, eval.(m.Δ), eval.(m.Λ), eval.(m.Φ))

function step(p::Problem{Model{T,
                               Array{Operation,1},
                               Array{Function,1},
                               Array{Function,1},
                               Array{Function,1}},
                         S, N} where {T,S,N},
              state)
    # @show state
    n = length(p.m.Δ)
    rates = map(p.m.Λ) do λ
        λ(state)
    end
    # @show rates
    nexti = sample(rates)
    if nexti == nothing
        return state
    end
    # @show nexti
    if p.m.Φ[nexti](state)
        p.m.Δ[nexti](state)
    end
    state
end

function step(p::Petri.Problem{Petri.Model{T,
                               Array{Operation,1},
                               Array{Function,1},
                               Array{Function,1},
                               Missing},
                         S, N} where {T,S,N},
              state)
    # @show state
    n = length(p.m.Δ)
    rates = map(p.m.Λ) do λ
        λ(state)
    end
    # @show rates
    nexti = sample(rates)
    if nexti == nothing
        return state
    end
    # @show nexti
    p.m.Δ[nexti](state)
    state
end
function apply(expr::Equation, data)
    rhs = expr.rhs
    apply(rhs, data)
end

function apply(expr::Constant, data)
    # constants don't have an op field they are just a value.
    return expr.value
end

function apply(expr::Tuple, data)
    # this method only exists to harmonize the API for Equation, Constant, and Operation
    # all the real work is happening in the three argument version below.
    vals = map(expr) do ex
        apply(ex, data)
    end
    return tuple(vals...)
end
function apply(expr::Operation, data)
    # this method only exists to harmonize the API for Equation, Constant, and Operation
    # all the real work is happening in the three argument version below.
    apply(expr.op, expr, data)
end

# this uses the operation function as a trait, so that we can dispatch on it;
# allowing client code to extend the language using Multiple Dispatch.
function apply(op::Function, expr::Operation, data)
    # handles the case where there are no more arguments to find.
    # we assume this is a leaf node in the expression, which refers to a field in the data
    if length(expr.args) == 0
        return getproperty(data, expr.op.name)
    end
    anses = map(expr.args) do a
        apply(a, data)
    end
    return op(anses...)
end

function funcbody(ex::Equation, ctx=:state)
    return ex.lhs.op.name => funcbody(ex.rhs, ctx)
end

function funcbody(ex::Operation, ctx=:state)
    args = Symbol[]
    body = postwalk(convert(Expr, ex)) do x
        # @show x, typeof(x);
        if typeof(x) == Expr && x.head == :call
            if length(x.args) == 1
                var = x.args[1]
                push!(args, var)
                return :($ctx.$var)
            end
        end
        return x
    end
    return body, Set(args)
end

funckit(fname, args, body) = quote $fname($(collect(args)...)) = $body end
funckit(fname::Symbol, arg::Symbol, body) = quote $fname($arg) = $body end
function funckit(p::Petri.Problem, ctx=:state)
    # @show "Λs"
    λf = map(p.m.Λ) do λ
        body, args = funcbody(λ, ctx)
        fname = gensym("λ")
        q = funckit(fname, ctx, body)
        return q
    end
    # @show "Δs"
    δf = map(p.m.Δ) do δ
        q = quote end
        map(δ) do f
            vname, vfunc = funcbody(f, ctx)
            body, args = vfunc
            qi = :(state.$vname = $body)
            push!(q.args, qi)
        end
        sym = gensym("δ")
        :($sym(state) = $(q) )
    end

    # @show "Φs"
    ϕf = map(p.m.Φ) do ϕ
        body, args = funcbody(ϕ, ctx)
        fname = gensym("ϕ")
        q = funckit(fname, ctx, body)
    end
    return Model(p.m.S, δf, λf, ϕf)
end


struct Span{L,C,R}
    l::L
    c::C
    r::R
end

struct DPOProblem
    rule::Span
    c′::Model
end

solve(p::DPOProblem) = pushout(p.rule.r, p.c′)



"""    pushout(m1::Model, m2::Model)

compute the CT pushout of two models.
"""
function pushout(m1::Model, m2::Model)
    states = union(m1.S, m2.S)
    Δ = union(m1.Δ, m2.Δ)
    Λ = union(m1.Λ, m2.Λ)
    Φ = union(m1.Φ, m2.Φ)
    return Model(states, Δ, Λ, Φ)
end

"""
    dropdown(l::Model, c::Model, l′::Model)

compute c′ given l, c, l′, the formula for petrinets is

T_{c'} = T_{l'} \\setdiff f(T_l) \\cup a(T_c)
"""
function dropdown(l::Model, c::Model, l′::Model)
    states = union(l′.S, c.S)
    Δ = union(setdiff(l′.Δ, l.Δ), c.Δ)
    Λ = union(setdiff(l′.Λ, l.Λ), c.Λ)
    Φ = union(setdiff(l′.Φ, l.Φ), c.Φ)
    return Model(states, Δ, Λ, Φ)
end

end
# -

# using Petri
import Base.show
using DiffEqBase
using ModelingToolkit
# using DiffEqBiological

macro grounding(ex)
    return ()
end

mutable struct SIRState{T,F}
    S::T
    I::T
    R::T
    β::F
    γ::F
    μ::F
end

mutable struct ParamSIR{T, P}
    S::T
    I::T
    R::T
    params::P
end

mutable struct ParamSEIR{T, P}
    S::T
    E::T
    I::T
    R::T
    params::P
end

mutable struct SEIRState{T,F}
    S::T
    I::T
    R::T
    β::F
    γ::F
    μ::F
    E::T
    η::F
end


mutable struct SEIRDState{T,F}
    S::T
    I::T
    R::T
    β::F
    γ::F
    μ::F
    E::T
    η::F
    D::T
    ψ::F
end

function show(io::IO, s::SIRState)
    t = (S=s.S, I=s.I, R=s.R, β=s.β, γ=s.γ, μ=s.μ)
    print(io, "$t")
end
