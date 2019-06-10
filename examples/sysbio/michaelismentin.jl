using DiffEqBiological
using DifferentialEquations
rs = @reaction_network begin
  c1, S + E --> SE
  c2, SE --> S + E
  c3, SE --> P + E
end c1 c2 c3
p = (0.00166,0.0001,0.1)
tspan = (0., 100.)
u0 = [301., 100., 0., 0.]  # S = 301, E = 100, SE = 0, P = 0

# solve ODEs
oprob = ODEProblem(rs, u0, tspan, p)
osol  = solve(oprob, Tsit5())

# solve JumpProblem
# u0 = [301, 100, 0, 0]
# dprob = DiscreteProblem(rs, u0, tspan, p)
# jprob = JumpProblem(dprob, Direct(), rs)
# jsol = solve(jprob, SSAStepper())
