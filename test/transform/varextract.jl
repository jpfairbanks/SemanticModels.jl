module Extract
using Cassette
using Test
Cassette.@context TraceCtx
function varname(ir::Core.CodeInfo, sym::Symbol)
    s = string(sym)[2:end]
    i = parse(Int,s)
    varname = ir.slotnames[i]
    return varname
end

# function Cassette.overdub(ctx::TraceCtx, f::typeof(varname), args...)
#     println("calling varname")
#     return Cassette.fallback(varname, args...)
# end

struct Extraction
    ir::Core.CodeInfo
    varnames::Vector{Symbol}
    funccalls::Vector{Any}
    literals::Vector{Any}
    SSAassigns::Vector{Any}
end

function Extraction(ir)
    return Extraction(ir, Symbol[], Any[], Any[], Any[])
end

function Base.push!(ext::Extraction, expr::Expr)
    ir = ext.ir
    if expr.head == :(=)
        @show expr
        try
            sym = Symbol(expr.args[1])
            vn = varname(ir, sym)
            push!(ext.varnames, vn)
            if isa(expr.args[2], Expr)
                if expr.args[2].head == :(call)
                    fname = expr.args[2].args[1]
                    push!(ext.funccalls, (vn, fname))
                else
                    @warn "No method to handle Non-call Expr as RHS: $(expr.args[2])"
                end
            elseif isa(expr.args[2], Core.SSAValue)
                @info "hit an SSAValue $vn = $(expr.args[2])"
                push!(ext.SSAassigns, expr)
            else
                @info "Residual Clause: $(expr): $(expr.args[2])"
                push!(ext.literals, expr)
            end
        catch ex
            @show ex
            # @warn "could not find slotname for $(expr.args[1])"
            # @show slotnames
            # @show expr.args[1], s, i
        end
    end
end

function Base.show(ext::Extraction)
    if length(ext.varnames) > 0
        @show ext.varnames
    end
    if length(ext.funccalls) > 0
        @show ext.funccalls
    end
    if length(ext.literals) > 0
        @show ext.literals
    end
    if length(ext.SSAassigns) > 0
        @show ext.SSAassigns
    end
end

# Define a Cassette pass to log the varnames
function extractpass(::Type{<:TraceCtx}, reflection::Cassette.Reflection)
    ir = reflection.code_info
    slotnames = ir.slotnames
    vn = slotnames[end]
    ext = Extraction(ir)
    s = ""
    i = 1
    modname = ir.linetable[1].mod
    methname = ir.linetable[1].method
    for expr in ir.code
        if expr == nothing
            continue
        end

        if !isa(expr, Expr) && expr != nothing
            @debug "Found non expression. $expr"
            continue
        end
        push!(ext, expr)
    end
    if length(ext.varnames) > 0
        @info "Working with method: $(modname).$(methname)"
        show(ext)
    end
    # TODO: do something with functions without explicit assignment.
    # if length(varnames) == 0
    #     @show ir
    # end
    return ir

end

const ExtractPass = Cassette.@pass extractpass


a = rand(3)
b = rand(3)
function add(a, b)
    c = a + b
    return c
end
ctx = TraceCtx(pass=ExtractPass, metadata = Any[])
# before_time = time()
result = Cassette.overdub(ctx, add, a, b)
@test result == a + b
@show result
# @test isempty(global_test_cache)
# @show callback()
# @test global_test_cache == [a, b, result]
# println("done (took ", time() - before_time, " seconds)")
end
