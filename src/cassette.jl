module Dubstep

using Cassette
export construct, TracedRun, trace, TraceCtx

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


function trace(f::Function)
    trace = Any[]
    val = Cassette.overdub(TraceCtx(metadata=trace), f)
    return TracedRun(trace, val)
end

end
