using Catlab
using MacroTools
import MacroTools: postwalk, striplines
using ModelingToolkit
import ModelingToolkit: Constant

using Catlab.WiringDiagrams
using Catlab.Doctrines
using Test
import Catlab.Doctrines.⊗
⊗(a::WiringDiagram, b::WiringDiagram) = otimes(a,b)
import Base: ∘
∘(a::WiringDiagram, b::WiringDiagram) = compose(b, a)
⊚(a,b) = b ∘ a


# Generators
S, E, I, R, D= Ob(FreeSymmetricMonoidalCategory, :S, :E, :I, :R, :D)

wirenames(d::WiringDiagram) = foldr(union,
    map(box->union(input_ports(box), output_ports(box)),
        boxes(d)))
OpVar(s::Symbol) = Operation(Variable(s), [])

plusup(op1, op2) = begin
    b = op1.op == identity
    b ? op2 : op1 + op2
end


function fluxes(d::WiringDiagram)
    # TODO design Multiple Dispatch Lens API
    # TODO use ModelingToolkit variables
    nb = nboxes(d)
    vars = wirenames(d)
    symvars = OpVar.(vars)
    @show symvars
    byvar = Dict{Symbol, Operation}()
    homnames = Vector{Symbol}()
    for var in vars
        byvar[var] = 0
    end
    @show byvar
    β = Variable(:β)
    @show β
    map(enumerate(boxes(d))) do (i, box)
        βi = Operation(β,[i])
        @show βi
        invars = input_ports(box)
        outvars = output_ports(box)
        homname = box.value
        push!(homnames, homname)
        ϕ =  *(βi, OpVar.(invars)...)
        @show ϕ
        map(invars) do v
            byvar[v] = plusup(byvar[v], -ϕ)
        end
        map(outvars) do v
            byvar[v] = plusup(byvar[v], ϕ)
        end
    end
    return byvar, vars, homnames
end
#end


exposure = WiringDiagram(Hom(:exposure, S⊗I, E⊗I))
infecting = Hom(:infection,S ⊗ I, I⊗I)
inf = WiringDiagram(infecting)
rec = WiringDiagram(Hom(:recovery,I, R))
wan = WiringDiagram(Hom(:waning,R, S))

sir = WiringDiagram(Hom(:infection, S⊗I, I⊗I)) ⊚ (rec ⊗ rec)
seir = WiringDiagram(Hom(:exposure, S⊗I, E⊗I)) ⊚ (rec ⊗ WiringDiagram(Hom(:progression, E, I)))

dudt = fluxes(sir)[1]
@show dudt[:I]

# function oderhs(dudt::Dict{T, Expr}, vars::Vector{T}, homnames::Any) where {T}
#     lines = map(enumerate(vars)) do (i, v)
#         ϕ = dudt[v]
#         #:(du.$(ϕ.first) = $(ϕ.second))
#         :(du[$(i)] = $(ϕ))
#     end
#     fdef = quote
#     function f(du, u, p, t)
#         $(lines...)
#         return du
#     end
#     end
#     return fdef, vars, homnames
# end

# """    oderhs(d::WiringDiagram)

# convert a wiring diagram into a dynamical system described as julia Exprs.
# We need to keep track of the names we give the variables and the parameters so those are the second and third arguments respectively.

# Returns an expression that defines a function, a list of symbols representing the variables, and a list of symbols representing the parameter names.

# see also fluxes(d::WiringDiagram) for implementation details
# """
# oderhs(d::WiringDiagram) = oderhs(fluxes(d)...)

# oderhs(sir)

# """    odeProblem(d::WiringDiagram, params, initials, tdomain, alg=missing)

# bind a wiring diagram to a set of paramters, initial conditions, time domain and solver algorithm and generate the code the solves it.

# see also odetemplate.
# """
# function odeProblem(d::WiringDiagram, params, initials, tdomain, alg=missing)
#     quote
#         using DifferentialEquations
#         $(oderhs(d)[1])
#         function main()
#             params = $params
#             initials = $initials
#             tdomain = $tdomain
#             prob = ODEProblem(f, params, initials, tdomain)
#             soln = solve(prob, alg=$alg)
#             return prob, soln
#         end
#     end
# end


# odeProblem(seir, :β, :i₀, (0, 365), :(Tsit5()))


# abstract type ProbProcess end
# """    odetemplate(d::WiringDiagram)

# create an expression that defines a code that solves the ODE.
# Given just the wiring diagram, we don't know the paramters, initial conditions, or timedomain,
# so they are passed in as arguments to the function we generate.

# These parameters and initial conditions are destructured in the main function so you can
# see what the code is expecting to receive by reading the generated output.

# The structure of the timedomain is not implied by the wiring diagram so it is passed directly to the
# ODEProblem constructor. Any keyword arguments you pass to `main()` are forwarded to `solve()`.

# """
# function render(::ProbProcess, d::WiringDiagram)
#     f, vars, homnames = oderhs(d)
#     params = Expr(:tuple, map(enumerate(homnames)) do (i, name)
#         Expr(:(=), name, :(β[$i]))
#             end...)
#     vars = wirenames(d)
#     states = Expr(:vect, map(vars) do v
#             :(i₀.$v)
#             end...)
#     quote
#         using Quantum
#         $(f.args[end])
#         function main(P, p₀, tdomain; kwargs...)
#             params = $params
#             vecs = $states
#             prob = ODEProblem(f, params, vecs)
#             soln = solve(prob; kwargs...)
#             return prob, soln
#         end
#     end
# end

# odetemplate(sir) |> x -> postwalk(x) do x
#     return striplines(x)
# end
