using Test
using SemanticModels

tests = [
         "epidemics.jl",
         "petricospans.jl",
         ]

for test in tests
  @testset "Running $test" begin
    include(test)
  end
end
