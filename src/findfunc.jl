"""    findfunc(expr::Expr, name::Symbol)

findfunc walks the AST of `expr` to find the definition of function called `name`.

This function returns a reference to the original expression so that you can modify it inplace
and is intended to help users rewrite the definitions of functions for generating new models.
"""
function findfunc(expr::Expr, name::Symbol)
    try
        expr.head
    catch
        return nothing
    end

    if expr.head == :module
        return findfunc(expr.args[3], name)
    end
    if expr.head == :function
        # normal function definition syntax ie. function f(x); return y end
        if expr.args[1].args[1] == name
            return expr
        end
        return findfunc(expr.args, name)
    end
    if expr.head == :(=)
        if isa(expr.args[1], Symbol)
            return nothing
        end

        if expr.args[1].head == :call
            # inline function definition ie. f(x) = y
            if expr.args[1].args[1] == name
                return expr
            end
            return findfunc(expr.args, name)
        end
    end
    if expr.head == :block
        return findfunc(expr.args, name)
    end
    return nothing
end

function findfunc(expr::LineNumberNode, s::Symbol)
    return nothing
end

function findfunc(args::Vector{Any}, name::Symbol)
    return filter(x->x!=nothing, [findfunc(a,name) for a in args])
end


walk(x, inner, outer) = outer(x)
walk(x::Expr, inner, outer) = outer(Expr(x.head, map(inner, x.args)...))

"""    findassign(expr::Expr, name::Symbol)

findassign walks the AST of `expr` to find the assignments to a variable called `name`.

This function returns a reference to the original expression so that you can modify it inplace
and is intended to help users rewrite expressions for generating new models.

See also: [`findfunc`](@ref).
"""
function findassign(expr::Expr, name::Symbol)
    # g(y) = filter(x->x!=nothing, y)
    matches = Expr[]
    g(y::Any) = :()
    f(x::Any) = :()
    f(x::Expr) = begin
        if x.head == :(=)
            if x.args[1] == name
                push!(matches, x)
                return x
            end

        end
        walk(x, f, g)
    end
    walk(expr, f, g)
    return matches
end

function replacevar(expr::Expr, name::Symbol, newname::Symbol)
    g(x::Any) = x
    f(x::Any) = x
    f(x::Symbol) = (x==name ? newname : x)
    f(x::Expr) = walk(x, f, g)
    return walk(expr, f, g)
end

function replacevar(expr::Expr, tr::Dict{Symbol, Any})
    g(x::Any) = x
    f(x::Any) = x
    f(x::Symbol) = get(tr, x, x)
    f(x::Expr) = walk(x, f, g)
    return walk(expr, f, g)
end
