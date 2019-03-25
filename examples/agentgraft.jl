# -*- coding: utf-8 -*-
# # Agent Based Model Augmentation
#
# SemanticModels supports model augmentation, which is the derivation of new models from old models with different (usually more advanced) capabilities. The approach is to define a type to represent a class of models and then a set of transformations that can act on that type to change the capabilities of the model.
#
# We can apply our model augmentation framework to models that are not defined as an analytical mathematical expression.
# A widely used class of models for complex systems are *agent based* in that they have an explicit representation of the agents with states and functions to represent their behavior and interactions. This notebook examines how to apply model transformations to augment agent based simulations.

# We are going to use the simulation in `examples/agentbased.jl` as a baseline simulation and add capabilities to the simulation with SemanticModels transformations. The simulation in question is an implementation of a basic SIRS model on a static population. We will make two augmentations.
#
# 1. Add *un estado de los muertos* or *a state for the dead*, transforming the model from SIRS to SIRD
# 2. Add *vital dynamics* a represented by net population growth
#
# These changes to the model could easily be made by changing the source code to add the features. However, this notebook shows how those changes could be scripted by a scientist. As we all know, once you can automate a scientific task by introducing a new technology, you free the mind of the scientist for more productive thoughts.
#
# In this case we are automating the implementation of model changes to free the scientist to think about *what augmentations to the model should I make?* instead of *how do I implement these augmentations?*

using SemanticModels

using SemanticModels.Parsers
using SemanticModels.ModelTools
using SemanticModels.ModelTools.ExpStateModels
import Base: push!

samples = 7
nsteps = 10
finalcounts = Any[]

println("Running Agent Based Simulation Augmentation Demo")
println("================================================")
println("demo parameters:\n\tsamples=$samples\n\tnsteps=$nsteps")


# ## Baseline SIRS model
#
# Here is the baseline model, which is read in from a text file. You could instead of using `parsefile` use a `quote/end` block to code up the baseline model in this script. 
#
# <img src="https://docs.google.com/drawings/d/e/2PACX-1vSeA7mAQ-795lLVxCWXzbkFQaFOHMpwtB121psFV_2cSUyXPyKMtvDjssia82JvQRXS08p6FAMr1hj1/pub?w=1031&amp;h=309">
#
# Agents progress from the susceptible state to infected and then recovered, and get become susceptible again after recovery. See the file `../examples/agentbased.jl` for a full description of this model

expr = parsefile("agentbased.jl")
m = model(ExpStateModel, expr)
#ModelTools.funclines(m.expr, :main)


println("\nRunning basic model")
AgentModels = eval(m.expr)
for i in 1:samples
    newsam, counts = AgentModels.main(nsteps)
    push!(finalcounts, (model=:basic, counts=counts))
end

m

# ## Adding the Dead State
#
# <img src="https://docs.google.com/drawings/d/e/2PACX-1vRUhrX6GzMzNRWr0GI3pDp9DvSqJVTDVpy9SNNBIB08b7Hyf9vaHobE2knrGPda4My9f_o9gncG34pF/pub?w=1028&amp;h=309">
#
# We are going to add an additional state to the model to represent the infectious disease fatalities. The user must specify what that concept means in terms of the name for the new state and the behavior of that state. `D` is a terminal state for a finite automata.

# +
println("\nThe system states are $(m.states.args)")
println("\nAdding un estado de los muertos")

put!(m, ExpStateTransition(:D, :((x...)->:D)))

println("\nThe system states are $(m.states.args)")
# once you are dead, you are dead forever
println("\nThere is no resurrection in this model")
println("\nInfected individuals recover or die in one step")

# add a transition rule for infected -> recovered, dead, or infected
m[:I] = :((x...)->begin
        roll = mod(rand(Int),3)
        if roll == 1
            return :R
        elseif roll == 2
            return :D
        else
            return :I
        end
    end
)
@show m[:I]
# -

println("\nRunning SIRD model")
AgentModels = eval(m.expr)
for i in 1:samples
    newsam, counts = AgentModels.main(nsteps)
    push!(finalcounts, (model=:sird, counts=counts))
end

# Some utilities for manipulating functions at a higher level than expressions.

# +

struct Func end

function push!(::Func, func::Expr, ex::Expr)
    push!(bodyblock(func), ex)
end
# -

# ## Population Growth
#
# Another change we can make to our model is the introduction of population growth. Our model for population is that on each timestep, one new suceptible person will be added to the list of agents. We use the `tick!` function as an anchor point for this transformation.
#
# <img src="https://docs.google.com/drawings/d/e/2PACX-1vRfLcbPPaQq6jmxheWApqidYte8FxK7p0Ebs2EyW2pY3ougNh5YiMjA0NbRMuGAIT5pD02WNEoOfdCd/pub?w=1005&amp;h=247">

println("\nAdding population growth to this model")
stepr = filter(x->isa(x,Expr), findfunc(m.expr, :tick!))[1]
@show stepr
push!(Func(), stepr, :(push!(sm.agents, :S)))
println("------------------------")
@show stepr;

println("\nRunning growth model")
AgentModels = eval(m.expr)
for i in 1:samples
    newsam, counts = AgentModels.main(nsteps)
    push!(finalcounts, (model=:growth, counts=counts))
end

# ## Presentation of results
#
# We have accumulated all of our simulation runs into the list `finalcounts` we process those simulation runs into summary tables describing the results of those simulations. This table can be used to make decisions and drive further inquiry.

# +
println("\nModel\t Counts")
println("-----\t ------")
for result in finalcounts
    println("$(result.model)\t$(result.counts)")
end

function groupagg(x::Vector{Tuple{S,T}}) where {S,T}
    c = Dict{S, Tuple{Int, T}}()
    # c2 = Dict{S, T}()
    for r in x
        g = first(r)
        c[g] = get(c, g,(0, 0.0)) .+ (1, last(r))
    end
    return c
end

mean_healthy_frac = [(r.model,
                  map(last, filter(x->(x.first == :R || x.first == :S), r.counts))[1] / sum(map(last, r.counts))[1])
                 for r in finalcounts] |> groupagg

num_unhealthy = [(r.model,
                  map(last,
                      sum(map(last, filter(x->(x.first != :R && x.first != :S),
                             r.counts)))))
                 for r in finalcounts] |> groupagg

println("\nModel\t Count \t Num Unhealthy \t Mean Healthy %")
println("-----\t ------\t --------------\t  --------------")
for (g, v) in mean_healthy_frac
    μ = last(v)/first(v)
    μ′ = round(μ*100, sigdigits=5)
    x = round(last(num_unhealthy[g]) / first(num_unhealthy[g]), sigdigits=5)
    println("$g\t   $(first(v))\t  $(rpad(x, 6))\t   $(μ′)")
end
# -


