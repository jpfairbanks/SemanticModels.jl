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

tests = ["parse.jl",
         "cassette.jl",
         "transform/ode.jl",
         "modeltools/functors.jl"]

for test in tests
  @testset "Running $test" begin
    include(test)
  end
end

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
@testset "Test all examples" begin
  for ex in examples
      @info "Running example: " file=ex
      try
        include(ex)
        @test true == true
      catch err
        println(err)
        @info "Error running " file=ex
        @test true == false
      end
  end
end
