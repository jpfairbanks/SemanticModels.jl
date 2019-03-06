using Cassette
using DifferentialEquations
using SemanticModels.Parsers
using SemanticModels.Dubstep

# source of original problem
include("../examples/epicookbook/src/SEIRmodel.jl")
model1 = parsefile("../examples/epicookbook/src/SEIRmodel.jl")

#the functions we want to modify
seir_ode = SEIRmodel.seir_ode

# source of the problem we want to take from
expr = parsefile("../examples/epicookbook/src/ScalingModel.jl")
model2 = expr


# Find the expression we want to graft
#vital dynamics S rate expression
micro1def = findfunc(expr, :micro_1)[1]
vdsre = findassign(micro1def, :dS)[1]
vdsre = replacevar(vdsre, :K,:N)
@show popgrowth = vdsre.args[2].args[2]


model_1 = ModelTool.model(ModelTool.ExpODEProblem, model1)
model_2 = ModelTool.model(ModelTool.ExpODEProblem, model2)
lhs(x::Expr) = begin
    @show x
    x.head == :(=) || error("x is not an assignment")
    return x.args[1]
end
fluxes(x::ModelTool.ExpODEProblem) = x.variables[1].flux

# fluxvar = lhs(fluxes(model_2)[1].args[2])
fluxvar = fluxes(model_2)[1].args[2].args[1]
popgrowth = replacevar(findassign(model_2.funcs[1], fluxvar)[1], :K, :N).args[2].args[2]
ex = model_1.variables[1].flux[1]
# TODO: add N=sum(S,E,I)
ex.args[2] = :($(popgrowth)+$(ex.args[2]))
function pusharg!(ex::Expr, s::Symbol)
    ex.head == :function || error("ex is not a function definition")
    push!(ex.args[1].args, s)
    return ex
end

pushfirst!(model_1.funcs[1].args[2].args, :(N = sum(Y)))
pusharg!(model_1.funcs[1], :r)
model_1.funcs[1].args[1].args[1] = gensym(model_1.funcs[1].args[1].args[1])
@show(model_1.funcs[1])
f′ = eval(model_1.funcs[1])

# generate the function newfunc
# this eval happens at the top level so should only happen once
# newfunc = eval(:(fpopgrowth(r,S,N) = $popgrowth))

# # This is the new problem
# # notice the signature doesn't even match, we have added a new parameter
# function fprime(dY,Y,p,t, ϵ)
#     #Infected per-Capita Rate
#     β = p[1]
#     #Incubation Rate
#     σ = p[2]
#     #Recover per-capita rate
#     γ = p[3]
#     #Death Rate
#     μ = p[4]

#     #Susceptible Individual
#     S = Y[1]
#     #Exposed Individual
#     E = Y[2]
#     #Infected Individual
#     I = Y[3]
#     #Recovered Individual
#     #R = Y[4]

#     # here is the graft point
#     dY[1] = μ-β*S*I-μ*S + newfunc(ϵ, S, S+E+I)
#     dY[2] = β*S*I-(σ+μ)*E
#     dY[3] = σ*E - (γ+μ)*I
# end

# define the overdub behavior, all the fucntions needed to be defined at this point
# using run time values slows down overdub.
function Cassette.overdub(ctx::Dubstep.GraftCtx, f::typeof(seir_ode), args...)
    # this call matches the new signature
    return Cassette.fallback(ctx, f′, args..., ctx.metadata[:lambda])
end


# set up our modeling configuration
function g()
    #Pram (Infected Rate, Incubation Rate, Recover Rate, Death Rate)
    pram=[520/365,1/60,1/30,774835/(65640000*365)]
    #Initialize Param(Susceptible Individuals, Exposed Individuals, Infected Individuals)
    init=[0.8,0.1,0.1]
    tspan=(0.0,365.0)

    seir_prob = ODEProblem(seir_ode,init,tspan,pram)

    sol=solve(seir_prob);
end

# sweep over population growth rates
function scalegrowth(λ=1.0)
    # ctx.metadata holds our new parameter
    ctx = Dubstep.GraftCtx(metadata=Dict(:lambda=>λ))
    return Cassette.overdub(ctx, g)
end

println("S\tI\tR")
for λ in [1.0,1.1,1.2]
    @time S,I,R = scalegrowth(λ)(365)
    println("$S\t$I\t$R")
end
#it works!
