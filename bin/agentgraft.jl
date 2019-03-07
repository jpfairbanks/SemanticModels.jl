using SemanticModels.Parsers
include("./modeltool.jl")

samples = 3
nsteps = 5
finalcounts = Any[]

println("Running Agent Based Simulation Augmentation Demo")
println("================================================")
println("demo parameters:\n\tsamples=$samples\n\tnsteps=$nsteps")


expr = parsefile("../examples/agentbased.jl")
m = ModelTool.model(ModelTool.ExpStateModel, expr)
println("\nRunning basic model")
AgentModels = eval(m.expr)
for i in 1:samples
    newsam, counts = AgentModels.main(nsteps)
    push!(finalcounts, (model=:basic, counts=counts))
end


println("\nThe system states are $(m.states.args)")
println("\nAdding un estado de los muertos")
@show push!(m.states.args, :(:D))
println("\nThe system states are $(m.states.args)")
# once you are dead, you are dead forever
println("\nThere is no resurrection in this model")
newrule = :(:D => (x...)->:D)
@show newrule

println("\nInfected individuals recover or die in one step")
# m.transitions[1].args[2].args[4].args[3].args[2].args[2].args[3] = :(:D)
m.transitions[1].args[2].args[3].args[3].args[2].args[2].args[2] = :(:D)

# TODO: make a better api for replacing expressions with other expressions
# rrule′ = replacevar(m.transitions[1].args[2].args[4], :(:S), :(:D))
# TODO: make replacevar handle quotenodes
# rrule′ = replacevar(m.transitions[1].args[2].args[4], :S, :D)
# m.transitions[1].args[2].args[4] = rrule′

push!(m.transitions[1].args[2].args, newrule)
@show m.transitions[1]

println("\nRunning SIRD model")
AgentModels = eval(m.expr)
for i in 1:samples
    newsam, counts = AgentModels.main(nsteps)
    push!(finalcounts, (model=:sird, counts=counts))
end



println("\nAdding population growth to this model")
stepr = findfunc(m.expr, :step!)[1]
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
