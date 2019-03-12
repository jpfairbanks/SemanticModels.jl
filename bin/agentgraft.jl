# -*- coding: utf-8 -*-
using SemanticModels.Parsers
using SemanticModels.ModelTools

samples = 3
nsteps = 5
finalcounts = Any[]

println("Running Agent Based Simulation Augmentation Demo")
println("================================================")
println("demo parameters:\n\tsamples=$samples\n\tnsteps=$nsteps")


expr = parsefile("../examples/agentbased.jl")
m = model(ExpStateModel, expr)
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

put!(m, ExpStateTransition(:D, :((x...)->:D)))

println("\nThe system states are $(m.states.args)")
# once you are dead, you are dead forever
println("\nThere is no resurrection in this model")
println("\nInfected individuals recover or die in one step")

# replace!(m, ExpStateTransition(:I, :((x...)->rand(Bool) ? :D : :I)))
m[:I] = :((x...)->rand(Bool) ? :R : :D)
@show m[:I]

# +
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
