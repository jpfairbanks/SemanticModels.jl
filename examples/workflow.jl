# -*- coding: utf-8 -*-
# # Augmenting Model Workflows
#
# We can apply our model augmentation framework to models that are compositions of component models.

# We are going to use the model augmentation presented in `examples/agentgraft.jl` as a baseline simulation and build a workflow to compose that model with the example in `examples/polynomial_regression.jl`. It is strongly recommended that you understand those examples before following this notebook.

# This example combines an agent based model of SIR diseases with a statistical model of polynomial regression to quantify the response of the agent based model with respect to one of its parameters. The input models have to be composed carefully in order to make the software work.
#
# As taught by the scientific computing education group [Software Carpentry](https://swcarpentry.github.io/), the best practice for composing scientific models is to have each component write files to disk and then use a workflow tool such as [Make](https://swcarpentry.github.io/make-novice/) to orchestrate the execution of the modeling scripts.
#
# An alternative approach is to design modeling frameworks for representing the models. The problem with this avenue becomes apparent when models are composed. The frameworks must be interoperable in order to make combined models. ModelTools avoids this problem by representing the models as code and manipulating the codes. The interoperation of two models is defined by user supplied functions in a fully featured programming language. 

# Let $m_1,m_2$ be models, and $t_1,t_2$ be tranformations and define $M_i = t_i(m_i)$. If we denote the creation of pipelines with the function composition symbol $g\circ f$ then we want to implement everything such that the following diagram commutes.
# <p><img src="../doc/build/img/commutative_pipeline.dot.svg" alt="A diagram showing how pipelining commutes with tranforming models"></p>
#
# This example shows how you can use a pipeline to represent the combination of models and then apply combinations of transformations to that pipeline. Transforming models and composing them into pipelines are two operations that commute, you can transform then compose or compose and then transform.

using SemanticModels.Parsers
using SemanticModels.ModelTools
using SemanticModels.ModelTools.ExpStateModels
import Base: push!
import SemanticModels.ModelTools: model, isexpr
using Random

samples = 100
nsteps = 25
finalcounts = Any[]

println("Running Agent Based Simulation Augmentation Demo")
println("================================================")
println("demo parameters:\n\tsamples=$samples\n\tnsteps=$nsteps")


# ## Baseline SIRS model
#
# Here is the baseline model, which is read in from a text file. You could instead of using `parsefile` use a `quote/end` block to code up the baseline model in this script. 
#
# <img src="https://docs.google.com/drawings/d/e/2PACX-1vSeA7mAQ-795lLVxCWXzbkFQaFOHMpwtB121psFV_2cSUyXPyKMtvDjssia82JvQRXS08p6FAMr1hj1/pub?w=1031&amp;h=309">

expr = parsefile("../examples/agentbased.jl")
m = model(ExpStateModel, expr)


function returns(block::Vector{Any})
    filter(x->(head(x)==:return), block)
end
returntuples = (bodyblock(filter(x->isa(x, Expr), findfunc(m.expr, :main))[end]) 
    |> returns 
    .|> x-> x.args[1].args )
push!(returntuples[1], :((ρ=ρ, μ=μ, n=n)))

magents = m
println("\nRunning basic model")
AgentModels = eval(m.expr)
@show AgentModels
for i in 1:samples
    println(("======= . Simulation $i  ========"))
    newsam, counts, params = AgentModels.main(nsteps)
    push!(finalcounts, (model=:basic, counts=counts, params=params))
end


@show length(finalcounts)
finalcounts

ModelTools.invoke(magents, 10)[2:end]

# ## Statistical Regression Model
# The following expression defines a univariate polynomial regression model of degree 0, which just computes the average of target variable. This model can be augmented to an polynomial regression model using transformations
# $T_1,T_x$ which will be defined later.

# +

expr = quote
    module Regression
    using Random
    using LsqFit
    using LinearAlgebra

    function f(x, β)
        # This .+ node is added so that we have something to grab onto
        # in the metaprogramming. It is the ∀a .+(a) == a. 
        return .+(β[1].* x.^0)
    end

    function sample(g::Function, n)
        x = randn(Float64, n)
        target = g(x) .+ randn(Float64, n[1])./1600
        return x, target
    end

    function describe(fit)
        if !fit.converged
            error("Did not converge")
        end
        return (β = fit.param, r=norm(fit.resid,2), n=length(fit.resid))
    end
    #setup
    a₀ = [1.0]
    function main(X, target)
        #solving
        fit = curve_fit(f, X, target, a₀)#; autodiff=:forwarddiff)
        result = describe(fit)
        return fit, result
    end
end
end
Regression = eval(expr.args[2])
# -

function connector(finalcounts)
    n = length(finalcounts)
    Data = zeros(n,length(finalcounts[1].counts))
    @show size(Data)
    for i in 1:n
        c = finalcounts[i].counts
        Data[i, : ] = map(last, c)
    end
    # multivariate regression not yet supported
    # X = Data[:, 1:end-2]
    # Y = Data[:, end]
    # @assert(size(X) == (n,size(Data,2)-2))
    # @assert(size(Y) == (n,))
    X = Data[:, 1]
    Y = Data[:, 2]
    @assert size(X,1) == size(Y,1)
    return X,Y
end

X,Y = connector(finalcounts)
collect(zip(X,Y))

fit, result = Regression.main(connector(finalcounts)...)
result

if sum(fit.resid)/length(fit.resid) > 1e-8
    @warn "Mean residual is large, regression might have failed"
end


# ## Implementation Details
# The following code is the implementation details for representing the models as an `AbstractProblem` and representing the transformations as `Product{Tuple{Pow{Int}, Pow{Int}}}` and applying the transformations onto the models.
#
# See the `examples/polynomial_regression.jl` example for details of what this code does.

using LinearAlgebra
using SemanticModels
using SemanticModels.ModelTools
using SemanticModels.ModelTools.Transformations
import SemanticModels.ModelTools: model, AbstractModel, isexpr
import SemanticModels.Parsers: findfunc, findassign
import Base: show

# +
"""    Lsq


A program that solves min_β || f(X,β) - y ||_2

Example:

`f(X, β) = β[1].*X.^p .+ β[2].*X.^q`

See also [`(t::Pow)(m::MultivariateLsq)`](@ref)
"""
struct Lsq <: AbstractModel
    expr
    f
    coefficient
    p₀
end

function show(io::IO, m::Lsq)
    write(io, "Lsq(\n  f=$(repr(m.f)),\n  coefficient=$(repr(m.coefficient)),\n  p₀=$(repr(m.p₀))\n)")
end

function model(::Type{Lsq}, expr::Expr)
    if expr.head == :block
        return model(Lsq, expr.args[2])
    end
    objective = :l2norm
    f = callsites(expr, :curve_fit)[end].args[2]
    coeff = callsites(expr, f)[1].args[end]
    p₀ = callsites(expr, :curve_fit)[end].args[end]
    return Lsq(expr, f, coeff, p₀)
end

"""    poly(m::Lsq)::Expr

find the part of the model that implements the polynomial model for regression.
"""
function poly(m::Lsq)
    func = findfunc(m.expr, m.f)[1]
    poly = func.args[2].args[end].args[1]
    return poly
end

"""    (t::Pow)(m::Lsq)

Example:

If `m` is a program implementing `f(X, β) = β[1]*X^p + β[2]*X^q`

a) and `t = Pow(2)` then `t(m)` is the model implementing
`f(X, β) = β[1]*X^p+2 + β[2]*X^q+q`.

"""
function (t::Pow)(m::Lsq)
    p = poly(m)
    for i in 2:length(p.args)
        slot = p.args[i]
        pow = callsites(slot, :(.^))
        pow[end].args[3] += t.inc
    end
    return m
end

# +
struct AddConst <: Transformations.Transformation end

"""    (c::AddConst)(m::MultivariateLsq)

Example:

If `m` is a program implementing `f(X, β) = β[1]*X^p + β[2]*X^q`

a) and `c = AddConst()` then `c(m)` is the model implementing
`f(X, β) = β[1]*X^p + β[2]*X^0`.

"""
function (c::AddConst)(m::Lsq)
    p = poly(m)
    ix = map(t->t.args[2].args[2], p.args[2:end])
    i = maximum(ix)+1
    @show p
    push!(p.args, :(β[$i].*x.^0))
    assigns = findassign(m.expr, m.p₀)
    @show assigns
    b = assigns[end].args[2].args
    push!(b, 1)
    return m
end
# -

# ## Model Augmentation yields polynomial regression
# Given our transformations `f(x) -> xf(x)` and `f(x) -> f(x) + beta` we are able to generate all possible polynomial regression using composition of these transformations.

# Let's build an instance of the model object from the code snippet expr
m = model(Lsq, deepcopy(expr))
mstats = deepcopy(m)
@show m
poly(m)

# Some *generator elements* will come in handy for building elements of the transformation group.
# $T_x,T_1$ are *generators* for our group of transformations $T = \langle T_x, T_1 \rangle$. $T_1$ adds a constant to our polynomial and $T_x$ increments all the powers of the terms by 1. Any polynomial can be generated by these two operations. The proof of Horner's rule for evaluating $p(x)$ gives a construction for how to create $f(x,\beta) = p(x)$ from these two operations.  

@show Tₓ = Pow(1)
@show T₁ = AddConst()
Tₓ, T₁

m′ = deepcopy(m)
Tₓ(m′)
T₁(m′)
@show poly(m)
Regression = eval(m′.expr)

@show m′.expr
fit′, result′ = Regression.main(connector(finalcounts)...)
result′

result′.r

# # Model workflows
#
# Models can be chained together into workflows, the most basic type is a pipeline where the outputs from model $m_i$ are passed to model $m_{i+1}$. One area where traditional modeling frameworks get in trouble is the fact that the connections between the models can be arbitrarily complex. Thus any modeling framework that supports worflows, must embed a programming language for describing the connectors between the steps of the workflow.
#
# Since we are already embedded in Julia, we will use regular Julia functions for the connectors.
#
# Mathematically, a pipeline is defined as $r_n = P(m_1,\dots,m_n, c_1,\dots,c_n)$ based on the recurrence,
#
# $r_0 = m_1(c)$ where $c$ is a constant value, and 
#
# $r_i = m_i(c_i(r_{i-1}))$
#
#
# We store the values of $r_i$ in the field results so that they can be accessed later by visualization and  analysis programs.

# +
module Pipelines
using SemanticModels.ModelTools
using Random
struct Pipeline <: AbstractModel
    steps
    connectors
    results
end

function run!(p::Pipeline)
    stages = length(p.steps)
    connectors = p.connectors
    for s in 1:stages
        data = p.results[end]
        r = connectors[s](p.steps[s], data...)
        push!(p.results, r)
    end
end

function reset!(p::Pipeline)
    while length(p.results) > 1
        pop!(p.results)
    end
    return p
end
end
# -

# ## Running the baseline workflow
#
# This workflow connects the two models so that we simulate the agent based model and then perform a regression on the outputs.

P = Pipelines.Pipeline(deepcopy.([magents, mstats]),
    [(m, args...) -> begin 
            Random.seed!(42)
            results = Any[]
            Mod = eval(m.expr)
            for i in 1:samples
                r = Base.invokelatest(Mod.main, args...)
                push!(results, (model=:basic, counts=r[2], params=r[3]))
                #push!(results, r)
            end
            return [results]
                end,
        (m, results...) -> begin
            data = connector(results...)
            Mod = eval(m.expr)
            Base.invokelatest(Mod.main, data...) end
        ],
        Any[(10)]
        )    

# Warning: Pipelines can only be run once. Recreate the pipeline and run it again if necessary.

Pipelines.run!(P)

for r in P.results[end]
    println(r)
    println("==========")
end


Tₓ(P.steps[2])
T₁(P.steps[2])
Tₓ(P.steps[2])
T₁(P.steps[2])

Pipelines.reset!(P)
Pipelines.run!(P)
P.results[end][2]

# 1. TODO implement the composition monoid on ExpStateModels
# 2. TODO use Product acting on Pipeline to represent Tuple.coordinates == Pipeline.steps

# Product = ModelTools.Transformations.Product
function (t::Product)(m::Pipelines.Pipeline)
    for (i, s) in enumerate(m.steps)
        t.dims[i](s)
    end
end


# ## Adding the Dead State
#
# <img src="https://docs.google.com/drawings/d/e/2PACX-1vRUhrX6GzMzNRWr0GI3pDp9DvSqJVTDVpy9SNNBIB08b7Hyf9vaHobE2knrGPda4My9f_o9gncG34pF/pub?w=1028&amp;h=309">
#
# We are going to add an additional state to the model to represent the infectious disease fatalities. The user must specify what that concept means in terms of the name for the new state and the behavior of that state. `D` is a terminal state for a finite automata.

function addstate!(m::ExpStateModel)
    println("\nThe system states are $(m.states.args)")
    println("\nAdding un estado de los muertos")

    put!(m, ExpStateTransition(:D, :((x...)->:D)))

    println("\nThe system states are $(m.states.args)")
    # once you are dead, you are dead forever
    println("\nThere is no resurrection in this model")
    println("\nInfected individuals recover or die in one step")

    # replace!(m, ExpStateTransition(:I, :((x...)->rand(Bool) ? :D : :I)))
    m[:I] = :((x...)->begin
            roll = rand()
            if roll < ρ
                return :R
            elseif rand(Bool)
                return :D
            else
                return :I
            end
        end
    )
    @show m[:I]
    return m
end


# Some utilities for manipulating functions at a higher level than expressions.

# +

struct Func end

function push!(::Func, func::Expr, ex::Expr)
    push!(bodyblock(func), ex)
end
# -

# ## Population Growth
#
# Another change we can make to our model is the introduction of population growth. Our model for population is that on each timestep, one new suceptible person will be added to the list of agents. We use the `tick!` function as an anchor point for this transformation.
#
# <img src="https://docs.google.com/drawings/d/e/2PACX-1vRfLcbPPaQq6jmxheWApqidYte8FxK7p0Ebs2EyW2pY3ougNh5YiMjA0NbRMuGAIT5pD02WNEoOfdCd/pub?w=1005&amp;h=247">

function addgrowth!(m::ExpStateModel)
    println("\nAdding population growth to this model")
    stepr = filter(x->isa(x,Expr), findfunc(m.expr, :tick!))[1]
    @show stepr
    push!(Func(), stepr, :(push!(sm.agents, :S)))
    println("------------------------")
    @show stepr;
    return m
end

# ## Transforming the Pipeline
#
# We can apply the tranformations that we defined onto the pipeline. Remember that $T_1\times T_2$ acts on a pipeline by creating $P(T_1(m_1),T_2(m_2), c_1,c_2)$. The current implementation does not support transforming the connectors, but that would be straightforward to add.

function connector(finalcounts, i, j)
    n = length(finalcounts)
    Data = zeros(n,length(finalcounts[1].counts))
    params = zeros(n,length(finalcounts[1].params))
    @show size(Data)
    for i in 1:n
        c = finalcounts[i].counts
        Data[i, : ] = map(last, c)
        params[i,:] = collect(map(float, finalcounts[i].params))
    end
    # multivariate regression not yet supported
    # X = Data[:, 1:end-2]
    # Y = Data[:, end]
    # @assert(size(X) == (n,size(Data,2)-2))
    # @assert(size(Y) == (n,))
    X = params[:, i]
    Y = Data[:, j]
    # normalization
    #Y = Y ./ [sum(Data[i, :]) for i in 1:n]
    @assert size(X,1) == size(Y,1)
    return X,Y
end
P = Pipelines.Pipeline(deepcopy.([magents, mstats]),
    [(m, args...) -> begin 
            Random.seed!(42)
            results = Any[]
            Mod = eval(m.expr)
            @show Mod
            for i in 1:samples
                r = Base.invokelatest(Mod.main, args...)
                push!(results, (model=:basic, counts=r[2],params=r[3]))
                #push!(results, r)
            end
            return [results]
                end,
        (m, results...) -> begin
            data = connector(results..., 1, 4)
            Mod = eval(m.expr)
            Base.invokelatest(Mod.main, data...) 
        end
        ],
        Any[(10)]
        )
println("\nInitial Pipeline")
println("----------------")
@show P.steps[1].states
@show poly(P.steps[2])
println("\n\nApplying the first pair of transformations")
println(     "------------------------------------------")
Product((addstate!, one(Pow)))(P)
@show P.steps[1].states
@show poly(P.steps[2])
println("\n\nApplying the second pair of transformations")
println(    "-------------------------------------------")
Product((x->x, AddConst()))(P)
Product((addgrowth!, one(Pow)))(P)
Product((x->x, AddConst()))(P)
Product((x->x, one(Pow)))(P)
Product((x->x, AddConst()))(P)
println("\n\nThe final model state")
println(     "---------------------")
println(filter(isexpr, findfunc(P.steps[1].expr, :tick!))[end])
@show poly(P.steps[2]);


# ## Running the new pipeline
#
# now that we have transformed the pipeline we run it to build the results

Pipelines.run!(P)
P.results[end][2]

# Here is the data we observed when running the first stage of the pipeline, stage two fits a polynomial to these observations

table = map(x->(round(x.params.ρ, digits=4), last(x.counts[end])), P.results[2][1]) |> sort
try 
    using Plots
catch
    @warn "Plotting is not available, make a table"
    for t in table
        println(join(t, "\t"))
    end
end


# ## Results
#
# The regression model that we have trained based on the simulated data from the SIRD model with population growth can be presented as a polynomial sampled over the domain. We construct this table to show the nonlinear dependence of the model on the recovery parameter $\rho$. The best fitting polynomial is shown below.

using Printf
eval(:(f(x,β) = $(poly(P.steps[2]))))
xdomain = (0.0:0.05:1.0)
println("ρ\tf(ρ,β)\n==============")
xŷ = zip(xdomain, f(xdomain, P.results[end][2].β))
z = collect(map(x->(@sprintf("%0.2f", x[1]),
                    @sprintf("%7.3f", x[2])),
        xŷ))
for t in z
    println(join(t, "\t"))
end

@info "Loading Plots, this may take a while"
using Plots

@info "Making plots, this may take a while"
p = scatter(first.(table), last.(table), label="obs")
plot!(first.(xŷ), last.(xŷ), label="fit")
xlabel!(p, "Probability of Recovery")
ylabel!(p, "Deaths")
println("β: ", P.results[end][2].β, "\n", string(poly(P.steps[2])))
p

# ## Conclusions
#
# This example shows that the SemanticModels approach to post-hoc modeling frameworks can enable metamodeling which is the combinations of model composed using different technologies into a coherent modeling workflow. Our ModelTools provides the basic building blocks for representing models and transformations in such a way that they transformations can be composed and models can be combined. Composition of transformations respects the combination of models. In this case the Product of transformation respects the Pipeline of models. Such that you can transform the models and then pipeline them, or pipeline them and then transform them.
#
# This example combined an agent based model of SIR diseases with a statistical model of polynomial regression to quantify the response of the agent based model with respect to one of its parameters. The input models have to be composed carefully in order to make the software work.
#
# As taught by the scientific computing education group [Software Carpentry](https://swcarpentry.github.io/), the best practice for composing scientific models is to have each component write files to disk and then use a workflow tool such as [Make](https://swcarpentry.github.io/make-novice/) to orchestrate the execution of the modeling scripts.
#
# An alternative approach is to design modeling frameworks for representing the models. The problem with this avenue becomes apparent when models are composed. The frameworks must be interoperable in order to make combined models. ModelTools avoids this problem by representing the models as code and manipulating the codes. The interoperation of two models is defined by user supplied functions in a fully featured programming language. 
#
# SemanticModels.jl also provides transformations on these models that are grounded in category theory and abstract algebra. The concepts of category theory such as Functors and Product Categories allow us to build a general framework fit for any modeling task. In the language of category theory, the Pipelining functor on models commutes with the Product functor on transformations.
#
# This examples shows that metamodeling is feasible with SemanticModels and that the algebras of model transformations can be preserved when acting on metamodel workflows.
