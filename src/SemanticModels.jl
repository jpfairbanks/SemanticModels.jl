""" SemanticModels

provides the AbstractModel type and constructors for building
metamodeling tooling for categorical model representations

"""
module SemanticModels

export model, AbstractModel

"""    AbstractModel

a placeholder struct to dispatch on how to parse the expression tree into a model.
"""
abstract type AbstractModel end

""" model(::AbstractModel, x)
dig into the expression that describes a model and break it down into components. This allows you to construct a structured representation of the modeling problem at the expression level. Just like how julia modeling frameworks build structured representations of the problems in data structures. This version builds them at the expression level.
The first argument is the type you want to construct, the second argument is the model structure that you want to analyze. For example
```
model(PetriModel, x::Petri.Model)::PetriModel
```
"""
function model(::Type{T}, x) where T<:AbstractModel
  error("NotImplemented: model(::$T, $(typeof(x)))")
end

include("CategoryTheory.jl")
include("PetriModels.jl")
include("RelOlogModels.jl")
include("GraphModels.jl")
include("OpenModels.jl")
include("OpenPetris.jl")
include("PetriCospans.jl")
include("WiringDiagrams.jl")

include("exprmodels/ExprModels.jl")

end
