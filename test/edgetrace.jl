module EdgeTrace
using SemanticModels.Dubstep

struct Edges
    list::Vector{Any}
end

import Base: push!
function push!(e::Edges, t::Pair)
    # @info "pushing $t"
    push!(e.list, t)
end
using LinearAlgebra
using Cassette
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

# ctx = Dubstep.TraceCtx(metadata=Dubstep.Edges([]))
# val = Cassette.overdub(ctx, g)
# dump(ctx.metadata)

# ctx = Dubstep.TraceCtx(metadata=Dubstep.Edges([]))

# val = Cassette.overdub(ctx, h)
# dump(ctx.metadata)

@show g()
ctx = Dubstep.LPCtx(metadata=Dict(1=>2, 2=>1, Inf=>1))
@show Cassette.overdub(ctx, g)
end
