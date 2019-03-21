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
import Base: show

# +
"""    SimpleProblem <: AbstractProblem

represents a generic scientific model, where there are blocks of code that get run in order some of which
are function definitions. This type assumes a minimal structure on code. Namely,

1. There are imports/usingf expressions at the top of the expression
2. Code is broken into chunks with either function defintions or begin/end pairs
3. There is a single entrypoint function that "runs the model" This defaults to main().
"""
mutable struct SimpleProblem <: AbstractProblem
    expr::Expr
    imports::Any
    blocks::Vector{Expr}
    functions::Vector{Expr}
    entry::Expr
end

"""    issome(x)

predicate for being neither missing or nothing
"""
issome(x) = !ismissing(x) && !isa(x, Nothing)

"""    head(x)

gets the head of an Expr or nothing for LineNumberNodes
"""
head(x::Expr) = x.head
head(n::LineNumberNode) = nothing

"""    isblock(x)

predicate for an expression being a block node. Exists to make filter(x->head(x)==:block) shorter.
"""
isblock(x) = head(x) == :block

"""    isfunc(x)

predicate for an expression being a function definition. Exists to make filter(x->head(x)==:function) shorter.
"""
isfunc(x) = head(x) == :function

"""    iscall(x)

predicate for an expression being a function call. Exists to make filter(x->head(x)==:call) shorter.
"""
iscall(x) = head(x) ==:call

"""    isimport(x)

predicate for an expression being an import statement. Exists to make filter(x->head(x)==:import) shorter.
"""
isimport(x) = head(x) == :import

"""    isusing(x)

predicate for an expression being a using statement. Exists to make filter(x->head(x)==:using) shorter.
"""
isusing(x) = head(x) == :using

"""    or(f,g) = x->f(x) || g(x)
"""
or(f::Function, g::Function) = x->(f(x) || g(x))

"""    and(f,g) = x->f(x) && g(x)
"""
and(f::Function, g::Function) = x->(f(x) && g(x))

function funcname(ex::Expr)
    if isfunc(ex)
        return ex.args[1].args[1]
    elseif iscall(ex)
        return ex.args[1]
    end
    
    return :nothing
end

entrypoint(m::AbstractProblem) = m.entry
function entryname(m::AbstractProblem)
    c = entrypoint(m)
    iscall(c) || error("Entrypoint is not a :call")
    if iscall(c)
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
    return :nothing
end

function model(::Type{SimpleProblem}, expr::Expr, entrypoint=:(main()))
    if expr.head == :block
        expr = expr.args[end]
    end
    b = body(expr)
    statements = b.args
    imports = filter(or(isusing,isimport), statements)
    blocks = filter(or(isblock, isfunc), statements)
    funcs = filter(isfunc, statements)
    return SimpleProblem(expr, imports, blocks, funcs, entrypoint)
end

function show(io::IO, m::SimpleProblem)
    fns = funcname.(m.functions)
    write(io, "SimpleProblem(\n")
    write(io, "  imports=$(repr(m.imports)),\n")
    write(io, "  blocks=$(repr(m.blocks)),\n")
    write(io, "  functions=$(repr(fns))\n")
    write(io, "  entry=$(repr(m.entry))")
end
# -


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

StatsMod = eval(m.expr)
StatsMod.main(10)

macro model(class, args...)
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
end

m′.expr

m′.functions

m′.entry

Mod = eval(m′.expr)
getfield(Mod, entryname(m′))(10)


