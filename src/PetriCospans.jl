module PetriCospans

using Catlab
using Catlab.Doctrines
using Catlab.WiringDiagrams
# using Catlab.Programs
import Base: (==), length, show
using Petri
using ..PetriModels
using ..CategoryTheory
import ..CategoryTheory: undecorate, ⊔

import Catlab.Doctrines:
  Ob, Hom, dom, codom, compose, ⋅, ∘, id, oplus, otimes, ⊗, ⊕, munit, mzero, braid,
  dagger, dunit, dcounit, mcopy, Δ, delete, ◊, mmerge, ∇, create, □,
  plus, zero, coplus, cozero, meet, top, join, bottom

export Epidemiology, FreeEpidemiology, spontaneous, exposure, death,
  IntPetriModel, NullModel, FinSet, PetriCospan

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



# TODO: The Model Toolkit interface was dumb, let's just do everything with integer variable numbers
# SEIR is Petri.Mode([1,2,3], [([1], [2]), ([1,2], [3]), ([3],[2])])
IntPetriModel(S, Δ) = Petri.Model(S, Δ)
IntPetriModel(S, Δ, λ, ϕ) = Petri.Model(S, Δ, λ, ϕ)
NullModel(n::Int) = PetriModel(IntPetriModel(collect(1:n), Vector{Tuple{Vector{Int}, Vector{Int}}}()))

function tcat(v::Vector{Tuple{Vector{Int},Vector{Int}}},
     w::Vector{Tuple{Vector{Int},Vector{Int}}}, shift::Int)
    w′ = Vector{Tuple{Vector{Int}, Vector{Int}}}()
    for t in w
        push!(w′, (map(x->x+shift, t[1]),
         map(x->x+shift, t[2])))
    end
    return vcat(v,w′)
end

# TODO: integrate this method with the one above. Multiple dispatch is hard.
function otimes_ipm(f::PetriModel, g::PetriModel)
    M = f.model
    N = g.model
    domcat(v, w) = vcat(v, w.+length(M.S))
    newS = domcat(M.S, N.S)
    newΔ = tcat(M.Δ, N.Δ, length(M.S))
    return PetriModel(Petri.Model(newS, newΔ))
end

compose(f::FinSetMorph, g::FinSetMorph) = FinSetMorph(g.codom, func(g).(f.fun))
⋅(f::FinSetMorph, g::FinSetMorph) = compose(f,g)

function compose_pushout(cs₁, cs₂)
    s = Span(left(cs₂), right(cs₁))
    cs′ = pushout(undecorate(s))
    # the quotient operator from X+Y --> X +_B Y
    q = (left(cs′) ⊔ right(cs′))
    coproduct = map(x->otimes_ipm(x[1], x[2]), zip(right(s).d, left(s).d))[1]
    sum = q(coproduct)
    f′ = left(cs₁).f ⋅ left(cs′)
    g′ = right(cs₂).f ⋅ right(cs′)
    f′ = Decorated(f′,sum)
    g′ = Decorated(g′, sum)
    return Cospan(f′, g′)
end

struct FinSet
    n::UnitRange{Int}
end

FinSet(n::Int) = FinSet(1:n)
length(X::FinSet) = length(X.n)
==(X::FinSet, Y::FinSet) = X.n == Y.n
id(::Type{FinSetMorph}, n::Int) = FinSetMorph(1:n, 1:n)
struct PetriCospan
    f::Cospan
end

@instance Epidemiology(FinSet, PetriCospan) begin

  dom(f::PetriCospan) = FinSet(dom(left(f.f)))
  codom(f::PetriCospan) = FinSet(dom(right(f.f)))

  compose(f::PetriCospan, g::PetriCospan) = begin
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
end #module PetriCospans
