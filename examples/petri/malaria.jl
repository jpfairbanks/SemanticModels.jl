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
using Catlab.Graphics.Graphviz
import Catlab.Graphics.Graphviz: Graph

⊗(f::OpenModel,g::OpenModel) = otimes(f,g)
⊚(f::OpenModel,g::OpenModel) = compose(f,g)

""" op(f::Model)

return the opposite model you get by reversing the direction of all the transitions
"""
op(f::Model) = Model(f.S, map(f.Δ) do t
                     reverse(t) end)

op(f::OpenModel) = OpenModel(f.dom, op(f.model), f.codom)

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
println("\nbdd = b⊗d⊗d")
bdd = otimes(otimes(b, d), d)
println("\nbdb = b⊗d⊗b")
bdb = otimes(b,otimes(d,b))
println("bipredation is (p⊗I)⊚(I⊗p)")
bipredation = compose(otimes(p(1,2,3),
                             eye(1)),
                      otimes(eye(1),
                             p(1,2,3)))
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
output = run_graphviz(g, prog="dot", format="svg")
write("img/foodchain.svg", output)

f = foodstar
g = Graph(f)
output = run_graphviz(g, prog="dot", format="svg")
write("img/foodstar.svg", output)

# @variables S, I, R, Sm, Im
# # people recover from and then lose their immunity to malaria
# rec = Petri.Model([S,I,R], [(I,R), (R, S)])
# # mosquitos recover from malaria, but are not immune
# recm = Petri.Model([Sm,Im], [(Im,Sm)])

# infect = Petri.Model([S,I,Im], [(S+Im, I+Im)])
# infectm = Petri.Model([Sm,I,Im], [(Sm+I, I+Im)])

# f = OpenModel([S,I,R], rec, [S,I])
# g = OpenModel([Sm,Im], recm, Operation[])

# h1 = OpenModel([S,I], infect, [I, Im])
# h2 = OpenModel([I,Im], infectm, [I])

println("Malaria Example")
# malaria = (f⊗g) ⊚ (h1⊚h2)
dualinfect = compose(ph⊗id(Xob), id(Xob)⊗pdagh)
rec = Hom(:rec, Xob⊗Xob, Xob⊗Xob)
wan = Hom(:wan, Xob⊗Xob, Xob⊗Xob)
cur = Hom(:cur, Xob⊗Xob, Xob⊗Xob)
curdag = Hom(Symbol("cur⋆"), Xob⊗Xob, Xob⊗Xob)
inf = Hom(Symbol("inf¹³₂₃"), Xob⊗Xob⊗Xob, Xob⊗Xob⊗Xob)
inf′ = Hom(Symbol("inf³¹₂₁"), Xob⊗Xob⊗Xob, Xob⊗Xob⊗Xob)
malariah = compose(compose(id(Xob)⊗inf, inf′⊗id(Xob)),cur⊗curdag)
drawhom(malariah, "img/malaria_wd")

cure = OpenModel([1,2], Model([1,2], [(X[2], X[1])]), [1,2])
curedag = op(cure)
trinary  = OpenModel([1,2,3], Model([1,2,3], [(X[1]+X[3], X[2]+X[3])]), [1,2,3])
trinary′ = OpenModel([1,2,3], Model([1,2,3], [(X[3]+X[1], X[2]+X[1])]), [1,2,3])
dualinfect = compose(trinary⊗eye(1), eye(1)⊗trinary′)
g = Graph(trinary)
output = run_graphviz(g, prog="dot", format="svg")
write("img/trinary.svg", output)

g = Graph(dualinfect)
output = run_graphviz(g, prog="dot", format="svg")
write("img/dualinfect.svg", output)

f = compose(dualinfect, cure ⊗ curedag )
homx = canonical(FreeSymmetricMonoidalCategory, malariah)
println("Cannonical form construction proves:  $malariah == $homx")
println("As an ordinary differential equation:")
@show symbolic_symplify(Petri.odefunc(f.model, :state)) |> striplines
g = Graph(f)
output = run_graphviz(g, prog="dot", format="svg")
write("img/malaria.svg", output)
end
