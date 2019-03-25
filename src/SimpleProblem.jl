import SemanticModels.ModelTools: model
import Base: show

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
