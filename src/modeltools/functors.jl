module FunctorTransforms
using Base.Iterators
using MacroTools

using SemanticModels
using SemanticModels.ModelTools

import Base: show
import SemanticModels.ModelTools: head
import SemanticModels.ModelTools.Transformations: Transformation

export FunctorTransformation, Functor, ob, morph, Extension, Method,
    PreimageExtension, transmorph

head(x::Symbol) = nothing
abstract type FunctorTransformation <: Transformation end

struct Functor{A,B} <: FunctorTransformation
    ob::A
    morph::B
end

function (ft::Functor)(x::DataType)
    ob(ft)(x)
end

function (ft::Functor)(f::Function)
    morph(ft)(f)
end

ob(F::Functor) = F.ob
morph(F::Functor) = F.morph

abstract type Extension <: Transformation end

struct Method{T}
    func::Function
    args::T
    ret::Union{Nothing, DataType}
end
Method(f, args::T) where T = Method{T}(f, args, nothing)

show(io::IO, m::Method) = begin
    fname = nameof(m.func)
    ret = m.ret == nothing ? "nothing" : string(m.ret)
    args = m.args
    write(io, "Method $fname($args)::$ret ")
end


struct ArithModel <: AbstractModel
    expr::Expr
end

# types(m::ArithModel) = DataType[]
# funcs(m::ArithModel) = begin
# end

function transmorph(f, ex::Expr)
    isa(ex, Expr) || return ex
    ex.head == :function || return ex
    return f(splitdef(ex))
end

function transmorph(f, x)
    return x
end

# function transmorph(f, ex::Vector{Expr})
#     isa(ex, Expr) || return ex
#     ex.head == :function || return ex
#     l = map(ex) do x
#         f(splitdef(x))
#     end |> flatten
#     return Macrotools.combinedef.(l)
# end

function transform(functor, ex)
    ex′ = MacroTools.postwalk(ex) do x
        isa(x, Expr) || return x
        if x.head == :function
            def = splitdef(x)
            return functor(def)
        end
        return x
    end
    return MacroTools.flatten(ex′)
end


struct PreimageExtension{M,M′} <: Extension
    obj::Vector{Pair{DataType,DataType}}
    morph::Vector{Pair{Expr,Expr}}
    expr::M
    expr′::M′
    F::Function
end

show(io::IO, pix::PreimageExtension) = begin
    write(io, string(typeof(pix)))
end

# function (t::PreimageExtension)(m::AbstractModel)
#     newTypes = map(types(m)) do T
#         T′ = ob(t.F)(T)
#         [t => T for t in T′]
#     end |> flatten
#     newFuncs = map(funcs(m)) do f
#         f′ = morph(t.F)(f)
#         [f=>ϕ for ϕ in f′]
#     end |> flatten
#     return newTypes, newFuncs
# end

# pe = PreimageExtension((Pair{DataType,DataType}[], Pair{Any,Any}[]), Functor(t->t, f->f))

function PreimageExtension(functor::Function, ex::Expr)
    preimages = Pair{Expr, Expr}[]
    ex = MacroTools.longdef(ex)
    ex′ = MacroTools.postwalk(ex) do x
        transmorph(x) do f
            newdefs = functor(f)
            newfs = map(newdefs) do def
                f′ = MacroTools.combinedef(def)
                push!(preimages, f′=>x)
                f′
            end
            newblock = :(begin $(newfs...) end)
            return newblock
        end
    end
    return PreimageExtension(Pair{DataType, DataType}[],
                             preimages,
                             ex,
                             ex′,
                             functor)
end


end
