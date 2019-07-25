using Catlab
using MacroTools
import MacroTools: postwalk, striplines
using ModelingToolkit
import ModelingToolkit: Constant
using Test

using Catlab.WiringDiagrams
using Catlab.Doctrines
import Catlab.Doctrines.⊗
import Catlab.Graphics: to_graphviz
import Catlab.Graphics.Graphviz: run_graphviz
⊗(a::WiringDiagram, b::WiringDiagram) = otimes(a,b)
import Base: ∘
∘(a::WiringDiagram, b::WiringDiagram) = compose(b, a)
⊚(a,b) = b ∘ a

function writesvg(f::Union{IO,AbstractString}, d::WiringDiagram)
    write(f, to_graphviz(d, labels=true)
          |>g->run_graphviz(g, format="svg")
          )
end

writesvg(x) = writesvg(x...)


wirenames(d::WiringDiagram) = foldr(union,
    map(box->union(input_ports(box), output_ports(box)),
        boxes(d)))

OpVar(s::Symbol) = Operation(Variable(s), [])

plusup(op1, op2) = begin
    b = op1.op == identity
    b ? op2 : op1 + op2
end

function simplify(transitions)
    return unique(transitions)
end

function petri_model(d::WiringDiagram)
    # TODO design Multiple Dispatch Lens API
    vars = wirenames(d)
    symvars = OpVar.(vars)
    byvar = Dict{Symbol, Operation}()
    homnames = Vector{Symbol}()
    transitions = map(enumerate(boxes(d))) do (i, box)
        invars = input_ports(box)
        outvars = output_ports(box)
        homname = box.value
        push!(homnames, homname)
        δ_in  =  length(invars)  > 1 ? +(OpVar.( invars)...) : OpVar.(invars[1])
        δ_out =  length(outvars) > 1 ? +(OpVar.(outvars)...) : OpVar.(outvars[1])
        return (δ_in, δ_out)
    end
    return vars, simplify(transitions), homnames
end

# Generators
S, E, I, R, D= Ob(FreeSymmetricMonoidalCategory, :S, :E, :I, :R, :D)

infecting = Hom(:infection, S ⊗ I, I⊗I)

inf  = WiringDiagram(infecting)
expo = WiringDiagram(Hom(:exposure, S⊗I, E⊗I))
rec  = WiringDiagram(Hom(:recovery, I,   R))
wan  = WiringDiagram(Hom(:waning,   R,   S))

si    = WiringDiagram(Hom(:infection,   S⊗I, I⊗I))
se    = WiringDiagram(Hom(:exposure,    S⊗I, E⊗I))
prog  = WiringDiagram(Hom(:progression, E,   I))
fatal = WiringDiagram(Hom(:die,  I, D))
rip   = WiringDiagram(Hom(:rest, D, D))

sir    = si    ⊚ (rec   ⊗ rec)
seir   = se    ⊚ (prog  ⊗ rec)
seirs  = seir  ⊚ (wan   ⊗ wan)
seird  = seir  ⊚ (fatal ⊗ WiringDiagram(Hom(:id, R, R)))
seirds = seird ⊚ (rip   ⊗ wan)


models = [sir, seir, seirs, seird, seirds]
nets   = petri_model.(models)

modelnames = ["sir",
         "seir",
         "seirs",
         "seird",
         "seirds",
         ]
map(zip(nets, modelnames)) do (net, name)
    Δ = reverse(net[2])
    println("Model: $name\n  Connections:")
    println("    $Δ\n")
    Δ
end

try
    mkpath("img")
    writesvg.(zip(["img/$f.svg"
                   for f in modelnames],
                  models))
catch e
    error("Could not write images, does ./img exist?\n $e")
end
println("Model Drawings are in ./img")
