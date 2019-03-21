# -*- coding: utf-8 -*-
# + {}
module SimpleProblems
using SemanticModels.ModelTools

export SimpleProblem, model

mutable struct SimpleProblem <: AbstractProblem
    expr::Expr
    imports::Any
    blocks::Vector{Expr}
    functions::Vector{Expr}
end

function model(::Type{SimpleProblem}, expr::Expr)
    body = expr.args[2].args[3]
    statements = body.args
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
    return SimpleProblem(expr, imports, blocks, funcs)
end

end