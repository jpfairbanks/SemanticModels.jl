""" ExprModels

provides functionality of extracting and manipulating models from julia source code

"""
module ExprModels

include("parse.jl")
using SemanticModels.ExprModels.Parsers

using SemanticModels
import SemanticModels: model

export model, isexpr, invoke, callsites, structured, bodyblock,
       pusharg!, setarg!, funcarg, issome, head, isblock, isfunc,
       or, and, isexpr, iscall, isusing, isimport, funcarg, funcname

""" model(::AbstractModel, expr::Expr)
dig into the expression that describes a model and break it down into components. This allows you to construct a structured representation of the modeling problem at the expression level. Just like how julia modeling frameworks build structured representations of the problems in data structures. This version builds them at the expression level.
The first argument is the type you want to construct, the second argument is the expression that you want to analyze. For example
```
model(ExpODEModel, expr)::ExpODEModel
```
"""
function model(::Type{T}, expr::Expr) where T<:SemanticModels.AbstractModel
    error("NotImplemented: model(::$T,::Expr")
end

""" isexpr(x)
predicate for isa(x, Expr).
"""
isexpr(x) = isa(x, Expr)

function invoke(m::AbstractModel, args...)
    Mod = eval(m.expr)
    Base.invokelatest(Mod.main, args...)
end

"""    callsites(expr::Expr, name::Symbol)

extract the location where the function `name` is called in `expr`.
"""
function callsites(expr::Expr, name::Symbol)
    matches = Expr[]
    f(x::Any) = x
    f(x::Expr) = begin
        if x.head == :call && x.args[2] == name
            push!(matches, x)
            return x
        else
            return walk(x, f, g)
        end
    end
    g(x) = x
    walk(expr, f, g)
    return matches
end

"""    structured(func, var::Symbol, assign=true)

extract the expressions that use structuring/destructuring assignment
to name the components of `var`
"""
function structured(func::Expr, var::Symbol, assign=true)
    body = func.args[2]
    paramvec = Expr[]
    for line in body.args
        if isa(line, LineNumberNode)
            continue
        end
        if  assign && line.head == :(=) && inexpr(line.args[2], var)
            push!(paramvec, line)
        end
        if !assign && line.head == :(=) && inexpr(line.args[1], var)
            push!(paramvec, line)
        end
    end
    return paramvec
end

"""    bodyblock(expr::Expr)

get the array of args representing the body of a function definition.
"""
function bodyblock(expr::Expr)
    expr.head == :function || error("$expr is not a function definition")
    return expr.args[2].args
end

"""    pusharg!(expr::Expr, s::Symbol)

push a new argument onto the definition of a function.

See also [`argslist`](@ref), [`setarg!`](@ref)
"""
function pusharg!(ex::Expr, s::Symbol)
    ex.head == :function || error("ex is not a function definition")
    push!(argslist(ex), s)
    return ex
end

"""    setarg!(expr::Expr, s::Symbol)

replace the argument in a function call.

See also [`argslist`](@ref), [`pusharg!`](@ref)
"""
function setarg!(ex::Expr, old, new)
    ex.head == :call || error("ex is not a function call")
    for (i, x) in enumerate(ex.args)
        if x == old
            ex.args[i] = new
        end
    end
    return ex
end

function funcarg(ex::Expr)
    return ex.args[1].args[2]
end

include("exprs.jl")
include("Transformations.jl")
include("SimpleModels.jl")
include("ExpODEModels.jl")
include("ExpStateModels.jl")
include("MonomialRegressionModels.jl")

end
