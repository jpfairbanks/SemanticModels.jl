# -*- coding: utf-8 -*-
using Cassette
using DifferentialEquations
using SemanticModels.Parsers
using SemanticModels.Dubstep
using SemanticModels.ModelTools

# source of original problem
include("../examples/epicookbook/src/SEIRmodel.jl")
model1 = parsefile("../examples/epicookbook/src/SEIRmodel.jl")

#the functions we want to modify
seir_ode = SEIRmodel.seir_ode

# source of the problem we want to take from
expr = parsefile("../examples/epicookbook/src/ScalingModel.jl")
model2 = expr

# process the ASTs into a structured representation we can manipulate with regular julia code
model_1 = model(ExpODEProblem, model1)
model_2 = model(ExpODEProblem, model2)
fluxes(x::ExpODEProblem) = x.variables[1].flux

# Find the expression we want to graft
#vital dynamics S rate expression
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

# generate the function f′ (Note: f\prime<TAB>)
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


# set up our modeling configuration
function g()
    #Pram (Infected Rate, Incubation Rate, Recover Rate, Death Rate)
    pram=[520/365,1/60,1/30,774835/(65640000*365)]
    #Initialize Param(Susceptible Individuals, Exposed Individuals, Infected Individuals)
    init=[0.8,0.1,0.1]
    tspan=(0.0,365.0)

    seir_prob = ODEProblem(seir_ode,init,tspan,pram)

    sol=solve(seir_prob);
end

# sweep over population growth rates
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
#it works!
