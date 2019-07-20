"""
img/workflow/wiring.jl creates ASKE workflows as wiring diagrams.

This is an attempt to show that we can use SemanticModels recursively on itself.
It is also a useful script to show how to make a wiring diagram and save it to an SVG.

"""
using Catlab

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

# Generators
F, M, C, Soln, Sci, Frame, Lib, Solv, Prog, Mach = Ob(FreeSymmetricMonoidalCategory,
                                                      :Formulation, :Model,
                                                      :Code, :Solution,
                                                      :Scientist, :Framework,
                                                      :Library, :Solver, :Program,
                                                      :Machine)

# Boxes
ops = WiringDiagram.([
    Hom(:derive, F⊗Frame, M),
    Hom(:implement, M⊗Lib, C),
    Hom(:generate, C, Prog),
    Hom(:run, Prog⊗Mach, Soln)
])

# this is a hack, because I don't know how to make a bare wire
idLib = WiringDiagram(Hom(:id, Lib,Lib))
idCode = WiringDiagram(Hom(:id, C,C))
idMach = WiringDiagram(Hom(:id, Mach, Mach))

derv, impl, genr, runi = ops

# build the model
flow = ((derv ⊗ idLib) ⊚ impl) ⊚ genr ⊗ idMach ⊚ runi

# save the image
modelnames = ["flow"]
models = [flow]

try
    mkpath("img")
    writesvg.(zip(["img/$f.svg"
                   for f in modelnames],
                  models))
catch e
    error("Could not write images, does ./img exist?\n $e")
end
println("Model Drawings are in ./img")
