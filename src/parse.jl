module Parsers
using Base.Meta

export parsefile

function parsefile(path)
    s = read(path, String)
    # open(path) do fp
    #     s = read(String, fp)
    # end
    @show s
    expr = Base.Meta.parse(s)
    return expr
end

abstract type AbstractCollector end

struct FuncCollector{T} <: AbstractCollector
    defs::T
end

function handle(fc::FuncCollector, expr::LineNumberNode)
    return expr, expr
end

function handle(fc::FuncCollector, expr::Expr)
    if expr.head == :function
        push!(fc.defs, expr.args[1] => expr.args[2])
    end
end

function funcs(body)
    fs = FuncCollector([])
    for subexpr in body
        @show subexpr
        handle(fs, subexpr)
    end
    return fs
end

end

@show expr =Parsers.parsefile("examples/epicookbook/notebooks/SimpleDeterministicModels/SIRModel.jl")

modulename = expr.args[2]
fs = Parsers.funcs(expr.args[3].args)
