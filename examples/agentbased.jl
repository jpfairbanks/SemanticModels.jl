module AgentModels

abstract type AgentModel end

struct StateModel <: AgentModel
    states
    agents
    transitions
end

function step!(sm::StateModel, n=1)
    for s in 1:n
      for (i, a) in enumerate(sm.agents)
          sm.agents[i] = sm.transitions[a](i,a)
      end
      println(describe(sm))
    end
    return sm
end

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
