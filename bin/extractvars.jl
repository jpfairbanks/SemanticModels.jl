#!/usr/bin/env julia
# extractvars.jl is a script to print out the variables contained in a julia program
# Example Usage:
#
#      julia ../bin/extractvars.jl epicookbook/src/SIRModel.jl epicookbook/src/ScalingModel.jl
#
# Example Output:
# loaded
# epicookbook/src/SIRModel.jl, "sir_sol"
# epicookbook/src/SIRModel.jl, "tspan"
# epicookbook/src/SIRModel.jl, "du[2]"
# epicookbook/src/SIRModel.jl, "(b, g)"
# epicookbook/src/SIRModel.jl, "S"
# epicookbook/src/SIRModel.jl, "pram"
# epicookbook/src/SIRModel.jl, "init"
# epicookbook/src/SIRModel.jl, "sir_prob2"
# epicookbook/src/SIRModel.jl, "(S, I, R)"
# epicookbook/src/SIRModel.jl, "du[3]"
# epicookbook/src/SIRModel.jl, "parms"
# epicookbook/src/SIRModel.jl, "β"
# epicookbook/src/SIRModel.jl, "γ"
# epicookbook/src/SIRModel.jl, "I"
# epicookbook/src/SIRModel.jl, "du[1]"
# epicookbook/src/SIRModel.jl, "sir_prob"
# epicookbook/src/ScalingModel.jl, "α"
# epicookbook/src/ScalingModel.jl, "sir_sol"
# epicookbook/src/ScalingModel.jl, "tspan"
# epicookbook/src/ScalingModel.jl, "βs[:, i]"
# epicookbook/src/ScalingModel.jl, "w"
# epicookbook/src/ScalingModel.jl, "μ"
# epicookbook/src/ScalingModel.jl, "K"
# epicookbook/src/ScalingModel.jl, "init"
# epicookbook/src/ScalingModel.jl, "(β, r, μ, K, α)"
# epicookbook/src/ScalingModel.jl, "dS"
# epicookbook/src/ScalingModel.jl, "ws"
# epicookbook/src/ScalingModel.jl, "(S, I)"
# epicookbook/src/ScalingModel.jl, "parms"
# epicookbook/src/ScalingModel.jl, "du"
# epicookbook/src/ScalingModel.jl, "r"
# epicookbook/src/ScalingModel.jl, "dI"
# epicookbook/src/ScalingModel.jl, "β"
# epicookbook/src/ScalingModel.jl, "m"
# epicookbook/src/ScalingModel.jl, "βs"
# epicookbook/src/ScalingModel.jl, "sir_prob"
# epicookbook/src/ScalingModel.jl, "i"
import Pkg;
Pkg.add("SemanticModels")
using SemanticModels.Parsers

"""    findassigns(expr::Expr)

findassign walks the AST of `expr` to find the assignments to variables.

This function returns a reference to the original expression so that you can modify it inplace
and is intended to help users rewrite expressions for generating new models.

See also: [`findassign`](@ref).
"""
function findassigns(expr::Expr)
    # g(y) = filter(x->x!=nothing, y)
    matches = Dict{Any,Set{Expr}}()
    g(y::Any) = :()
    f(x::Any) = :()
    f(x::Expr) = begin
        if x.head == :(=)
            s = get(matches, x.args[1], Set{Expr}())
            matches[x.args[1]] = push!(s, x)
            return x
        end
        walk(x, f, g)
    end
    walk(expr, f, g)
    return matches
end

"""    findvars(file)

finds all the variable names from a julia script.

Example:
    file = "epicookbook/src/DiscreteTimeSIR.jl"
    matches = findvars(file)
"""
function findvars(file)
    ex = parsefile(file)
    matches = findassigns(ex)
    matches = matches
    return matches
end

if length(ARGS) > 0
    for file in ARGS
        matches = findvars(file)
        for k in keys(matches)
            println("$file, \"$k\"")
        end
    end

end