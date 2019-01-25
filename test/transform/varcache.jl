module SlicePass
using Test
using Cassette
import Cassette: @context, canoverdub, overdub, fallback, similarcontext
print("   running SliceCtx test...")
 before_time = time()
 using Core: CodeInfo, SlotNumber, SSAValue
 @context SliceCtx
 function Cassette.execute(ctx::SliceCtx, callback, f, args...)
    if canoverdub(ctx, f, args...)
        _ctx = similarcontext(ctx, metadata = callback)
        return overdub(_ctx, f, args...) # return result, callback
    else
        return fallback(ctx, f, args...), callback
    end
end
 const global_test_cache = Any[]
 push_to_global_test_cache!(x) = push!(global_test_cache, x)
 function Cassette.execute(ctx::SliceCtx, callback, ::typeof(push_to_global_test_cache!), x)
    return nothing, () -> (callback(); push_to_global_test_cache!(x))
end
 # handle Core._apply calls; Cassette might do this for you in a future update
function Cassette.execute(ctx::SliceCtx, callback, ::typeof(Core._apply), f, args...)
    return Core._apply(Cassette.execute, (ctx,), (callback,), (f,), args...)
end

function varname(ir::CodeInfo, sym::Symbol)
    s = string(sym)[2:end]
    i = parse(Int,s)
    varname = ir.slotnames[i]
    return varname
end


 function sliceprintln(::Type{<:SliceCtx}, ::Type{S}, ir::CodeInfo) where {S}
    slotnames = ir.slotnames
    vn = slotnames[end]
    varnames = Symbol[]
     funccalls = Any[]
     s = ""
     i = 1
    for expr in ir.code
        isa(expr, Expr) || continue
        if expr.head == :(=)
            @show expr
            try
                sym = Symbol(expr.args[1])
                vn = varname(ir, sym)
                push!(varnames, vn)
                if expr.args[2].head == :(call)
                    fname = expr.args[2].args[1]
                    push!(funccalls, (varname, fname))
                else
                    @show expr.args[2]
                    @show expr.args[2]
                end
            catch ex
                @show ex
                # @warn "could not find slotname for $(expr.args[1])"
                # @show slotnames
                # @show expr.args[1], s, i
            end
        end
    end
     if length(varnames) > 0
         @show varnames
     end
     # TODO: do something with functions without explicit assignment.
     # if length(varnames) == 0
     #     @show ir
     # end

     if length(funccalls) > 0
         @show funccalls
     end

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
    push_to_global_test_cache!(a)
    push_to_global_test_cache!(b)
    c = a + b
    push_to_global_test_cache!(c)
    return c
end
ctx = SliceCtx(pass=sliceprintlnpass, metadata = () -> nothing)
result, callback = Cassette.overdub(ctx, add, a, b)
@test result == a + b
@test isempty(global_test_cache)
@show callback()
@test global_test_cache == [a, b, result]
 println("done (took ", time() - before_time, " seconds)")
end
