module Graft
using Cassette
using DifferentialEquations

include("../examples/epicookbook/src/SEIRmodel.jl")
seir_ode = SEIRmodel.seir_ode

using SemanticModels.Parsers
expr = parsefile("examples/epicookbook/src/ScalingModel.jl")

#vital dynamics S rate expression
vdsre = expr.args[3].args[5].args[2].args[4]
@show popgrowth = vdsre.args[2].args[2]
replacevar(expr, old, new) = begin
    dump(expr)
    expr.args[3].args[3].args[3] = new
    return expr
end
popgrowth = replacevar(popgrowth, :K,:N)
newfunc = eval(:(fpopgrowth(r,S,N) = $popgrowth))

function fprime(dY,Y,p,t, ϵ)
    #Infected per-Capita Rate
    β = p[1]
    #Incubation Rate
    σ = p[2]
    #Recover per-capita rate
    γ = p[3]
    #Death Rate
    μ = p[4]

    #Susceptible Individual
    S = Y[1]
    #Exposed Individual
    E = Y[2]
    #Infected Individual
    I = Y[3]
    #Recovered Individual
    #R = Y[4]

    dY[1] = μ-β*S*I-μ*S + newfunc(ϵ, S, S+E+I)
    dY[2] = β*S*I-(σ+μ)*E
    dY[3] = σ*E - (γ+μ)*I
end


Cassette.@context GraftCtx


"""    GraftCtx

grafts an expression from one simulation onto another

This context is useful for modifying simulations by changing out components to add features

see also: [`Dubstep.LPCtx`](@ref)
"""
GraftCtx

function Cassette.overdub(ctx::GraftCtx, f, args...)
    if Cassette.canrecurse(ctx, f, args...)
        newctx = Cassette.similarcontext(ctx, metadata = ctx.metadata)
        return Cassette.recurse(newctx, f, args...)
    else
        return Cassette.fallback(ctx, f, args...)
    end
end

function Cassette.overdub(ctx::GraftCtx, f::typeof(seir_ode), args...)
    return Cassette.fallback(ctx, fprime, args..., ctx.metadata[:lambda])
end

"""    replacefunc(f::Function, d::AbstractDict)

run f, but replace every call to f using the mapping in d.
"""
function replacefunc(f::Function, d::AbstractDict)
    ctx = GraftCtx(metadata=d)
    return Cassette.recurse(ctx, f)
end

end #module

using Cassette
using DifferentialEquations


function g()
    #Pram (Infected Rate, Incubation Rate, Recover Rate, Death Rate)
    pram=[520/365,1/60,1/30,774835/(65640000*365)]
    #Initialize Param(Susceptible Individuals, Exposed Individuals, Infected Individuals)
    init=[0.8,0.1,0.1]
    tspan=(0.0,365.0)

    seir_prob = ODEProblem(Graft.seir_ode,init,tspan,pram)

    sol=solve(seir_prob);
end

function scalegrowth(λ=1.0)
    ctx = Graft.GraftCtx(metadata=Dict(:lambda=>λ))
    return Cassette.overdub(ctx, g)
end
println("S\tI\tR")
for λ in [1.0,1.1,1.2]
    S,I,R = scalegrowth(λ)(365)
    println("$S\t$I\t$R")
end
