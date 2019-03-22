# -*- coding: utf-8 -*-
# ---
# jupyter:
#   jupytext:
#     text_representation:
#       extension: .jl
#       format_name: light
#       format_version: '1.3'
#       jupytext_version: 1.0.2
#   kernelspec:
#     display_name: Julia 1.0.3
#     language: julia
#     name: julia-1.0
# ---

using SemanticModels
using SemanticModels.ModelTools
using SemanticModels.ModelTools.SimpleModels

import SemanticModels.ModelTools.SimpleModels: entrypoint, entryname, body
expr = quote
    module StatsMod
    using Statistics
    function foo(x)
        return x.^2
    end
    function bar(x,y)
        ρ = foo(x.-y)./(foo(x) .+ foo(y))
        return ρ
    end
    function main(n)
        x = rand(Float64, n)
        μ = mean(x)
        ρ = bar(x,μ)
        return x, ρ
    end
    end
end

m = model(SimpleModel, deepcopy(expr), :(main(n::Int)))

StatsMod = eval(m.expr)
StatsMod.main(10)

macro model(class, args...)
    expr = args[end]
    if expr.head == :block
        expr = expr.args[end]
    end
    
    ex = Expr(:nothing)
    expr = quote $expr end
    if length(args) > 1
        additional_args = args[1:end-1]
        ex = :(model($class, $expr, $additional_args...))
    else
        ex = :(model($class, $expr ))
    end
    return ex
end

m′ = @model SimpleModel main(n::Int64) quote
    module StatsMod
    using Statistics
    function foo(x)
        return x.^2
    end
    function bar(x,y)
        ρ = foo(x.-y)./(foo(x) .+ foo(y))
        return ρ
    end
    function main(n)
        x = rand(Float64, n)
        μ = mean(x)
        ρ = bar(x,μ)
        return x, ρ
    end
    end
end

m′.expr

m′.functions

m′.entry

Mod = eval(m′.expr)
getfield(Mod, entryname(m′))(10)


