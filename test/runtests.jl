# using Base.Tests
using Test
using SemanticModels
#using Distributions: Uniform
#using GLM
#using DataFrames
#using Plots

tests = [
         "modeltools/epidemics.jl",
         "modeltools/petricospans.jl",
         "parse.jl",
         ]
for test in tests
  @testset "Running $test" begin
    include(test)
  end
end

examples = [
            "agentbased.jl",
            "agentgraft.jl",
            "modelmacro.jl",
            "monomial_regression.jl",
            "multivariate_regression.jl",
            "odegraft.jl",
            "polynomial_regression.jl",
            "pseudo_polynomial_regression.jl",
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
