
#
# This file copies much of the same functionality from varextract.jl, 
# with important modifications to write out test traces to a file - 
# "traces.dat" - for subsequent classification modeling. 
# 

using Distributions
using DelimitedFiles
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

# defines the set of methods we do NOT want to descend into.
function Cassette.canrecurse(ctx::TraceCtx,
                             f::Union{typeof(+), typeof(*), typeof(/), typeof(-),typeof(Base.iterate),
                                      typeof(Base.sum),
                                      typeof(Base.mapreduce),
                                      typeof(Base.Broadcast.copy),
                                      typeof(Base.Broadcast.instantiate),
                                      typeof(Base.Broadcast.broadcasted)},
                             args...)
    return false
end


#
# This function has been modified from the version in varextract.jl 
# in the first line, where instead of "@show f, args" we write these
# objects to our output file "traces.dat"
# 
# Not elegant, but various other approaches did not write out the 
# correct trace information. This should be updated with a more elegant
# solution when possible. 
# 

function Cassette.overdub(ctx::TraceCtx,
                          f,
                          args...)
    open("traces.dat", "a") do file
        write(file, string(f))
        write(file, string(args))
    end
    
    # if we are supposed to descend, we call Cassette.recurse
    if Cassette.canrecurse(ctx, f, args...)
        subtrace = (Any[],Any[])
        push!(ctx.metadata[1], (f, args) => subtrace)
        newctx = Cassette.similarcontext(ctx, metadata = subtrace)
        retval = Cassette.recurse(newctx, f, args...)
        # push!(ctx.metadata[2], subtrace[2])
    else
        retval = Cassette.fallback(ctx, f, args...)
        push!(ctx.metadata[1], :t)
        push!(ctx.metadata[2], retval)
    end
    @info "returning"
    @show retval
    return retval
end


function add(a, b)
    c = a + b
    return c
end

#
# This testset produces 30,000 traces on these basic arithmetic 
# functions, and writes them to a file called "traces.dat"
# 

@testset "TraceExtract" begin
    g(x) = begin
        y = add(x.*x, -x)
        z = 1
        v = y .- z
        s = sum(v)
        return s
    end
    h(x) = begin
        z = g(x)
        zed = sqrt(z)
        return zed
    end

    open("traces.dat", "w") do f
        write(f, "")
    end

    # Error conditions happen when our inputs are sufficiently small, so 
    # Normal(0,2) gives us a good range of values to generate a reasonable
    # percentage of "bad" traces on which to train. Empirically the share
    # of "bad" traces is about 15-17%.

    seeds = rand(Normal(0,2),3000,3)
    
    for i=1:size(seeds,1)
        ctx = TraceCtx(pass=ExtractPass, metadata = (Any[], Any[]))
        try
            result = Cassette.overdub(ctx, h, seeds[i,:])
        catch DomainError
            dump(ctx.metadata)
        finally
            open("traces.dat", "a") do f
                write(f, "\n")
            end
        end
        if i%1000 == 0
            @info string(i)
        end
    end
end

text = split(String(read("traces.dat")), "\n");
Ys = Int.(occursin.(Ref(r"(Base[\S(?!\))]+error)"i), text));

text = split.(text, Ref(r"(Base[\S(?!\))]+error)"i));
text = [t[1] for t in text];

writedlm( "traces.csv",  text[1:end-1], ',')
writedlm( "y_results.csv",  Ys[1:end-1], ',')
