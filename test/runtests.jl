using Test
using SemanticModels

tests = [
         "modeltools/epidemics.jl",
         "modeltools/petricospans.jl",
         ]

for test in tests
  @testset "Running $test" begin
    include(test)
  end
end
