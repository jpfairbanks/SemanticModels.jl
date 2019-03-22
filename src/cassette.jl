module Dubstep

using Cassette
using LinearAlgebra
export construct, TracedRun, trace, TraceCtx, LPCtx, replacenorm,
    GraftCtx, replacefunc

function construct(T::Type, args...)
    @info "constructing a model $T"
    return T(args...)
end

Cassette.@context TraceCtx

"""    TraceCtx

builds dynamic analysis traces of a model for information extraction
"""
TraceCtx

function Cassette.overdub(ctx::TraceCtx, args...)
    subtrace = Any[]
    push!(ctx.metadata, args => subtrace)
    if Cassette.canrecurse(ctx, args...)
        newctx = Cassette.similarcontext(ctx, metadata = subtrace)
        return Cassette.recurse(newctx, args...)
    else
        return Cassette.fallback(ctx, args...)
    end
end

function Cassette.overdub(ctx::TraceCtx, f::typeof(Base.vect), args...)
    @info "constructing a vector"
    push!(ctx.metadata, (f, args))
    return Cassette.fallback(ctx, f, args...)
end

function Cassette.overdub(ctx::TraceCtx, f::typeof(Core.apply_type), args...)
    # @info "applying a type $(args)"
    push!(ctx.metadata, (f, args))
    return Cassette.fallback(ctx, f, args...)
end

# TODO: support calls like construct(T, a, f(b))
function Cassette.overdub(ctx::TraceCtx, f::typeof(construct), args...)
    @info "constructing with type $f"
    push!(ctx.metadata, (f, args))
    y = Cassette.fallback(ctx, f, args...)
    @info "constructed model: $y"
    return y
end

"""    TracedRun{T,V}

captures the dataflow of a code execution. We store the trace and the value.

see also `trace`.
"""
struct TracedRun{T,V}
    trace::T
    value::V
end

"""    trace(f)

run the function f and return a TracedRun containing the trace and the output.
"""
function trace(f::Function)
    trace = Any[]
    val = Cassette.recurse(TraceCtx(metadata=trace), f)
    return TracedRun(trace, val)
end



Cassette.@context LPCtx

"""    LPCtx

replaces all calls to `LinearAlgebra.norm` with a different `p`.

This context is useful for modifying statistical codes or machine learning regularizers.
"""
LPCtx

function Cassette.overdub(ctx::LPCtx, args...)
    if Cassette.canrecurse(ctx, args...)
        newctx = Cassette.similarcontext(ctx, metadata = ctx.metadata)
        return Cassette.recurse(newctx, args...)
    else
        return Cassette.fallback(ctx, args...)
    end
end

function Cassette.overdub(ctx::LPCtx, f::typeof(norm), arg, power)
    p = get(ctx.metadata, power, power)
    return f(arg, p)
end

"""    replacenorm(f::Function, d::AbstractDict)

run f, but replace every call to norm using the mapping in d.
"""
function replacenorm(f::Function, d::AbstractDict)
    ctx = LPCtx(metadata=d)
    return Cassette.recurse(ctx, f)
end

Cassette.@context GraftCtx


"""    GraftCtx

grafts an expression from one simulation onto another

This context is useful for modifying simulations by changing out components to add features

see also: [`Dubstep.LPCtx`](@ref)
"""
GraftCtx

function Cassette.overdub(ctx::GraftCtx, f, args...)
    if Cassette.canrecurse(ctx, f, args...)
        newctx = Cassette.similarcontext(ctx, metadata = ctx.metadata)
        return Cassette.recurse(newctx, f, args...)
    else
        return Cassette.fallback(ctx, f, args...)
    end
end


"""    replacefunc(f::Function, d::AbstractDict)

run f, but replace every call to f using the context GraftCtx.
in order to change the behavior you overload overdub based on the context.
Metadata used to influence the context is stored in d.

see also: `bin/graft.jl` for an example.
"""
function replacefunc(f::Function, d::AbstractDict)
    ctx = GraftCtx(metadata=d)
    return Cassette.recurse(ctx, f)
end
            
#---------------------------------------------------------------------------
            
Cassette.@context TypeCtx
            
"""   TypeCtx

creates a MetaDiGraph tracking the types of args and ret values throughout a script

"""
TypeCtx
            
            

"""   FCollector(depth::Int,frame::function,data::FCollector)

struct to collect all the "frames" called throughout a script
        
"""
mutable struct FCollector{I,F,C}
    depth::I
    frame::F
    data::Vector{C}
end
            


"""   FCollector(depth::Int,frame::Frame)

this is an initialization funtion for the FCollector

"""
function FCollector(d::Int, f)
    FCollector(d, f, FCollector[])
end

""" Frame(func, args, ret, subtrace)

a structure to hold metadata for recursive type information for each function call
Every frame can be thought of as a single stack frame when a function is called
            
"""
mutable struct Frame{F,T,U}
    func::F
    args::T
    ret::U
end
            
function Cassette.overdub(ctx::TypeCtx, f, args...) # add boilerplate for functionality
    c = FCollector(ctx.metadata.depth-1, Frame(f, args, Any))
    push!(ctx.metadata.data, c)
    if c.depth > 0 && Cassette.canrecurse(ctx, f, args...)
        newctx = Cassette.similarcontext(ctx, metadata = c)
        z = Cassette.recurse(newctx, f, args...)
        c.frame.ret = typeof(z)
        return z
    else
        z = Cassette.fallback(ctx, f, args...)
        c.frame.ret = typeof(z)
        return z
    end
end

Cassette.canrecurse(ctx::TypeCtx,::typeof(Base.vect), args...) = false # limit the stacktrace in terms of which to recurse on
Cassette.canrecurse(ctx::TypeCtx,::typeof(FCollector)) = false
Cassette.canrecurse(ctx::TypeCtx,::typeof(Frame)) = false
     
"""    buildgraph

internal function used in the typegraphfrompath
takes the collector object and returns a metagraph
            
"""
function buildgraph(g,collector)
    try
        add_vertex!(g,:name,collector.frame.args)
    catch
        nothing
    end
    try
        add_vertex!(g,:name,collector.frame.ret)
    catch
        nothing
    end
    try
        add_edge!(g,g[collector.frame.args,:name],g[collector.frame.ret,:name],:name,collector.frame.func)
    catch
        nothing
    end
    for frame in collector.data
        buildgraph(g,frame)
    end
    return g
end

"""    typegraph(path::AbstractString,maxdepth::Int)
            
This is a function that takes in an array of script and produces a MetaDiGraph descibing the system.
takes in optional parameter of recursion depth on the stacktrace defaulted to 3

"""
function typegraph(m::Module,maxdepth::Int=3)
    
    extractor = FCollector(maxdepth, Frame(nothing, (), nothing,)) # init the collector object     
    ctx = TypeCtx(metadata = extractor);     # init the context we want             
    Cassette.overdub(ctx,m.main);    # run the script internally and build the extractor data structure
    g = MetaDiGraph()    # crete a graph where we will init our tree
    set_indexing_prop!(g,:name)    # we want to set this metagraph to be able to index by the names
    return buildgraph(g,extractor)    # pass the collector ds to make the acutal metagraph
    
end

end #module

