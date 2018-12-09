module CassTest

# this recursion based solution is too fancy for me to understand.
using Cassette

function construct(T::Type, args...)
    @info "constructing a model $T"
    return T(args...)
end

Cassette.@context TraceCtx

function Cassette.execute(ctx::TraceCtx, args...)
    subtrace = Any[]
    push!(ctx.metadata, args => subtrace)
    if Cassette.canoverdub(ctx, args...)
        newctx = Cassette.similarcontext(ctx, metadata = subtrace)
        return Cassette.overdub(newctx, args...)
    else
        return Cassette.fallback(ctx, args...)
    end
end

function Cassette.execute(ctx::TraceCtx, f::typeof(Base.vect), args...)
    @info "constructing a vector"
    push!(ctx.metadata, (f, args))
    return Cassette.fallback(ctx, f, args...)
end

function Cassette.execute(ctx::TraceCtx, f::typeof(Core.apply_type), args...)
    @info "applying a type $f"
    push!(ctx.metadata, (f, args))
    return Cassette.fallback(ctx, f, args...)
end

# TODO: support calls like construct(T, a, f(b))
function Cassette.execute(ctx::TraceCtx, f::typeof(construct), args...)
    @info "constructing with type $f"
    push!(ctx.metadata, (f, args))
    y = Cassette.fallback(ctx, f, args...)
    @info "constructed model: $y"
    return y
end

struct TracedRun{T,V}
    trace::T
    value::V
end


function buildtrace(f::Function)
    trace = Any[]
    val = Cassette.overdub(TraceCtx(metadata=trace), f)
    return TracedRun(trace, val)
end



trace = Any[]
x, y, z = rand(3)
f(x, y, z) = x*y + y*z
Cassette.overdub(TraceCtx(metadata = trace), () -> f(x, y, z))

# returns `true`
trace == Any[
   (f,x,y,z) => Any[
       (*,x,y) => Any[(Base.mul_float,x,y)=>Any[]]
       (*,y,z) => Any[(Base.mul_float,y,z)=>Any[]]
       (+,x*y,y*z) => Any[(Base.add_float,x*y,y*z)=>Any[]]
   ]
]
# using Cassette

# Cassette.@context TraceCtx

# mutable struct Trace
#     current::Vector{Any}
#     stack::Vector{Any}
#     Trace() = new(Any[], Any[])
# end

# function enter!(t::Trace, args...)
#     pair = args => Any[]
#     push!(t.current, pair)
#     push!(t.stack, t.current)
#     t.current = pair.second
#     return nothing
# end

# function exit!(t::Trace)
#     t.current = pop!(t.stack)
#     return nothing
# end

# Cassette.prehook(ctx::TraceCtx, args...) = enter!(ctx.metadata, args...)
# Cassette.posthook(ctx::TraceCtx, args...) = exit!(ctx.metadata)

# trace = Trace()
# x, y, z = rand(3)
# f(x, y, z) = x*y + y*z
# Cassette.overdub(TraceCtx(metadata = trace), () -> f(x, y, z))

# # returns `true`
# trace.current == Any[
#     (f,x,y,z) => Any[
#         (*,x,y) => Any[(Base.mul_float,x,y)=>Any[]]
#         (*,y,z) => Any[(Base.mul_float,y,z)=>Any[]]
#         (+,x*y,y*z) => Any[(Base.add_float,x*y,y*z)=>Any[]]
#     ]
# ]

struct ODEProblem{T,U,V,W}
    ode::T
    init::U
    tspan::V
    parms::W
end

# Define == for ODEProblems to mean they are semantically equivalent.
# The normal definition for structs is that equality of fields is done with ===
# which means structs that contain arrays, cannot be == if those arrays are not ===
# perhaps we should use the AutoHashEquals.jl package here.
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

# these should be equal, but we have to write a custom == function for ODEProblem.

@info "Tracing implementation with construct call"
trace1 = buildtrace(g)
@info "Tracing implementation without construct call"
trace2 = buildtrace(h)
@assert trace2.value == trace1.value

for i in 1:3
    @assert trace1.trace[i] == trace2.trace[i]
end

@info "Trace step for construct call"
@show trace1.trace[4]
@assert trace1.trace[4][1] == construct
@info "Trace step for direct apply type"
@show trace2.trace[4]
@assert last(trace2.trace[4])[1][1] == Core.apply_type

end
