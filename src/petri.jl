# +
module PetriNets

abstract type AbstractNode end

const Option{T} = Union{T, Missing}

mutable struct Node <: AbstractNode
    name::Any
    value::Int32
end

struct Transition <: AbstractNode
    name::Any
    inputs::Vector{Tuple{Node,Bool}}
    outputs::Vector{Node}
end

struct PetriNet
    nodes::Vector{Node}
    transitions::Vector{Transition}
end

name(n::AbstractNode) = n.name

function ready(t::Tuple{Node,Bool})
    n = t[1]
    b = t[2]
    return b ? value(n) > 0 : value(n) == 0
end

function ready(n::Transition)
    return length(filter(x->ready(x) == false, n.inputs)) == 0
end

function value(n::Node)
    return n.value
end

clear(n::Node) = begin
    n.value = 0
    return
end

function run!(n::Transition)
    #@show name(n)
    if ready(n)
        if length(findall(i->!xor(i[1] in n.outputs, i[2]), n.inputs)) == length(n.inputs)
            error(string("Infinite loop detected at transition ", name(n)))
        end
        #@info "Decrease inputs"
        map(n.inputs) do i
            i[1].value -= i[1].value > 0 ? 1 : 0
        end
        #@info "Increase outputs"
        map(n.outputs) do i
            i.value += 1
        end
    end
end

function run!(p::PetriNet)
    run = true
    while run
        run = false
        for n in p.transitions
            while ready(n)
                run = true
                run!(n)
            end
        end
    end
end

end


# +
n1 = PetriNets.Node(:n1, 10)
n2 = PetriNets.Node(:n2, 1)
n3 = PetriNets.Node(:n3, 0)
n4 = PetriNets.Node(:n4, 0)
n5 = PetriNets.Node(:n5, 0)
n6 = PetriNets.Node(:n6, 0)
n7 = PetriNets.Node(:n7, 1)
n8 = PetriNets.Node(:n8, 0)

t1 = PetriNets.Transition(:t1, [(n1,true)], [n3])
t2 = PetriNets.Transition(:t2, [(n2,true)], [n3])
t3 = PetriNets.Transition(:t3, [(n3,true)], [n4,n5])
t4 = PetriNets.Transition(:t4, [(n4,true)], [n6])
t5 = PetriNets.Transition(:t5, [(n5,true)], [n6])
t6 = PetriNets.Transition(:t6, [(n6,true)], [n8])
t7 = PetriNets.Transition(:t7, [(n7,true)], [n8])

pn1 = PetriNets.PetriNet([n1,n2,n3,n4,n5,n6,n7,n8], [t1, t2, t3, t4, t5, t6, t7])
PetriNets.run!(pn1)
@show n8


n9 = PetriNets.Node(:n9, 1)
n10 = PetriNets.Node(:n10, 0)
n11 = PetriNets.Node(:n11, 0)

t8 = PetriNets.Transition(:t8, [(n9, true), (n10, false)], [n11])

pn2 = PetriNets.PetriNet([n9, n10, n11], [t8])
PetriNets.run!(pn2)
@show n11

n12 = PetriNets.Node(:n12, 1)
n13 = PetriNets.Node(:n13, 0)
n14 = PetriNets.Node(:n14, 0)
t9 = PetriNets.Transition(:t9, [(n12, true), (n13, false)], [n12,n14])
pn3 = PetriNets.PetriNet([n12, n13], [t9])
PetriNets.run!(pn3)
# -

import TikzPictures
using Catlab.Graphics
using Catlab.Doctrines
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

WiringDiagram(p::PetriNets.PetriNet, mappi lng) = composel(boxes(p, mapping)) |> composel


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
# can we represent a petrinet as a presentation?
# This is like a database schema where you have Ob representing tables
# and Homs representing foreign keys. The equations are the business rules
# preserved by the DB.
# How do we represent a specific petri net?
# As a Petri-Instance, ie. a functor from Petri to what?
@present Petri(FreeCategory) begin
  # Primitive concepts.
  Node::Ob
  Symb::Ob
  Input::Ob
  Position::Ob
  
  name::Hom(Node, Symb)
  output::Hom(Node, Node)
  slot::Hom(Input, Position)
  source::Hom(Input, Node) # the place a connection came from
  target::Hom(Input, Node) # the place a connection goes to

  # Defined concepts.
  # second_level_manager := compose(manager, manager)
  # third_level_manager := compose(manager, manager, manager)

  # Abbreviations (no syntactic term for LHS).
  # boss = manager

  # Managers work in the same department as their employees.
  # compose(boss, works_in) == works_in
  # The secretary of a department works in that department.
  # compose(secretary, works_in) == id(Department)
end


struct Instance{C, D}
    index::C
    image::D
end

inst = Instance(Petri, p)

import Base: getindex, setindex
function getindex(inst::Instance{Presentation{Symbol},PetriNets.PetriNet}}, obj::Catlab.Doctrines.FreeCategory.Ob{:generator})
    instance.index
end
