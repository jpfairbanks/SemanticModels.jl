# -*- coding: utf-8 -*-
module AgentModels

# ## Agent Based Modeling
# This script is a self contained agent based model, we define a modeling microframework and then use it to implement an agent based model. This agent based model represents the SIR model of infectious disease with discrete time. This model is not intended as a realistic model of disease, but as an example of how to reverse engineer a model structure from code that implements it. See the agentgraft.jl script for an example of model augmentation on this class of models.

"""    AgentModel

the root type for agent based models.

See also: StateModel
"""
abstract type AgentModel end

"""     StateModel

holds the components of an agent based simulation using finite state machines.

- states: a collection of distinct states an agent can occupy
- agents: a collection of states `aᵢ = agents[i] ∈ states` indicating that agent `i` is in state `aᵢ`
- transitions: the functions `f: states -> states`
"""
struct StateModel <: AgentModel
    states
    agents
    transitions
end

#     step!(sm::StateModel, n=1)
#
# advance the simulation by `n` ticks of time.
# This is an in-place operation that modifies the current state of the simulation.
#

function step!(sm::StateModel, n=1)
    for s in 1:n
      for (i, a) in enumerate(sm.agents)
          sm.agents[i] = sm.transitions[a](i,a)
      end
      println(describe(sm))
    end
    return sm
end

"""    describe(sm::StateModel)

summarize the state of the simulation for presentation or analysis.
"""
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
# This script has an entrypoint to call it so that you can include this file and run as many simulations as you want. The intended use case is to repeatedly call `main` and accumulate the return values into an array for later analysis. 

function main(nsteps)
    n = 10
    a = fill(:S, n)
    T = Dict(
        :S=>(x...)->rand(Bool) ? :I : :S,
        :I=>(x...)->rand(Bool) ? :I : :R,
        :R=>(x...)->rand(Bool) ? :R : :S,
    )


    sam = StateModel([:S, :I, :R], a, T)
    newsam = step!(deepcopy(sam), nsteps)
    @show newsam.agents
    counts = describe(newsam)
    return newsam, counts
end



end
