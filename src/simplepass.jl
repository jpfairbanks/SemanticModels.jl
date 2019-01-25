module Pass
using Cassette
using Core: CodeInfo, SlotNumber, SSAValue

Cassette.@context Ctx
storage = Any[]

function Cassette.execute(ctx::Ctx, f, args...)
    if Cassette.canoverdub(ctx, f, args...)
        _ctx = Cassette.similarcontext(ctx, metadata = storage)
        return Cassette.overdub(_ctx, f, args...) 
    else
        return Cassette.fallback(ctx, f, args...)
    end
end

function Cassette.execute(ctx::Ctx, ::typeof(println), args...)
    @info "dalaying a print"
    push!(ctx.metadata, ()->println(args))
    return false
end


# this should be the identity pass that does nothing.
function sliceprintln(::Type{<:Ctx}, s::Type{S}, ir::CodeInfo) where {S}
    @show s
    @info "slicing"
    # Cassette.replace_match!(

    #    Expr(:call, Expr(:nooverdub, s[1].instance), s.),
    #     ir
    # )
    @show ir
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

result = Cassette.overdub(ctx, add, a, b)

@info "calling the callback"
# callback()
for f in storage
    f()
end


end
