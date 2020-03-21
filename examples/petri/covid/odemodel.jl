using OrdinaryDiffEq
import OrdinaryDiffEq: ODEProblem
using Petri
using Test

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

function makeplots(sol, dir)
    mkpath(dir)
    p = plot(sol,vars=[1,2,3,4], linewidth=3,title="City 1")
    savefig(p, "$dir/city1.pdf")
    p = plot(sol,vars=[5,6,7,8], linewidth=3,title="City 2")
    savefig(p, "$dir/city2.pdf")
    p = plot(sol,vars=[9,10,11,12], linewidth=3,title="City 3")
    savefig(p, "$dir/city3.pdf")
    p = plot(sol,vars=[2,6,10], linewidth=3,title="Infectious Population")
    savefig(p, "$dir/infections.pdf")
    p = plot(sol,vars=[3,7,11], linewidth=3,title="Exposed Population")
    savefig(p, "$dir/exposures.pdf")
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
makeplots(sol, "img/baseline")


βseir = [10/sum(u0), 1/2, 1/5]
βtravel = [1/2, 1/2, 1/2]/100
β = vcat(βseir, βtravel, βseir, βtravel, βseir)
prob = ODEProblem(fluxes(m), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
@show sol.u[end]
makeplots(sol, "img/travel")

βseir = [10/sum(u0), 1/2, 1/5]
βtravel = [1/2, 1/200, 1/2]/100
β = vcat(βseir, βtravel, βseir, βtravel, βseir)
prob = ODEProblem(fluxes(m), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
@show sol.u[end]
makeplots(sol, "img/screening")

βseir = [10/sum(u0), 1/2, 1/5]
βtravel = [1/200, 1/200, 1/200]/100000
β = vcat(βseir, βtravel, βseir, βtravel, βseir)
prob = ODEProblem(fluxes(m), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
@show sol.u[end]
makeplots(sol, "img/shutdown")
