# -*- coding: utf-8 -*-
# ## Grafting models together
# Much of scientific thought and scholarship involves reading papers and textbooks with different models and synthesizing a novel model from components found in existing, well studied models.
#
# We refer to this as model grafting, where a component is taking from one model and grafted onto another model. SemanticModels supports automating much of the low level code details from this task to free scientists to think about what features to combine instead of the mechanical aspects of changing the code by hand.
#
# This notebook is an example based on the SEIR model and the ScalingModel examples in the epirecipes cookbook.

using Cassette
using DifferentialEquations
using SemanticModels.Parsers
using SemanticModels.Dubstep
using SemanticModels.ModelTools

# ## Loading the original model
# we use parsefile to load the model into an expression

include("../examples/epicookbook/src/SEIRmodel.jl")
model1 = parsefile("../examples/epicookbook/src/SEIRmodel.jl")

# seir_ode is the name of the function we want to modify
# an ODEProblem is defined by the right hand side of the equation.
# $du/dt = f(u, t)$

seir_ode = SEIRmodel.seir_ode

# The ScalingModel provides a population growth component that we want to graft onto the SEIR model to create an SEIR model with population dynamics. We load that model from its source file

expr = parsefile("../examples/epicookbook/src/ScalingModel.jl")
model2 = expr

# process the ASTs into a structured representation we can manipulate with regular julia code

model_1 = model(ExpODEProblem, model1)
model_2 = model(ExpODEProblem, model2)
fluxes(x::ExpODEProblem) = x.variables[1].flux

# Find the expression we want to graft
# vital dynamics S rate expression

fluxvar = fluxes(model_2)[1].args[2].args[1]
popgrowth = replacevar(findassign(model_2.funcs[1], fluxvar)[1], :K, :N).args[2].args[2]
ex = model_1.variables[1].flux[1]
ex.args[2] = :($(popgrowth)+$(ex.args[2]))
function pusharg!(ex::Expr, s::Symbol)
    ex.head == :function || error("ex is not a function definition")
    push!(ex.args[1].args, s)
    return ex
end

# define N as the sum of the entries of Y ie. S+E+I

pushfirst!(model_1.funcs[1].args[2].args, :(N = sum(Y)))

# we need to add a new paramter to the function we are going to define
# this signature doesn't match the old signature so we are going to
# use a Cassette context to supply that parameter at runtime.
# this parameter instead could be added to the vector of parameters.

pusharg!(model_1.funcs[1], :r)
model_1.funcs[1].args[1].args[1] = gensym(model_1.funcs[1].args[1].args[1])

# generate the function f′ (Note: f\primeTAB)
# this eval happens at the top level so should only happen once

@show(model_1.funcs[1])
f′ = eval(model_1.funcs[1])

# define the overdub behavior, all the fucntions needed to be defined at this point
# in order to avoid a world age problem in the julia runtime
# make sure to use only values that are statically known or passed in from
# ctx.metadata, using globals here will slow down overdub.

function Cassette.overdub(ctx::Dubstep.GraftCtx, f::typeof(seir_ode), args...)
    # this call matches the new signature
    return Cassette.fallback(ctx, f′, args..., ctx.metadata[:lambda])
end


# ## Modeling configuration
# The following code sets up our modeling configuration with initial conditions and parameters. It represents the entry point to solving the model.

function g()
    #Pram (Infected Rate, Incubation Rate, Recover Rate, Death Rate)
    pram=[520/365,1/60,1/30,774835/(65640000*365)]
    #Initialize Param(Susceptible Individuals, Exposed Individuals, Infected Individuals)
    init=[0.8,0.1,0.1]
    tspan=(0.0,365.0)

    seir_prob = ODEProblem(seir_ode,init,tspan,pram)

    sol=solve(seir_prob);
end

# ## Parameter Estimation
# Adding a capability to a model usually introduces additional parameters that must be chosen. Analyzing a model requires developing a procedure for estimating those parameters or characterizing the effect of that parameter on the behavior of the modeled system.

# Here we  sweep over population growth rates to show what happens when the population growth rate changes.

function scalegrowth(λ=1.0)
    # ctx.metadata holds our new parameter
    ctx = Dubstep.GraftCtx(metadata=Dict(:lambda=>λ))
    return Cassette.overdub(ctx, g)
end

println("S\tI\tR")
for λ in [1.0,1.1,1.2]
    @time S,I,R = scalegrowth(λ)(365)
    println("$S\t$I\t$R")
end

# ## It Works!
