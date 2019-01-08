module TraceTest

using Cassette
using Test
using SemanticModels.Dubstep
using LinearAlgebra

struct ODEProblem{T,U,V,W}
    ode::T
    init::U
    tspan::V
    parms::W
end

# Define == for ODEProblems to mean they are semantically equivalent. The
# normal definition for structs is that equality of fields is done with ===
# which means structs that contain arrays, cannot be == if those arrays are
# not === perhaps we should use the AutoHashEquals.jl package here.
function Base.:(==)(p::ODEProblem, q::ODEProblem)
    return p.ode == q.ode && p.init == q.init && p.tspan == q.tspan && p.parms == q.parms
end

"""   sir_ode2(du,u,p,t)

        computes the du/dt array for the SIR system. parameters p is b,g = beta,gamma.
        """
sir_ode2(du,u,p,t) = begin
    S,I,R = u
    b,g = p
    du[1] = -b*S*I
    du[2] = b*S*I-g*I
    du[3] = g*I
end

# Cassette.@context TraceCtx

# function Cassette.overdub(ctx::TraceCtx, args...)
#     subtrace = Any[]
#     push!(ctx.metadata, args => subtrace)
#     if Cassette.canrecurse(ctx, args...)
#         newctx = Cassette.similarcontext(ctx, metadata = subtrace)
#         return Cassette.recurse(newctx, args...)
#     else
#         return Cassette.fallback(ctx, args...)
#     end
# end

trace = Any[]
x, y, z = rand(3)
f(x, y, z) = x*y + y*z
Cassette.recurse(Dubstep.TraceCtx(metadata = trace), () -> f(x, y, z))
@testset "Cassette" begin
        @test trace == Any[
            (f,x,y,z) => Any[
                (*,x,y) => Any[(Base.mul_float,x,y)=>Any[]]
                (*,y,z) => Any[(Base.mul_float,y,z)=>Any[]]
                (+,x*y,y*z) => Any[(Base.add_float,x*y,y*z)=>Any[]]
            ]
        ]
end


function g()
    parms = [0.1,0.05]
    init = [0.99,0.01,0.0]
    tspan = (0.0,200.0)
    sir_prob2 = construct(ODEProblem,sir_ode2,init,tspan,parms)
    # sir_sol = solve(sir_prob2,saveat = 0.1)
    return sir_prob2
end

function h()
    parms = [0.1,0.05]
    init = [0.99,0.01,0.0]
    tspan = (0.0,200.0)
    sir_prob2 = ODEProblem(sir_ode2,init,tspan,parms)
    # sir_sol = solve(sir_prob2,saveat = 0.1)
    return sir_prob2
end

# these are equal, because we wrote a custom == function for ODEProblem.
@testset "Dubstep" begin
    @testset "SIR" begin

    @info "Tracing implementation with construct call"
    trace1 = Dubstep.trace(g)
    @info "Tracing implementation without construct call"
    trace2 = Dubstep.trace(h)
    @test trace2.value == trace1.value

    for i in 1:3
        @test trace1.trace[i] == trace2.trace[i]
    end

    @info "Trace step for construct call"
    @show trace1.trace[4]
    @test trace1.trace[4][1] == construct
    @info "Trace step for direct apply type"
    @show trace2.trace[4]
    @test last(trace2.trace[4])[1][1] == Core.apply_type

end #SIR

end #Dubstep


subg(x,y) = norm([x x x]/6 - [y y y]/2, 2)
function g()
    a = 5+7
    b = 3+4
    c = subg(a,b)
    return c
end
function h()
    a = 5+7
    c = subg(a,(3+4))
    return c
end

@testset "LP" begin 
@test 2.5980 < g() < 2.599
ctx = Dubstep.LPCtx(metadata=Dict(1=>2, 2=>1, Inf=>1))
@test Cassette.recurse(ctx, g) == 4.5
end #LP

end #module
