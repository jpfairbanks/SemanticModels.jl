module Parsers
using Base.Meta
import Base.push!

export parsefile, defs, funcs, recurse,
    MetaCollector, FuncCollector, AbstractCollector,
    walk, inexpr, findfunc, findassign, replacevar,
    postwalk, prewalk, replace, inexpr

include("macrotools.jl")
include("findfunc.jl")

"""    parsefile(path)

read in a julia source file and parse it.

Note: If the top level is not a simple expression or module definition the file is wrapped in a Module named modprefix.
"""
function parsefile(path, modprefix="Modeling")
    s = read(path, String)
    # open(path) do fp
    #     s = read(String, fp)
    # end
    try
        expr = Base.Meta.parse(s)
        return expr
    catch
        s = "module $modprefix\n$s \nend #module $modprefix"
        expr = Base.Meta.parse(s)
        return expr
    end
end

"""    AbstractCollector

subtypes of AbstractCollector support extracting and collecting information
from input sources.
"""
abstract type AbstractCollector end


"""    FuncCollector{T} <: AbstractCollector

collects function definitions and names
"""
struct FuncCollector{T} <: AbstractCollector
    defs::T
end

function push!(fc::AbstractCollector, expr::LineNumberNode)
    return nothing
end

function push!(fc::FuncCollector, expr::Expr)
    if expr.head == :function
        push!(fc.defs, expr.args[1] => expr.args[2])
    end
end

"""   MetaCollector{T,U,V,W} <: AbstractCollector

collects multiple pieces of information such as

- exprs: expressions
- fc: functions
- vc: variable assignments
- modc: module imports
"""
struct MetaCollector{T,U,V,W} <: AbstractCollector
    exprs::V
    fc::T
    vc::U
    modc::W
end

function push!(mc::MetaCollector, expr::Expr)
    push!(mc.exprs, expr)
    push!(mc.fc, expr)
    if expr.head == :(=)
        @debug "pushing into vc" expr=expr
        push!(mc.vc, expr.args[1]=>expr.args[2])
    elseif expr.head == :using
        push!(mc.modc, expr.args[1].args)
    else
        @info "unknown expr type for metacollector"
        @show expr
    end
end


"""    funcs(body)

collect the function definitions from a module expression.
"""
function funcs(body)
    fs = FuncCollector([])
    for subexpr in body
        push!(fs, subexpr)
    end
    return fs
end

"""    defs(body)

collect the function definitions and variable assignments from a module expression.
"""
function defs(body)
    # fs = funcs(body)
    mc = MetaCollector(Any[], FuncCollector([]), Any[], Any[])
    for expr in body
        push!(mc, expr)
    end
    return mc
end

function recurse(mc::AbstractCollector)
    subdefs = Any[]
    funcdefs = mc.fc.defs
    @show funcdefs
    for def in funcdefs
        funcname = def[1]
        funcquote = def[2]
        push!(subdefs, funcname=>defs(funcquote.args))
    end
    return subdefs
end

end


