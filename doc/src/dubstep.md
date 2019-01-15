# Dubstep 

This module uses [Cassette.jl](https://www.github.com/jrevels/Cassette.jl) ([Zenodo](https://zenodo.org/record/1806173)) to modify programs by overdubbing their executions in a context. 

## TraceCtx

Builds hierarchical runtime value traces by running the program you pass it. You can change the metadata.
You can change out the metadata that you pass in order to collect different information. The default is Any[].

## LPCtx

Replaces all calls to `norm(x,p)` which `norm(x,ctx.metadata[p])` so you can change the norms that a code uses to
compute. 

### Example
Here is an example of changing an internal component of a mathematical operation using cassette to rewrite the norm function.


First we define a function that uses norm, and
another function that calls it. 
```julia
subg(x,y) = norm([x x x]/6 - [y y y]/2, 2)
function g()
    a = 5+7
    b = 3+4
    c = subg(a,b)
    return c
end
```

We use the Dubstep.LPCtx which is shown here.

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
configures how we want to do the substitution.
```julia
@testset "LP" begin 
@test 2.5980 < g() < 2.599
ctx = Dubstep.LPCtx(metadata=Dict(1=>2, 2=>1, Inf=>1
@test Cassette.recurse(ctx, g) == 4.5
```

And just like that, we can control the execution
of a program without rewriting it at the lexical level.


## Transformations

You can also transform model by executing it in a
context that changes the function calls.
Eventually we will support writing compiler passes
for modifying models at the expression level, but
for now function calls are a good entry point.

### Example: Perturbations

This example comes from the unit tests `test/transform/ode.jl`.

The first step is to define a context for solving
models.

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
context.metadata using a modifying operator push!.

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
Cassette.Context to highjack the execution of a
scientific model in order to change the execution
in a meaningful way. We also see how the execution
allows use to example the sensitivity of the
solution with respect to the derivative. This
technique allows scientists to answer
counterfactual questions about the execution of
codes, such as "what if the model had a slightly
different RHS?"

## Reference


```@autodocs
Modules = [SemanticModels.Dubstep]
```
