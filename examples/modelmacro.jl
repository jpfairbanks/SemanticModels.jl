# -*- coding: utf-8 -*-
# ---
# jupyter:
#   jupytext:
#     text_representation:
#       extension: .jl
#       format_name: light
#       format_version: '1.3'
#       jupytext_version: 1.0.2
#   kernelspec:
#     display_name: Julia 1.0.3
#     language: julia
#     name: julia-1.0
# ---

using SemanticModels
using SemanticModels.ModelTools
import SemanticModels.ModelTools: model

mutable struct SimpleProblem <: AbstractProblem
    expr::Expr
    imports::Any
    blocks::Vector{Expr}
    functions::Vector{Expr}
    entry::Expr
end


# +
issome(x) = !ismissing(x) && !isa(x, Nothing)
head(x::Expr) = x.head
head(n::LineNumberNode) = nothing
isblock(x) = head(x) == :block
isfunc(x) = head(x) ==:function
or(f::Function, g::Function) = x->(f(x) || g(x))
entrypoint(m::AbstractProblem) = m.entry
entryname(m::AbstractProblem) = begin
    c = entrypoint(m)
    if isa(c, Expr)
        c.head == :call || error("Entrypoint is not a :call")
        return c.args[1]
    elseif isa(c, Symbol)
        return c
    end
end

function body(expr)
    if expr.head == :block
        return body(expr.args[end])
    elseif expr.head == :module
        return expr.args[end]
    end
    return expr
end
# -


function model(::Type{SimpleProblem}, expr::Expr, entrypoint=:(main()))
    b = body(expr)
    statements = b.args
    imports = filter(issome,
        map(x-> if head(x) == :using
                   return x
                else
                   return nothing
                end,
            statements)
    )
    blocks = filter(or(isblock, isfunc), statements)
    funcs = filter(isfunc, statements)
    return SimpleProblem(expr, imports, blocks, funcs, entrypoint)
end


expr = quote
    module StatsMod
    using Statistics
    function foo(x)
        return x.^2
    end
    function bar(x,y)
        ρ = foo(x.-y)./(foo(x) .+ foo(y))
        return ρ
    end
    function main(n)
        x = rand(Float64, n)
        μ = mean(x)
        ρ = bar(x,μ)
        return x, ρ
    end
    end
end

m = model(SimpleProblem, deepcopy(expr), :(main(n::Int)))

StatsMod = eval(m.expr.args[2])
StatsMod.main(10)

macro model(class, args...)
    @show class
    @show args
    expr = args[end]
    if expr.head == :block
        expr = expr.args[end]
    end
    
    ex = Expr(:nothing)
    expr = quote $expr end
    if length(args) > 1
        additional_args = args[1:end-1]
        ex = :(model($class, $expr, $additional_args...))
    else
        ex = :(model($class, $expr ))
    end
    @show ex
    return ex
end

m′ = @model SimpleProblem main(n::Int64) quote
    module StatsMod
    using Statistics
    function foo(x)
        return x.^2
    end
    function bar(x,y)
        ρ = foo(x.-y)./(foo(x) .+ foo(y))
        return ρ
    end
    function main(n)
        x = rand(Float64, n)
        μ = mean(x)
        ρ = bar(x,μ)
        return x, ρ
    end
    end
end;

m′.expr

m′.functions

m′.entry

Mod = eval(m′.expr.args[end])
getfield(Mod, entryname(m′))(10)
