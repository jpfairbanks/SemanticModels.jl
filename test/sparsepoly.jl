using Test
using Base.Iterators
using MacroTools
import Base: size, getindex, setindex!

using SemanticModels
using SemanticModels.ModelTools
using SemanticModels.ModelTools.Transformations
using SemanticModels.ModelTools.FunctorTransforms

# ## generate data
using Random
using LinearAlgebra
using LsqFit

function sample(g::Function, n)
    x = randn(Float64, n)
    target = g(x) .+ randn(Float64, n[1])./4
    return x, target
end

function describe(fit)
    if !fit.converged
        error("Did not converge")
    end
    return (β = fit.param, r=norm(fit.resid,2), n=length(fit.resid))
end


    #setup
function generate(seed=42)
    Random.seed!(42)
    β = (1/2, 1/2, -1/2)
    p = (1, 3, 5)
    n = (100)
    g(x) = sum(zip(β, p)) do (β, i)
        β.*x.^i
    end

    X, target = sample(g, n)
    return X, target
end

    # x, y = X[:,1], X[:,2]
    # @show size(X), size(target)
    # loss(a) = sum((f.(a, x, y) .- target).^2)
    # @show loss.([-1,-1/2,-1/4, 0, 1/4,1/3,1/2,2/3, 1])
X, target = generate()
@show size(X), size(target)

mutable struct PolyModel{T,U} <: AbstractArray{T, 1}
    degree::U
    x::Vector{T}
end

getindex(m::PolyModel, i...) = m.x[i...]
setindex!(m::PolyModel, val, i...) = setindex!(m,val, i...)
size(m::PolyModel) = size(m.x)

function f(m::PolyModel, β)
    # This .+ node is added so that we have something to grab onto
    # in the metaprogramming. It is the ∀a .+(a) == a.
    return sum(m.x.^m.degree[i] .* β[i] for i in 1:length(β))
end


    function f(x, β)
        # This .+ node is added so that we have something to grab onto
        # in the metaprogramming. It is the ∀a .+(a) == a.
        return sum(x.^i .* β[i] for i in 1:length(β))
    end
    # Generate the data for this example

# poly(p...) = :(x->Base.Math.@horner(x, $(p...)))
# poly(1,2,3)

    # Compute the regression statistics
    d = 5
    a₀ = ones(Float64, d)
    try
        ŷ₀ = f(X, a₀)
        catch except
        @show except
        error("Could not execute f on the initial data")
    end

    #solving
    fit = curve_fit(f, X, target, a₀)
    @show describe(fit).r
    degs = [1, 3, 5, 6,7,8,9]
    a₀ = ones(length(degs))
    fit = curve_fit(f, PolyModel(degs, X), target, a₀)
    @show describe(fit).r
    # autodiff takes longer to compile, but is faster to run.
    # @time fit = curve_fit(f, X, target, a₀, autodiff=:forwarddiff)
    result = describe(fit)



# ## fit exact model

# ## model selection


