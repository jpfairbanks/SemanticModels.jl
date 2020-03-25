module ODEXform
using OrdinaryDiffEq
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

using LinearAlgebra
using Test
using Cassette
using OrdinaryDiffEq
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

"""    perturb(f, factor)

run the function f with a perturbation specified by factor.
"""
function perturb(f, factor)
    t = (factor=factor,extras=Float64[])
    ctx = ODEXform.SolverCtx(metadata = t)
    val = Cassette.recurse(ctx, f)
    return val, t
end

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

@testset "ODE perturbation" begin

@test norm(sol1(100) .- solns[1](100),2) < 1e-6
@test norm(sol1(100) .- solns[2](100),2) > 1e-6
@test norm(solns[1](100) .- solns[2](100),2) < norm(solns[1](100) .- solns[3](100),2)
@test norm(solns[1](100) .- solns[2](100),2) < norm(solns[1](100) .- solns[4](100),2)

end
