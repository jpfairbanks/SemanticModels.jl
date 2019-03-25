stripunits(x) = uconvert(NoUnits, x)

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
        sir = SemanticModels.BasicSIR()

        β = sir.equations[1].parameters[1]
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
    prob = odeproblem(springmodel)
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
    @test sol(sol.t[end])[1] < u"1e-4*1person"
    @test sol(sol.t[end])[end] > u"99*1person"
end

@testset "combined_meters" begin
    springmodel = SpringModel([u"1.0s^-2"], (u"0s",4π*u"s"), [u"1.0m", u"0m/s"])
    prob = odeproblem(springmodel)
    sol = solve(springmodel)
    @test sol(u"4π*1s")[1] - u"1m" < u"1e-4*1m"

    initialS = sol.u[end][1] * 100
    initialI = abs(sol.u[end][2] *u"200s" + u"1m")
    initialpop = [initialS, initialI, u"0.0m"]
    sirprob = SIRSimulation(initialpop, (u"0.0s", u"20s"), SIRParams(u"40.0/s", u"20.0m/s"))
    sirsol = solve(odeproblem(sirprob), alg=Vern9(),  dt = u"0.1s")

    # test that everything is converted from S to R
    @test sirsol(sirsol.t[end])[1] < u"1e-4*1m"
    @test sirsol(sirsol.t[end])[end] > 0.99 * sirsol(sirsol.t[1])[1]

end

@testset "CombinedModel" begin
    springmodel = SpringModel([u"1.0s^-2"], (u"0s",4π*u"s"), [u"1.0m", u"0m/s"])
    function create_sir(m, solns)
        sol = solns[1]
        initialS = sol.u[end][1] * 100
        initialI = abs(sol.u[end][2] *u"200s" + u"1m")
        initialpop = [initialS, initialI, u"0.0m"]
        sirprob = SIRSimulation(initialpop, (u"0.0s", u"20s"), SIRParams(u"40.0/s", u"20.0m/s"))
        return sirprob
    end
    cm = CombinedModel([springmodel], create_sir)

    sirsol = solve(cm)

    # test that everything is converted from S to R
    @test sirsol(sirsol.t[end])[1] < u"1e-4*1m"
    @test sirsol(sirsol.t[end])[end] > 0.99 * sirsol(sirsol.t[1])[1]
end

@testset "Regression Example" begin
    START_YR = 2000
    STOP_YR = 2005

    df = generate_synthetic_data(100, START_YR, STOP_YR)
    yhat = ols(df, rand(Uniform(50,100)), STOP_YR+1)
end

@testset "FluModel" begin

    tfinal = 4π*u"d"
    springmodel = SpringModel([u"1.0d^-2"], (u"0d",tfinal), [u"25.0C", u"0C/d"])
    function create_sir(m, solns)
        sol = solns[1]
        initialS = u"10000person" #sol.u[end][1] * 100
        initialI = abs(sol.u[end][1] *u"2person/C" + u"1person")
        initialpop = [initialS, initialI, u"0.0person"]
        γ = u"3.0person/d" / u"C" * sol(sol.t[end])[1]
        @show γ
        sirprob = SIRSimulation(initialpop, (u"0.0d", u"20d"), SIRParams(u"40.0/d", γ))
        return sirprob
    end

    function create_flu(cm, solns)
        sol = solns[1]
        finalI = stripunits(sol(sol.t[end])[2])
        population = stripunits(sol(sol.t[end])[2])
        # population = stripunits(sum(sol.u[end]))
        df = generate_synthetic_data(population, 0,100)
        f = @formula(vaccines_produced ~ flu_patients)
        model =  lm(f, df[2:length(df.year), [:year, :flu_patients, :vaccines_produced]])
        println("GLM Model:")
        println(model)

        year_to_predict = 50
        num_flu_patients_from_sim = finalI
        vaccines_produced = missing
        targetDF = DataFrame(year=year_to_predict, flu_patients=num_flu_patients_from_sim, vaccines_produced=missing)
        @show targetDF

        # predicted_num_vaccines = predict(model, targetDF)
        # println("Predicted number of vaccines based on simulated number of flu patients for year ", year_to_predict, " = ", ceil(predicted_num_vaccines[1]))
        # β = solve(RegressionProblem(f, model, targetDF, missing))
        return RegressionProblem(f, model, targetDF, missing)
    end
    cm = CombinedModel([springmodel], create_sir)
    flumodel = CombinedModel([cm], create_flu)
    sol = solve(flumodel)
    @test ceil(Int, sol[1]) >= 4393

    spsol = solve(springmodel)
    # plot(map(x->spsol(x)[1]/Unitful.C, collect(spsol.t[1]:0.1s:spsol.t[end])))
    print(spsol)
    print(solve(cm).u)
    # plot(solve(cm))
    print(solve(flumodel))
end

@testset "knowledge" begin
isa = "isa"
unit = "Unit"
knowledge = [
    :(u"m", isa, unit),
    (u"s", isa, unit),
    (u"m", "instantiates", "Distance"),
    (u"s", isa, "Time"),
    (u"person", isa, unit),
    (u"person", "instantiates", "Quantity"),
    ("sir","solvedby","ODEs"),
    :(springmodel,solvedby,ODEs),
    :(
        (x, represented, m),
        (springmodel, isa, ODEModel),
        (springmodel, var(1), x),
        (springmodel, var(2), dx/dt),
        (sirmodel, var(1), S),
        (sirmodel, var(2), I),
        (sirmodel, var(2), R)
    )
]
path(x, R) = :(
    (springmodel, var(1), x),
    (x, measured_in, m),
    (S, measured_in, m),
    (sirmodel, var(1), S),
    (sirmodel, var(3), R)
)
end
