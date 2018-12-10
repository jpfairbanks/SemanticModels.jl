# Dubstep 

This module uses Cassette.jl to modify programs by overdubbing their executions in a context. 

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

function Cassette.execute(ctx::LPCtx, args...)
    if Cassette.canoverdub(ctx, args...)
        newctx = Cassette.similarcontext(ctx, metadata = ctx.metadata)
        return Cassette.overdub(newctx, args...)
    else
        return Cassette.fallback(ctx, args...)
    end
end

using LinearAlgebra
function Cassette.execute(ctx::LPCtx, f::typeof(norm), arg, power)
    return f(arg, ctx.metadata[power])
end
```

Note the method definition of `Cassette.execute`
for LPCtx when called with the function
`LinearAlgebra.norm`.

We then construct an instance of the context that
configures how we want to do the substitution.
```julia
@testset "LP" begin 
@test 2.5980 < g() < 2.599
ctx = Dubstep.LPCtx(metadata=Dict(1=>2, 2=>1, Inf=>1
@test Cassette.overdub(ctx, g) == 4.5
```

And just like that, we can control the execution
of a program without rewriting it at the lexical level.

## Reference


```@autodocs
Modules = [SemanticModels.Dubstep]
```
