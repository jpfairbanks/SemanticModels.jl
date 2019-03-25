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

# # @typegraph example
# In this notebook, we will be going through a tutorial on how to use the `@typegraph` macro to extract the mapping of how type are transformed through functions.

using SemanticModels.ModelTools


include("../../src/modeltools/typegraph.jl");

# After loading `@typegraph` in to our workspace, we simply begin the extraction by calling the macro immediately followed by an `Expr` which will return an edge list which is easily passed through to `MetaGraphs.jl` to visualize the transformations that are taking place throughout the code.
#
# *_To learn more about `Expr` & metaprogramming, we recommend looking at the offcial [Julia docs](@https://docs.julialang.org/en/v1.0/manual/metaprogramming/) on the topic._

edgelist = @typegraph begin
    import Base: count

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

    #     step!(sm::StateModel, n=1)
    #
    # advance the simulation by `n` ticks of time.
    # This is an in-place operation that modifies the current state of the simulation.
    #

    function step!(sm::StateModel, n)
        for s in 1:n
          tick!(sm)
          for (i, a) in enumerate(sm.agents)
              sm.agents[i] = sm.transitions[a](sm, i,a)
          end
            describe(sm)
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
    end;



    # ## Run the model
    #
    # This script defines a basic agent based model of disease spread called SIRS. Each agent is in one of 3 states
    #
    # 1. $S$ Susceptible
    # 2. $I$ Infected
    # 3. $R$ Recovered
    #
    # <img src="https://docs.google.com/drawings/d/e/2PACX-1vSeA7mAQ-795lLVxCWXzbkFQaFOHMpwtB121psFV_2cSUyXPyKMtvDjssia82JvQRXS08p6FAMr1hj1/pub?w=1031&amp;h=309">
    #
    # The agents go from `S->I`, `I-R`, and `R->S` based on random numbers. The probability of S-> is dependent on the fraction of agents in state :I. The probability of recovering is a constant ρ, and the disease confers some temporary immunity with probability μ.
    #
    # This script has an entrypoint to call it so that you can include this file and run as many simulations as you want. The intended use case is to repeatedly call `main` and accumulate the return values into an array for later analysis.

    function main(nsteps)
        n = 20
        a = fill(:S, n)
        ρ = 0.5 + randn(Float64)/4 # chance of recovery
        μ = 0.5 # chance of immunity
        T = Dict(
            :S=>(x...)->rand(Float64) < stateload(x[1], :I) ? :I : :S,
            :I=>(x...)->rand(Float64) < ρ ? :I : :R,
            :R=>(x...)->rand(Float64) < μ ? :R : :S,
        )


        sam = StateModel([:S, :I, :R], a, T, zeros(Float64,3))
        newsam = step!(deepcopy(sam), nsteps)
        @show newsam.agents
        counts = describe(newsam)
        return newsam, counts
    end;

    # +
    # # An example of how to run this thing.
    main(10);
    # -

    end;

# In the above example, we have a simple agent based simulation where we defined new stucts to collect the singltonian type information for our simulation. To reduce the nosie from collecting the iterations throughout the runtime of our model we need to collect the unique calls through our our example which contain the relevant information.

E = unique((f.func, f.args, f.ret) for f in edgelist)

# ## visualizing the edges
#
# Now that we have extracted the relevant type information, we want to visualize these transformations in a knowledge graph.

using MetaGraphs;
using LightGraphs;

g = MetaDiGraph();
set_indexing_prop!(g,:label);

for e in E
    try
        g[e[2],:label]
    catch
        add_vertex!(g,:label,e[2]) # add ags
    end
    
    try
        g[e[3],:label]
    catch
        add_vertex!(g,:label,e[3]) # add rets
    end
    
    try
        add_edge!(g,g[e[2],:label],g[e[3],:label],:label,e[1]) # add func edges
    catch
        nothing
    end
end

savegraph("exampletypegraph.dot",g,DOTFormat());

run(`dot -Tsvg -O exampletypegraph.dot`);

s = read("exampletypegraph.dot.svg",String);
display("image/svg+xml",s)

# +
# TODO use a different script and repeat, extraction, drawing, and rendering

# +
# TODO discuss difference in type graphs
