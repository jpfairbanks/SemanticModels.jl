# -*- coding: utf-8 -*-
# + {}
module ExpODEModels
import Base: show
using Catlab.WiringDiagrams
using MacroTools
import MacroTools: postwalk, striplines

using SemanticModels.Parsers
using SemanticModels.ModelTools
import SemanticModels.ModelTools: model

export ExpODEModel, model, odeTemplate

"""    ExpODEModel

tells the model function to parse an expression as the definition
of an ODE model. Used for dispatch.
"""
struct ExpODEModel <: AbstractModel
    expr::Expr
    calls
    funcs
    variables
    domains
    values
end

""" model(::AbstractModel, expr::Expr)

dig into the expression that describes a model and break it down into components. This allows you to construct a structured representation of the modeling problem at the expression level. Just like how julia modeling frameworks build structured representations of the problems in data structures. This version builds them at the expression level.

The first argument is the type you want to construct, the second argument is the expression that you want to analyze. For example

```
model(ExpODEModel, expr)::ExpODEModel
```

"""
function model(::Type{ExpODEModel}, expr::Expr)
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
    return ExpODEModel(expr, matches, funcs, vars, tdomain, initial)
end

function model(::Type{ExpODEModel}, d::WiringDiagram)
    return model(ExpODEModel, odeTemplate(d))
end

function show(io::IO, m::ExpODEModel)
    write(io, "ExpODEModel(\n  calls=$(repr(m.calls)),\n  funcs=$(repr(m.funcs)),\n  variables=$(repr(m.variables)),\n  domains=$(repr(m.domains)),  values=$(repr(m.values))\n)")
end

wirenames(d::WiringDiagram) = foldr(union,
    map(box->union(input_ports(box), output_ports(box)),
        boxes(d)))

function fluxes(d::WiringDiagram)
    # TODO design Multiple Dispatch Lens API
    # TODO use ModelingToolkit variables
    nb = nboxes(d)
    vars = wirenames(d)
    byvar = Dict{Symbol, Expr}()
    homnames = Vector{Symbol}()
    for var in vars
        byvar[var] = :(+())
    end
    map(enumerate(boxes(d))) do (i, box)
        invars = input_ports(box)
        outvars = output_ports(box)
        homname = box.value
        push!(homnames, homname)
        βᵢ = :(p.$(homname))
        ϕ =  :(*($βᵢ, $(invars...)))
        map(invars) do v
            push!(byvar[v].args, :(-$ϕ))
        end
        map(outvars) do v
            push!(byvar[v].args, :($ϕ))
        end
    end
    return byvar, vars, homnames
end

function oderhs(dudt::Dict{T, Expr}, vars::Vector{T}, homnames::Any) where {T}
    vardefs = map(enumerate(vars)) do (i, v)
        :($(v) = u[$(i)])
    end
    lines = map(enumerate(vars)) do (i, v)
        ϕ = dudt[v]
        #:(du.$(ϕ.first) = $(ϕ.second))
        :(du[$(i)] = $(ϕ))
    end
    fdef = quote
    function f(du, u, p, t)
        $(vardefs...)
        $(lines...)
        return du
    end
    end
    return fdef, vars, homnames
end

"""    oderhs(d::WiringDiagram)

convert a wiring diagram into a dynamical system described as julia Exprs.
We need to keep track of the names we give the variables and the parameters so those are the second and third arguments respectively.

Returns an expression that defines a function, a list of symbols representing the variables, and a list of symbols representing the parameter names.

see also fluxes(d::WiringDiagram) for implementation details
"""
oderhs(d::WiringDiagram) = oderhs(fluxes(d)...)


"""    odeTemplate(d::WiringDiagram)

create an expression that defines a code that solves the ODE.
Given just the wiring diagram, we don't know the paramters, initial conditions, or timedomain, 
so they are passed in as arguments to the function we generate.

These parameters and initial conditions are destructured in the main function so you can
see what the code is expecting to receive by reading the generated output.

The structure of the timedomain is not implied by the wiring diagram so it is passed directly to the
ODEProblem constructor. Any keyword arguments you pass to `main()` are forwarded to `solve()`. 

"""
function odeTemplate(d::WiringDiagram)
    f, vars, homnames = oderhs(d)
    params = Expr(:tuple, map(enumerate(homnames)) do (i, name)
        Expr(:(=), name, :(β[$i]))
            end...)
    vars = wirenames(d)
    initials = Expr(:vect, map(vars) do v
            :(i₀.$v)
            end...)
    out = quote
        using DifferentialEquations
        $(f.args[end])
        function main(β, i₀, tdomain; kwargs...)
            params = $params
            initials = $initials
            prob = ODEProblem(f, params, initials, tdomain)
            soln = solve(prob; kwargs...)
            return prob, soln
        end
    end
    out |> x -> postwalk(x) do x
        return striplines(x)
    end
end

end
