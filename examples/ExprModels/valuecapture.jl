using SemanticModels
using SemanticModels.ExprModels


expr =quote
    function f(a::Int64, b::Int64)
        c = a + b
        d = g(float(c))

        return d
    end
    function g(res::Float64)
        res = abs(res)
        res -= 1

        while res > 0
            res = g(res)
        end

        return res
    end
    @show f(1,2)
end

# +
funcs = Expr[]
for ex in expr.args
    if isa(ex, LineNumberNode)
        continue
    end
    if ex.head == :function
        push!(funcs, ex)
    end
end

funcs

# +
nametype(ex::Expr) = begin
    ex.head == :(::) || error("$ex is not a type assertion")
    avar = ex.args[1]
    atyp = ex.args[2]
    return avar, atyp
end

nametype(s::Symbol) = (s, :Any)

function describeargs(fu::Expr)
    f = fu
    @show argl = f.args[1].args[2:end]
    @show argl
    @show body = f.args[2].args
    fname = string(f.args[1])
    for a in reverse(argl)
        avar, atyp = nametype(a)
        varname = string(avar)
        pushfirst!(body,
            :(println("F: ", $fname,";",
                $varname,"=", $avar,"::",typeof($avar), "<:", $atyp))
        )
    end
    return f
end

for f in funcs
    describeargs(f)
    body = f.args[2].args
    fname = string(f.args[1])
    for ex in body
        if isa(ex,LineNumberNode)
            continue
        end
        if ex.head == :(=)
            @show a = ex.args[1]
            varname = string(a)
            insert!(body, length(body)-1,:(println("A: ", $fname,";",$varname, "=", $a)))
        end
    end
end
expr
# -

eval(expr)
