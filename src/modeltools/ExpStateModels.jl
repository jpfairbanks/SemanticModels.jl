# -*- coding: utf-8 -*-
# + {}
module ExpStateModels
import Base: show, getindex, setindex!, put!, replace!

using SemanticModels.Parsers
using SemanticModels.ModelTools
import SemanticModels.ModelTools: model

export ExpStateModel, ExpStateTransition, model

"""    ExpStateModel

represents an agent based model symbolically, with a collection of stats, agents, and transitions.
The agents are a collection of states and the transitions map from state to state. This structure allows you to represent an agent based model at the semantic level and apply transformations to that model.

The common transformations for an agent based model are adding, removing, or replacing, states, agents, or transitions. See [`model`](@ref), [`put!`](@ref), [`setindex`](@ref), [`getindex`](@ref), [`put!`](@ref), [`replace!`](@ref).
"""
struct ExpStateModel <: AbstractModel
    expr::Expr
    states
    agents
    transitions
end

"""    ExpStateTransiton

represents a state-transition function for an agent based model. `ExpStateTransition(s,x)` represents the transition from state `s` to any other states. The expression `x` should define a function that takes any number of arguments and returns a value representing the new state.
"""
struct ExpStateTransition
  state::Symbol
  expr::Expr
end

function model(::Type{ExpStateModel}, expr::Expr)
    constructor = callsites(expr, :StateModel)[1]
    states = constructor.args[2]
    #TODO: find out why this identifies extra assignments possibly from the (i,a) = enumerate(sm.agents) part.
    agents = findassign(expr, constructor.args[3])
    transitions = findassign(expr, constructor.args[4])
    return ExpStateModel(expr, states, agents, transitions)
end

function show(io::IO, m::ExpStateModel)
    write(io, "ExpStateModel(\n  states=$(repr(m.states)),\n  agents=$(repr(m.agents)),\n  transitions=$(repr(m.transitions))\n)")
end

""" put!(m::ExpStateModel, transition::ExpStateTransition)

Store an [`ExpStateTransition`](@ref) `transition` into an [`ExpStateModel`](@ref) `m`. A `put!` on an already set state throws an `Exception`.

Returns the transition function inserted into `m`.
"""
function put!(m::ExpStateModel, transition::ExpStateTransition)
  q = QuoteNode(transition.state)
  any(x->x.value==transition.state, m.states.args) && error("Symbol $(transition.state) already exists")
  any(x->typeof(x) == Expr && x.args[2] == q, m.transitions[1].args[2].args) && error("Symbol $sym has a transition, but is not in the states")
  push!(m.states.args, QuoteNode(transition.state))
  push!(m.transitions[1].args[2].args, :($q=>$(transition.expr)))
  return transition.expr
end

""" replace!(m::ExpStateModel, transition::ExpStateTransition)

Store an [`ExpStateTransition`](@ref) `transition` into an [`ExpStateModel`(@ref) `m`. A `replace!` on an already set state will replace the current transition function.

Returns the transition function inserted into `m`.
"""
function replace!(m::ExpStateModel, transition::ExpStateTransition)
  !any(x->x.value==transition.state, m.states.args) && error("Symbol $sym doesn't exist")
  found=filter(x->typeof(x) == Expr && x.args[2] == QuoteNode(transition.state), m.transitions[1].args[2].args)
  found[1].args[3] = transition.expr
  return transition.expr
end

""" setindex!(m::ExpStateModel, expr::Expr, sym::Symbol)

Store an [`Expr`](@ref) `expr` as the transition function for state `sym` in [`ExpStateModel`](@ref) `m`. A `setindex!` on an already set state will replace the current transition function.

Returns the transition function inserted into `m`.
"""
function setindex!(m::ExpStateModel, expr::Expr, sym::Symbol)
  any(x->x.value==sym, m.states.args) && return replace!(m, ExpStateTransition(sym, expr))
  return put!(m, ExpStateTransition(sym, expr))
end


""" getindex(m::ExpStateModel, sym::Symbol)
Returns the transition function for state `sym` in [`ExpStateModel`](@ref) `m`. A `getindex` on a state that doesn't exist in `m` throws an `Exception`.
"""
function getindex(m::ExpStateModel, sym::Symbol)
  found=filter(x->typeof(x) == Expr && x.args[2] == QuoteNode(sym), m.transitions[1].args[2].args)
  length(found) == 0 && error("Symbol $sym doesn't exist")
  return found[1].args[3]
end

end
