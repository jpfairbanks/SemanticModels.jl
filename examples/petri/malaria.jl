module Malaria
using Petri
using ModelingToolkit
import ModelingToolkit: Constant
import Base: ==

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
function ==(x::Petri.Model,y::Petri.Model)
    all(isequal.(x.S, y.S)) && all(isequal.(x.Δ, y.Δ))
end

function ==(f::OpenModel,g::OpenModel)
    all(isequal.(f.dom, g.dom)) && all(isequal.(f.codom, g.codom)) && f.model == g.model
end


⊕(v::Vector, w::Vector) = vcat(v,w)

function otimes(f::OpenModel{T,M}, g::OpenModel{T,M}) where {T<: Vector, M<: Petri.Model}
    @show f.model.S
    @show g.model.S
    # TODO: need to renumber the states of g
    M = Petri.Model(f.model.S ⊕ g.model.S, f.model.Δ ⊕ g.model.Δ)
    return OpenModel(f.dom ⊕ g.dom, M, f.codom ⊕ g.codom)
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

function compose(f::OpenModel{T,Md}, g::OpenModel{T,Md}) where {T<: Vector, Md<: Petri.Model}
    X = f.dom
    Y = f.codom
    Y′ = g.dom
    @show Y, Y′
    @assert isequal.(Y, Y′) |> all
    Z = g.codom
    M = f.model
    N = g.model

    states = equnion(M.S, N.S)
    Δ = equnion(M.Δ, N.Δ)
    Λ = equnion(M.Λ, N.Λ)
    Φ = equnion(M.Φ, N.Φ)
    Mp_yN = Petri.Model(states, Δ, Λ, Φ)
    return OpenModel(X, Mp_yN, Z)
    # TODO: need to renumber the states of g
    # return Petri.Model(modulo(M.S⊕N.S, Y), f.model.Δ ⊕ g.model.Δ)
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
end


fog = Malaria.otimes(Malaria.f , Malaria.g)
h   = Malaria.compose(Malaria.h1 , Malaria.h2)
mal = Malaria.compose(fog , h)

mal′ = Malaria.compose(Malaria.compose(Malaria.otimes(Malaria.f,Malaria.g), Malaria.h1), Malaria.h2)
mal′ == mal
