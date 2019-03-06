using SemanticModels.Parsers
include("./modeltool.jl")

expr = parsefile("../examples/agentbased.jl")
m = ModelTool.model(ModelTool.ExpStateModel, expr)

println("The system states are $(m.states.args)")
println("Adding un estado de los muertos")
@show push!(m.states.args, :(:D))
println("The system states are $(m.states.args)")
# once you are dead, you are dead forever
println("There is no resurrection in this model")
@show newrule = :(:D => (x...)->:D)

println("Infected individuals recover or die in one step")
# m.transitions[1].args[2].args[4].args[3].args[2].args[2].args[3] = :(:D)
m.transitions[1].args[2].args[3].args[3].args[2].args[2].args[2] = :(:D)

# TODO: make a better api for replacing expressions with other expressions
# rrule′ = replacevar(m.transitions[1].args[2].args[4], :(:S), :(:D))
# TODO: make replacevar handle quotenodes
# rrule′ = replacevar(m.transitions[1].args[2].args[4], :S, :D)
# m.transitions[1].args[2].args[4] = rrule′

push!(m.transitions[1].args[2].args, newrule)
@show m.transitions[1]
AgentModels = eval(m.expr)


println("Adding population growth to this model")
@show stepr = findfunc(m.expr, :step!)[1]
push!(stepr.args[2].args[2].args[2].args, :(push!(sm.agents, :S)))
@show stepr
# splice!(stepr.args[2].args[2].args, 2:1, [:(push!(sm.agents, :S))])
AgentModels = eval(m.expr)
