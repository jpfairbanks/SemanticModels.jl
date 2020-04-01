# -*- coding: utf-8 -*-
module Malaria
using Petri
using MacroTools
import MacroTools: postwalk, striplines
using ModelingToolkit
import ModelingToolkit: Constant
import Base: ==, ∈, show
using Catlab.Doctrines
import Catlab.Doctrines: ⊗, compose, otimes
using Catlab.WiringDiagrams
using Catlab.Graphics
using SemanticModels.WiringDiagrams
using Catlab.Graphics.Graphviz
import Catlab.Graphics.Graphviz: Graph
import Base: ^

⊗(f::OpenModel,g::OpenModel) = otimes(f,g)
⊚(f::OpenModel,g::OpenModel) = compose(f,g)

^(x::Doctrines.FreeSymmetricMonoidalCategory.Ob{:generator}, n::Int) = foldl(⊗, x for i in 1:n)
^(f::Doctrines.FreeSymmetricMonoidalCategory.Hom{:id}, n::Int64) = foldl(⊗, f for i in 1:n)

function show(io::IO, z::Petri.Model)
    X, Y = z.S, z.Δ
    compact = get(io, :compact, true)
    if compact
        x,y = length(X), length(Y)
        print(io,"Model(∣S∣=$x,∣Δ∣=$y)")
    else
        print(io,"Model(S=$X, Δ=$Y)")
    end
end
function show(io::IO, z::OpenModel)
    X,Y = z.dom, z.codom
    compact = get(io, :compact, true)
    if compact
        x,y = length(X), length(Y)
        print(io,"OpenModel:$x→$y with ")
        show(io,z.model)
    else
        print(io,"Domain: $X\nCodomain: $Y\nModel: ")
        show(io, z.model)
    end
end

""" op(f::Model)

return the opposite model you get by reversing the direction of all the transitions
"""
op(f::Model) = Model(f.S, map(f.Δ) do t
                     reverse(t) end)

op(f::OpenModel) = OpenModel(f.dom, op(f.model), f.codom)



function debug_show(io::IO, f::Model)
    X,Y = f.S, f.Δ
    print(io,"Model(S=$X, Δ=")
    if length(Y) == 0
        print("[])")
    else
        for (i,t) in enumerate(Y)
            if i == 1
                print(io, "[")
                print(io, "$(t[1])→$(t[2]),")
            end
            if 1 < i < length(Y)
                print(io, " $(t[1])→$(t[2]),")
            end
            if i == length(Y)
                print(io, " $(t[1])→$(t[2])])\n")
            end
        end
    end
end
debug_show(io::IO, f::OpenModel) = debug_show(io, f.model)
debug_show(f::OpenModel) = debug_show(stdout, f.model)

function debug_show(io::IO, f::OpenModel, fname::String)
    X,Y = f.dom, f.codom
    print(io,"Domain: $X\nCodomain: $Y\nModel: ")
    debug_show(io, f.model)
    println(io, "\n")

    g = Graph(f)
    # pprint(g)
    output = run_graphviz(g, prog="dot", format="svg")
    write(fname, output)
end

debug_show(f::OpenModel, fname::String) = debug_show(stdout, f, fname)

X = Petri.X

Base.Filesystem.mkpath("img")

println("\nSpontaneous reaction spontaneous = X₁→X₂")
spontaneous = OpenModel([1,2], Model([1,2], [(X[1],X[2])]), [1,2])
println("\nParallel reaction parallel = spontaneous ⊗ spontaneous = X₁→X₂, X₃→X₄")
parallel = spontaneous ⊗ spontaneous
println("\nInfection reaction infect = X₁+X₂→ 2X₂")
infect = OpenModel([1,2], Model([1,2], [(X[1]+X[2], 2*X[2])]), [1,2])
println("\nParallel Infections reactions infect ⊗ infect = X₁+X₂→ 2X₂ && X₃ +X₄ → 2X₄")
parinfect = infect ⊗ infect
sponinf = compose(spontaneous, infect)



println("\nTesting the compose and otimes with parallel ⊚ (infect ⊗ I₂)")
m1 = compose(parallel, infect ⊗ eye(2))
println(m1)
debug_show(m1)

println("\nTesting parallel ⊚ (I₁ ⊗ infect ⊗ I₂)")
m2 = compose(parallel, (eye(1) ⊗ infect) ⊗ eye(1))
println(m2)
debug_show(m2)

println("\nTesting parallel ⊚ (I₂ ⊗ infect)")
m3 = compose(parallel, eye(2) ⊗ infect)
println(m3)
debug_show(m3)


println("\nCreating food web processes birth, death, predation")
birth   = Model([1], [(X[1], 2X[1])])
death   = Model([1, 2], [(X[1], X[2])])
pred(α,β,γ) = Model([1, 2], [(α*X[1] + β*X[2], γ*X[2])])

b = OpenModel([1], birth, [1])
d = OpenModel([1], death, [1])
p(α, β, γ) = OpenModel([1,2], pred(α, β, γ), [1,2])
println("\nCreating food web processes σ, predation†")
σ() = OpenModel([1,2], NullModel(2), [2,1])
pdag(α,β,γ) = OpenModel([1,2], Model([1, 2], [(α*X[2] + β*X[1], γ*X[1])]), [1,2])

# Catlab expressions for our variables
Xob = Ob(FreeSymmetricMonoidalCategory, :X)
idₓ = id(Xob)
bh = Hom(:birth, Xob,Xob)
dh = Hom(:death, Xob, Xob)
ph = Hom(:predation, Xob^2, Xob^2)
pdagh = Hom(Symbol("p⋆"), Xob^2, Xob^2)

println("\nbd = b⊗d")
bd = b⊗d
println(bd.model.Δ)
println("\nlv2 = bd⊚p")
lv2 = compose(bd, p(1,2, 3))
println(lv2)
debug_show(lv2)

# the first predator is the second prey
println("\nbdd = b⊗d⊗d")
bdd = bd⊗d
println("\nbdb = b⊗d⊗b")
bdb = b⊗(d⊗b)
println("bipredation is (p⊗I)⊚(I⊗p)")
bipredation = compose(p(1,2,3)⊗eye(1), eye(1)⊗p(1,2,3))
println("\nfoodchain is (bipredation)⊚(bdd). A fish, a bigger fish, and biggest fish")
foodchain = compose(bipredation, bdd)
println(foodchain)
debug_show(foodchain)

foodchainh = compose(ph⊗idₓ, idₓ⊗ph, bh⊗dh⊗dh)
drawhom(foodchainh, "img/foodchain_wd")
homx = canonical(FreeSymmetricMonoidalCategory, foodchainh)
println("Cannonical form construction proves:  $foodchainh == $homx")
println("As an ordinary differential equation:")
@show symbolic_symplify(Petri.odefunc(foodchain.model, :state)) |> striplines

# # the first predator is the second predator (with two independent prey species)
println("\npp† is (p⊗I)⊚(I⊗p†)")
ppdag = compose(p(1,2,3)⊗eye(1), eye(1) ⊗ pdag(1,2,3))
println("\nfoodstar is (pp†)⊚(bdb). Two prey with a common predator")
foodstar = compose(ppdag, bdb)
println(foodstar)
debug_show(foodstar)

foodstarh = compose(ph⊗idₓ, idₓ⊗pdagh, bh⊗dh⊗bh)
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
\
# h1 = OpenModel([S,I], infect, [I, Im])
# h2 = OpenModel([I,Im], infectm, [I])

println("Malaria Example")
# malaria = (f⊗g) ⊚ (h1⊚h2)
dualinfect = compose(ph⊗idₓ, idₓ⊗pdagh)
σh = braid(Xob, Xob)
cur = Hom(:cur, Xob⊗Xob, Xob⊗Xob)
curdag = Hom(Symbol("cur⋆"), Xob^2, Xob^2)
inf = Hom(Symbol("inf¹³₂₃"), Xob^3, Xob^3)
inf′ = Hom(Symbol("inf³¹₂₁"), Xob^3, Xob^3)
malariah = compose(compose(inf⊗idₓ, idₓ⊗inf′),cur⊗compose(σh,cur,σh))
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

malaria = compose(dualinfect, cure ⊗ curedag )
homx = canonical(FreeSymmetricMonoidalCategory, malariah)
println("Cannonical form construction proves:  $malariah == $homx")
println("As an ordinary differential equation:")
@show symbolic_symplify(Petri.odefunc(malaria.model, :state)) |> striplines
g = Graph(malaria)
output = run_graphviz(g, prog="dot", format="svg")
write("img/malaria.svg", output)

println("Mosquito Hunting Birds")

# ppdagh = compose(idₓ⊗ph,idₓ⊗compose(σh, ph))
birdsh = compose(σh⊗idₓ,idₓ⊗ph, σh⊗idₓ, idₓ⊗ph)
drawhom(birdsh, "img/birds_wd")
homx = canonical(FreeSymmetricMonoidalCategory, birdsh)
println("Cannonical form construction proves:  $birdsh == $homx")
# vitals for Sp, Ip, Im, Sm, B are:
# born, die (of malaria), die (of malaria), born, die (starvation)
vitalsh = bh⊗dh⊗dh⊗bh⊗dh
vitals = b⊗d⊗d⊗b⊗d
birdmalh = compose(malariah ⊗ idₓ, idₓ^2 ⊗ birdsh, vitalsh)
drawhom(birdmalh, "img/birdmal_wd")
birds = compose(σ()⊗eye(1), eye(1)⊗p(1,1,1.05), σ()⊗eye(1), eye(1)⊗p(1,1,1.05))
debug_show(birds, "img/birds.svg")
birdmal = compose(malaria⊗eye(1), eye(2)⊗birds, vitals)
debug_show(birdmal, "img/birdmal.svg")
homx = canonical(FreeSymmetricMonoidalCategory, birdmalh)
println("Cannonical form construction proves:  $birdmalh == $homx")
println("As an ordinary differential equation:")
fex = @show symbolic_symplify(Petri.odefunc(birdmal.model, :state)) |> striplines
Petri.N(s) = 1 #sum(s[1:end-3])
f = Petri.mk_function(birdmal.model)

using LabelledArrays
using OrdinaryDiffEq
import OrdinaryDiffEq: solve
u0 = @LArray [20,1,0,40,0.1,0,0,0.0] (:X₁, :X₂, :X₃, :X₄, :X₅, :X₆, :X₇, :X₈)
# βpm = 1
# βmp = 1
# ρp = 0.005
# ρm = 0.004
# ηI = 1
# ηS = 15
# νp = 0.0005
# δp = 0.05
# δm = 0.01
# νm = 0.31
# δb = 0.09
βpm = 1
βmp = 1
ρp = 0.5
ρm = 0.4
ηI = 1
ηS = 15
νp = 0.5
δp = 0.5
δm = 0.1
νm = 0.31
δb = 0.9
params = [βpm, βmp,ρp,ρm,ηI, ηS, νp, δp, δm, νm, δb]
prob = ODEProblem(f,u0,(0.0,365.0),params)
sol = solve(prob,Tsit5())
@show sol[end]
using Plots
# varnames = map(LabelledArrays.symnames(typeof(sol[end]))) do x
#     i = Petri.STATELOOKUP[x]
#     return "X$i"
# end |> collect

varnames = [:Sp, :Ip, :Im, :Sm, :B, :Dp, :Dm, :Db]

plt = plot(sol, vars =1:length(varnames)-3, labels=varnames)
# yaxis!("amount", :log10)
savefig(plt, "img/birdmal_sol.png")

error("stop")
println("Testing Braiding with composition for Petri.OpenModel")


# these examples show that σ_guess can precompose with a morphism to reverse it's two wires, it cannot post compose with it to renumber its outputs.
# This relates to our implementation that favors f in compose(f,g), and the fact that in a PROP, all objects are natural numbers.
# If all objects are braid(X,X) = X⊗X as objects. You can compose(braid(X,X), f) to get the version of f with the first and second state reversed, but
# you cannot reverse the outputs because our "renumbering the states" implementation will renumber that away.
σ_guess = OpenModel([1,2], NullModel(2), [2,1])
f = compose(σ_guess, bd)
debug_show(f, "img/braid_debug_precomp.svg")
f = compose(bd, σ_guess)
debug_show(f, "img/braid_debug_postcomp.svg")
debug_show(bd, "img/braid_debug_btimesd.svg")
debug_show(compose(σ_guess, p(1,2,3)), "img/braid_debug_pred.svg")
debug_show(compose(σ_guess, eye(2)), "img/braid_debug_precompid.svg")
debug_show(compose(σ_guess, σ_guess, eye(2)), "img/braid_debug_precomp2id.svg")
debug_show(compose(compose(σ_guess, p(1,2,3))⊗eye(1), compose(eye(1)⊗σ_guess, eye(1)⊗p(1,2,3))), "img/braid_debug_pred2.svg")
debug_show(σ_guess⊗σ_guess, "img/braid_debug_precomp4.svg")
debug_show(compose(σ_guess⊗σ_guess, eye(4)), "img/braid_debug_precomp4id.svg")
debug_show(compose(σ_guess⊗σ_guess, p(1,2,3)⊗p(2,4,6)), "img/braid_debug_precomp4psq.svg")



end
