# -*- coding: utf-8 -*-
# + {}
module SimpleModels
using SemanticModels.ModelTools
import SemanticModels.ModelTools: model

export SimpleModel, model

mutable struct SimpleModel <: AbstractModel
    expr::Expr
    imports::Any
    blocks::Vector{Expr}
    functions::Vector{Expr}
end

function model(::Type{SimpleModel}, expr::Expr)
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
    return SimpleModel(expr, imports, blocks, funcs)
end

end
