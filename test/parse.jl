using SemanticModels
using Test
using Base.Meta

@show expr = Parsers.parsefile("examples/epicookbook/notebooks/SimpleDeterministicModels/SIRModel.jl")

modulename = expr.args[2]
mc = Parsers.defs(expr.args[3].args)

@show expr = Parsers.parsefile("examples/epicookbook/notebooks/SimpleDeterministicModels/SEIRModel.jl")

sericmodulename = expr.args[2]
seirc = Parsers.defs(expr.args[3].args)
