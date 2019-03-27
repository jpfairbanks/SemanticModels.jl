# -*- coding: utf-8 -*-
# # Group Actions on Models
#
# One goal of SemanticModels is to lift model augmentation into the world of category theory and algebra.
# This is analogous to a long tradition in the *symbolification* of mathematics, for example geometry is the study of shapes and their relations, which gets lifted to group theory by the algebraists who want to to make everything symbolic reasoning.
#
# He we will represent a model class *monomial regression* with a data structure `MonomialRegression` and define a set group of transformations that can act on models from this class.

using SemanticModels
using SemanticModels.ModelTools
using SemanticModels.ModelTools.MonomialRegressionModels
using SemanticModels.ModelTools.Transformations

# ## Monomial Regression
#
# Here we take our class of models to be monomial regression and write a script that implements an experiment with this model.
#
# 1. Define a function $f(a, x) = ax^p$ for some integer $p$
# 2. Generate data from the distribution $x, f(a, x)+Normal(0,\sigma)$
# 3. Given the sample data, use least squares to solve for $a$.
#
# Note that the value of $p$ when we generate the data does not need to match the value of $p$ when we solve the least squares problem.

# Here is an implementation of our model.

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
end;

# ## Transforming the model 
#
# Valid transformations for this model include increasing and decreasing the power of the monomial by 1. And you can apply those transformations repeatedly.
#
# Mathematically we can go from $f(a,x) = ax^p$ to $f(a,x) = ax^{p+1}$ or $f(a,x) = ax^{p-1}$. If we allow repeated application of these two generator transformations as a free monoid, we find that the set of transformations we get is isomorphic to the *group* $(Z, +, 0)$ which is the integers with addition. In Julia, we have decided to represent elements from this transformation group with a struct `Pow{Int} <: Transformation`. The composition operation for these transformations can be found in the source file `groups.jl`. 
#
# Composition of `Pow{Int}` maps naturally to addition of the power to transform with. You can see how transformations are applied below.

m = model(MonomialRegressionModel, deepcopy(expr))
@show m.f.args[2]
m′ = deepcopy(m)
Pow(+1)(m′)
m′.f.args[2]


m′ = deepcopy(m)
Pow(-3)(m′)
m′.f.args[2]

# With this machinery in place we can think about the action of $Z$ on a `MonomialRegression` model to create a family of models with different powers of monomoial. Each monomial model finds the best fit to a particular data set, and by leveraging this group action, we can systematically explore the space of all models in the class.

# ## Chosing the right power
# Given a fixed dataset, we want to loop over all the models in a class an fit the best coefficients, then we will decide which monomial order allows for the best fit to this data.

m = model(MonomialRegressionModel, expr)
println(m)
sol = eval(m.expr)
@show sol.ahat
@show sol.loss(sol.ahat[1])
results = [(0,
            m.f.args[2].args[2].args[1].args[3].args[3],
            sol.ahat[1],
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

# ## Conclusions
#
# We can see that this sweep of monomial degree, recovers the right model order of $2$. We can actually some fundamental algebra at work here. When we apply the `Pow(-1)` element repeatedly, the optimal value of $a$ alternates between positive and negative. Here the even and odd elements of $Z$ are causing positive and negative values for the coefficient in the `MonomialRegression` model. 
#
#
# This example shows that you can represent the transformations on a model as a group and the action of the group on a model is the way to represent transformations on models. Insights from the algebraic structures homormorphic/isomorphic to the algebra of transformations provide insights on the class of models.


