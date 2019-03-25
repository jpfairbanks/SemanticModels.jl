# -*- coding: utf-8 -*-
# + {}
""" SemanticModels

provides the AbstractModel type and constructors for building hierarchical model representations.

"""
module SemanticModels

using Unitful
using Unitful: Units

export Parsers, Extraction, Graphs

abstract type AbstractModel end

abstract type Model end
abstract type EpiModel <: Model end
#abstract type Unit end
abstract type NumberClass end
abstract type Amount <: NumberClass end
abstract type Rate <: NumberClass end
abstract type BirthRate <: Rate end
abstract type DeathRate <: Rate end
abstract type TransitionRate <: Rate end
abstract type Equation end
abstract type Expression end
abstract type Variable end

struct NumParameter{U, C}
    name::Symbol
    unit::U
    class::C
end

struct NumVariable{U, C}
    name::Symbol
    unit::U
    class::C
end

struct ODE{P,V} <: Equation
    f::Expr
    parameters::Vector{P}
    variables::Vector{V}
end

struct SIR{E, Vp, Vt} <: EpiModel
    equations::Vector{E}
    population::Vp
    domain::Vt
end

@unit person "person" Person 1 true
Unitful.register(SemanticModels)
const localunits = Unitful.basefactors
function __init__()
    merge!(Unitful.basefactors, localunits)
    Unitful.register(SemanticModels)
end

"""    BasicSIR

defines a representation of Susceptible Infected Recovered models using Unitful
numbers and expressions.

"""
function BasicSIR()
    β = NumParameter(:β, u"person/s", TransitionRate)
    γ = NumParameter(:γ, u"person/s", TransitionRate)
    @show β, γ

    S = NumVariable(:S, u"person", Amount)
    I = NumVariable(:I, u"person", Amount)
    R = NumVariable(:R, u"person", Amount)
    sir = SIR([ODE(:(dS/dt -> -βSI/N),
                [β], [S]),
                ODE(:(dI/dt -> βSI/N -γI),
                    [β, γ], [S, I]),
            ODE(:(dR/dt -> γI), [γ], [I])],
            NumVariable.([:N,:S,:I,:R], u"person", Amount),
            NumVariable(:t, u"s", Amount))
    return sir
end

include("cassette.jl")

"""    CombinedModel

represents a model that has a fixed set of dependencies.
It is the basic building block of a model DAG.

"""
mutable struct CombinedModel{F,S} <: Model
    deps::F
    target::S
end

"""    solve(m::AbstractModel)

executes the solving of a model for models with dependencies, those deps are
executed first and then the node is solved. This is the function that evaluates
the model DAG.

"""
function solve(m::CombinedModel)
    return solve(m.target(m, solve.(m.deps)))
end

include("parse.jl")
include("modeltools/ModelTools.jl")

end
# -
