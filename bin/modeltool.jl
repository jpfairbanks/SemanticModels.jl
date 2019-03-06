module ModelTool
using SemanticModels.Parsers

"""    callsites(expr::Expr, name::Symbol)

extract the location where the function `name` is called in `expr`.
"""
function callsites(expr::Expr, name::Symbol)
    matches = Expr[]
    f(x::Any) = x
    f(x::Expr) = begin
        if x.head == :call && x.args[1] == name
            push!(matches, x)
            return x
        else
            return walk(x, f, g)
        end
    end
    g(x) = x
    walk(expr, f, g)
    return matches
end

"""    structured(func, var::Symbol, assign=true)

extract the expressions that use structuring/destructuring assignment
to name the components of `var`
"""
function structured(func::Expr, var::Symbol, assign=true)
    body = func.args[2]
    paramvec = Expr[]
    for line in body.args
        if isa(line, LineNumberNode)
            continue
        end
        if  assign && line.head == :(=) && inexpr(line.args[2], var)
            push!(paramvec, line)
        end
        if !assign && line.head == :(=) && inexpr(line.args[1], var)
            push!(paramvec, line)
        end
    end
    return paramvec
end

"""    AbstractProblem

a placeholder struct to dispatch on how to parse the expression tree into a model.
"""
abstract type AbstractProblem end

"""    ExpODEProblem

tells the model function to parse an expression as the definition
of an ODE model. Used for dispatch.
"""
struct ExpODEProblem
    calls
    funcs
    variables
    domains
    values
end

""" model(::AbstractProblem, expr::Expr)

dig into the expression that describes a model and break it down into components. This allows you to construct a structured representation of the modeling problem at the expression level. Just like how julia modeling frameworks build structured representations of the problems in data structures. This version builds them at the expression level.

The first argument is the type you want to construct, the second argument is the expression that you want to analyze. For example

```
model(ExpODEProblem, expr)::ExpODEProblem
```

"""
function model(::Type{ExpODEProblem}, expr::Expr)
    matches = callsites(expr, :ODEProblem)
    @show matches
    funcs = [findfunc(expr, rhs.args[2])[1] for rhs in matches]
    params(x) = structured(x, x.args[1].args[4])
    states(x) = structured(x, x.args[1].args[3])
    fluxes(x) = structured(x, x.args[1].args[2], false)
    vars = map(x->(state=states(x),
                   flux=fluxes(x),
                   params=params(x)), funcs)
    tdomain = map(m->findassign(expr, m.args[4]), matches)
    initial = map(m->findassign(expr, m.args[3]), matches)
    return ExpODEProblem(matches, funcs, vars, tdomain, initial)
end

lhs(x::Expr) = begin
    @show x
    x.head == :(=) || error("x is not an assignment")
    return x.args[1]
end
end
