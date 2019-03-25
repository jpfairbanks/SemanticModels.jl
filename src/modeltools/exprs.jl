"""    issome(x)

predicate for being neither missing or nothing
"""
issome(x) = !ismissing(x) && !isa(x, Nothing)

"""    head(x)

gets the head of an Expr or nothing for LineNumberNodes
"""
head(x::Expr) = x.head
head(n::LineNumberNode) = nothing

"""    isblock(x)

predicate for an expression being a block node. Exists to make filter(x->head(x)==:block) shorter.
"""
isblock(x) = head(x) == :block

"""    isfunc(x)

predicate for an expression being a function definition. Exists to make filter(x->head(x)==:function) shorter.
"""
isfunc(x) = head(x) == :function

"""    iscall(x)

predicate for an expression being a function call. Exists to make filter(x->head(x)==:call) shorter.
"""
iscall(x) = head(x) ==:call

"""    isimport(x)

predicate for an expression being an import statement. Exists to make filter(x->head(x)==:import) shorter.
"""
isimport(x) = head(x) == :import

"""    isusing(x)

predicate for an expression being a using statement. Exists to make filter(x->head(x)==:using) shorter.
"""
isusing(x) = head(x) == :using

"""    or(f,g) = x->f(x) || g(x)
"""
or(f::Function, g::Function) = x->(f(x) || g(x))

"""    and(f,g) = x->f(x) && g(x)
"""
and(f::Function, g::Function) = x->(f(x) && g(x))

"""    funcname(ex::Expr)

get the function name from an expression object return :nothing for non function expressions.
"""
function funcname(ex::Expr)
    if isfunc(ex)
        return ex.args[1].args[1]
    elseif iscall(ex)
        return ex.args[1]
    end
    return :nothing
end
