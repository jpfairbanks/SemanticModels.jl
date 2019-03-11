# -*- coding: utf-8 -*-
using SemanticModels.Parsers
include("./modeltools.jl")
expr = parsefile("../examples/agentbased.jl")
m = ModelTools.model(ModelTools.ExpStateModel, expr)

samples = 3
nsteps = 5
finalcounts = Any[]

println("Running Agent Based Simulation Augmentation Demo")
println("================================================")
println("demo parameters:\n\tsamples=$samples\n\tnsteps=$nsteps")


expr = parsefile("../examples/agentbased.jl")
m = ModelTools.model(ModelTools.ExpStateModel, expr)
println("\nRunning basic model")
AgentModels = eval(m.expr)
for i in 1:samples
    newsam, counts = AgentModels.main(nsteps)
    push!(finalcounts, (model=:basic, counts=counts))
end


m

# +
println("\nThe system states are $(m.states.args)")
println("\nAdding un estado de los muertos")

ModelTools.put!(m, :(:D => (x...)->:D))

println("\nThe system states are $(m.states.args)")
# once you are dead, you are dead forever
println("\nThere is no resurrection in this model")
println("\nInfected individuals recover or die in one step")

ModelTools.replace!(m, :(:I => (x...)->rand(Bool) ? :D : :I))

m[:I] = :((x...)->rand(Bool) ? :I : :D)
@show m
# -

# TODO: make a better api for replacing expressions with other expressions
# rrule′ = replacevar(m.transitions[1].args[2].args[4], :(:S), :(:D))
# TODO: make replacevar handle quotenodes
# rrule′ = replacevar(m.transitions[1].args[2].args[4], :S, :D)
# m.transitions[1].args[2].args[4] = rrule′

println("\nRunning SIRD model")
AgentModels = eval(m.expr)
for i in 1:samples
    newsam, counts = AgentModels.main(nsteps)
    push!(finalcounts, (model=:sird, counts=counts))
end

println("\nAdding population growth to this model")
stepr = findfunc(m.expr, :step!)[1]

stepr.args[2].args[2].args[2].args

@show stepr
println("------------------------")
push!(stepr.args[2].args[2].args[2].args, :(push!(sm.agents, :S)))
@show stepr
# splice!(stepr.args[2].args[2].args, 2:1, [:(push!(sm.agents, :S))])
println("\nRunning growth model")
AgentModels = eval(m.expr)
for i in 1:samples
    newsam, counts = AgentModels.main(nsteps)
    push!(finalcounts, (model=:growth, counts=counts))
end

println("\nModel\t Counts")
println("-----\t ------")
for result in finalcounts
    println("$(result.model)\t$(result.counts)")
end
