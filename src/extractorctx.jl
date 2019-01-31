module Dubstep
using Cassette

# export ExtractorCtx,
#     construct,
#     Ctx

# function construct(T::Type, args...)
#     @info "constructing a model $T"
#     return T(args...)
# end

# # TODO: This doesn't work because you can't use code_lowered programmatically
# Cassette.@context ExtractorCtx

# function Cassette.overdub(ctx::ExtractorCtx, args...)
#     subtrace = Any[]
#     push!(ctx.metadata, args => subtrace)
#     if Cassette.canrecurse(ctx, args...)
#         newctx = Cassette.similarcontext(ctx, metadata = subtrace)
#         return Cassette.recurse(newctx, args...)
#     else
#         try
#             @info "lowering code $args"
#             code = code_lowered(args[1], typeof.(args...)...)
#             @info code
#             println(code.code)
#             y = Cassette.fallback(ctx, args...)
#             return y
#         catch
#             return Cassette.fallback(ctx, args...)
#         end
#     end
# end

# function Cassette.overdub(ctx::ExtractorCtx, f::typeof(Base.vect), args...)
#     @info "constructing a vector"
#     push!(ctx.metadata, (f, args))
#     return Cassette.fallback(ctx, f, args...)
# end

# function Cassette.overdub(ctx::ExtractorCtx, f::typeof(Core.apply_type), args...)
#     @info "applying a type $f"
#     push!(ctx.metadata, (f, args))
#     return Cassette.fallback(ctx, f, args...)
# end

# # TODO: support calls like construct(T, a, f(b))
# function Cassette.overdub(ctx::ExtractorCtx, f::typeof(construct), args...)
#     @info "constructing with type $f"
#     push!(ctx.metadata, (f, args))
#     y = Cassette.fallback(ctx, f, args...)
#     @info "constructed model: $y"
#     return y
# end

using Cassette
using Core: CodeInfo, SlotNumber, SSAValue

Cassette.@context Ctx

function Cassette.overdub(ctx::Ctx, callback, f, args...)
    if Cassette.canrecurse(ctx, f, args...)
        _ctx = Cassette.similarcontext(ctx, metadata = callback)
        return Cassette.recurse(_ctx, f, args...) # return result, callback
    else
        return Cassette.fallback(ctx, f, args...), callback
    end
end

function Cassette.overdub(ctx::Ctx, callback, ::typeof(println), args...)
    return nothing, () -> (callback(); println(args...))
end

function sliceprintln(::Type{<:Ctx}, reflection::Cassette.Reflection)
    ir = reflection.code_info
    callbackslotname = gensym("callback")
    push!(ir.slotnames, callbackslotname)
    push!(ir.slotflags, 0x00)
    callbackslot = SlotNumber(length(ir.slotnames))
    getmetadata = Expr(:call, Expr(:nooverdub, GlobalRef(Core, :getfield)), Expr(:contextslot), QuoteNode(:metadata))

    # insert the initial `callbackslot` assignment into the IR.
    Cassette.insert_statements!(ir.code, ir.codelocs,
                                 (stmt, i) -> i == 1 ? 2 : nothing,
                                 (stmt, i) -> [Expr(:(=), callbackslot, getmetadata), stmt])

    # replace all calls of the form `f(args...)` with `callback(f, args...)`, taking care to
    # properly destructure the returned `(result, callback)` into the appropriate statements
    Cassette.insert_statements!(ir.code, ir.codelocs,
                                 (stmt, i) -> begin
                                    i > 1 || return nothing # don't slice the callback assignment
                                    stmt = Base.Meta.isexpr(stmt, :(=)) ? stmt.args[2] : stmt
                                    return Base.Meta.isexpr(stmt, :call) ? 3 : nothing
                                 end,
                                 (stmt, i) -> begin
                                     items = Any[]
                                     callstmt = Base.Meta.isexpr(stmt, :(=)) ? stmt.args[2] : stmt
                                     push!(items, Expr(:call, callbackslot, callstmt.args...))
                                     push!(items, Expr(:(=), callbackslot, Expr(:call, Expr(:nooverdub, GlobalRef(Core, :getfield)), SSAValue(i), 2)))
                                     result = Expr(:call, Expr(:nooverdub, GlobalRef(Core, :getfield)), SSAValue(i), 1)
                                     if Base.Meta.isexpr(stmt, :(=))
                                         result = Expr(:(=), stmt.args[1], result)
                                     end
                                     push!(items, result)
                                     return items
                                 end)

    # replace return statements of the form `return x` with `return (x, callback)`
    Cassette.insert_statements!(ir.code, ir.codelocs,
                                  (stmt, i) -> Base.Meta.isexpr(stmt, :return) ? 2 : nothing,
                                  (stmt, i) -> begin
                                      return [
                                          Expr(:call, Expr(:nooverdub, GlobalRef(Core, :tuple)), stmt.args[1], callbackslot)
                                          Expr(:return, SSAValue(i))
                                      ]
                                  end)
    return ir
end

const sliceprintlnpass = Cassette.@pass sliceprintln


a = rand(3)
b = rand(3)
function add(a, b)
    println("I'm about to add $a + $b")
    c = a + b
    println("c = $c")
    return c
end
@info "adding"
add(a, b)
@info "dubbed adding"
ctx = Dubstep.Ctx(pass=Dubstep.sliceprintlnpass, metadata = () -> nothing);
result, callback = Cassette.recurse(ctx, add, a, b)
callback()
end

using Cassette
# using Dubstep

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
function g()
    parms = [0.1,0.05]
    init = [0.99,0.01,0.0]
    tspan = (0.0,200.0)
    sir_prob2 = Dubstep.construct(ODEProblem,sir_ode2,init,tspan,parms)
    # sir_sol = solve(sir_prob2,saveat = 0.1)
    return sir_prob2
end

# trace = Any[]
# val = Cassette.recurse(Dubstep.ExtractorCtx(metadata=trace), g)

# dump(trace)
# dump(val)

