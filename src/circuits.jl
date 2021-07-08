module ModelCircuits
import Base: ∘

abstract type Circuit end
abstract type PG end

# Attempt to do implement static checking of dimensionality
# TODO make this work like in StaticArrays

# mutable struct FuncPG{F,M,N}
#     f::F
# end

# FuncPG(f::F, m, n) where F = FuncPG{F,Val{m},Val{n}}(f)

# ind(fp::FuncPG{F,M,N})  where {F,M,N} = M
# outd(fp::FuncPG{F,M,N} where {F,M,N}) = N


mutable struct Node <: Circuit
    f
    m::Int
    n::Int
end

"""    Node(f,m,n) <: Circuit

creates an (m,n) circuit that applies the function f to its arguments.
These are the basic nodes of the circuit graph.
"""
function (fp::Node)(args...)
    if length(args) != fp.m
        throw(DimensionMismatch("Input $(fp.m) != $(length(args))"))
    end
    out = fp.f(args...)
    if length(out) != fp.n
        throw(DimensionMismatch("Output $(fp.n) != $(length(out))"))
    end
    return out
end

# Node(f::F, m, n) where F = Node{F}(f, m, n)

ind(fp::Circuit) = fp.m
outd(fp::Circuit) = fp.n

# compose with the same order as function composition
function ∘(c2::Circuit, c1::Circuit)
    ind(c2) == outd(c1) || throw(DimensionMismatch("circuits domains must match"))
    return Node((x...)->c2(c1(x...)...), ind(c1), outd(c2))
end

"""    Embedding(f,m,i) <: Circuit

embeds the circuit f as the ith dimension of a (m,m) circuit.
"""
mutable struct Embedding <: Circuit
    f
    m::Int
    i::Int
end

function embed(f, m::Int, i::Int)
    return Embedding(f, m, i)
end

function (e::Embedding)(args...)
    s = enumerate(args)
    f(x) = begin
        x[1]==e.i ? e.f(x[2]...) : x[2]
    end

    return tuple(map(f, s)...)
end

ind(fp::Embedding) = fp.m
outd(fp::Embedding) = fp.m

"""    Sum{C,D} <: Circuit

if c1,c2 are (a,b) and (m,n) circuits respectively Sum(c1,c2) is the
circuit created by applying c1 to arguments 1:m and applying c2 to
arguments m+1:m+1+n.

It is plays the role of disjoint union on sets.
"""
mutable struct Sum{C,D} <: Circuit
    c1::C
    c2::D
end

ind(fp::Sum) = ind(fp.c1) + ind(fp.c2)
outd(fp::Sum) = outd(fp.c1) + outd(fp.c2)

function (s::Sum)(args...)
    m = ind(c1)
    return tuple(s.c1(args[1:m])..., s.c2(args[m+1:end])...)
end

"""    Composite{C,D} <: Circuit

if c1,c2 are (a,b) and (m,n) circuits respectively Composite(c1,c2) is the
circuit created by applying c1 and then applying c2 to the output of c1.

It is plays the role of function composition.
"""
mutable struct Composite{C,D} <: Circuit
    f::C
    g::D
    m::Int
    n::Int
end

function Composite(c1, c2)
    ind(c2) == outd(c1) || throw(DimensionMismatch("circuits domains must match"))
    return Composite(c1, c2, ind(c1), outd(c2))

end

function (c::Composite)(x...)
    return c.g(c.f(x...)...)
end


using Test

@testset "Identity" begin
    id23 = Node(identity, 2,3)
    @assert id23.f == identity
    @assert ind(id23) == 2
    @assert outd(id23) == 3
end

@testset "Dimensions" begin
    id23 = Node(identity, 2,3)
    @test_throws DimensionMismatch id23((1,2))
    id23_z = Node((a,b) -> (a,b,0), 2,3)
    @test id23_z(1,2) == (1,2,0)
    @test_throws DimensionMismatch id23_z(( 1,2 ))
    id23_zz = Node((a,b) -> (a,b,0,0), 2,3)
    @test_throws DimensionMismatch id23_z(( 1,2 ))
end

square(x) = x^2

@testset "Composition" begin
    na = Node((x,y)->x, 2,1)
    @test na(1,2) == 1
    @test na(2,2) == 2
    naa = Node((x,y)->y, 2,1)
    nb = Node((x)->( x, x ), 1,2)
    @test nb(2) == (2,2)
    @test nb(3) == (3,3)
    nab = nb ∘ na
    @test nab.m == 2
    @test nab.n == 2
    @test nab(1,2) == (1,1)
end
@testset "Composites" begin
    na = Node((x,y)->x, 2,1)
    @test na(1,2) == 1
    @test na(2,2) == 2
    naa = Node((x,y)->y, 2,1)
    nb = Node((x)->( x, x ), 1,2)
    @test nb(2) == (2,2)
    @test nb(3) == (3,3)
    nab = Composite( na,nb )
    @show nab
    @test nab.m == 2
    @test nab.n == 2
    @test nab(1,2) == (1,1)
end

@testset "Embedding" begin
    na = Node((x,y)->x, 2,1)
    naa = Node((x,y)->y, 2,1)
    nb = Node((x)->(x, x), 1,2)
    nab = nb ∘ na
    @test nab.m == 2
    @test nab.n == 2
    @test nab(1,2) == (1,1)
    em = embed(x -> x^2, 2,2)
    g = (em ∘ nb)
    @test g(3) == (3, 9)
end
Tupler = Node((x...)->tuple(x), 2,1)
Mapper(f, n) = Node((x...)->map(f, x), n,n)
@testset "Map" begin
    na = Node((x,y)->x, 2,1)
    naa = Node((x,y)->y, 2,1)
    nb = Node((x)->(x, x), 1,2)
    mr = Mapper(sum, 2)
    G = mr ∘ (nb ∘ (Tupler ∘ nb))
    @show c1 = Composite(nb, Tupler)
    @show c2 = Composite(c1, nb)
    @show G2 = Composite(c2, mr)

    @show G.f
    y = G(1)
    @test y == (2,2)

    @show G2.f
    y = G2(1)
    @test y == (2,2)
end


end #module
