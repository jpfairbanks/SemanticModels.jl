# -*- coding: utf-8 -*-
# + {}
module WiringDiagrams

using Catlab.WiringDiagrams
using Catlab.Doctrines
using Catlab.Graphics
using MacroTools
import MacroTools: postwalk, striplines

export wirenames, label!, odeTemplate, drawhom, canonical

"""    drawhom(hom, name::String, format="svg")

draw a hom expression as a wiring diagram and store it as a file.
Defaults to SVG format. The filename is <name.format>.
"""
function drawhom(hom, name::String, format="svg")
    d = to_wiring_diagram(hom)
    g = to_graphviz(d, direction=:horizontal)
    t = Graphics.Graphviz.run_graphviz(g, format=format)
    write("$name.$format", t)
    return g
end

"""    canonical(Syntax::Module, hom)

canonicalizes a hom expression by converting it to a WiringDiagram and then back again.
The Syntax parameter is the Doctrine for the morphism such as FreeSymmetricMonoidalCategory.
"""
canonical(Syntax::Module, hom) = begin d = to_wiring_diagram(hom)
    to_hom_expr(Syntax, d)
end

wirenames(d::WiringDiagram) = foldr(union,
    map(box->union(input_ports(box), output_ports(box)),
        boxes(d)))

function label!(g::Graphviz.Graph, v::Vector{String})
    iter = Iterators.Stateful(v)
    map(enumerate(g.stmts)) do (i,s)
        if typeof(s) <: Edge
            g.stmts[i].attrs[:label] = popfirst!(iter)
        end 
    end
end

# CODE TO CONVERT WIRING DIAGRAM TO ODE

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

# ADD CATEGORY THEORY REWRITE RULES FOR WIRING DIAGRAMS

end
