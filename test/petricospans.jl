module TestPetriCospans

using Catlab
using Catlab.Doctrines
using Catlab.WiringDiagrams
using Catlab.Programs
import Base.Multimedia: display
import Base: (==), length, show
using Test
using Petri
using SemanticModels.CategoryTheory
import SemanticModels.CategoryTheory: undecorate, ⊔
using SemanticModels.PetriModels
using SemanticModels.PetriCospans
import SemanticModels.PetriCospans: otimes_ipm, compose_pushout

import Catlab.Doctrines:
  Ob, Hom, dom, codom, compose, ⋅, ∘, id, oplus, otimes, ⊗, ⊕, munit, mzero, braid,
  dagger, dunit, dcounit, mcopy, Δ, delete, ◊, mmerge, ∇, create, □,
  plus, zero, coplus, cozero, meet, top, join, bottom

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

X = FinSet(1)
@testset "Functor" begin
    Fsei = compose(exposure(X,X,X), otimes(spontaneous(X,X), id(X)), mmerge(X))
    @test left(Fsei.f).d[1].model.S == 1:3
    @test left(Fsei.f).d[1].model.Δ == [([1,2], [3,2]), ([3], [2])]
    @show dom(right(Fsei.f).f) == 1:1
    @show codom(right(Fsei.f).f) == 1:3
    @show right(Fsei.f).f.fun == [2]


    Fseir = Fsei ⋅ spontaneous(X,X)
    @show Fseir
    @test left(Fseir.f).d[1].model.S == 1:4
    # @test left(Fsei.f).d[1].model.Δ == [([1,2], [3,2]), ([3], [2])]
    @show dom(right(Fseir.f).f) == 1:1
    @show codom(right(Fseir.f).f) == 1:4
    @show right(Fseir.f).f.fun == [4]


end
end  # module TestPetriCospans
