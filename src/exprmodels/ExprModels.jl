""" ExprModels

provides functionality of extracting and manipulating models from julia source code

"""
module ExprModels

using SemanticModels
import SemanticModels: model

export isexpr, model

""" isexpr(x)
predicate for isa(x, Expr).
"""
isexpr(x) = isa(x, Expr)

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


include("parse.jl")
include("Transformations.jl")
include("SimpleModels.jl")
include("ExpODEModels.jl")
include("ExpStateModels.jl")
include("MonomialRegressionModels.jl")

end
