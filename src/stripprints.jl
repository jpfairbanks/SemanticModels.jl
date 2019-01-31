using Cassette

Cassette.@context Ctx

mutable struct Callback
    f::Any
end

function Cassette.execute(ctx::Ctx, ::typeof(println), args...)
    previous = ctx.metadata.f
    ctx.metadata.f = () -> (previous(); println(args...))
    return nothing
end

a = rand(3)
b = rand(3)
function add(a, b)
    println("I'm about to add $a + $b")
    c = a + b
    println("c = $c")
    return c
end

add(a, b)

ctx = Ctx(metadata = Callback(() -> nothing));

c = Cassette.overdub(ctx, add, a, b)

ctx.metadata.f()
