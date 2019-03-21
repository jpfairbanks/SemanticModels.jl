# -*- coding: utf-8 -*-
# + {}
module ExpODEProblems
using SemanticModels.ModelTools

export ExpODEProblem, model, show

"""    ExpODEProblem

tells the model function to parse an expression as the definition
of an ODE model. Used for dispatch.
"""
struct ExpODEProblem <: AbstractProblem
    expr::Expr
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
    return ExpODEProblem(expr, matches, funcs, vars, tdomain, initial)
end

function show(io::IO, m::ExpODEProblem)
    write(io, "ExpODEProblem(\n  calls=$(repr(m.calls)),\n  funcs=$(repr(m.funcs)),\n  variables=$(repr(m.variables)),\n  domains=$(repr(m.domains)),  values=$(repr(m.values))\n)")
end

end