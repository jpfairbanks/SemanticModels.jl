using Catlab
using Catlab.Doctrines
using Catlab.Graphics
using Catlab.WiringDiagrams
using Catlab.Programs
import Base.Multimedia: display
import Catlab.Graphics: to_graphviz, LeftToRight
import Base: (==), length, show
using Test

println("Done Importing Catlab")

import Catlab.Doctrines:
  Ob, Hom, dom, codom, compose, ⋅, ∘, id, oplus, otimes, ⊗, ⊕, munit, mzero, braid,
  dagger, dunit, dcounit, mcopy, Δ, delete, ◊, mmerge, ∇, create, □,
  plus, zero, coplus, cozero, meet, top, join, bottom

wd = to_wiring_diagram
draw(d::WiringDiagram) = to_graphviz(add_junctions(d), orientation=LeftToRight, labels=true)
draw(d::HomExpr) = draw(wd(d))

@theory BiproductCategory(Ob, Hom) => Epidemiology(Ob, Hom) begin
    spontaneous(A::Ob, B::Ob)::Hom(A,B)
    transmission(A::Ob, B::Ob)::Hom(A⊗B, B⊗B)
    exposure(A::Ob, B::Ob, C::Ob)::Hom(A⊗B, C⊗B)
    death(A)::Hom(A, munit()) ⊣ A::Ob
end

spontaneous(A::Ports, B::Ports) = singleton_diagram(Epidemiology.Hom, Box(:→, A, B))
exposure(A::Ports, B::Ports, C::Ports) = singleton_diagram(Epidemiology.Hom, Box(:exposure, A⊗B, C⊗B))
death(A::Ports) = singleton_diagram(Epidemiology.Hom, Box(:𝗫, A, Ports([])))
mcopy(A::Ports{Epidemiology.Hom}, Symbol) = implicit_mcopy(A, 2)
mmerge(A::Ports{Epidemiology.Hom}, Symbol) = implicit_mmerge(A, 2)


@syntax FreeEpidemiology(ObExpr, HomExpr) Epidemiology begin
    otimes(A::Ob, B::Ob) = associate_unit(new(A,B), munit)
    otimes(f::Hom, g::Hom) = associate(new(f,g))
    compose(f::Hom, g::Hom) = associate(new(f,g; strict=true))

    pair(f::Hom, g::Hom) = Δ(dom(f)) → (f ⊗ g)
    copair(f::Hom, g::Hom) = (f ⊗ g) → ∇(codom(f))
    proj1(A::Ob, B::Ob) = id(A) ⊗ ◊(B)
    proj2(A::Ob, B::Ob) = ◊(A) ⊗ id(B)
    incl1(A::Ob, B::Ob) = id(A) ⊗ □(B)
    incl2(A::Ob, B::Ob) = □(A) ⊗ id(B)
    otimes(A::Ob, B::Ob) = associate_unit(new(A,B), munit)
    otimes(f::Hom, g::Hom) = associate(new(f,g))
end

@present Disease(FreeEpidemiology) begin
    S::Ob
    E::Ob
    I::Ob
    R::Ob
end

S,E,I,R = generators(Disease)
draw(spontaneous(E,I)⋅spontaneous(I,R)⊗(spontaneous(E,I)))
sei = compose(exposure(S,I,E), otimes(spontaneous(E,I), id(I)), mmerge(I))
draw(sei)
seir = sei⋅Δ(I)⋅(id(I)⊗spontaneous(I, R))
draw(seir)
seir2 = compose(mcopy(S)⊗id(I), id(S)⊗seir)
draw(seir2)

draw(death(S))

d = @program Disease (s::S, e::E, i::I) begin
    e1, i1 = exposure{S,I,E}(s,i)
    i2 = spontaneous{E,I}(e1)
    e = [e, e1]
    e_out = spontaneous{E,E}(e)
    i1 = [i1, i2]
    r = spontaneous{I,R}(i1)
    s_out = spontaneous{S,S}(s)
    return s_out, e_out, spontaneous{I,I}(i1)
end
draw(d)

draw(d⋅d)

seirdef = to_hom_expr(FreeEpidemiology, d)
try
    add_definition!(Disease, :seir, seirdef)
catch
    println("INFO: definition already added.")
end

# if the disease is fatal, we need to add a death component
seird = @program Disease (s::S, e::E, i::I) begin
    e1, i1 = exposure{S,I,E}(s,i)
    i2 = spontaneous{E,I}(e1)
    e = [e, e1]
    e_out = spontaneous{E,E}(e)
    i1 = [i1, i2]
    r = spontaneous{I,R}(i1)
    s_out = spontaneous{S,S}(s)
    death{I}(i1)
    return s_out, e_out, spontaneous{I,I}(i1)
end
#TODO: This does not get translated correctly, bug?
seirddef = to_hom_expr(FreeEpidemiology, seird)
try
    add_definition!(Disease, :seird, seirddef)
catch
    println("INFO: definition already added.")
end

seirgen = generator(Disease, :seir)
seirdgen = generator(Disease, :seird)


ncities(city,n::Int) = compose([city for i in 1:n]...)
city³ = ncities(seirgen, 3)
draw(city³)

dcity³ = wd(city³)
dc3 = substitute(dcity³, box_ids(dcity³), [d,d,d])
@show dc3 == ncities(d, 3)
draw(dc3)

import Base: repeat
repeat(d::WiringDiagram, n::Int) = compose([d for i in 1:n]...)
repeat(d::FreeEpidemiology.Hom, n::Int) = compose([d for i in 1:n]...)

draw(ncities(seirdgen, 3))
draw(repeat(seird, 3))

draw(seirddef)
#
# using TikzPictures
# using Catlab.Graphics.TikZWiringDiagrams
# using Convex
# using SCS
#
# to_tikz(seirddef, labels=true)
println("Loading SemanticModels")
using Petri
using SemanticModels
using SemanticModels.ModelTools.PetriModels
using SemanticModels.ModelTools.OpenModels
using SemanticModels.ModelTools.OpenPetris
using SemanticModels.ModelTools.CategoryTheory
import SemanticModels.ModelTools.CategoryTheory: undecorate, ⊔
pushout = CategoryTheory.pushout
undecorate(c::Cospan) = Cospan(undecorate(left(c)), undecorate(right(c)))
undecorate(c::Span) = Span(undecorate(left(c)), undecorate(right(c)))

# function ⊔(f::FinSetMorph, g::FinSetMorph)
#     Y = codom(f) ⊔ codom(g)
#     h = f.fun ⊔ (g.fun .+ codom(f))
#     FinSetMorph(Y, h)
# end

show(io::IO, f::FinSetMorph) = begin
    x = length(dom(f))
    y = length(codom(f))
    print(io, "$x→$y($(f.fun))")
end
show(io::IO, f::Decorated) = begin
    d = f.d[1]
    m = f.f
    print(io, "Decorated($m, $d)")
end

show(io::IO, f::Cospan) = begin
    print(io, "Cospan(l=")
    print(io, left(f))
    print(", r=")
    print(io, right(f))
    print(")")
end
function show(io::IO, z::Petri.Model)
    X, Y = z.S, z.Δ
    # compact = get(io, :compact, true)
    compact = false
    if compact
        x,y = length(X), length(Y)
        print(io,"Model(∣S∣=$x,∣Δ∣=$y)")
    else
        print(io,"Model(S=$X, Δ=[")
        for i in Y
            print(io, "$i")
        end
        print(io,"]")
    end
end


# Petri.Model(r::UnitRange, x) = Petri.Mode(collect(r), x, missing, missing)
struct OpenPetriDom
  N::Int
end

println("Done Loading")
==(X::OpenPetriDom, Y::OpenPetriDom) = (X.N==Y.N)

# TODO: The Model Toolkit interface was dumb, let's just do everything with integer variable numbers
# SEIR is Petri.Mode([1,2,3], [([1], [2]), ([1,2], [3]), ([3],[2])])
IntPetriModel(S, Δ) = Petri.Model(S, Δ, [],[])
NullModel(n::Int) = IntPetriModel(collect(1:n), Vector{Tuple{Vector{Int}, Vector{Int}}}(), missing, missing)

function tcat(v::Vector{Tuple{Vector{Int},Vector{Int}}},
     w::Vector{Tuple{Vector{Int},Vector{Int}}}, shift::Int)
    w′ = Vector{Tuple{Vector{Int}, Vector{Int}}}()
    for t in w
        push!(w′, (map(x->x+shift, t[1]),
         map(x->x+shift, t[2])))
    end
    return vcat(v,w′)
end

function otimes_ipm(f::OpenModel, g::OpenModel)
    @show M = f.model
    @show N = g.model
    domcat(v::Vector{Int}, w::Vector{Int}) = vcat(v, w.+length(M.S))
    @show newdom = domcat(f.dom, g.dom)
    @show newcodom = domcat(f.codom, g.codom)
    @show newS = domcat(M.S, N.S)
    @show M
    @show M.S
    @show M.Δ
    @show newΔ = tcat(M.Δ, N.Δ, length(M.S))
    return OpenModel(newdom, IntPetriModel(newS, newΔ), newcodom)
end

# TODO: integrate this method with the one above. Multiple dispatch is hard.
function otimes_ipm(f::PetriModel, g::PetriModel)
    @show M = f.model
    @show N = g.model
    domcat(v, w) = vcat(v, w.+length(M.S))
    @show newS = domcat(M.S, N.S)
    @show M
    @show M.S
    @show M.Δ
    @show newΔ = tcat(M.Δ, N.Δ, length(M.S))
    return PetriModel(Petri.Model(newS, newΔ, missing, missing))
end

function (f::FinSetMorph)(gModel::G) where G <: PetriModel
    g = gModel.model
    @show dom(f)
    @show g.S
    length(dom(f)) == length(g.S) || throw(DomainError(g.S))
    ϕ = func(f)
    #outS = Array{Operation}(undef, length(Set(ϕ.m.fun)))
    outS = 1:length(Set(ϕ.m.fun))
    outΔ = Vector{Tuple{Vector{Int}, Vector{Int}}}()
    for t in g.Δ
        ins = ϕ.(t[1])
        outs = ϕ.(t[2])
        push!(outΔ, (ins,outs))
     end
    out = deepcopy(g)
    PetriModel(Petri.Model(outS, outΔ, out.Λ, out.Φ))
end

compose(f::FinSetMorph, g::FinSetMorph) = FinSetMorph(g.codom, func(g).(f.fun))
⋅(f::FinSetMorph, g::FinSetMorph) = compose(f,g)

function compose_pushout(cs₁, cs₂)
    @show right(cs₁)
    @show left(cs₂)
    s = Span(left(cs₂), right(cs₁))
    cs′ = pushout(undecorate(s))
    # the quotient operator from X+Y --> X +_B Y
    q = (left(cs′) ⊔ right(cs′))
    @show q.fun
    coproduct = map(x->otimes_ipm(x[1], x[2]), zip(right(s).d, left(s).d))[1]
    sum = q(coproduct)
    #TODO: figure out legs of new cospan
    f′ = left(cs₁).f ⋅ left(cs′)
    g′ = right(cs₂).f ⋅ right(cs′)
    f′ = Decorated(f′,sum)
    g′ = Decorated(g′, sum)
    return Cospan(f′, g′)
end




println("Defining Our Instance")

struct FinSet
    n::UnitRange{Int}
end

FinSet(n::Int) = FinSet(1:n)

NullModel(n::Int) = PetriModel(Petri.Model(collect(1:n), Vector{Tuple{Vector{Int},Vector{Int}}}(), missing, missing))
length(X::FinSet) = length(X.n)
==(X::FinSet, Y::FinSet) = X.n == Y.n

struct PetriCospan
    f::Cospan
end


id(::Type{FinSetMorph}, n::Int) = FinSetMorph(1:n, 1:n)

@instance Epidemiology(FinSet, PetriCospan) begin

  dom(f::PetriCospan) = FinSet(dom(left(f.f)))
  codom(f::PetriCospan) = FinSet(dom(right(f.f)))

  compose(f::PetriCospan, g::PetriCospan) = begin
      @show typeof(f.f)
      @show typeof(g.f)
      PetriCospan(compose_pushout(f.f,g.f))
  end

  id(X::FinSet) = PetriCospan(Cospan(Decorated(id(FinSetMorph, length(X.n)),
                                        NullModel(length(X.n))),
                              Decorated(id(FinSetMorph, length(X.n)),
                                        NullModel(length(X.n)))))
  otimes(X::FinSet, Y::FinSet) = FinSet(length(X) + length(Y))

  otimes(f::PetriCospan, g::PetriCospan) = begin
      df = left(f.f).d[1]
      dg = left(g.f).d[1]
      f, g = undecorate(f.f), undecorate(g.f)
      Y₁ = codom(left(f)) ⊔ codom(left(g))
      h₁ = vcat(left(f).fun, left(g).fun .+ length(codom(left(f))))
      l = FinSetMorph(Y₁, h₁)
      Y = codom(right(f)) ⊔ codom(right(g))
      h = vcat(right(f).fun, right(g).fun .+ length(codom(right(f))))
      r = FinSetMorph(Y,h)
      d = otimes_ipm(df, dg)
      PetriCospan(Cospan(Decorated(l, d), Decorated(r, d)))
  end


  munit(::Type{FinSet}) = FinSet(0)
  braid(X::FinSet, Y::FinSet) = begin
      Z = otimes(X,Y).n
      d = NullModel(Z)
      M,N = length(X), length(Y)
      f₁ = Decorated(FinSetMorph(Z, Z), d)
      f₂ = Decorated(FinSetMorph(Z, vcat(N:N+M, 1:N)), d)
      return PetriCospan(Cospan(f₁, f₂))
  end

  mcopy(X::FinSet) = begin
      d = NullModel(length(X))
      f = Decorated(FinSetMorph(X.n, collect(X.n)), d)
      g = Decorated(FinSetMorph(X.n, kron(ones(Int, 2), X.n)), d)
      PetriCospan(Cospan(f,g))
  end

  mmerge(X::FinSet) = begin
      d = NullModel(length(X))
      f = Decorated(FinSetMorph(X.n, X.n), d)
      g = Decorated(FinSetMorph(X.n, kron(ones(Int, 2), X.n)), d)
      PetriCospan(Cospan(g,f))
  end

  create(X::FinSet) = begin
      d = NullModel(length(X))
      f = Decorated(FinSetMorph(X.n, Int[]), d)
      g = Decorated(id(FinSetMorph, length(X)), d)
      PetriCospan(Cospan(f,g))
  end

  delete(X::FinSet) = begin
      d = NullModel(length(X))
      f = Decorated(FinSetMorph(X.n, Int[]), d)
      g = Decorated(id(FinSetMorph, length(X)), d)
      PetriCospan(Cospan(g,f))
  end

  pair(f::PetriCospan, g::PetriCospan) = compose(mcopy(dom(f)), otimes(f,g))
  copair(f::PetriCospan, g::PetriCospan) = compose(otimes(f,g), mmerge(codom(f)))
  proj1(A::FinSet,B::FinSet) = otimes(id(A), delete(B))
  proj2(A::FinSet,B::FinSet) = otimes(delete(A), id(B))

  incl1(A::FinSet,B::FinSet) = otimes(id(A), create(B))
  incl2(A::FinSet,B::FinSet) = otimes(create(A), id(B))

  spontaneous(A::FinSet, B::FinSet) = begin
      M, N = length(A), length(B)
      S = M+N
      M == N || error("Length of A and length of B must be equal")
      d = PetriModel(IntPetriModel(1:S, [([i], [M+i]) for i in 1:M]))
      f = Decorated(FinSetMorph(1:S, 1:M), d)
      g = Decorated(FinSetMorph(1:S, (M+1):S), d)
      PetriCospan(Cospan(f,g))
  end

  transmission(A::FinSet, B::FinSet) = begin
      M, N = length(A), length(B)
      length(A) == 1 || error("Currently only supports one transmission variable")
      d = PetriModel(IntPetriModel([1, 2], [([1, 2], [2,2])]))
      f = Decorated(id(FinSetMorph, M), d)
      g = Decorated(id(FinSetMorph, M), d)
      PetriCospan(Cospan(f,g))
  end
  exposure(A::FinSet, B::FinSet, C::FinSet) = begin
      length(C) == 1 || error("Currently only supports one exposure variable")
      d = PetriModel(IntPetriModel([1, 2, 3], [([1, 2], [3,2])]))
      f = Decorated(FinSetMorph(1:3, [1,2]), d)
      g = Decorated(FinSetMorph(1:3, [3,2]), d)
      PetriCospan(Cospan(f,g))
  end
  death(A::FinSet) = begin
      M = length(A)
      d = PetriModel(IntPetriModel(1:2M, [([i], [M+i]) for i in 1:M]))
      f = Decorated(FinSetMorph(1:2M, 1:M), d)
      g = Decorated(FinSetMorph(1:2M, Int[]), d)
      PetriCospan(Cospan(f,g))
  end
end

println("Testing CT API")
f = FinSetMorph(1:4, [1,2,3])
g = FinSetMorph(1:4, [4,1])
f′ = FinSetMorph(1:3, [2,3])
g′ = FinSetMorph(1:3, [1,2])
Cospan(f,g), Cospan(f′, g′)

pushout(Span(g,f′))


spon = PetriModel(Petri.Model([1,2], [([1], [2])], missing, missing))
f = Decorated(FinSetMorph(1:2, [2]), [spon])
g = Decorated(FinSetMorph(1:2, [1]), [spon])
s = Span(g,f)

cs = pushout(undecorate(s))



f = FinSetMorph(1:2, [2])
g = FinSetMorph(1:2, [1])
s = Span(g,f)

cs = CategoryTheory.pushout(s)


f₁ = Decorated(FinSetMorph(1:2, [1]), spon)
g₁ = Decorated(FinSetMorph(1:2, [2]), spon)

f₂ = Decorated(FinSetMorph(1:2, [1]), spon)
g₂ = Decorated(FinSetMorph(1:2, [2]), spon)

cs₁ = Cospan(f₁, g₁)
cs₂ = Cospan(f₂, g₂)

@testset "Spon Quotient" begin
spon2 = otimes_ipm(spon, spon)
spon2quo = (left(cs)⊔right(cs))(spon2)
@test spon2quo.model.S == 1:3
@test spon2quo.model.Δ == [([1], [2]),([2], [3])]
end


@testset "compose_pushout" begin
@test (left(cs)⊔right(cs)).fun == [1,2,2,3]
sponspon = compose_pushout(cs₁, cs₂)
@test sponspon.f.f.codom == sponspon.g.f.codom
@test sponspon.f.f.fun == [1]
@test sponspon.g.f.fun == [3]
# @test sponspon.f.f == FinSetMorph(1:3, [1])
# @test sponspon.g.f == FinSetMorph(1:3, [3])
@test sponspon.g.d == sponspon.f.d
end
@testset "Merge and Copy" begin
    m4 = mmerge(FinSet(4))
    @test dom(m4.f.f.f) == 1:8
    @test codom(m4.f.f.f) == 1:4
    @test m4.f.f.d[1].model.S == 1:4
    @test m4.f.f.d[1].model.Δ == []
    m4 = mcopy(FinSet(4))
    @show m4
    @test dom(m4.f.f.f) == 1:4
    @test codom(m4.f.f.f) == 1:4
    @test dom(m4.f.g.f) == 1:8
    @test codom(m4.f.g.f) == 1:4
    @test m4.f.f.d[1].model.S == 1:4
    @test m4.f.f.d[1].model.Δ == []
    X = FinSet(1)
    m4 = mcopy(X)⋅(mcopy(X)⊗mcopy(X))
    @test dom(left(m4.f)) == 1:1
    @test codom(left(m4.f)) == 1:1
    @test dom(right(m4.f)) == 1:4
    @test codom(right(m4.f)) == 1:1
end

# states(f::OpenModel) = f.model.S
# transitions(f::OpenModel) = f.model.Δ
# @test states(dsq) == [1,2,3,4]
# @test length(transitions(dsq)) == 2
# @test states(otimes_ipm(dsq, dsq)) == 1:8
#
# dc = otimes_ipm(dth, create(FinSet(1)))
# @test states(dc) == 1:3
# @test transitions(dc) == [([1], [2])]
#
# dcc = otimes_ipm(dc, create(FinSet(1)))
# @test states(dcc) == 1:4
# @test transitions(dcc) == [([1], [2])]
#
# dccd = otimes_ipm(dcc, death(FinSet(1)))
# @test states(dccd) == 1:6
# @test transitions(dccd) == [([1], [2]), ([5],[6])]

#function compose_ipm(f::OpenModel, g::OpenModel)

@testset "Two Chains" begin
    chain = Cospan(Decorated(FinSetMorph(1:2, [1]), spon), Decorated(FinSetMorph(1:2, [2]), spon))
    twochain = compose_pushout(chain, chain)
    @test dom(left(twochain)) == 1:1
    @test codom(left(twochain)) == 1:3
    @test left(twochain).f.fun == [1]
    @test dom(right(twochain)) == 1:1
    @test codom(right(twochain)) == 1:3
    @test right(twochain).f.fun == [3]
    threechain = compose_pushout(twochain, chain)
end


@testset "Create Death" begin
    dth = death(FinSet(1))
    crt = create(FinSet(1))
    r = right(crt.f).f
    @test r.fun == [1]
    l = left(dth.f).f
    @test l.fun == [1]
    cs = pushout(Span(r, l))
    @test dom(left(cs)) == 1:2
    @test dom(right(cs)) == 1:1
    @test codom(left(cs)) == 1:2
    @test codom(right(cs)) == 1:2

    crtdth = compose_pushout(crt.f, dth.f)
    @show crtdth
    @test dom(left(crtdth).f) == 1:0
    @test codom(left(crtdth).f) == 1:2
    @test left(crtdth).f.fun == Int[]
end

@testset "Death Sq" begin
    dth = death(FinSet(1))
    dsq = otimes(dth, dth)
    @test left(dsq.f).f.fun == [1,3]
    @test dsq.f.f.d[1].model.S == 1:4
    @test dsq.f.f.d[1].model.Δ == [([1],[2]), ([3], [4])]
    @test dom(dsq.f.f.f) == [1,2]
    @test dom(dsq.f.g.f) == 1:0
    @test codom(dsq.f.f.f) == 1:4
    @test codom(dsq.f.g.f) == 1:4
    @test dsq.f.f.f.fun == [1,3]
    @test dsq.f.g.f.fun == Int[]
end

@testset "Exposure" begin
    exp = exposure(FinSet(1), FinSet(1), FinSet(1))
    T = [([1, 2], [3, 2]), ([3, 2], [4, 2])]
    @show e² = exp⋅exp
    @test left(e².f).d[1].model.Δ == T
    @test dom(left(e².f).f) == 1:2
    @test codom(left(e².f).f) == 1:4
    @test dom(right(e².f).f) == 1:2
    @test codom(right(e².f).f) == 1:4
end

@testset "Spontaneous" begin
    X = FinSet(1)
    f = otimes(mcopy(X), id(X))
    @test dom(left(f.f).f) == 1:2
    @test codom(left(f.f).f) == 1:2
    @test left(f.f).f.fun == 1:2
    @test right(f.f).f.fun == [1,1,2]
    @test dom(right(f.f).f) == 1:3
    @test codom(right(f.f).f) == 1:2
    g = (id(X)⊗spontaneous(X,X)⊗id(X))
    @test dom(left(g.f).f) == 1:3
    @test codom(left(g.f).f) == 1:4
    @test left(g.f).f.fun == [1,2,4]
    @test right(g.f).f.fun == [1,3,4]
    @test dom(right(g.f).f) == 1:3
    @test codom(right(g.f).f) == 1:4

    h = (id(X)⊗mmerge(X))
    @show h
    @test dom(left(h.f).f) == 1:3
    @test codom(left(h.f).f) == 1:2
    @test left(h.f).f.fun == [1,2,2]
    @test right(h.f).f.fun == [1,2]
    @test dom(right(h.f).f) == 1:2
    @test codom(right(h.f).f) == 1:2

    m = f⋅g⋅h
    @show m
    @test dom(left(m.f).f) == 1:2
    @test codom(left(m.f).f) == 1:2
    @test left(m.f).f.fun == [1,2]
    @test right(m.f).f.fun == [1,2]
    @test dom(right(m.f).f) == 1:2
    @test codom(right(m.f).f) == 1:2
end
