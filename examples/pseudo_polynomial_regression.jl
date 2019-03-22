# -*- coding: utf-8 -*-
# + {}
using Pkg
Pkg.activate("Algebra")
try 
    using Polynomials
catch
    Pkg.add("Polynomials")
end

using Polynomials
# -

# # Polynomial Ring of Transformations
#
# One goal of SemanticModels is to lift model augmentation into the world of category theory and algebra.
# This is analogous to a long tradition in the *symbolification* of mathematics, for example geometry is the study of shapes and their relations, which gets lifted to group theory by the algebraists who want to to make everything symbolic reasoning.
#
# He we will represent a model class *monomial regression* with a data structure `MonomialRegression` and define a set group of transformations that can act on models from this class.

using SemanticModels
using SemanticModels.ModelTools
using SemanticModels.ModelTools.Transformations
using SemanticModels.ModelTools.MonomialRegressionModels

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
    function f(x, a)
        y = first(a)*x^0
        return y
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
        target = g.(x) .+ randn(Float64, n)./8
        return x, target
    end


    #setup

    Random.seed!(42)
    a = 1/2
    n = 10
    g(x) = a*(1 + x^1 + x^2)
    x, target = sample(g, n)
    loss(a) = sum((f.(x, a) .- target).^2)
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
@show bodyblock(m.f)


# With this machinery in place we can think about the action of $Z$ on a `MonomialRegression` model to create a family of models with different powers of monomoial. Each monomial model finds the best fit to a particular data set, and by leveraging this group action, we can systematically explore the space of all models in the class.

eval(m.expr);
â = Regression.ahat

function (p::Poly)(m::MonomialRegressionModel)
    if m.expr.head == :module
        # we need to add the using statement to get polyval defined
        pushfirst!(m.expr.args[3].args, :(using Polynomials))
    end
    bodyblock(m.f)[end-2] = Parsers.replace(bodyblock(m.f)[end-2], :(x^0), :(polyval($p,x)))
end
Poly([1,0,1])(m)
m

eval(m.expr);
â = Regression.ahat

# ## Chosing the right polynomial
# Given a fixed dataset, we want to loop over all the models in a class and fit the best coefficient, then we will decide which polynomial allows for the best fit to this data.

m = model(MonomialRegressionModel, deepcopy(expr))
# println(m)
# sol = eval(m.expr)
# @show sol.ahat
# @show sol.loss(sol.ahat[1])
results = Any[]
for i in 0:1
    for j in 0:1
        for k in 0:2
            m = model(MonomialRegressionModel, deepcopy(expr))
            (i*Poly([1]) + j*Poly([0, 1]) + k*Poly([0,0,1]))(m)
            @show m.f.args[2].args[2]
            sol = eval(m.expr)
            p = bodyblock(m.f)
            ahat = @show sol.ahat[1]
            lhat = @show sol.loss(sol.ahat[1])
            push!(results, (i, ahat, lhat, p))
        end   
    end
end


using Printf
fmt(i::Int) = i
fmt(f::Real) = Printf.@sprintf "% .4f" round(f, sigdigits=5)
fmt(f::Any) = f[end-2].args[2].args[3].args[2]
println("\nResults:\n\n\ni\tâ         ℓ⋆ \t\tpoly\n----------------------------------------------")
for r in results
    println(join(fmt.(r), "     "))
end
best = sort(results, by=x->x[end-1])[1][2:end]
println("Model order $(fmt(best[end])) is the best with a=$(fmt(best[1])) and loss $(fmt(best[2]))")

# ## Conclusions
#
# We can see that this sweep over polynomials, recovers the right model. We can see some fundamental algebra at work here.
#
#
# This example shows that you can represent the transformations on a model as a group and the action of the group on a model is the way to represent transformations on models. Insights from the algebraic structures homormorphic/isomorphic to the algebra of transformations provide insights on the class of models.

div(Poly([1,2,3])*Poly([0,1]), Poly([0,1]))


divrem((Poly([1,2,3])*Poly([0,1,2])), Poly([1,1,2,1]))

gcd((Poly([1,2,3])*Poly([1,3,4])), Poly([1,2,3]))
