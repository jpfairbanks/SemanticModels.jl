module Edges

function edgetype(var, val::Expr)
    if val.head == :call
        return :output
    elseif length(val.args) >=2 && typeof(val.args[2]) <: Expr && val.args[2].head == :tuple
        @show val.args
        return :structure
    else
        return :takes
    end
end

edgetype(var, val::Symbol) = :destructure


function edges(mc, subdef, scope)
    @info("Making edges",scope=scope)
    edg = Any[]
    for ( var,val ) in mc.vc
        @show var, val
        typ = edgetype(var, val)
        val = typ==:structure ? val.args[2] : val
        e = (scope, typ, :var, var, :val, val)
        push!(edg, e)
        if typ == :output
            e = (scope, typ, :var, var, :exp, val)
            push!(edg, e)
        end
        if typ == :structure
            e = (scope, typ, :var, var, :tuple, val.args[2])
            push!(edg, e)
        end

        if typeof(val) <: Expr && val.head == :vect
            push!(edg, (scope, :has, :value, var, :property, :collection))
        end
        if typeof(val) <: Expr && val.head == :call
            push!(edg, (scope, :input, :func, val.args[1], :args, Symbol.(val.args[2:end])))
        end
        if typ == :destructure
            @debug var.args
            for lhs in var.args
                push!(edg, (scope, :comp, :var, val, :var, lhs))
            end
        end
        if typ == :structure
            @debug var, val
            for rhs in val.args
                push!(edg, (scope, :comp, :var, var, :val, rhs))
            end
        end

    end
    for (funcname, smc) in subdef
        @debug "Recursing"
        # @show funcname, smc
        subedges = edges(smc, [], "$scope.$funcname")
        for e in subedges
            push!(edg, e)
        end
    end
    return edg
end
end

using SemanticModels.Parsers
@debug "Done Loading Package"

if length(ARGS) < 1
    error("You must provide a file path to a .jl file", args=ARGS)
end
path = ARGS[1]
@info "Parsing julia script" file=path
expr = parsefile(path)
mc = defs(expr.args[3].args)
@info "script uses modules" modules=mc.modc
@info "script defines functions" funcs=mc.fc.defs
@info "script defines glvariables" funcs=mc.vc
subdefs = recurse(mc)
@info "local scope definitions" subdefs=subdefs

for func in subdefs
    funcname = func[1]
    mc = func[2]
    @info "$funcname uses modules" modules=mc.modc
    @info "$funcname defines functions" funcs=mc.fc.defs
    @info "$funcname defines variables" funcs=mc.vc
end



edg = Edges.edges(mc, subdefs, expr.args[2])
@info("Edges found", path=path)
for e in edg
    println(e)
end
