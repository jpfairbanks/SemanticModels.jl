using Petri

function main(β, γ, μ)

    g = Graph(6)
    g.names[:] = [:S, :T1, :I, :T2, :R, :T3]

    add_edge(g, :S,  :T1)
    add_edge(g, :I,  :T1)
    add_edge(g, :T1, :S)
    add_edge(g, :T1, :I)
    add_edge(g, :I,  :T2)
    add_edge(g, :T2, :R)
    add_edge(g, :R,  :T3)
    add_edge(g, :T3, :S)

    Δ = [
        T1 => (x,y) -> (x-1, y+1),
        T2 => (x,y) -> (x-1, y+1),
        T3 => (x,y) -> (x-1, y+1),
    ]

    ϕ = [
        T1 => (x,y) -> x>0,
        T2 => (x) -> x>0,
        T3 => (x) -> x>0,
    ]

    Λ = [
        T1 => (x,y) -> β*x*y/n,
        T2 => (x) -> γ*x/n,
        T3 => (x) -> μ*x/n
    ]

    m = Petri.Model(g, Δ, ϕ, Λ)
    soln = solve(m)
end

macro grounding(ex)
    return ()
end

function main(β, γ, μ)
    @grounding begin
        S => Noun(Susceptible, ontology=Snowmed)
        I => Noun(Infectious, ontology=ICD9)
        R => Noun(Recovered, ontology=ICD9)
        λ₁ => Verb(infection)
        λ₂ => Verb(recovery)
        λ₃ => Verb(loss_of_immunity)
    end

    @reaction begin
        λ₁, S + I -> 2I
        λ₂, I -> R
        λ₃, R -> S
    end, λ₁, λ₂, λ₃

    # β, 1S + 1I -> 0S + 2I
    # γ, 0R + 1I -> 0I + 1R
    # μ, 1R + 0S -> 1S + 0R

    Δ = [
        (S,I) -> (S-1, I+1),
        (I,R) -> (I-1, R+1),
        (R,S) -> (R-1, S+1),
    ]

    ϕ = [
        (S, I) -> x > 0 && I > 0,
        (I) -> x > 0,
        (R) -> x > 0,
    ]

    Λ = [
        λ₁(S,I) = begin n = +(S,I,R); β*S*I/n end,
        λ₂(I) = begin γ*I end,
        λ₃(R) = begin μ*R end
    ]
    m = Petri.Model(g, Δ, ϕ, Λ)
    d = convert(ODEProblem, m)
    soln = solve(m) #discrete
    soln = solve(d) #continuos
end


