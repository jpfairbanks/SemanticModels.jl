module OpenPetris
import Base: ∈
using Petri
import SemanticModels.ModelTools.PetriModels: PetriModel
import SemanticModels.ModelTools.OpenModels: OpenModel
using ModelingToolkit
import ModelingToolkit: Constant
using Catlab.Doctrines
import Catlab.Doctrines: ⊗, compose, otimes

export OpenPetri, eye, ⊕

MAX_STATES = 20
X = @variables(X[1:MAX_STATES])[1]
STATELOOKUP = Dict(s.op.name=>i for (i,s) in enumerate(X))

const OpenPetri{V} = OpenModel{V, Petri.Model}

⊕(v::Vector, w::Vector) = vcat(v,w)
# ⊕(v::Vector{Int}, w::Vector{Int}) = vcat(v,w.+length(v))

function otimes(f::OpenPetri{T}, g::OpenPetri{T}) where {T<: Vector}
    f.model.S
    g.model.S
    # TODO: need to renumber the states of g
    M = Petri.Model(f.model.S ⊕ g.model.S, f.model.Δ ⊕ g.model.Δ)
    return OpenModel(f.dom ⊕ g.dom, M, f.codom ⊕ g.codom)
end

function otimes(f::OpenModel{T, Md}, g::OpenModel{T,Md}) where {T<: Vector{Int}, Md<:Petri.Model}
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

function compose(f::OpenModel{T, Md}, g::OpenModel{T, Md}) where {T<: Vector, Md<:Petri.Model}
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

eye(n::Int) = foldr(otimes, [OpenModel([1], NullPetri(1), [1]) for i in 1:n])

end
