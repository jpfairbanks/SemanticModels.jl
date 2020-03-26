using OrdinaryDiffEq
import OrdinaryDiffEq: ODEProblem
using Petri
using Test
using Catlab
using Catlab.Doctrines
using Catlab.Graphics
using Catlab.WiringDiagrams
using Catlab.Programs
using SemanticModels.ModelTools.CategoryTheory
import SemanticModels.ModelTools.CategoryTheory: undecorate, ⊔
using SemanticModels.ModelTools.PetriModels
using SemanticModels.ModelTools.PetriCospans
import SemanticModels.ModelTools: model


"""    fluxes(m::Petri.Model)

a PetriNet interpreter that computes the mass action kinetics of a petri net.

Usage: pass this to ODEProblem to set up an ODE for a given model.
"""
function fluxes(m::Petri.Model)
    S = m.S
    T = m.Δ
    nS = length(S)
    nT = length(T)
    ϕ = zeros(Float64, nT)
    f(du, u, p, t) = begin
        for (i, t) in enumerate(T)
            ins = t[1]
            # TODO: accomodate multiplicites here
            ϕ[i] = p[i]*prod(u[ins])
        end
        for i in S
            du[i] = 0
        end
        for (i, t) in enumerate(T)
            ins = t[1]
            out = t[2]
            for s in ins
                # TODO: accomodate multiplicites here
                du[s] -= ϕ[i]
            end
            for s in out
                # TODO: accomodate multiplicites here
                du[s] += ϕ[i]
            end
        end
        return du
    end
    return f
end

u₀(m::Petri.Model) = begin
    zeros(Float64, length(m.S))
end

u₀(m::Petri.Model, initialS, initialI=1) = begin
    u0=zeros(Float64, length(m.S))
    u0[1] = initialS
    u0[2] = initialI
    return u0
end

function savedata(sol::ODESolution, colnames, fname::String)
    open(fname, "w") do fp
        println(fp, "time, $colnames")
        map(tuples(sol)) do (u,t)
            print(fp, "$t")
            map(u) do x
                print(fp, ",$x")
            end
            println(fp, "")
        end
    end
end

model(c::PetriCospan) = left(c.f).d[1].model

X = FinSet(1)
# Fseir = compose(exposure(X,X,X),otimes(spontaneous(X,X),id(X)),mmerge(X),mcopy(X),otimes(id(X),spontaneous(X,X)))
# states are [S, I, E, R]
# m_seir = left(Fseir.f).d[1]

Psir = PetriModel(
          Petri.Model(1:3,[
            ([1,2],[2,2]), # exposure
            ([2],[3]),     # recovery
            ], missing, missing))

m = Psir.model

u0 = zeros(Float64, length(m.S))
u0[1]  = 10000
u0[2]  = 1

β = [10/sum(u0), 1/5]

tspan = (0,100.0)
prob = ODEProblem(fluxes(m), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob, alg=Tsit5())

savedata(sol, "S,I,R", "sirdata.csv")

Psird = PetriModel(
          Petri.Model(1:4,[
            ([1,2],[2,2]), # exposure
            ([2],[3]),     # recovery
            ([2],[4]),     # death
            ], missing, missing))

m = Psird.model

u0 = zeros(Float64, length(m.S))
u0[1]  = 10000
u0[2]  = 1

β = [10/sum(u0), 1/5, 1/10]

tspan = (0,100.0)
prob = ODEProblem(fluxes(m), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob, alg=Tsit5())

savedata(sol, "S,I,R,D", "sirddata.csv")

Pseir = PetriModel(
          Petri.Model(1:5,[
            ([1,2],[3,2]), # exposure
            ([3],[2]),     # onset
            ([2],[4]),     # recovery
            ], missing, missing))

m = Pseir.model

u0 = zeros(Float64, length(m.S))
u0[1]  = 10000
u0[2]  = 1

β = [10/sum(u0), 1/2, 1/5]

tspan = (0,100.0)
prob = ODEProblem(fluxes(m), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob, alg=Tsit5())

savedata(sol, "S,I,E,R", "seirdata.csv")
Pseird = PetriModel(
          Petri.Model(1:5,[
            ([1,2],[3,2]), # exposure
            ([3],[2]),     # onset
            ([2],[4]),     # recovery
            ([2],[5]),     # death
            ], missing, missing))

m = Pseird.model

u0 = zeros(Float64, length(m.S))
u0[1]  = 10000
u0[2]  = 1

seirdparams() = begin
    βseird = [10/sum(u0), 1/2, 1/5, 1/16]
end

tspan = (0,100.0)
prob = ODEProblem(fluxes(m), u0, tspan, seirdparams())
sol = OrdinaryDiffEq.solve(prob, alg=Tsit5())

savedata(sol, "S,I,E,R,D", "seirddata.csv")
