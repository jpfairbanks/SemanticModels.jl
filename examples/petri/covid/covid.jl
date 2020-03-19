using Catlab
using Catlab.Doctrines
using Catlab.Graphics
using Catlab.WiringDiagrams
using Catlab.Programs
import Base.Multimedia: display
import Catlab.Graphics: to_graphviz, LeftToRight
import Base: (==)
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
pushout = CategoryTheory.pushout

struct OpenPetriDom
  N::Int
end

println("Done Loading")
==(X::OpenPetriDom, Y::OpenPetriDom) = (X.N==Y.N)

# TODO: The Model Toolkit interface was dumb, let's just do everything with integer variable numbers
# SEIR is Petri.Mode([1,2,3], [([1], [2]), ([1,2], [3]), ([3],[2])])
IntPetriModel(S, Δ) = Petri.Model(S, Δ, [],[])
NullModel(n::Int) = IntPetriModel(collect(1:n), Vector{Tuple{Vector{Int}, Vector{Int}}}())

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
    domcat(v::Vector{Int}, w::Vector{Int}) = vcat(v, w.+length(M.S))
    @show newS = domcat(M.S, N.S)
    @show M
    @show M.S
    @show M.Δ
    @show newΔ = tcat(M.Δ, N.Δ, length(M.S))
    return PetriModel(Petri.Model(newS, newΔ, missing, missing))
end

println("Defining Our Instance")

@instance Epidemiology(OpenPetriDom, OpenModel) begin
  @import ⊗

  dom(f::OpenModel) = OpenPetriDom(length(f.dom))
  codom(f::OpenModel) = OpenPetriDom(length(f.codom))

  compose(f::OpenModel, g::OpenModel) = OpenPetris.compose_om(f,g)
  id(X::OpenPetriDom) = OpenPetris.eye(length(X.N))

  otimes(X::OpenPetriDom, Y::OpenPetriDom) = OpenModel(X.N + Y.N)
  otimes(f::OpenModel, g::OpenModel) = OpenPetris.otimes_ipm(f,g)
  munit(::Type{OpenPetriDom}) = OpenPetriDom(0)
  braid(X::OpenPetriDom, Y::OpenPetriDom) =
    OpenModel(vcat(collect(1:X.N),collect(1:Y.N).+X.N),
              PetriModel(NullPetri(X.N+Y.N)),
              vcat(collect(1:Y.N).+X.N, collect(1:X.N)))
  mcopy(X::OpenPetriDom) = OpenModel([1], NullModel(1), ones(Int, X))
  mmerge(X::OpenPetriDom) = OpenModel(ones(Int, X.N), NullModel(1), [1])
  create(X::OpenPetriDom) = OpenModel(Int[], NullModel(X.N), collect(1:X.N))
  delete(X::OpenPetriDom) = OpenModel(collect(1:X.N), NullModel(X.N), Int[])
  pair(f::OpenModel, g::OpenModel) = compose(mcopy(dom(f)), otimes(f,g))
  copair(f::OpenModel, g::OpenModel) = compose(otimes(f,g), mmerge(codom(f)))
  proj1(A::OpenPetriDom,B::OpenPetriDom) = otimes(id(A), delete(B))
  proj2(A::OpenPetriDom,B::OpenPetriDom) = otimes(delete(A), id(B))

  incl1(A::OpenPetriDom,B::OpenPetriDom) = otimes(id(A), create(B))
  incl2(A::OpenPetriDom,B::OpenPetriDom) = otimes(create(A), id(B))

  spontaneous(A::OpenPetriDom, B::OpenPetriDom) = begin
     OpenModel([1], IntPetriModel([1,2],
                                      [([1], [2])]),
                                      [2])
  end
  transmission(A::OpenPetriDom, B::OpenPetriDom) = begin
     OpenModel([1,2], IntPetriModel([1,2],
                                      [([1,2], [2,2])]),
                                      [2,2])
  end
  exposure(A::OpenPetriDom, B::OpenPetriDom, C::OpenPetriDom) = begin
     OpenModel([1,2], IntPetriModel([1, 2],
                                      [([1, 2], [3,2])]),
                                      [3,2])
  end
  death(A::OpenPetriDom) = begin
     OpenModel([1], IntPetriModel([1,2],
                                      [([1], [2])]),
                                      Int[])
  end
end


dth = death(OpenPetriDom(1))

create(OpenPetriDom(1))


m1 = Petri.Model([1,2], [([1],[2])], [],[])




states(f::OpenModel) = f.model.S
transitions(f::OpenModel) = f.model.Δ
dsq = otimes_ipm(dth, dth)
@test states(dsq) == [1,2,3,4]
@test length(transitions(dsq)) == 2
@test states(otimes_ipm(dsq, dsq)) == 1:8

dc = otimes_ipm(dth, create(OpenPetriDom(1)))
@test states(dc) == 1:3
@test transitions(dc) == [([1], [2])]

dcc = otimes_ipm(dc, create(OpenPetriDom(1)))
@test states(dcc) == 1:4
@test transitions(dcc) == [([1], [2])]

dccd = otimes_ipm(dcc, death(OpenPetriDom(1)))
@test states(dccd) == 1:6
@test transitions(dccd) == [([1], [2]), ([5],[6])]

#function compose_ipm(f::OpenModel, g::OpenModel)

println("Testing CT API")
f = FinSetMorph(1:4, [1,2,3])
g = FinSetMorph(1:4, [4,1])
f′ = FinSetMorph(1:3, [2,3])
g′ = FinSetMorph(1:3, [1,2])
Cospan(f,g), Cospan(f′, g′)

pushout(Span(g,f′))


spon = PetriModel(spontaneous(OpenPetriDom(1), OpenPetriDom(1)).model)
f = Decorated(FinSetMorph(1:2, [2]), [spon])
g = Decorated(FinSetMorph(1:2, [1]), [spon])
s = Span(g,f)

cs = pushout(undecorate(s))

function (f::FinSetMorph)(gModel::G) where G <: PetriModel
    g = gModel.model
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

spon2 = otimes_ipm(spon, spon)
spon2quo = (left(cs)⊔right(cs))(spon2)
@test spon2quo.model.S == 1:3
@test spon2quo.model.Δ == [([1], [2]),([2], [3])]


f = FinSetMorph(1:2, [2])
g = FinSetMorph(1:2, [1])
s = Span(g,f)

cs = CategoryTheory.pushout(s)

@test (left(cs)⊔right(cs)).fun == [1,2,2,3]

f₁ = Decorated(FinSetMorph(1:2, [1]), spon)
g₁ = Decorated(FinSetMorph(1:2, [2]), spon)

f₂ = Decorated(FinSetMorph(1:2, [1]), spon)
g₂ = Decorated(FinSetMorph(1:2, [2]), spon)

cs₁ = Cospan(f₁, g₁)
cs₂ = Cospan(f₂, g₂)

compose(f::FinSetMorph, g::FinSetMorph) = FinSetMorph(g.codom, func(g).(f.fun))
⋅(f::FinSetMorph, g::FinSetMorph) = compose(f,g)

function compose_pushout(cs₁, cs₂)
    @show right(cs₁)
    @show right(cs₂)
    s = Span(left(cs₁), right(cs₂))
    cs′ = pushout(undecorate(s))
    # the quotient operator from X+Y --> X +_B Y
    q = (left(cs′)⊔right(cs′))
    @show q.fun
    coproduct = map(x->otimes_ipm(x[1], x[2]), zip(left(s).d, right(s).d))[1]
    #coproduct = otimes_ipm(decorations(cs₁)[1], decorations(cs₂)[1])
    sum = q(coproduct)
    @show sum
    #TODO: figure out legs of new cospan
    println("forming legs")
    @show left(cs₁)
    @show left(cs₁).f
    @show left(cs′)
    f′ = left(cs₁).f ⋅ left(cs′)
    @show f′
    g′ = right(cs₂).f ⋅ right(cs′)
    @show g′
    f′ = Decorated(f′,sum)
    g′ = Decorated(g′, sum)
    return Cospan(f′, g′)
end

sponspon = compose_pushout(cs₁, cs₂)
@test sponspon.f.f.codom == sponspon.g.f.codom
@test sponspon.f.f.fun == [1]
@test sponspon.g.f.fun == [3]
# @test sponspon.f.f == FinSetMorph(1:3, [1])
# @test sponspon.g.f == FinSetMorph(1:3, [3])
@test sponspon.g.d == sponspon.f.d
