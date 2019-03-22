# using Base.Tests
using Test
using SemanticModels
using SemanticModels.Unitful
import SemanticModels.Unitful: DimensionError, uconvert, NoUnits, s
using DifferentialEquations
using Distributions: Uniform
using GLM
using DataFrames
using Plots

include("parse.jl")
include("cassette.jl")
include("transform/ode.jl")

examples = ["agentbased.jl",
            "agentgraft.jl",
            "modelmacro.jl",
            "monomial_regression.jl",
            "multivariate_regression.jl",
            "polynomial_regression.jl",
            "workflow.jl",
            "pseudo_polynomial_regression.jl",
            "odegraft.jl",
            ]
for ex in examples
    @info "Running example: " file=ex
    try
      include(ex)
    catch err
      println(err)
      @warn "Error running: " file=ex
    end
end
