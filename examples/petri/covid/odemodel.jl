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
        # @show du
        # du = zeros(Float64, nS)
        # @show u
        # @show p
        # @show t
        for (i, t) in enumerate(T)
            # @show i
            ins = t[1]
            # TODO: accomodate multiplicites here
            # @show u[ins]
            ϕ[i] = p[i]*prod(u[ins])
        end
        # println("DEBUG: done with loop over T")
        # println("DEBUG: zeroing out du")
        for i in S
            du[i] = 0
        end
        # println("DEBUG: done zeroing out du")
        # println("DEBUG: starting with loop over T")
        for (i, t) in enumerate(T)
            # println("DEBUG: $i, $t")
            ins = t[1]
            out = t[2]
            for s in ins
                # println("DEBUG: starting with loop over ins")
                # TODO: accomodate multiplicites here
                du[s] -= ϕ[i]
            end
            for s in out
                # println("DEBUG: starting with loop over out")
                # TODO: accomodate multiplicites here
                du[s] += ϕ[i]
            end
        end
        return du
    end
    return f
end

u₀(m::Petri.Model) = begin
    u0=zeros(Float64, length(m.S))
    u0[1] = 1.0
    return u0
end

ODEProblem(m::Petri.Model, tspan, p) = ODEProblem(fluxes(m), u₀(m), tspan, p)

T = [
    # SEIR 1
     ([1, 2], [3, 2]),
     ([3], [2]),
     ([2], [4]),
     # outflow 1→2
     ([1], [5]),
     ([2], [6]),
     ([3], [7]),
     # inflow 1→2
     ([5], [8]),
     ([6], [9]),
     ([7], [10]),
    # SEIR 2
     ([8, 9], [10, 9]),
     ([10], [9]),
     ([9], [11]),
     # outflow 2→3
     ([8], [12]),
     ([9], [13]),
     ([10], [14]),
     # inflow 2→3
     ([12], [15]),
     ([13], [16]),
     ([14], [17]),
    # SEIR 3
     ([15, 16], [17, 16]),
     ([17], [16]),
     ([16], [18])
]

m = Petri.Model(1:18, T, missing, missing)
β = ones(Float64, length(T))
@test fluxes(m)(zeros(Float64, length(m.S)), ones(Float64, length(m.S)), β, 1) |> length == length(m.S)

tspan = (0.0,60.0)
prob = ODEProblem(m,tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
@test sol.u[end][end-3] > .90
@test sol.u[end][end-2] == 0
@test sol.u[end][end-1] == 0
@test sol.u[end][end] == 0


u0 = zeros(Float64, length(m.S))
u0[1]  = 10000
u0[8]  = 10000
u0[15] = 10000
u0[2]  = 1

βseir = [10/sum(u0), 1/2, 1/5]
βtravel = [1/2, 1/2, 1/2, 50, 50, 50]/1000
β = vcat(βseir, βtravel, βseir, βtravel, βseir)
prob = ODEProblem(fluxes(m), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
@show sol.u[end]
# @show sol
using Plots
#
p = plot(sol,vars=[1,2,3,4], linewidth=3,title="City 1")
savefig(p, "city1.pdf")
p = plot(sol,vars=[8,9,10,11], linewidth=3,title="City 2")
savefig(p, "city2.pdf")
p = plot(sol,vars=[15,16,17,18], linewidth=3,title="City 3")
savefig(p, "city3.pdf")
p = plot(sol,vars=[2,9,16], linewidth=3,title="Infectious Population")
savefig(p, "infections.pdf")
p = plot(sol,vars=[3,10,17], linewidth=3,title="Exposed Population")
savefig(p, "exposures.pdf")

p = plot(sol,vars=[5,6,7], linewidth=3,title="Immigration Queue 1 to 2")
savefig(p, "immigration1to2.pdf")
p = plot(sol,vars=[12,13,14], linewidth=3,title="Immigration Queue 2 to 3")
savefig(p, "immigration2to3.pdf")
# plot(sol,vars=[1,8,15], linewidth=3,title="Curve")

βseir = [10/sum(u0), 1/2, 1/5]
βtravel = [1/2, 1/2, 1/2, 50, 50, 50]/100
β = vcat(βseir, βtravel, βseir, βtravel, βseir)
prob = ODEProblem(fluxes(m), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
@show sol.u[end]
# @show sol
using Plots
#
p = plot(sol,vars=[1,2,3,4], linewidth=3,title="City 1")
savefig(p, "travel-city1.pdf")
p = plot(sol,vars=[8,9,10,11], linewidth=3,title="City 2")
savefig(p, "travel-city2.pdf")
p = plot(sol,vars=[15,16,17,18], linewidth=3,title="City 3")
savefig(p, "travel-city3.pdf")
p = plot(sol,vars=[2,9,16], linewidth=3,title="Infectious Population")
savefig(p, "travel-infections.pdf")
p = plot(sol,vars=[3,10,17], linewidth=3,title="Exposed Population")
savefig(p, "travel-exposures.pdf")

p = plot(sol,vars=[5,6,7], linewidth=3,title="Immigration Queue 1 to 2")
savefig(p, "travel-immigration1to2.pdf")
p = plot(sol,vars=[12,13,14], linewidth=3,title="Immigration Queue 2 to 3")
savefig(p, "travel-immigration2to3.pdf")

βseir = [10/sum(u0), 1/2, 1/5]
βtravel = [1/2, 1/200, 1/2, 50, 50, 50]/100
β = vcat(βseir, βtravel, βseir, βtravel, βseir)
prob = ODEProblem(fluxes(m), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
@show sol.u[end]
# @show sol
using Plots
#
p = plot(sol,vars=[1,2,3,4], linewidth=3,title="City 1")
savefig(p, "screening-city1.pdf")
p = plot(sol,vars=[8,9,10,11], linewidth=3,title="City 2")
savefig(p, "screening-city2.pdf")
p = plot(sol,vars=[15,16,17,18], linewidth=3,title="City 3")
savefig(p, "screening-city3.pdf")
p = plot(sol,vars=[2,9,16], linewidth=3,title="Infectious Population")
savefig(p, "screening-infections.pdf")
p = plot(sol,vars=[3,10,17], linewidth=3,title="Exposed Population")
savefig(p, "screening-exposures.pdf")

p = plot(sol,vars=[5,6,7], linewidth=3,title="Immigration Queue 1 to 2")
savefig(p, "screening-immigration1to2.pdf")
p = plot(sol,vars=[12,13,14], linewidth=3,title="Immigration Queue 2 to 3")
savefig(p, "screening-immigration2to3.pdf")

βseir = [10/sum(u0), 1/2, 1/5]
βtravel = [1/200, 1/200, 1/200, 50, 50, 50]/100000
β = vcat(βseir, βtravel, βseir, βtravel, βseir)
prob = ODEProblem(fluxes(m), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
@show sol.u[end]

p = plot(sol,vars=[1,2,3,4], linewidth=3,title="City 1")
savefig(p, "shutdown-city1.pdf")
p = plot(sol,vars=[8,9,10,11], linewidth=3,title="City 2")
savefig(p, "shutdown-city2.pdf")
p = plot(sol,vars=[15,16,17,18], linewidth=3,title="City 3")
savefig(p, "shutdown-city3.pdf")
p = plot(sol,vars=[2,9,16], linewidth=3,title="Infectious Population")
savefig(p, "shutdown-infections.pdf")
p = plot(sol,vars=[3,10,17], linewidth=3,title="Exposed Population")
savefig(p, "shutdown-exposures.pdf")

p = plot(sol,vars=[5,6,7], linewidth=3,title="Immigration Queue 1 to 2")
savefig(p, "shutdown-immigration1to2.pdf")
p = plot(sol,vars=[12,13,14], linewidth=3,title="Immigration Queue 2 to 3")
savefig(p, "shutdown-immigration2to3.pdf")
