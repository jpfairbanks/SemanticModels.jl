include("groups.jl")

using SemanticModels
using SemanticModels.ModelTools
using .Transformations

expr = quote
    module Regression
    using Random
    mid(a,b) = (a+b)/2
    function f(a, x)
        return a*x^4
    end

    function optimize(l, interval)
        left = interval[1]
        right = interval[2]
        if left > right - 1e-8
            return (interval)
        end
        midp = (left+right)/2
        if l(mid(left, midp)) > l(mid(midp, right))
            return optimize(l, (midp, right))
        else
            return optimize(l, (left, midp))
        end
    end

    function sample(g::Function, n::Int)
        x = randn(Float64, n)
        target = g(x) .+ randn(Float64, n)./8
        return x, target
    end


    #setup

    Random.seed!(42)
    a = 1/2
    n = 10
    g(x) = a.*x.^2
    x, target = sample(g, n)
    loss(a) = sum((f.(a, x) .- target).^2)
    a₀ = [-1, 1]
    # @show loss.([-1,-1/2,-1/4, 0, 1/4,1/3,1/2,2/3, 1])

    #solving
    ahat = optimize(loss, a₀)

    end
end

m = model(MonomialRegression, expr)
println(m)
sol = eval(m.expr)
@show sol.ahat
@show sol.loss(sol.ahat[1])
results = [(0,
            m.f.args[2].args[2].args[1].args[3].args[3],
            sol.ahat,
            sol.loss(sol.ahat[1]))]
for i in 1:5
    Pow(-1)(m)
    @show m.f.args[2].args[2]
    sol = eval(m.expr)
    p = m.f.args[2].args[2].args[1].args[3].args[3]
    ahat = @show sol.ahat[1]
    lhat = @show sol.loss(sol.ahat[1])
    push!(results, (i, p, ahat, lhat))
end

fmt(i::Int) = i
fmt(f::Real) = round(f, digits=7)
println("\nResults:\n\n\ni\tp\tâ\t\tl⋆\n-----------------------------")
for r in results
    println(join(fmt.(r), "\t"))
end
best = sort(results, by=x->x[end])[1][2:end]
println("Model order $(best[1]) is the best with a=$(best[2]) and loss $(best[end])")
