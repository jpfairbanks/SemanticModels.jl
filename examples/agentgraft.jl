# -*- coding: utf-8 -*-
using SemanticModels.Parsers
using SemanticModels.ModelTools

samples = 7
nsteps = 10
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
# -

println("\nRunning SIRD model")
AgentModels = eval(m.expr)
for i in 1:samples
    newsam, counts = AgentModels.main(nsteps)
    push!(finalcounts, (model=:sird, counts=counts))
end

# +
println("\nAdding population growth to this model")
stepr = findfunc(m.expr, :step!)[1]

stepr.args[2].args[2].args[2].args

@show stepr
println("------------------------")
push!(stepr.args[2].args[2].args[2].args, :(push!(sm.agents, :S)))
@show stepr
# splice!(stepr.args[2].args[2].args, 2:1, [:(push!(sm.agents, :S))])
# -

println("\nRunning growth model")
AgentModels = eval(m.expr)
for i in 1:samples
    newsam, counts = AgentModels.main(nsteps)
    push!(finalcounts, (model=:growth, counts=counts))
end

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


