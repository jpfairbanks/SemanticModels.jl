using OrdinaryDiffEq
import OrdinaryDiffEq: ODEProblem
using Petri
using Test

#this function was removed in Julia 0.7
"""    linreg(x,y)

perform a simple linear regression for scalar case. Coefficients are returned
as (intercept, scalar)
"""
linreg(x, y) = hcat(fill!(similar(x), 1), x) \ y

"""    peakgap(s1, s2)

identify the time delay between the peak in two time series. Time series should
be stored as (x(t), t) for consistency with the tuples(sol) from OrdinaryDiffEq.
"""
function peakgap(s1, s2)
    @show p1, i1 = findmax(first.(s1))
    @show p2, i2 = findmax(first.(s2))
    return s2[i2][end] - s1[i1][end]
end

"""    peakgap(sol, i::Int, j::Int)

identify the time delay between the peak in two dimensions of an ODE solution structure.
"""
function peakgap(sol, i::Int, j::Int)
    s1 = [(u[i],t) for (u,t) in tuples(sol)]
    s2 = [(u[j],t) for (u,t) in tuples(sol)]
    return peakgap(s1,s2)
end

"""    paramsweep(f::Function, m::Petri.Model, initials, tspan, params)

solve an ODEProblem for each parameter setting in params and apply the function f to the solution.

Usage:
    paramsweep(m,initials,tspan,[p1,p2,p3]) do sol
        return f(sol)
    end
"""
function paramsweep(f::Function, m::Petri.Model, initials, tspan, params)
    map(params) do p
        prob = ODEProblem(fluxes(m), initials, tspan, p)
        sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
        return f(sol)
    end
end

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

function makeplots_seir(sol, prefix)
    mkpath(dirname(prefix))
    p1 = plot(sol,vars=[1,2,3,4], xlabel="", ylabel="people", linewidth=3,title="Cities", legend=false)
    p2 = plot(sol,vars=[5,6,7,8], xlabel="", ylabel="people", linewidth=3, legend=false)
    p3 = plot(sol,vars=[9,10,11,12], xlabel="time", ylabel="people", linewidth=3, legend=false)
    p4 = plot(sol,vars=[2,6,10], xlabel="", linewidth=3, labels=["i1" "i2" "i3"], legend=true)
    p5 = plot(sol,vars=[3,7,11], xlabel="", linewidth=3,title="Populations", labels=["e1" "e2" "e3"], legend=true)
    p6 = plot(sol,vars=[4,8,12], xlabel="time", linewidth=3, labels=["r1" "r2" "r3"], legend=true)
    p = plot(p1, p5, p2, p4, p3, p6, layout=(3,2), linewidth=3, link=:both)
    savefig(p, "$(prefix)combined.pdf")
    p
end

function makeplots_seird(sol, prefix)
    mkpath(dirname(prefix))
    p1 = plot(sol,vars=[1,2,3,4,5], xlabel="", ylabel="people", linewidth=3,title="Cities", legend=false)
    p2 = plot(sol,vars=[6,7,8,9,10], xlabel="", ylabel="people", linewidth=3, legend=false)
    p3 = plot(sol,vars=[11,12,13,14,15], xlabel="time", ylabel="people", linewidth=3, legend=false)
    p4 = plot(sol,vars=[2,7,12], xlabel="", linewidth=3, labels=["i1" "i2" "i3"], legend=true)
    p5 = plot(sol,vars=[3,8,13], xlabel="", linewidth=3,title="Populations", labels=["e1" "e2" "e3"], legend=true)
    p6 = plot(sol,vars=[5,10,15], xlabel="time", linewidth=3, labels=["d1" "d2" "d3"], legend=true)
    p = plot(p1, p5, p2, p4, p3, p6, layout=(3,2), linewidth=3, link=:both)
    savefig(p, "$(prefix)combined.pdf")
    p
end

T = [
    # City 1 SEIR
    ([1, 2], [3, 2]),
    ([3], [2]), # E→I
    ([2], [4]), # I→R
    # outflow 1→2
    ([1], [5]), # S→S′
    ([2], [6]), # I→I′
    ([3], [7]), # E→E′
    # City 2 SEIR
    ([5, 6], [7, 6]),
    ([7], [6]), # E→I
    ([6], [8]), # I→R
    # outflow 2→3
    ([5], [9]), # S→S′
    ([6], [10]),# I→I′
    ([7], [11]),# E→E′
    # City 3 SEIR
    ([9, 10], [11, 10]),
    ([11], [10]), # E→I
    ([10], [12]) # I→R
]

m = Petri.Model(1:12, T, missing, missing)
nS = length(m.S)
β = ones(Float64, length(T))
@test fluxes(m)(zeros(Float64, nS), ones(Float64, nS), β, 1) |> length == length(m.S)

tspan = (0.0,60.0)
prob = ODEProblem(fluxes(m), u₀(m, 1,0), tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
@test sol.u[end][end-3] > .90
@test sol.u[end][end-2] == 0
@test sol.u[end][end-1] == 0
@test sol.u[end][end] == 0


u0 = zeros(Float64, length(m.S))
u0[1]  = 10000
u0[5]  = 10000
u0[9]  = 10000
u0[2]  = 1
u0
βseir = [10/sum(u0), 1/2, 1/5]
βtravel = [1/2, 1/2, 1/2]/1000
β = vcat(βseir, βtravel, βseir, βtravel, βseir)
@show β
prob = ODEProblem(fluxes(m), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
@show sol.u[end]

using Plots
makeplots_seir(sol, "img/seir/baseline")


βseir = [10/sum(u0), 1/2, 1/5]
βtravel = [1/2, 1/2, 1/2]/100
β = vcat(βseir, βtravel, βseir, βtravel, βseir)
prob = ODEProblem(fluxes(m), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
@show sol.u[end]
makeplots_seir(sol, "img/seir/travel")

βseir = [10/sum(u0), 1/2, 1/5]
βtravel = [1/2, 1/200, 1/2]/100
β = vcat(βseir, βtravel, βseir, βtravel, βseir)
prob = ODEProblem(fluxes(m), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
@show sol.u[end]
makeplots_seir(sol, "img/seir/screening")

βseir = [10/sum(u0), 1/2, 1/5]
βtravel = [1/200, 1/200, 1/200]/100000
β = vcat(βseir, βtravel, βseir, βtravel, βseir)
prob = ODEProblem(fluxes(m), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
@show sol.u[end]
makeplots_seir(sol, "img/seir/shutdown")


println("Exploring the SEIRD^3 example")

S = 1:15
T = [([1, 2], [3, 2]),
     ([3], [2]),
     ([2], [4]),
     ([2], [5]),
     ([1], [6]),
     ([2], [7]),
     ([3], [8]),
     ([6, 7], [8, 7]),
     ([8], [7]),
     ([7], [9]),
     ([7], [10]),
     ([6], [11]),
     ([7], [12]),
     ([8], [13]),
     ([11, 12], [13, 12]),
     ([13], [12]),
     ([12], [14]),
     ([12], [15])]
m = Petri.Model(S, T, missing, missing)
u0 = zeros(Float64, length(m.S))
u0[1]  = 10000
u0[6]  = 10000
u0[11]  = 10000
u0[2]  = 1
u0
βseir = [10/sum(u0), 1/2, 1/5, 1/10]
βtravel = [1/2, 1/2, 1/2]/1000
β = vcat(βseir, βtravel, βseir, βtravel, βseir)
@show β
prob = ODEProblem(fluxes(m), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
@show sol.u[end]
makeplots_seird(sol, "img/seird/baseline")


function paramsweep(f::Function, m::Petri.Model, initials, tspan, params)
    map(params) do p
        prob = ODEProblem(fluxes(m), initials, tspan, p)
        sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
        return f(sol)
    end
end

packparams(βlocal, βflow) = vcat(βlocal, βflow, βlocal, βflow, βlocal)

# The βseir parameters are the mass action kinetics rates of
# 1. S+I --> E+I
# 2. E --> I
# 3. I --> R
# The βtravel parameters are the mass action kinetics rates of outflow to the next
# city in the transit network.
# 1. S --> S⁺
# 2. I --> I⁺
# 3. E --> E⁺

# Baseline scenario

βseir = [10/sum(u0), 1/2, 1/5]
βtravel = [1/2, 1/2, 1/2]/100
β1 = packparams(βseir, βtravel)

# Travel scenario
βtravel = [1/2, 1/2, 1/2]/10
β2 = packparams(βseir, βtravel)

# Screening scenario
βtravel = [1/2, 1/20, 1/2]/100
β3 = packparams(βseir, βtravel)

# Shutdown scenario
βtravel = [1/2, 1/2, 1/2]/1000
β4 = packparams(βseir, βtravel)

# Total and Complete Shutdown scenario
βtravel = [1/2, 1/2, 1/2]/10000

β5 = packparams(βseir, βtravel)
βs = [β1, β2, β3, β4, β5]

T = [
    # City 1 SEIR
    ([1, 2], [3, 2]),
    ([3], [2]), # E→I
    ([2], [4]), # I→R
    # outflow 1→2
    ([1], [5]), # S→S′
    ([2], [6]), # I→I′
    ([3], [7]), # E→E′
    # City 2 SEIR
    ([5, 6], [7, 6]),
    ([7], [6]), # E→I
    ([6], [8]), # I→R
    # outflow 2→3
    ([5], [9]), # S→S′
    ([6], [10]),# I→I′
    ([7], [11]),# E→E′
    # City 3 SEIR
    ([9, 10], [11, 10]),
    ([11], [10]), # E→I
    ([10], [12]) # I→R
]

# u0 is the initial configuration of the system
# u0[[1,5,9]] = number of initially Susceptible people in each population
# u0[2] = number of Infected individuals
u0 = zeros(Float64, length(m.S))
u0[1]  = 10000
u0[5]  = 10000
u0[9]  = 10000
u0[2]  = 1
u0

m = Petri.Model(1:12, T, missing, missing)
gaps = paramsweep(sol->peakgap(sol, 2, 10), m, u0, tspan, βs)

# prob = ODEProblem(fluxes(m), u0, tspan, βs[1])
# sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
# makeplots_seir(sol, "img/debug_1")

travelparams(k::Number) = begin
    βseir = [10/sum(u0), 1/2, 1/5]
    βtravel = [1/2, 1/2, 1/2]/(100k)
    β = packparams(βseir, βtravel)
    return β
end

travelsweep(r::AbstractVector) = begin
    return travelparams.(2 .^ r)
end


βrange = 1:8
gaps = paramsweep(sol->peakgap(sol, 2, 10), m, u0, tspan, travelsweep(βrange))


coeffs = linreg(βrange, gaps)
@test sum(abs.((coeffs[1] .+ (coeffs[2]*(βrange))) .- gaps))/length(βrange)<= 1e-1

# struct GapResult{P,G}
#     param::P
#     gap::G
# end
#
# GapResult(t::Tuple) = GapResult(t...)
#
# struct GapStudy
#     result::Vector
#     coeffs::Vector
# end
#
# slope(gs::GapStudy) = gs.coeffs[end]

function estimatedelay(r::AbstractVector)
    gaps = paramsweep(sol->peakgap(sol, 2, 10), m, u0, tspan, travelsweep(r))
    coeffs = linreg(βrange, gaps)
    return (results=zip(r, gaps), coeffs=coeffs)
end

function estimatedelay(m::Petri.Model, u0, tspan, parameters)
    gaps = paramsweep(sol->peakgap(sol, 2, 10), m, u0, tspan, parameters)
    coeffs = linreg(βrange, gaps)
    return (results=zip(parameters, gaps), coeffs=coeffs)
end

slope(gs) = gs.coeffs[end]

gs = estimatedelay(βrange)
@test slope(gs) > 1
collect(gs.results)
gs.coeffs


using Catlab
using Catlab.Doctrines
using Catlab.Graphics
using Catlab.WiringDiagrams
using Catlab.Programs
using SemanticModels.CategoryTheory
import SemanticModels.CategoryTheory: undecorate, ⊔
using SemanticModels.PetriModels
using SemanticModels.PetriCospans
import SemanticModels: model

model(c::PetriCospan) = left(c.f).d[1].model

X = FinSet(1)
Fseir = compose(exposure(X,X,X),otimes(spontaneous(X,X),id(X)),mmerge(X),mcopy(X),otimes(id(X),spontaneous(X,X)))
# states are [S, I, E, R]
seir_petri = left(Fseir.f).d[1]
f = FinSetMorph(1:4, [1, 2, 3])
g = FinSetMorph(1:4, [1, 2, 3])
Fseir′ = PetriCospan(Cospan(Decorated(f,seir_petri), Decorated(g, seir_petri)))
s = spontaneous(X,X)
Fflow = otimes(s, s, s)
@test length(model(Fseir′).S) == 4
@test length(model(Fseir′).Δ) == 3

m = model(Fseir′ ⋅ Fflow ⋅ Fseir′ ⋅ Fflow ⋅ Fseir′)

u0 = zeros(Float64, length(m.S))
u0[1]  = 10000
u0[5]  = 10000
u0[9]  = 10000
u0[2]  = 1
res = estimatedelay(m::Petri.Model, u0, tspan, travelsweep(1:8))
seirgaps = collect(map(last, res.results))

@test 1.35 <= slope(res) <= 1.45


Pseird = PetriModel(
          Petri.Model(1:5,[
            ([1,2],[3,2]), # exposure
            ([3],[2]),     # onset
            ([2],[4]),     # recovery
            ([2],[5]),     # death
            ], missing, missing))
inputs = FinSetMorph(1:5, [1,2,3])
outputs = FinSetMorph(1:5, [1,2,3])
Fcityd = PetriCospan(Cospan(Decorated(inputs, Pseird),
                            Decorated(outputs, Pseird)))
s = spontaneous(X,X)
Fflow = otimes(s, s, s)
Fcity₀ = Fcityd ⋅ Fflow
Fcity₁ = Fcityd ⋅ Fflow
Fcityₑ = Fcityd
Fcity³ = Fcity₀⋅Fcity₁⋅Fcityₑ

m = model(Fcity³)

u0 = zeros(Float64, length(m.S))
u0[1]  = 10000
u0[6]  = 10000
u0[11] = 10000
u0[2]  = 1
seirdparams(k) = begin
    βseird = [10/sum(u0), 1/2, 1/5, 1/16]
    βtravel = [1/2, 1/2, 1/2]/(100k)
    β = vcat(βseird, βtravel)
    return vcat(β, β, β)
end

gaps = paramsweep(sol->peakgap(sol, 2, 12), m,
                  u0, tspan, seirdparams.(2 .^ (1:8)))

prob = ODEProblem(fluxes(model(Fcity³)), u0, tspan, seirdparams(2))
sol = OrdinaryDiffEq.solve(prob, alg=Tsit5())

seirdgaps = gaps

@test model(Fcity³).S == 1:15
@test length(model(Fcity³).Δ) == 18

makeplots_seird(sol, "img/tmp")

gp = plot([seirgaps seirdgaps], marker=:square, labels=[:seir :seird], xlabel="2^x fold reduction in travel", ylabel="Gap between first and last epidemic", legend=:bottomright, title="Effect of model assumptions on travel restrictions")
savefig(gp, "img/gapplot.pdf")
