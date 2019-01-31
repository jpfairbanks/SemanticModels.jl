using SemanticModels
using Test
using Base.Meta

@testset "Parsers" begin 
@show expr = Parsers.parsefile("examples/epicookbook/notebooks/SimpleDeterministicModels/SIRModel.jl")

modulename = expr.args[2]
mc = Parsers.defs(expr.args[3].args)

@show expr = Parsers.parsefile("examples/epicookbook/notebooks/SimpleDeterministicModels/SEIRModel.jl")

sericmodulename = expr.args[2]
seirc = Parsers.defs(expr.args[3].args)
@test seirc.modc[1][1] == :DifferentialEquations
@test seirc.fc.defs[1][1].head==:call
@show seirc.fc.defs[1][1].args[1] == :seir_ode
@show seirc.fc.defs[1][1].args == [:seir_ode, :dY, :Y, :p, :t]
@test map(first, seirc.vc) == [ :pram, :init, :tspan, :seir_prob, :sol, :va, :y, :R]
end
