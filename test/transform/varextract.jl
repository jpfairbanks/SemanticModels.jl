module Extract
using Cassette
using Test
Cassette.@context TraceCtx

"""    varname(ir::Core.CodeInfo, sym::Symbol)

look up the name of a slot from the codeinfo slotnames.

see also: ir.slotnames
"""
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

"""    Extraction

- ir: a CodeInfo object that we are extracting from
- varnames: Variable names used as left hand sides
- funccalls: Tuples of (returnvar, funcname)
- literals: Literal values used as right hand sides in assignment
- SSAassigns: Locations used for the storage of subexpression results ie (2+2*4), the value 8 is stored in an SSAassign
"""
struct Extraction
    ir::Core.CodeInfo
    varnames::Vector{Any}
    funccalls::Vector{Any}
    literals::Vector{Any}
    SSAassigns::Vector{Any}
end

"""     Extraction(ir)

construct an Extraction object from a piece of code info
"""
function Extraction(ir)
    return Extraction(ir, Symbol[], Any[], Any[], Any[])
end

function findvars(ext, ir, expr)
    @info "Finding Variables"
    # @show ir
    # dump(expr)
    # if typeof(expr) <: SSAValue
    #     return
    # end

    vars = Any[]
    try
        args = expr.args
        for arg in args
            # @show arg
            if typeof(arg) <: Core.SlotNumber
                push!(vars, varname(ir, Symbol(arg)))
            elseif typeof(arg) <: GlobalRef
                # @show arg
                continue
            # elseif typeof(arg) <: SSAValue
            #     continue
            else
                push!(vars, findvars(ext,ir,arg))
            end
        end
    catch
        dump(expr)
        return varname(ir, Symbol(expr))
    end

    return vars
end



# add an expression to the Extraction struct by parsing out the relevant info.
function Base.push!(ext::Extraction, expr::Expr)
    ir = ext.ir
    if expr.head == :(=)
        # @show expr
        try
            # @show expr.args
            sym = Symbol(expr.args[1])
            vn = varname(ir, sym)
            # vntree = findvars(ext, ir, expr)
            # push!(ext.varnames, vntree)
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

"""    extractpass(::Type{<:TraceCtx}, reflection::Cassette.Reflection)

is a Cassette pass to log the varnames and function calls to build the dynamic code graph
part of the SemanticModels knowledge graph.

"""
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
        # @show ext.ir
        @show ext.ir.slotnames
        println((modul=modname, func=methname, varnames=ext.ir.slotnames, callees=ext.funccalls))
    end
    # TODO: do something with functions without explicit assignment.
    # if length(varnames) == 0
    #     @show ir
    # end
    return ir

end

const ExtractPass = Cassette.@pass extractpass

function Cassette.overdub(ctx::TraceCtx,
                          f::Union{typeof(+), typeof(*), typeof(/), typeof(-),typeof(Base.iterate),
                                   typeof(Base.mapreduce),
                                   typeof(Base.Broadcast.copy),
                                   typeof(Base.Broadcast.instantiate),
                                   typeof(Base.Broadcast.broadcasted)},
                          args...)
    @show f, args
    retval = Cassette.fallback(ctx, f, args...)
    @show retval
    return retval
end


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
# println("done (took ", time() - before_time, " seconds)")
@info "Analyzing function g"
g(x) = begin
    y = add(x.*x, x)
    z = 1
    v = y .- z
    s = sum(v)
    return s
end

result = Cassette.overdub(ctx, g, [2,2,2])
end
