# -*- coding: utf-8 -*-
using Petri
using ModelingToolkit
import ModelingToolkit: Constant, Variable

mutable struct SIRState{T,F}
    S::T
    I::T
    R::T
    β::F
    γ::F
    μ::F
end

mutable struct ParamSIR{T, P}
    S::T
    I::T
    R::T
    params::P
end

mutable struct ParamSEIR{T, P}
    S::T
    E::T
    I::T
    R::T
    params::P
end

mutable struct SEIRState{T,F}
    S::T
    I::T
    R::T
    β::F
    γ::F
    μ::F
    E::T
    η::F
end


mutable struct SEIRDState{T,F}
    S::T
    I::T
    R::T
    β::F
    γ::F
    μ::F
    E::T
    η::F
    D::T
    ψ::F
end

macro grounding(ex)
    return ()
end

# +
function main()
    @grounding begin
        S => Noun(Susceptible, ontology=Snowmed)
        I => Noun(Infectious, ontology=ICD9)
        R => Noun(Recovered, ontology=ICD9)
        λ₁ => Verb(infection)
        λ₂ => Verb(recovery)
        λ₃ => Verb(loss_of_immunity)
    end
    @variables S, I, R, β, γ, μ
    N = +(S,I,R)
    ϕ = [(S > 0) * (I > 0),
         I > 0,
         R > 0]

    Δ = [(S~S-1, I~I+1),
        (I~I-1, R~R+1),
        (R~R-1, S~S+1)]

    Λ = [β*S*I/N,
        γ*I,
        μ*R]

    m = Petri.Model([S,I,R], Δ, Λ, ϕ)
    p = Petri.Problem(m, SIRState(100, 1, 0, 0.5, 0.15, 0.05), 150)


    @grounding begin
        E => Noun(Exposed, ontology=ICD9)
        λ₄ => Verb(exposure)
    end
    @variables E, η
    N = +(S,E,I,R)
    ϕ = [(S > 0) * (I > 0),
         E > 0]

    Δ = [(S~S-1, E~E+1),
         (E~E-1, I~I+1)]

    Λ = [β*S*I/N,
        η*E]
    m2 = Petri.Model([S,E], Δ, Λ, ϕ)
    f = Dict(S => S)
    m′ = deepcopy(m)
    Petri.rewrite!(m′, m2, f)
    m
    p2 = Petri.Problem(m′, SEIRState(100, 1, 0, 0.5, 0.15, 0.05, 0, 0.12), 150)

    @grounding begin
        D => Noun(Dead, ontology=ICD9)
        λ₅ => Verb(death)
    end
    @variables D, ψ
    ϕ = [I > 0]

    Δ = [(I~I-1, D~D+1)]

    Λ = [ψ*I]

    m3 = Petri.Model([D], Δ, Λ, ϕ)
    m′′ = deepcopy(m′)
    Petri.rewrite!(m′′, m3)
    p3 = Petri.Problem(m′′, SEIRDState(100, 1, 0, 0.5, 0.15, 0.05, 0, 0.12, 0, 0.1), 150)

    return p, p2, p3

end
# -

p, p2, p3 = main()

# +
@show "SIR"

Petri.solve(p)
@time Petri.solve(p)

mf = Petri.eval(Petri.funckit(p))
pf = Petri.Problem(mf, SIRState(100, 1, 0, 0.5, 0.15, 0.05), 150)
Petri.solve(pf)
@time Petri.solve(pf)

# +
@show "SEIR"

Petri.solve(p2)
@time Petri.solve(p2)

mf2 = Petri.eval(Petri.funckit(p2))
pf2 = Petri.Problem(mf2, SEIRState(100, 1, 0, 0.5, 0.15, 0.05, 0, 0.12), 150)
Petri.solve(pf2)
@time Petri.solve(pf2)

# +
@show "SEIRD"

Petri.solve(p3)
@time Petri.solve(p3)

mf3 = Petri.eval(Petri.funckit(p3))
pf3 = Petri.Problem(mf3, SEIRDState(100, 1, 0, 0.5, 0.15, 0.05, 0, 0.12, 0, 0.1), 150)
Petri.solve(pf3)
@time Petri.solve(pf3)
