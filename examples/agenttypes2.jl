using SemanticModels
using SemanticModels.Parsers
using SemanticModels.ModelTools

using SemanticModels.Parsers
import Base: ==

mutable struct Edge{S,T,R}
    func::S
    args::T
    ret::R
end

==(e::Edge,E::Edge) = begin (@show e.func==E.func && @show e.args == E.args && @show e.ret == E.ret) end

mutable struct CallArg{S,T,U,V}
    f::S
    arg::T
    T::U
    val::V
end
write(io, ca::CallArg) = write(io, "$(repr(ca.f))($(repr(f.arg))::$(repr(f.T))=$(repr(f.val)))")

mutable struct RetArg{S,T,U,V}
    f::S
    arg::T
    T::U
    val::V
end


function Edges(snapshots)
    stack = Any[]
    fs = Any[]
    for snap in snapshots
        #@show (x->x.f).(stack)
        if !isa(snap, RetArg)
            push!(stack, snap)
        end
        if isa(snap, RetArg)
            if length(stack) <= 0
                @show snap
                @show fs
                error("stack shouldn't have been empty here")
            end
            callargs = pop!(stack)
            framename = first(callargs).f
            t = Edge(framename, (x->x.T).(callargs), snap.T)
            push!(fs, t)
        end
    end
    return fs
end

head(x) = :nothing
head(x::Expr) = x.head

annotate(x::Any) = x

function annotate(x::Expr)
    # Grabing the values and types of the inputs
    if head(x) == :function
        b = bodyblock(x)
        argl= argslist(x)
        funcname = string(argl[1])
        if length(argl) > 1
            argl= argslist(x)[2:end]
        else
            argl = []
        end
        sargl = string.(argl)
        v = Expr(:vect)
        for (i, t) in enumerate(zip(sargl,argl))
            name, val = t
            T = :(typeof($val))
            q = :(CallArg($funcname, $name, $T, $val))
            push!(v.args, q)
        end
        insert!(b, 1, :(store($v)))

    end
    # Grabbing the return types
    if head(x) == :return
        g = gensym("ann")
        s = string(x)
        r = x.args[1]

        return quote
            $g = $r
            T = typeof($g)
            store(RetArg("ret", $s, T, $g))
            return $g
        end
     end
    return x
end

function wrap(expr::Expr)
    b = expr.args
    g = gensym("wrap_storage")
    insert!(b, 1, :(store(args) = begin push!($g, args) end ))
    insert!(b, 1, :($g = Any[]))
    push!(b, :($g))
    push!(b, :(Edges($g)))
    @show expr
    expr
end

macro typegraph(expr)
    expr2 = postwalk(annotate, expr)
    expr3 = wrap(expr2)
    return expr3
end

expr = parsefile("agenttypes.jl")
expr2 = wrap(postwalk(annotate, expr.args[end].args[end].args[end]))

edgelist = eval(expr2)
E = unique((f.func, f.args, f.ret) for f in edgelist)
@show E
