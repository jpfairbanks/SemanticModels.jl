module Malaria
using Petri
using MacroTools
import MacroTools: postwalk, striplines
using ModelingToolkit
import ModelingToolkit: Constant
import Base: ==, ∈
using Catlab.Doctrines
import Catlab.Doctrines: ⊗, compose
using Catlab.WiringDiagrams
using Catlab.Graphics

function drawhom(hom, name::String, format="svg")
    d = to_wiring_diagram(hom)
    g = to_graphviz(d, direction=:horizontal)
    t = Graphics.Graphviz.run_graphviz(g, format=format)
    write("$name.$format", t)
end

canonical(Syntax::Module, hom) = begin d = to_wiring_diagram(hom)
    to_hom_expr(Syntax, d)
end

function symbolic_symplify(ex::Expr)
    iscall(x) = false
    iscall(x, name::Symbol) = false
    iscall(x::Expr) = x.head == :call
    iscall(x::Expr, name::Symbol) = iscall(x) && x.args[1] == name

    MacroTools.postwalk(ex) do x
        if x == :param
            return :T
        end
        if x == :state
            return :u
        end
        # -1/1 => -1
        if x == :(-1/1)
            return :(-1)
        end
        # +(x) => x
        if iscall(x, :+) && length(x.args)==2
            return x.args[2]
        end
        # 1*x => x
        if iscall(x, :*) && length(x.args)==3 && x.args[2] == 1
            return x.args[3]
        end
        # *(a, *(b,c)) => *(a,b,c)
        if iscall(x, :*) && length(x.args)==3 && iscall(x.args[end], :*)
            return :(*($(x.args[2]), $(x.args[3].args[2:end]...)))
        end
        # *(a, /(b,c)) => /(*(a,b),c)
        if iscall(x, :*) && length(x.args)==3 && iscall(x.args[end], :/)
            a = x.args[2]
            b = x.args[3].args[2]
            c = x.args[3].args[3]
            num = :(*($(a), $(b)))
            # apply *(a, *(b,c)) => *(a,b,c) again
            if iscall(num, :*) && length(num.args)==3 && iscall(num.args[end], :*)
                num = :(*($(num.args[2]), $(num.args[3].args[2:end]...)))
            end
            f = :($num / $c)
            return f
        end
        return x
    end
end

MAX_STATES = 20
X = @variables(X[1:MAX_STATES])[1]
STATELOOKUP = Dict(s.op.name=>i for (i,s) in enumerate(X))

@variables S, I, R, Sm, Im
# people recover from and then lose their immunity to malaria
rec = Petri.Model([S,I,R], [(I,R), (R, S)])
# mosquitos recover from malaria, but are not immune
recm = Petri.Model([Sm,Im], [(Im,Sm)])

infect = Petri.Model([S,I,Im], [(S+Im, I+Im)])
infectm = Petri.Model([Sm,I,Im], [(Sm+I, I+Im)])

struct OpenModel{V,M}
    dom::V
    model::M
    codom::V
end

function ==(f::OpenModel,g::OpenModel)
    all(isequal.(f.dom, g.dom)) && all(isequal.(f.codom, g.codom)) && f.model == g.model
end


⊕(v::Vector, w::Vector) = vcat(v,w)
# ⊕(v::Vector{Int}, w::Vector{Int}) = vcat(v,w.+length(v))

function otimes(f::OpenModel{T,Md}, g::OpenModel{T,Md}) where {T<: Vector, Md<: Petri.Model}
    f.model.S
    g.model.S
    # TODO: need to renumber the states of g
    M = Petri.Model(f.model.S ⊕ g.model.S, f.model.Δ ⊕ g.model.Δ)
    return OpenModel(f.dom ⊕ g.dom, M, f.codom ⊕ g.codom)
end

function otimes(f::OpenModel{T,Md}, g::OpenModel{T,Md}) where {T<: Vector{Int}, Md<: Petri.Model}
    f.model.S
    g.model.S
    nf = length(f.model.S)
    ng = length(g.model.S)
    newstates = Dict(X[s]=>X[s+nf] for (i, s) in enumerate(g.model.S))
    replace(t::Tuple{Operation, Operation}) = (replace(t[1]), replace(t[2]))
    replace(c::Constant) = c
    replace(op::Operation) = begin
        if op.op == (+)
            return sum(map(replace, op.args))
        end
        if op.op == (*)
            return prod(map(replace, op.args))
        end
        if length( op.args ) == 0
            return newstates[op]
        end
        return op
    end
    newtransitions = f.model.Δ
    if length(g.model.Δ) > 0
        newtransitions = newtransitions ⊕ map(g.model.Δ) do t
            replace(t)
        end
    end

    newstatespace = collect(1:(nf+ng))
    M = Petri.Model(newstatespace, newtransitions)
    return OpenModel(f.dom ⊕ (g.dom .+ nf), M, f.codom ⊕ (g.codom .+ nf))
end

function equnion(a::Vector, b::Vector)
    x = copy(a)
    for item in b
        if !any(item2 -> isequal(item2, item), x)
            push!(x, item)
        end
    end
    return x
end

∈(x::Operation, S::Vector{Operation}) = any(isequal.(x,S))

function compose(f::OpenModel{T,Md}, g::OpenModel{T,Md}) where {T<: Vector, Md<: Petri.Model}
    Y = f.codom
    Y′ = g.dom
    @assert length(Y) == length(Y′)
    Z = g.codom
    M = f.model
    N = g.model

    states = vcat(M.S, ( 1:length(filter(s->!(s ∈ Y′), N.S)) ) .+ length(M.S))
    newstates = Dict(X[Y′[i]]=>X[Y[i]] for i in 1:length(Y))
    i = 0
    newstates′ = map(N.S) do s
        if s ∈ Y′
            return nothing
        end
        i+=1
        X[s] => X[i+length(M.S)]
    end |> l-> filter(x-> x != nothing, l) |> Dict
    newstates = union(newstates, newstates′) |> Dict

    replace(t::Tuple{Operation, Operation}) = (replace(t[1]), replace(t[2]))
    replace(c::Constant) = c
    replace(op::Operation) = begin
        if op.op == (+)
            return sum(map(replace, op.args))
        end
        if op.op == (*)
            return prod(map(replace, op.args))
        end
        if length( op.args ) == 0
            # op ∈ keys(newstates), but for Operations
            if any(isequal.(keys(newstates), op))
                return newstates[op]
            end
            return op
        end
        return op
    end
    newtransitions = f.model.Δ
    if length(g.model.Δ) > 0
        newtransitions = newtransitions ⊕ map(g.model.Δ) do t
            replace(t)
        end
    end
    Δ = newtransitions
    Λ = vcat(M.Λ, N.Λ)
    Φ = vcat(M.Φ, N.Φ)
    Mp_yN = Petri.Model(states, Δ, Λ, Φ)
    Z′ = map(Z) do z
        findfirst(x->isequal(x, newstates[X[z]]), X)
    end
    return OpenModel(f.dom, Mp_yN, Z′)
end

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

X = @variables(X[1:20])[1]
println("\nSpontaneous reaction spontaneous = X₁→X₂")
spontaneous = OpenModel([1,2], Model([1,2], [(X[1],X[2])]), [1,2])
println("\nParallel reaction parallel = spontaneous ⊗ spontaneous = X₁→X₂, X₃→X₄")
parallel = otimes(spontaneous, spontaneous)
println("\nInfection reaction infect = X₁+X₂→ 2X₂")
infect = OpenModel([1,2], Model([1,2], [(X[1]+X[2], 2*X[2])]), [1,2])
println("\nParallel Infections reactions infect ⊗ infect = X₁+X₂→ 2X₂ && X₃ +X₄ → 2X₄")
parinfect = otimes(infect,infect)
sponinf = compose(spontaneous, infect)

NullModel(n::Int) = Model(collect(1:n), Vector{Tuple{Operation,Operation}}())
eye(n::Int) = foldr(otimes, [OpenModel([1], NullModel(1), [1]) for i in 1:n])

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

end

# fog = Malaria.otimes(Malaria.f , Malaria.g)
# h   = Malaria.compose(Malaria.h1 , Malaria.h2)
# mal = Malaria.compose(fog , h)

# mal′ = Malaria.compose(Malaria.compose(Malaria.otimes(Malaria.f,Malaria.g), Malaria.h1), Malaria.h2)
# mal′ == mal
