module Parsers
using Base.Meta
import Base.push!

export parsefile

"""    parsefile(path)

read in a julia source file and parse it. currently only works if the top level is a simple expression or module definition.
"""
function parsefile(path)
    s = read(path, String)
    # open(path) do fp
    #     s = read(String, fp)
    # end
    @show s
    expr = Base.Meta.parse(s)
    return expr
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

function push!(fc::FuncCollector, expr::LineNumberNode)
    return nothing
end

function push!(fc::FuncCollector, expr::Expr)
    if expr.head == :function
        push!(fc.defs, expr.args[1] => expr.args[2])
    end
end

"""    funcs(body)

collect the function definitions from a module expression.
"""
function funcs(body)
    fs = FuncCollector([])
    for subexpr in body
        @show subexpr
        push!(fs, subexpr)
    end
    return fs
end

end

@show expr =Parsers.parsefile("examples/epicookbook/notebooks/SimpleDeterministicModels/SIRModel.jl")

modulename = expr.args[2]
fs = Parsers.funcs(expr.args[3].args)
