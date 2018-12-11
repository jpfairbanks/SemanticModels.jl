module SlicePass
using Cassette
using Core: CodeInfo, SlotNumber, SSAValue


Cassette.@context Ctx

struct Slice end

const SLICE = Slice()
call(s::Slice) = nothing

function Cassette.execute(ctx::Ctx, ::Slice, callback, f, args...)
    if Cassette.canoverdub(ctx, f, args...)
        _ctx = Cassette.similarcontext(ctx, metadata = callback)
        return Cassette.overdub(_ctx, f, args...) # return result, callback
    else
        return Cassette.fallback(ctx, f, args...), callback
    end
end

function Cassette.execute(ctx::Ctx, ::Slice, callback, ::typeof(println), args...)
    return nothing, () -> (callback(); println(args...))
end

# Note that this uses some Cassette stuff that isn't documented yet but will be (e.g. `:contextslot` and `:nooverdub` expr heads, but you can guess what those are)
function sliceprintln(::Type{<:Ctx}, ::Type{S}, ir::CodeInfo) where {S}
    callbackslotname = gensym("callback")
    push!(ir.slotnames, callbackslotname)
    push!(ir.slotflags, 0x00)
    callbackslot = SlotNumber(length(ir.slotnames))
    getmetadata = Expr(:call, Expr(:nooverdub, GlobalRef(Core, :getfield)), Expr(:contextslot), QuoteNode(:metadata))

    # Insert the initial `callbackslot` assignment into the IR.
    # This is an internal Cassette utility, which we'll use for now for convenience. It'd be
    # nice for Base to expose something like this for pre-inference IR...
    Cassette.insert_statements!(ir.code, ir.codelocs,
                                 (stmt, i) -> i == 1 ? 2 : nothing,
                                 (stmt, i) -> [Expr(:(=), callbackslot, getmetadata), stmt])

    # Replace all calls of the form `f(args...)` with `SLICE(callback, f, args...)`,
    # taking care to properly destructure the returned `(result, callback)` into the
    # appropriate statements.
    Cassette.insert_statements!(ir.code, ir.codelocs,
                                 (stmt, i) -> begin
                                    i > 1 || return nothing # don't slice callback assignment
                                    stmt = Base.Meta.isexpr(stmt, :(=)) ? stmt.args[2] : stmt
                                    return Base.Meta.isexpr(stmt, :call) ? 3 : nothing
                                 end,
                                 (stmt, i) -> begin
                                     items = Any[]
                                     callstmt = Base.Meta.isexpr(stmt, :(=)) ? stmt.args[2] : stmt
                                     push!(items, Expr(:call, GlobalRef(Main, :SLICE), callbackslot, callstmt.args...))
                                     push!(items, Expr(:(=), callbackslot, Expr(:call, Expr(:nooverdub, GlobalRef(Core, :getfield)), SSAValue(i), 2)))
                                     result = Expr(:call, Expr(:nooverdub, GlobalRef(Core, :getfield)), SSAValue(i), 1)
                                     if Base.Meta.isexpr(stmt, :(=))
                                         result = Expr(:(=), stmt.args[1], result)
                                     end
                                     push!(items, result)
                                     return items
                                 end)

    # Replace return statements of the form `return x` with `return x, callback`.
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

ctx = Ctx(pass=sliceprintlnpass, metadata = () -> nothing)
a = rand(3)
b = rand(3)
add(x,y) = x+y
result, callback = Cassette.overdub(ctx, add, a, b)
end
