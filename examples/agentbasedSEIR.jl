# -*- coding: utf-8 -*-
# ---
# jupyter:
#   jupytext:
#     text_representation:
#       extension: .jl
#       format_name: light
#       format_version: '1.3'
#       jupytext_version: 0.8.6
#   kernelspec:
#     display_name: Julia 1.0.3
#     language: julia
#     name: julia-1.0
# ---

# ## Agent Based Modeling
# This script is a self contained agent based model, we define a modeling microframework and then use it to implement an agent based model. This agent based model represents the SEIR model of infectious disease with discrete time. This model is not intended as a realistic model of disease, but as an example of how to reverse engineer a model structure from code that implements it. See the agentgraft.jl script for an example of model augmentation on this class of models.
#
# Agent based models are useful for representing computations that cannot be done in closed form and need to be simulated. These simulations arise when analyzing complex systems, such as road networks, social behavior, or very small scale physical systems. The basic principles of ABM are to have agents that can be in states, and transitions between those states, the model then advances the simulation forward in time to get from an initial condition to a final condition. This framework is based on synchronous ABM where there is a global clock and all agents update their state once per clock tick.

module AgentModels

import Base: count

# """    AgentModel

# the root type for agent based models.

# See also: StateModel
# """

abstract type AgentModel end

# """     StateModel

# holds the components of an agent based simulation using finite state machines.

# - states: a collection of distinct states an agent can occupy
# - agents: a collection of states `aᵢ = agents[i] ∈ states` indicating that agent `i` is in state `aᵢ`
# - transitions: the functions `f: states -> states`
# """

mutable struct StateModel <: AgentModel
    states
    agents
    transitions
    loads
end

# +
# Determine number of agents in a given state
function count(sm::StateModel, state)
    return length(filter(a->(a==state), sm.agents))
end

# counts the number of agents
function count(sm::StateModel)
    return length(sm.agents)
end
# -

# stateload computes the fraction of agents in each state
# it is used by tick! to update the statemodel for computing the probability of infection.
function stateload(sm::StateModel, state::Symbol)
    return (count(sm, state)+1)/(count(sm)+1)
end

#     tick!(sm::StateModel)
#
# performs the operations that need to happen once per time step. Things like caching values that need to be computed at the beginning of the timestep like the distribution of the agents' states.

function tick!(sm::StateModel)
    sm.loads = map(s->stateload(sm, s), sm.states)
    return sm.loads
end

#     step!(sm::StateModel, n)
#
# advance the simulation by `n` ticks of time.
# This is an in-place operation that modifies the current state of the simulation.
#

function step!(sm::StateModel, n)
    for s in 1:n
      tick!(sm)
      for (i, a) in enumerate(sm.agents)
          sm.agents[i] = sm.transitions(sm, i, a)
      end
        describe(sm)
    end
    return sm
end

# """    describe(sm::StateModel)

# summarize the state of the simulation for presentation or analysis.
# """

function describe(sm::StateModel)
    counts = zeros(Int, size(sm.states))
    d = Dict{eltype(sm.states), Int}()
    for (i,s) in enumerate(sm.states)
        d[s] = i
    end
    for a in sm.agents
        i = d[a]
        counts[i] += 1
    end
    return collect(map(x->Pair(x...), zip(sm.states, counts)))
end

# ## Run the model
#
# This script defines a basic agent based model of disease spread called SEIRS. Each agent is in one of 4 states
#
# 1. $S$ Susceptible
# 2. $E$ Exposed
# 3. $I$ Infected
# 4. $R$ Recovered
#
# The agents go from `S->E`, `E->I`, `I-R`, and `R->S` based on random numbers. The probability of S-> is dependent on the fraction of agents in state :E. The probability of recovering is a constant ρ, the probability of exposure is denoted by variable β, and the disease confers some temporary immunity with probability μ.
#
# This script has an entrypoint to call it so that you can include this file and run as many simulations as you want. The intended use case is to repeatedly call `main` and accumulate the return values into an array for later analysis.

ρ = 0.5 + randn(Float64)/4 # chance of recovery
μ = 0.5 # chance of immunity
β = 0.5 # chance of exposure
function transition(sm::StateModel, i::Int, s::Symbol)
    r = rand(Float64)
    if s == :S
        if r < stateload(sm, :E)
            return :E
        else
            return :S
        end
    elseif s == :E
        if β < ρ
            return :E
        else
            return :I
        end
    elseif s == :I
        if r < ρ
            return :I
        else
            return :R
        end
    elseif s == :R
        if r < μ
            return :R
        else
            return :S
        end
    end
    return s
end



function main(nsteps)
    n = 20
    a = fill(:S, n)
    T = transition


    sam = StateModel([:S, :E, :I, :R], a, T, zeros(Float64,3))
    newsam = step!(deepcopy(sam), nsteps)
    @show newsam.agents
    counts = describe(newsam)
    return newsam, counts
end

# +
# # An example of how to run this thing.
#main(50)
# -

end


