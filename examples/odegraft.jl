# -*- coding: utf-8 -*-
# ## Grafting models together
# Much of scientific thought and scholarship involves reading papers and textbooks with different models and synthesizing a novel model from components found in existing, well studied models.
#
# We refer to this as model grafting, where a component is taking from one model and grafted onto another model. SemanticModels supports automating much of the low level code details from this task to free scientists to think about what features to combine instead of the mechanical aspects of changing the code by hand.
#
# This notebook is an example based on the SEIR model and the ScalingModel examples in the epirecipes cookbook.

using Pkg
try
    using DifferentialEquations
catch
    Pkg.add("DifferentialEquations")
end
using DifferentialEquations
using SemanticModels.Parsers
using SemanticModels.ModelTools
using SemanticModels.ModelTools.ExpODEModels

# ## Loading the original model
# We use parsefile to load the model into an expression. The original model is an SEIR model which has 4 states suceptible, exposed, infected, and recovered. It has parameters $\beta, \gamma, \mu, \sigma$. 

expr1 = parsefile("../examples/epicookbook/src/SEIRmodel.jl")
model1 = model(ExpODEModel, expr1)

module1 = eval(model1.expr)

# ## Running our baseline model
#
# The code that defines the baseline model creates a module for that model to run in. This ensures that the code will not have unintended sideeffects when run in a julia process with other models. The entrypoint to this module is called `main`, which is a function that has no arguments and does the setup and execution of the model.

module1.main()

# seir_ode is the name of the function we want to modify
# an ODEProblem is defined by the right hand side of the equation.
# $du/dt = f(u, t)$

# The ScalingModel provides a population growth component that we want to graft onto the SEIR model to create an SEIR model with population dynamics. We load that model from its source file. You can inspect this file to see the definition of $dS/dt = r * (1 - S / K) * S - \beta * S * I$ which includes a population growth rate parameter $r$.

expr2 = parsefile("../examples/epicookbook/src/ScalingModel.jl")

# Once the ASTs are processed into a structured representation we can manipulate with regular julia code, we are able to write manipulations of the models that operate on a higher level than textual changes to the code.

model2 = model(ExpODEModel, expr2)
fluxes(x::ExpODEModel) = x.variables[1].flux

# Find the expression we want to graft
# vital dynamics S rate expression

fluxvar = fluxes(model2)[1].args[2].args[1]
popgrowth = replacevar(findassign(model2.funcs[1], fluxvar)[1], :K, :N).args[2].args[2]
ex = model1.variables[1].flux[1]
ex.args[2] = :($(popgrowth)+$(ex.args[2]))


# define N as the sum of the entries of Y ie. S+E+I

@assert argslist(:(function foo(x, y); return x+y; end)) == [:foo, :x, :y]

pushfirst!(bodyblock(model1.funcs[1]), :(N = sum(Y)))

# we need to add a new paramter to the function we are going to define
# this signature doesn't match the old signature so we are going to
# do some surgery on the main function to add that parameter
# this parameter instead could be added to the vector of parameters.

pusharg!(model1.funcs[1], :r)
# gensym gives us a unique name for the new function
g = gensym(argslist(model1.funcs[1])[1])
argslist(model1.funcs[1])[1] = g

# ## Model Augmentations often require new parameters
#
# When we add the population growth term to the SEIR model, we introduce a new parameter $r$
# that needs to be supplied to the model. One problem with approaches that require scientists
# to modify source code is the fact that adding the new features necessitates changes to the 
# APIs provided by the original author. SemanticModels.ModelTools provides a higher level API
# for making these changes that assist in propagating the necessary changes to the API.
#
# For example, in this code we need to add an argument to the entrypoint function `main` and 
# provide an anonymous function that conforms to the API that `DifferentialEquations` expects
# from its inputs.

mainx = findfunc(model1.expr, :main)[end]
pusharg!(mainx, :λ)

# An `ODEProblem` expects the user to provide a function $f(du, u, p, t)$ which takes the current fluxes, current system state, parameters, and current time as its arguments and updates the value of `du`. Since our new function `g` does not satisfy this interface, we need to introduce a wrapper function that does. 
#
# Here is an instance where having a smart compiler helps julia. In many dynamic languages where this kind of metaprogramming would be easy, the runtime is not smart enough to inline these anonymous functions, which means that there is additional runtime performance overhead to metaporgramming like this. Julia's compiler (and LLVM) can inline these functions which drastically reduces that overhead.

setarg!(model1.calls[end], :seir_ode, :((du,u,p,t)->$g(du,u,p,t,λ)))
@show model1.expr
NewModule = eval(model1.expr)

# ## Modeling configuration
#
# The following code sets up our modeling configuration with initial conditions and parameters. It represents the entry point to solving the model.

findfunc(model1.expr, :main)[end]


# ## Solving the new model
#
# Once we have changed the function `seir_ode` and adapted the API of `main` to suit we can do a parameter sweep over our new parameter by solving the problem with different values of $\lambda$.

newsol = NewModule.main(1)


# ## Parameter Estimation
# Adding a capability to a model usually introduces additional parameters that must be chosen. Analyzing a model requires developing a procedure for estimating those parameters or characterizing the effect of that parameter on the behavior of the modeled system.

# Here we  sweep over population growth rates to show what happens when the population growth rate changes.

scalegrowth(λ=1.0) = NewModule.main(λ)


println("S\tI\tR")
for λ in [1.0,1.1,1.2,1.3,1.4,1.5]
    S,I,R = scalegrowth(λ)(365)
    println("$S\t$I\t$R")
end

# ## It Works!
#
# This simulation allows an epidemiologist to examine the effects of population growth on an SEIR disease outbreak. A brief analysis of this simulation shows that as you increase the population growth rate, you increase the final population of infected people. More sophisticated analysis could be employed to show something more interesting about this model.
#
# We have shown how you can use SemanticModels.jl to combine features of various ODE systems and solve them with a state of the art solver to increase the capabilities of a code that implements a scientific model. We call this combination process grafting and believe that it supports a frequent use case of scientific programming.


