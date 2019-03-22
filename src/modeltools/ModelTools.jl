module ModelTools
using SemanticModels.Parsers

export model, callsites, structured, AbstractModel,
    pusharg!, setarg!, bodyblock, argslist, issome,
    head, isblock, isfunc, or, and, isexpr, iscall,
    isusing, isimport, funcarg, funcname,
    Edge, Edges, typegraph, @typegraph

# TODO Possible imports/exports: invoke

isexpr(x) = isa(x, Expr)

"""    AbstractModel

a placeholder struct to dispatch on how to parse the expression tree into a model.
"""
abstract type AbstractModel end

function model(::Type{T}, expr::Expr) where T<:AbstractModel
    error("NotImplemented: model(::$T,::Expr")
end


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
        if x.head == :call && x.args[1] == name
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

lhs(x::Expr) = begin
    @show x
    x.head == :(=) || error("x is not an assignment")
    return x.args[1]
end

"""    bodyblock(expr::Expr)

get the array of args representing the body of a function definition.
"""
function bodyblock(expr::Expr)
    expr.head == :function || error("$expr is not a function definition")
    return expr.args[2].args
end

"""    funclines(expr::Expr, s::Symbol)

clean up the lines of a function definition for presentation
"""
function funclines(expr::Expr, s::Symbol)
    q = Expr(:block)
    q.args = (filter(isexpr, findfunc(expr, s))[end]
              |> bodyblock
              |> arr -> filter(x->!isa(x, LineNumberNode),arr))
    return q
end

"""    argslist(expr::Expr)

get the array of args representing the arguments of a defined function.
the first element of this list is the function name

See also [`bodyblock`](@ref), [`pusharg!`](@ref),
"""
function argslist(expr::Expr)
    expr.head == :function || error("$expr is not a function definition")
    return expr.args[1].args
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
include("typegraphs.jl")
include("Transformations.jl")
include("SimpleModels.jl")
include("ExpODEModels.jl")
include("ExpStateModels.jl")
include("MonomialRegressionModels.jl")

end
