module PetriNets


abstract type AbstractNode end

struct Constant{T} <: AbstractNode
    value::T
end

struct Sink <: AbstractNode
    name
    op::Function
    inputs::Vector{AbstractNode}
end

struct Box{T}
    ready::Bool
    value::T
end

const Option{T} = Union{T, Missing}

mutable struct Node <: AbstractNode
    name::Any
    op::Function
    inputs::Vector{AbstractNode}
    outputs::Union{Any, Missing}
end

struct PetriNet
    nodes::Vector{AbstractNode}
end

name(n::AbstractNode) = n.name
name(c::Constant) = Symbol("C$(value(c))")

function value(n::Node)
    return n.outputs
end

function value(n::Constant)
    return n.value
end

clear(n::Node) = begin
    n.outputs = missing
    return
end

clear(c::Constant) = nothing
clear(s::Sink) = nothing

tupler(inputs::Vector{AbstractNode}) = Node(gensym(:tupler), tuple, inputs, missing)

run!(c::Constant) = c.value
function run!(n::Node)
    @show name(n)
    invals = map(n.inputs) do i
        value(i)
    end

    if any(ismissing, invals)
        @info "Waiting for a dependency"
        return missing
    end

    if !ismissing(value(n))
        @info "Waiting for output to clear"
        return missing
    end
    @info "Firing node $(name(n)), $(invals)"
    n.outputs = n.op(invals...)

    @info "Clearing out deps"
    map(n.inputs) do i
        clear(i)
    end

    return n.outputs

end

function run!(n::Sink)
    @show name(n)
    invals = map(n.inputs) do i
        value(i)
    end

    if any(ismissing, invals)
        @info "Waiting for a dependency"
        return missing
    end

    @info "Firing node $(name(n)), $(invals)"
    y = n.op(invals...)

    @info "Clearing out deps"
    map(n.inputs) do i
        clear(i)
    end

    return y

end

nv(p) = length(p.nodes)

function run!(p::PetriNet)
    for (i, n) in enumerate(p.nodes)
        value = run!(n)
        if !ismissing(value) && i == nv(p)
            @show name(n), value
        end

    end
end


n1 = Node(:A,
          x->x+1,
          [Constant(1)],
          missing)
n2 = Node(:B,
          x->2x,
          [n1],
          missing)
n3 = Node(:C,
          +,
          [n2, Constant(1)],
          missing
          )
# n4 = Node(:D,
#           ( x... )->begin println(+(x...))
#           return missing
#           end,
#           [n2, Constant(1)],
#           missing
#           )
n4 = Sink(:D, println, [n3])

@show n1
@show n4

end

name = PetriNets.name

n1 = PetriNets.n1
n2 = PetriNets.n2
n3 = PetriNets.n3
n4 = PetriNets.n4
# for i in 1:3
#     PetriNets.run!(n1)
# end

p = PetriNets.PetriNet([n1,n2,n3, n4])
for i in 1:10
    PetriNets.run!(p)
end

using Catlab
using Catlab.WiringDiagrams
import Catlab.WiringDiagrams.WiringDiagramCore: boxes, WiringDiagram

A, B, C, D, One = Ob(FreeSymmetricMonoidalCategory, :A, :B, :C, :D, :1)

function boxes(p::PetriNets.PetriNet, mapping)
    j = 1
    map(p.nodes) do n
        @info "Constructing Homsets to $(name(n))"
        map(n.inputs) do i
            s,t = name(i), name(n)
            x,y = mapping[s], mapping[t]
            j += 1
            WiringDiagram(Hom(Symbol("f_$j"), x,y))
        end
    end
end

composel(x::Vector{Vector{WiringDiagram}}) = foldl.(compose, x)
composel(x::Vector{WiringDiagram}) = foldl(compose, x)

WiringDiagram(p::PetriNets.PetriNet, mapping) = composel(boxes(p, mapping)) |> composel


mapping = Dict(:A=>A,
              :B=>B,
              :C=>C,
              :D=>D,
              :C1=>One)
bx = boxes(p, mapping)

@assert length(bx) == PetriNets.nv(p)
d = WiringDiagram(p, mapping)

struct PetriEdge
    value
    input
    output
    meta
end



function PetriNet(d::WiringDiagram, mapping)
    edges = map(boxes(d)) do box
        PetriEdge(box.value, box.input_ports[1], box.output_ports[1],())
    end
    
end
