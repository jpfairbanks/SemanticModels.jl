# Dubstep 

This module uses [Cassette.jl](https://www.github.com/jrevels/Cassette.jl) ([Zenodo](https://zenodo.org/record/1806173)) to modify programs by overdubbing their executions in a context. 
Overdubbing allows you to define a context that defines allows a program to control the execution behavior of programs
that are passed to it. Cassette is a novel approach to software development and integrates deeply with the Julia
compiler to provide high performance aspect oriented programming.

## TraceCtx

Builds hierarchical runtime value traces by running the program you pass it. You can change the metadata.
You can change out the metadata that you pass in order to collect different information. The default is Any[].

## LPCtx

Replaces all calls to `norm(x,p)` with `norm(x,ctx.metadata[p])` so you can change the norms that a code uses to
compute. 

### Example
Here is an example of changing an internal component of a mathematical operation using cassette to rewrite the norm function:

First we define a function that uses ```norm```, and
another function that calls it: 
```julia

subg(x,y) = norm([x x x]/6 - [y y y]/2, 2)

function g()
    a = 5+7
    b = 3+4
    c = subg(a,b)
    return c
end
```

We use the ```Dubstep.LPCtx```, which is shown here:

```julia
Cassette.@context LPCtx

function Cassette.overdub(ctx::LPCtx, args...)
    if Cassette.canrecurse(ctx, args...)
        newctx = Cassette.similarcontext(ctx, metadata = ctx.metadata)
        return Cassette.recurse(newctx, args...)
    else
        return Cassette.fallback(ctx, args...)
    end
end

using LinearAlgebra
function Cassette.overdub(ctx::LPCtx, f::typeof(norm), arg, power)
    return f(arg, ctx.metadata[power])
end
```

Note the method definition of `Cassette.overdub`
for LPCtx when called with the function
`LinearAlgebra.norm`.

We then construct an instance of the context that
configures how we want to do the substitution:
```julia
@testset "LP" begin 
@test 2.5980 < g() < 2.599
ctx = Dubstep.LPCtx(metadata=Dict(1=>2, 2=>1, Inf=>1))
@test Cassette.recurse(ctx, g) == 4.5
```

And just like that, we can control the execution
of a program without rewriting it at the lexical level.


## Transformations

You can also transform a model by executing it in a
context that changes the function calls.
Eventually we will support writing compiler passes
for modifying models at the expression level, but
for now, function calls are a good entry point.

### Example: Perturbations

This example comes from the unit tests `test/transform/ode.jl`.

The first step is to define a context for solving
models:

```julia
module ODEXform
using DifferentialEquations
using Cassette
using SemanticModels.Dubstep

Cassette.@context SolverCtx
function Cassette.overdub(ctx::SolverCtx, args...)
    if Cassette.canrecurse(ctx, args...)
        #newctx = Cassette.similarcontext(ctx, metadata = ctx.metadata)
        return Cassette.recurse(ctx, args...)
    else
        return Cassette.fallback(ctx, args...)
    end
end

function Cassette.overdub(ctx::SolverCtx, f::typeof(Base.vect), args...)
    @info "constructing a vector length $(length(args))"
    return Cassette.fallback(ctx, f, args...)
end

# We don't need to overdub basic math. this hopefully makes execution faster.
# if these overloads don't actually make it faster, they can be deleted.
function Cassette.overdub(ctx::SolverCtx, f::typeof(+), args...)
    return Cassette.fallback(ctx, f, args...)
end
function Cassette.overdub(ctx::SolverCtx, f::typeof(-), args...)
    return Cassette.fallback(ctx, f, args...)
end
function Cassette.overdub(ctx::SolverCtx, f::typeof(*), args...)
    return Cassette.fallback(ctx, f, args...)
end
function Cassette.overdub(ctx::SolverCtx, f::typeof(/), args...)
    return Cassette.fallback(ctx, f, args...)
end
end #module
```

Then we define our RHS of the differential
equation that is `du/dt = sir_ode(du, u, p, t)`.
This function needs to be defined before we define
the method for `Cassette.overdub` with the
signature:
`Cassette.overdub(ctx::ODEXform.SolverCtx, f::typeof(sir_ode), args...)` 
because we need to have the function we want to
overdub defined before we can specify how to
overdub it.

```julia
using LinearAlgebra
using Test
using Cassette
using DifferentialEquations
using SemanticModels.Dubstep

"""   sir_ode(du,u,p,t)

computes the du/dt array for the SIR system. parameters p is b,g = beta,gamma.
"""
sir_ode(du,u,p,t) = begin
    S,I,R = u
    b,g = p
    du[1] = -b*S*I
    du[2] = b*S*I-g*I
    du[3] = g*I
end
```
This code implements the model
$\frac{dS}{dt} = -\beta S I$
$\frac{dI}{dt} = \beta S I - \gamma I$
$\frac{dR}{dt} = \gamma I$

A common modeling activity is for a scientist to consider counterfactual scenarios, what if the infection was a little
bit stronger. In this model the strength of infection is a direct parameter of the model, but our approach works on
aspects of the model that are not so easily accessible.

We want to add to the code a perturbation that allows us to examine these counterfactuals.
Suppose the infection was a little stronger by a factor of $\alpha$

$\frac{dS}{dt} = \alpha (\beta S I - \gamma I)$

Then we could modify the code at run time using a Cassette Context.

```julia
function Cassette.overdub(ctx::ODEXform.SolverCtx, f::typeof(sir_ode), args...)
    y = Cassette.fallback(ctx, f, args...)
    # add a lagniappe of infection
    extra = args[1][1] * ctx.metadata.factor
    push!(ctx.metadata.extras, extra)
    args[1][1] += extra
    args[1][2] -= extra
    return y
end
```

The key thing is that we define the execute method
by specifying that we want to execute `sir_ode`
then compute the extra amount (the lagniappe) and
add that extra amount to the `dS/dt`. The SIR
model has an invariant that `dI/dt = -dS/dt + dR/dt`
so we adjust the `dI/dt` accordingly.

The rest of this code runs the model in the
context.

```julia
function g()
    parms = [0.1,0.05]
    init = [0.99,0.01,0.0]
    tspan = (0.0,200.0)
    sir_prob = Dubstep.construct(ODEProblem,sir_ode,init,tspan,parms)
    return sir_prob
end

function h()
    prob = g()
    return solve(prob, alg=Vern7())
end

#precompile
@time sol1 = h()
#timeit
@time sol1 = h()
```

We define a perturbation function that handles
setting up the context and collecting the results.
Note that we store the extras in the
```context.metadata``` using a modifying operator ```push!```.

```julia
"""    perturb(f, factor)

run the function f with a perturbation specified by factor.
"""
function perturb(f, factor)
    t = (factor=factor,extras=Float64[])
    ctx = ODEXform.SolverCtx(metadata = t)
    val = Cassette.recurse(ctx, f)
    return val, t
end
```
The use of an execution context allows the programmer to capture state from the program
in the context and reuse it across function calls. This solves one of the big problems 
with reuse of modeling code. Scientific code is not written with extensibility in mind.
There is often no way to pass information between function calls without modifying a large
number of functions. Attempts to solve this with object oriented programming often lead to
overly complex systems that are difficult for new scientists to use. The ability of the execution
context to pass state between functions allows for redefining behavior of a complex software
system without reengineering all the application programming interfaces (APIs).

We collect the traces `t` and solutions `s` in
order to quantify the effect of our perturbation
on the answer computed by `solve`. We test to make
sure that the bigger the perturbation, the bigger
the error.

```julia
traces = Any[]
solns = Any[]
for f in [0.0, 0.01, 0.05, 0.10]
    val, t = perturb(h, f)
    push!(traces, t)
    push!(solns, val)
end

for (i, s) in enumerate(solns)
    @show s(100)
    @show traces[i].factor
    @show traces[i].extras[5]
    @show sum(traces[i].extras)/length(traces[i].extras)
end

@testset "ODE perturbation"

@test norm(sol1(100) .- solns[1](100),2) < 1e-6
@test norm(sol1(100) .- solns[2](100),2) > 1e-6
@test norm(solns[1](100) .- solns[2](100),2) < norm(solns[1](100) .- solns[3](100),2)
@test norm(solns[1](100) .- solns[2](100),2) < norm(solns[1](100) .- solns[4](100),2)

end
```

This example illustrates how you can use a
```Cassette.Context``` to highjack the execution of a
scientific model in order to change the execution
in a meaningful way. We also see how the execution
allows use to examine the sensitivity of the
solution with respect to the derivative. This
technique allows scientists to answer
counterfactual questions about the execution of
codes, such as "what if the model had a slightly
different RHS?"

This illustrative example would be possible with a direct modification of the source code. We present this general
framework for code analysis and modification because when the codes become sophisticated, complex models it is
infeasible for scientists to just read the code and make the changes themselves. This is largly due to the fact that
scientific models are not engineered to be extensible. The development resources are spent on innovative algorithms and
mathematics and not on designing general purpose modeling frameworks that can be easily extended. When researchers do
attempt to build general purpose software tools, they often lack the funding to design and maintain them at a level of
utility that users expect. This leads to a cycle where scientists have bad experiences with general purpose software and
thus invest fewer resources in its development in the future, perpetuating the preference for specialized use case
specific software.

## Model Grafting

Once you have built a knowledge graph from other codes, you can reason over that knowledge graph to decide how to make
modifications to the models. The Dubstep module provides the `GraftCtx` to facilitate these model modifications.

```julia
using Cassette
using DifferentialEquations
using SemanticModels.Parsers
using SemanticModels.Dubstep

# source of original problem
include("../examples/epicookbook/src/SEIRmodel.jl")

#the functions we want to modify
seir_ode = SEIRmodel.seir_ode
```

Once you have identified the entry point to your model, you can identify pieces of another model that you want to graft
onto it. This piece of the other model might take significant preparation in order to be ready to fit onto the base
model. These transformations include changing variables, and other plumbing aspects. If you stick to taking whole
functions and not expressions, this prep work is reduced.

```julia
# source of the problem we want to take from
expr = parsefile("examples/epicookbook/src/ScalingModel.jl")


# Find the expression we want to graft
#vital dynamics S rate expression
vdsre = expr.args[3].args[5].args[2].args[4]
@show popgrowth = vdsre.args[2].args[2]

replacevar(expr, old, new) = begin
    dump(expr)
    expr.args[3].args[3].args[3] = new
    return expr
end

popgrowth = replacevar(popgrowth, :K,:N)

# generate the function newfunc
# this eval happens at the top level so should only happen once
newfunc = eval(:(fpopgrowth(r,S,N) = $popgrowth))

# This is the new problem
# notice the signature doesn't even match, we have added a new parameter
function fprime(dY,Y,p,t, ϵ)
    #Infected per-Capita Rate
    β = p[1]
    #Incubation Rate
    σ = p[2]
    #Recover per-capita rate
    γ = p[3]
    #Death Rate
    μ = p[4]

    #Susceptible Individual
    S = Y[1]
    #Exposed Individual
    E = Y[2]
    #Infected Individual
    I = Y[3]
    #Recovered Individual
    #R = Y[4]

    # here is the graft point
    dY[1] = μ-β*S*I-μ*S + newfunc(ϵ, S, S+E+I)
    dY[2] = β*S*I-(σ+μ)*E
    dY[3] = σ*E - (γ+μ)*I
end
```

Define the overdub behavior; all the functions need to be defined at this point using run time values slows down overdub.

```julia
function Cassette.overdub(ctx::Dubstep.GraftCtx, f::typeof(seir_ode), args...)
    # this call matches the new signature
    return Cassette.fallback(ctx, fprime, args..., ctx.metadata[:lambda])
end
```

The last step is to run the new model!

```julia
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
```

It works! We can see that increasing the population growth causes a larger infected and recovered population at the end
of 1 year.

## Reference


```@autodocs
Modules = [SemanticModels.Dubstep]
```
