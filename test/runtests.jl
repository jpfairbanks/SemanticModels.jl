# using Base.Tests
using Test
using Semantics
using Semantics.Unitful
import Semantics.Unitful: DimensionError
using DifferentialEquations

@testset "spring models" begin

    springmodel = SpringModel([1.0], (0,4π), [1.0, 0.0])
    solslow = solve(odeproblem(springmodel))
    @test abs(solslow(π/2)[1]) < 1e-6
    @test abs(solslow(3π/2)[1]) < 1e-4

    accelerate!(springmodel, 4.0)
    solfast = solve(odeproblem(springmodel), atol=1e-8)
    @test abs(solfast(π/2)[1]+1) < 1e-5
    @test_skip abs(solfast(3π/2)[1]+1) < 1e-4
    @test abs(solfast(π/4)[1]) < 1e-5
    @test abs(solfast(3π/4)[1]) < 1e-4

end

@testset "SIR" begin
    function test1()
        sir = Semantics.BasicSIR()
        # @show sir

        β = sir.equations[1].parameters[1]
        @show β
        @test (4*β.unit + 6β.unit) * 3u"s" == u"30person"
        @test u"24person" + u"1kperson" == u"1024person"
        @test u"24person" + u"1kperson/s"*u"3s" == u"3024person"
        @test_throws DimensionError 4*β.unit + (6β.unit) * 3u"s" 
    end
    test1()
end

function RealSIR()
    # β = NumParameter(:β, u"person/s", TransitionRate)
    # γ = NumParameter(:γ, u"person/s", TransitionRate)
    # @show β, γ

    # S = NumVariable(:S, u"person", Amount)
    # I = NumVariable(:I, u"person", Amount)
    # R = NumVariable(:R, u"person", Amount)

    # sir = SIR([ODE(:(dS/dt -> -βSI/N),
    #             [β], [S]),
    #             ODE(:(dI/dt -> βSI/N -γI),
    #                 [β, γ], [S, I]),
    #         ODE(:(dR/dt -> γI), [γ], [I])],
    #         NumVariable.([:N,:S,:I,:R], u"person", Amount),
    #         NumVariable(:t, u"s", Amount))

    return odeproblem(SIRSimulation([100,1,0.0],
                      (0,100.0),
                       SIRParams(0.50,5.0)))
end
# test case where nothing happens because of *0.0
    # return odeproblem(SIRSimulation([100,0,0.0],
    #                   (0,10.0),
    #                    SIRParams(1.0,0.2)))
@testset "real sir" begin
    sir = RealSIR()
    solsir = solve(sir)
    @test solsir[end][1] < 1
    @test solsir[end][end] > 99
end

@testset "spring_units" begin
    springmodel = SpringModel([u"1.0s^-2"], (u"0s",4π*u"s"), [u"1.0m", u"0m/s"])
    @show prob = odeproblem(springmodel)
    sol = solve(springmodel)
    t = u"π/2*1s"
    v = (1e-6)*u"m"
    @test sol(u"4π*1s")[1] - u"1m" < u"1e-4*1m" 
end

@testset "sir_meters" begin
    initialpop = [99, 1, 0.0].*u"m"
    prob = SIRSimulation(initialpop, (u"0.0s", u"200s"), SIRParams(u"40.0/s", u"20.0m/s"))   
    sol = solve(odeproblem(prob), alg=Vern9(),  dt = u"0.1s")
    @test sol(sol.t[end])[1] < u"1e-4*1m"
    @test sol(sol.t[end])[end] > u"99m"
end

@testset "sir_units" begin
    initialpop = [99, 1, 0.0].*u"person"
    prob = SIRSimulation(initialpop, (u"0.0minute", u"75minute"), SIRParams(u"40.0/minute", u"20.0person/minute"))   
    sol = solve(odeproblem(prob), alg=Vern9(),  dt = u"0.1minute")
    @show sol
    @test sol(sol.t[end])[1] < u"1e-4*1person"
    @test sol(sol.t[end])[end] > u"99*1person"
end