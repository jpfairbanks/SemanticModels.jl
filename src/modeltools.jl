module ModelTools
using SemanticModels.Parsers
import Base: show, getindex, setindex!, put!, replace!
export model, callsites, structured, AbstractProblem, pusharg!, setarg!, bodyblock, argslist,
    ExpStateModel, ExpStateTransition, ExpODEProblem


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

function invoke(m::AbstractProblem, args...)
    Mod = eval(m.expr)
    Base.invokelatest(Mod.main, args...)
end

include("SimpleProblem.jl")

"""    ExpODEProblem

tells the model function to parse an expression as the definition
of an ODE model. Used for dispatch.
"""
struct ExpODEProblem
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

lhs(x::Expr) = begin
    @show x
    x.head == :(=) || error("x is not an assignment")
    return x.args[1]
end

"""    bodyblock(expr::Expr)

get the array of args representing the body of a function definition.
"""
function bodyblock(expr::Expr)
    expr.head == :function || error("$expr is not a function definition")
    return expr.args[2].args
end

"""    funclines(expr::Expr, s::Symbol)

clean up the lines of a function definition for presentation
"""
function funclines(expr::Expr, s::Symbol)
    q = Expr(:block)
    isexpr(x) = isa(x, Expr)
    q.args = (filter(isexpr, findfunc(expr, s))[end]
              |> bodyblock
              |> arr -> filter(x->!isa(x, LineNumberNode),arr))
    return q
end
"""    argslist(expr::Expr)

get the array of args representing the arguments of a defined function.
the first element of this list is the function name

See also [`bodyblock`](@ref), [`pusharg!`](@ref),
"""
function argslist(expr::Expr)
    expr.head == :function || error("$expr is not a function definition")
    return expr.args[1].args
end

"""    pusharg!(expr::Expr, s::Symbol)

push a new argument onto the definition of a function.

See also [`argslist`](@ref), [`setarg!`](@ref)
"""
function pusharg!(ex::Expr, s::Symbol)
    ex.head == :function || error("ex is not a function definition")
    push!(argslist(ex), s)
    return ex
end

"""    setarg!(expr::Expr, s::Symbol)

replace the argument in a function call.

See also [`argslist`](@ref), [`pusharg!`](@ref)
"""
function setarg!(ex::Expr, old, new)
    ex.head == :call || error("ex is not a function call")
    for (i, x) in enumerate(ex.args)
        if x == old
            ex.args[i] = new
        end
    end
    return ex
end

"""    ExpStateModel

represents an agent based model symbolically, with a collection of stats, agents, and transitions.
The agents are a collection of states and the transitions map from state to state. This structure allows you to represent an agent based model at the semantic level and apply transformations to that model.

The common transformations for an agent based model are adding, removing, or replacing, states, agents, or transitions. See [`model`](@ref), [`put!`](@ref), [`setindex`](@ref), [`getindex`](@ref), [`put!`](@ref), [`replace!`](@ref).
"""
struct ExpStateModel <: AbstractProblem
    expr::Expr
    states
    agents
    transitions
end

"""    ExpStateTransiton

represents a state-transition function for an agent based model. `ExpStateTransition(s,x)` represents the transition from state `s` to any other states. The expression `x` should define a function that takes any number of arguments and returns a value representing the new state.
"""
struct ExpStateTransition
  state::Symbol
  expr::Expr
end

function model(::Type{ExpStateModel}, expr::Expr)
    constructor = callsites(expr, :StateModel)[1]
    states = constructor.args[2]
    #TODO: find out why this identifies extra assignments possibly from the (i,a) = enumerate(sm.agents) part.
    agents = findassign(expr, constructor.args[3])
    transitions = findassign(expr, constructor.args[4])
    return ExpStateModel(expr, states, agents, transitions)
end

function show(io::IO, m::ExpStateModel)
    write(io, "ExpStateModel(\n  states=$(repr(m.states)),\n  agents=$(repr(m.agents)),\n  transitions=$(repr(m.transitions))\n)")
end

""" put!(m::ExpStateModel, transition::ExpStateTransition)

Store an [`ExpStateTransition`](@ref) `transition` into an [`ExpStateModel`](@ref) `m`. A `put!` on an already set state throws an `Exception`.

Returns the transition function inserted into `m`.
"""
function put!(m::ExpStateModel, transition::ExpStateTransition)
  q = QuoteNode(transition.state)
  any(x->x.value==transition.state, m.states.args) && error("Symbol $(transition.state) already exists")
  any(x->typeof(x) == Expr && x.args[2] == q, m.transitions[1].args[2].args) && error("Symbol $sym has a transition, but is not in the states")
  push!(m.states.args, QuoteNode(transition.state))
  push!(m.transitions[1].args[2].args, :($q=>$(transition.expr)))
  return transition.expr
end

""" replace!(m::ExpStateModel, transition::ExpStateTransition)

Store an [`ExpStateTransition`](@ref) `transition` into an [`ExpStateModel`(@ref) `m`. A `replace!` on an already set state will replace the current transition function.

Returns the transition function inserted into `m`.
"""
function replace!(m::ExpStateModel, transition::ExpStateTransition)
  !any(x->x.value==transition.state, m.states.args) && error("Symbol $sym doesn't exist")
  found=filter(x->typeof(x) == Expr && x.args[2] == QuoteNode(transition.state), m.transitions[1].args[2].args)
  found[1].args[3] = transition.expr
  return transition.expr
end

""" setindex!(m::ExpStateModel, expr::Expr, sym::Symbol)

Store an [`Expr`](@ref) `expr` as the transition function for state `sym` in [`ExpStateModel`](@ref) `m`. A `setindex!` on an already set state will replace the current transition function.

Returns the transition function inserted into `m`.
"""
function setindex!(m::ExpStateModel, expr::Expr, sym::Symbol)
  any(x->x.value==sym, m.states.args) && return replace!(m, ExpStateTransition(sym, expr))
  return put!(m, ExpStateTransition(sym, expr))
end


""" getindex(m::ExpStateModel, sym::Symbol)
Returns the transition function for state `sym` in [`ExpStateModel`](@ref) `m`. A `getindex` on a state that doesn't exist in `m` throws an `Exception`.
"""
function getindex(m::ExpStateModel, sym::Symbol)
  found=filter(x->typeof(x) == Expr && x.args[2] == QuoteNode(sym), m.transitions[1].args[2].args)
  length(found) == 0 && error("Symbol $sym doesn't exist")
  return found[1].args[3]
end

end
