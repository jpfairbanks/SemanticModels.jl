module Pass
using Cassette
using Core: CodeInfo, SlotNumber, SSAValue

Cassette.@context Ctx

function Cassette.execute(ctx::Ctx, callback, f, args...)
    if Cassette.canoverdub(ctx, f, args...)
        _ctx = Cassette.similarcontext(ctx, metadata = callback)
        return Cassette.overdub(_ctx, f, args...) # return result, callback
    else
        return Cassette.fallback(ctx, f, args...), callback
    end
end

function Cassette.execute(ctx::Ctx, callback, ::typeof(println), args...)
    return nothing, () -> (callback(); println(args...))
end

function sliceprintln(::Type{<:Ctx}, ::Type{S}, ir::CodeInfo) where {S}
    @show callbackslotname = gensym("callback")
    @show push!(ir.slotnames, callbackslotname)
    @show push!(ir.slotflags, 0x00)
    @show callbackslot = SlotNumber(length(ir.slotnames))
    @info "getmetadata"
    getmetadata = Expr(:call, Expr(:nooverdub, GlobalRef(Core, :getfield)), Expr(:contextslot), QuoteNode(:metadata))

    # insert the initial `callbackslot` assignment into the IR.
    @info "insert"
    Cassette.insert_statements!(ir.code, ir.codelocs,
                                 (stmt, i) -> i == 1 ? 2 : nothing,
                                 (stmt, i) -> [Expr(:(=), callbackslot, getmetadata), stmt])

    # replace all calls of the form `f(args...)` with `callback(f, args...)`, taking care to
    # properly destructure the returned `(result, callback)` into the appropriate statements
    @info "insert more"
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

    @info "insert a third time"
    # replace return statements of the form `return x` with `return (x, callback)`
    Cassette.insert_statements!(ir.code, ir.codelocs,
                                  (stmt, i) -> Base.Meta.isexpr(stmt, :return) ? 2 : nothing,
                                  (stmt, i) -> begin
                                @info "lambda"
                                @show ex = Expr(:nooverdub, GlobalRef(Core, :tuple))
                                @show a = ex, stmt.args[1]
                                @show typeof(a)
                                @info "SSAV"
                                @show sv = SSAValue(i)
                                @info "return"
                                @show out = [
                                          Expr(:call, a, callbackslot)
                                          Expr(:return, sv)
                                      ]
                                return out
                                end)
    @info "returning $ir"
    return ir
end

const sliceprintlnpass = Cassette.@pass sliceprintln


a = rand(3)
b = rand(3)
function add(a, b)
    # println("I'm about to add $a + $b")
    c = a + b
    # println("c = $c")
    return c
end
add(a, b)
ctx = Ctx(pass=sliceprintlnpass, metadata = () -> nothing);

result, callback = Cassette.overdub(ctx, add, a, b)

@info "calling the callback"
# callback()

end
