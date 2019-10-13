module Malaria
using Petri
using MacroTools
import MacroTools: postwalk, striplines
using ModelingToolkit
import ModelingToolkit: Constant
import Base: ==, ∈
using Catlab.Doctrines
import Catlab.Doctrines: ⊗, compose, otimes
using Catlab.WiringDiagrams
using Catlab.Graphics
using SemanticModels.ModelTools.WiringDiagrams
# using Petri.OpenModels
using Catlab.Graphics.Graphviz
import Catlab.Graphics.Graphviz: Graph


@variables S, I, R, Sm, Im
# people recover from and then lose their immunity to malaria
rec = Petri.Model([S,I,R], [(I,R), (R, S)])
# mosquitos recover from malaria, but are not immune
recm = Petri.Model([Sm,Im], [(Im,Sm)])

infect = Petri.Model([S,I,Im], [(S+Im, I+Im)])
infectm = Petri.Model([Sm,I,Im], [(Sm+I, I+Im)])



f = OpenModel([S,I,R], rec, [S,I])
g = OpenModel([Sm,Im], recm, Operation[])

h1 = OpenModel([S,I], infect, [I, Im])
h2 = OpenModel([I,Im], infectm, [I])

# malaria = (f⊗g) ⊚ (h1⊚h2)

# @variables X, Y, k
# lv = Petri.Model([X,Y],
#                  [(X,2X),
#                   (Y, Constant(0)),
#                   (X+Y, (k*Y))
#                   ])

# OpenModel([X], lv, [Y]) ⊚ OpenModel([Y], lv, [X])

# NullModel(k) = Petri.Model([Operation(:S, Expression[Constant(i)]) for i in 1:k],[])
# Id(k) = OpenModel(1:k, NullModel(k), 1:k)
# σ2 = OpenModel([2,1], NullModel(2), [2,1])
# birth   = Petri.Model([X], [(X, 2X)])
# death   = Petri.Model([X], [(X, Constant(0))])
# pred(k) = Petri.Model([X,Y], [(X+Y, kY)])

# f    = OpenModel([1], birth, [1])
# g    = OpenModel([1], death, [1])
# h(k) = OpenModel([1,2], pred(k), [1,2])

# onsecond = OpenModel([1,2], NullModel(2), [2])
# lotka(k) = f ⊗ g ⊚ h(k)
# # combine predation onto LV where the predator of LV is the new prey
# # eg. sharks eat fish that eat smaller fish
# # chain(k,n) = lotka(k) ⊚ onsecond ⊚ OpenModel([1], pred(n), [2])
# chain(k,n) = (lotka(k) ⊗ Id(1)) ⊚ (Id(1) ⊗ pred(n))

# # combine predation onto LV where the predator of LV is the new predator
# # eg. Wolves hunt rabbits and sheep
# # twoprey(k,n) = lotka(k) ⊚ onsecond ⊚ OpenModel([2], pred(n), [1,2])
# twoprey(k,n) = (lotka(k) ⊗ Id(1)) ⊚ (Id(1) ⊗ (σ2 ⊚ pred(n) ⊚ σ2))

X = Petri.X
println("\nSpontaneous reaction spontaneous = X₁→X₂")
spontaneous = OpenModel([1,2], Model([1,2], [(X[1],X[2])]), [1,2])
println("\nParallel reaction parallel = spontaneous ⊗ spontaneous = X₁→X₂, X₃→X₄")
parallel = otimes(spontaneous, spontaneous)
println("\nInfection reaction infect = X₁+X₂→ 2X₂")
infect = OpenModel([1,2], Model([1,2], [(X[1]+X[2], 2*X[2])]), [1,2])
println("\nParallel Infections reactions infect ⊗ infect = X₁+X₂→ 2X₂ && X₃ +X₄ → 2X₄")
parinfect = otimes(infect,infect)
sponinf = compose(spontaneous, infect)


println("\nTesting the compose and otimes with parallel ⊚ (infect ⊗ I₂)")
m1 = compose(parallel, otimes(infect,eye(2)))
@show m1.dom
@show m1.model.S
@show m1.codom
@show m1.model.Δ


println("\nTesting parallel ⊚ (I₁ ⊗ infect ⊗ I₂)")
m2 = compose(parallel, otimes(otimes(eye(1),infect),eye(1)))
@show m2.dom
@show m2.model.S
@show m2.codom
@show m2.model.Δ

println("\nTesting parallel ⊚ (I₂ ⊗ infect)")
m3 = compose(parallel, otimes(eye(2), infect))
@show m3.dom
@show m3.model.S
@show m3.codom
@show m3.model.Δ


println("\nCreating food web processes birth, death, predation")
birth   = Model([1], [(X[1], 2X[1])])
death   = Model([1, 2], [(X[1], X[2])])
pred(α,β,γ) = Model([1, 2], [(α*X[1] + β*X[2], γ*X[2])])

b = OpenModel([1], birth, [1])
d = OpenModel([1], death, [1])
p(α, β, γ) = OpenModel([1,2], pred(α, β, γ), [1,2])
println("\nCreating food web processes σ, predation†")
σ() = OpenModel([2,1], NullModel(2), [2,1])
pdag(α,β,γ) = OpenModel([1,2], Model([1, 2], [(α*X[2] + β*X[1], γ*X[1])]), [1,2])

# Catlab expressions for our variables
Xob = Ob(FreeSymmetricMonoidalCategory, :X)
bh = Hom(:b, Xob,Xob)
dh = Hom(:d, Xob, Xob)
ph = Hom(:p, Xob⊗Xob, Xob⊗Xob)
pdagh = Hom(Symbol("p⋆"), Xob⊗Xob, Xob⊗Xob)

println("\nbd = b⊗d")
bd = otimes(b,d)
@show bd.model.Δ
println("\nlv2 = bd⊚p")
lv2 = compose(bd, p(1,2, 3))
@show lv2.dom
@show lv2.model.S
@show lv2.codom
@show lv2.model.Δ

# the first predator is the second prey
# foodchain = compose(compose(otimes(compose(otimes(b,
#                                                   eye(1)),
#                                            p(1,2,3)),
#                                    eye(1)),
#                             otimes(eye(1),
#                                    p(1,2,3))),
#                     otimes(otimes(eye(1), d), b))
println("\nbdd = b⊗d⊗d")
bdd = otimes(otimes(b, d), d)
println("\nbdb = b⊗d⊗b")
bdb = otimes(b,otimes(d,b))
# foodchain = compose(compose(otimes(p(1,2,3),
#                                    eye(1)),
#                             otimes(eye(1),
#                                    p(1,2,3))),
#                     bdd)
println("bipredation is (p⊗I)⊚(I⊗p)")
bipredation = compose(otimes(p(1,2,3),
                             eye(1)),
                      otimes(eye(1),
                             p(1,2,3)))
# t1 = otimes(otimes(eye(1), d), eye(1))
println("\nfoodchain is (bipredation)⊚(bdd). A fish, a bigger fish, and biggest fish")
foodchain = compose(bipredation, bdd)
@show foodchain.dom
@show foodchain.model.S
@show foodchain.codom
@show foodchain.model.Δ

foodchainh = compose(compose(ph⊗id(Xob),id(Xob)⊗ph), bh⊗dh⊗dh)
drawhom(foodchainh, "img/foodchain_wd")
homx = canonical(FreeSymmetricMonoidalCategory, foodchainh)
println("Cannonical form construction proves:  $foodchainh == $homx")
println("As an ordinary differential equation:")
@show symbolic_symplify(Petri.odefunc(foodchain.model, :state)) |> striplines

# # the first predator is the second predator (with two independent prey species)
println("\npp† is (p⊗I)⊚(I⊗p†)")
ppdag = compose(otimes(p(1,2,3), eye(1)), otimes(eye(1), pdag(1,2,3)))
println("\nfoodstar is (pp†)⊚(bdb). Two prey with a common predator")
foodstar = compose(ppdag, bdb)
@show foodstar.dom
@show foodstar.model.S
@show foodstar.codom
@show foodstar.model.Δ

foodstarh = compose(compose(ph⊗id(Xob),id(Xob)⊗pdagh), bh⊗dh⊗bh)
drawhom(foodstarh, "img/foodstar_wd")
homx = canonical(FreeSymmetricMonoidalCategory, foodstarh)
println("Cannonical form construction proves:  $foodstarh == $homx")
println("As an ordinary differential equation:")
@show symbolic_symplify(Petri.odefunc(foodstar.model, :state)) |> striplines

f = foodchain
g = Graph(f)
pprint(g)
output = run_graphviz(g, prog="dot", format="svg")
write("img/foodchain.svg", output)

f = foodstar
g = Graph(f)
pprint(g)
output = run_graphviz(g, prog="dot", format="svg")
write("img/foodstar.svg", output)
end

# fog = Malaria.otimes(Malaria.f , Malaria.g)
# h   = Malaria.compose(Malaria.h1 , Malaria.h2)
# mal = Malaria.compose(fog , h)

# mal′ = Malaria.compose(Malaria.compose(Malaria.otimes(Malaria.f,Malaria.g), Malaria.h1), Malaria.h2)
# mal′ == mal
