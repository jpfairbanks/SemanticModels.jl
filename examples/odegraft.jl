# -*- coding: utf-8 -*-
# ## Grafting models together
# Much of scientific thought and scholarship involves reading papers and textbooks with different models and synthesizing a novel model from components found in existing, well studied models.
#
# We refer to this as model grafting, where a component is taking from one model and grafted onto another model. SemanticModels supports automating much of the low level code details from this task to free scientists to think about what features to combine instead of the mechanical aspects of changing the code by hand.
#
# This notebook is an example based on the SEIR model and the ScalingModel examples in the epirecipes cookbook.

using DifferentialEquations
using SemanticModels.Parsers
# using SemanticModels.Dubstep
using SemanticModels.ModelTools

# ## Loading the original model
# we use parsefile to load the model into an expression

# include("../examples/epicookbook/src/SEIRmodel.jl")
expr1 = parsefile("../examples/epicookbook/src/SEIRmodel.jl")
model1 = model(ExpODEProblem, expr1)

module1 = eval(model_1.expr)

# ## Running our baseline model

module1.main()

# seir_ode is the name of the function we want to modify
# an ODEProblem is defined by the right hand side of the equation.
# $du/dt = f(u, t)$

# The ScalingModel provides a population growth component that we want to graft onto the SEIR model to create an SEIR model with population dynamics. We load that model from its source file

expr2 = parsefile("../examples/epicookbook/src/ScalingModel.jl")

# process the ASTs into a structured representation we can manipulate with regular julia code

model2 = model(ExpODEProblem, expr2)
fluxes(x::ExpODEProblem) = x.variables[1].flux

# Find the expression we want to graft
# vital dynamics S rate expression

fluxvar = fluxes(model2)[1].args[2].args[1]
popgrowth = replacevar(findassign(model2.funcs[1], fluxvar)[1], :K, :N).args[2].args[2]
ex = model1.variables[1].flux[1]
ex.args[2] = :($(popgrowth)+$(ex.args[2]))


# define N as the sum of the entries of Y ie. S+E+I

pushfirst!(model1.funcs[1].args[2].args, :(N = sum(Y)))

# we need to add a new paramter to the function we are going to define
# this signature doesn't match the old signature so we are going to
# do some surgery on the main function to add that parameter
# this parameter instead could be added to the vector of parameters.

pusharg!(model1.funcs[1], :r)
g = gensym(model1.funcs[1].args[1].args[1])
model1.funcs[1].args[1].args[1] = g

mainx = findfunc(model1.expr, :main)[end]
pusharg!(mainx, :λ)

setarg!(model1.calls[end], :seir_ode, :((du,u,p,t)->$g(du,u,p,t,λ)))
@show model1.expr
NewModule = eval(model1.expr)

newsol = NewModule.main(1)


# # ## Modeling configuration
# # The following code sets up our modeling configuration with initial conditions and parameters. It represents the entry point to solving the model.

@show model1.calls[1]


# ## Parameter Estimation
# Adding a capability to a model usually introduces additional parameters that must be chosen. Analyzing a model requires developing a procedure for estimating those parameters or characterizing the effect of that parameter on the behavior of the modeled system.

# Here we  sweep over population growth rates to show what happens when the population growth rate changes.

scalegrowth(λ=1.0) = NewModule.main(λ)


println("S\tI\tR")
for λ in [1.0,1.1,1.2]
    S,I,R = scalegrowth(λ)(365)
    println("$S\t$I\t$R")
end

# ## It Works!
