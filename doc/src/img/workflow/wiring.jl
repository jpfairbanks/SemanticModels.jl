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
idLib = id(Ports([Lib]))
idCode = id(Ports([C]))
idMach = id(Ports([Mach]))

derv, impl, genr, runi = ops

# build the model
flow = ((derv ⊗ idLib) ⊚ impl) ⊚ genr ⊗ idMach ⊚ runi

# model of rewrite rules as a wiring diagram

Model, Span = Ob(FreeSymmetricMonoidalCategory, :Model, :Rule)
spanner = Hom(:construct, Model ⊗ Model ⊗ Model, Span) |> WiringDiagram
dpo = Hom(:rewrite, Span ⊗ Model, Model ⊗ Model) |> WiringDiagram
# deleter = Hom(:discard, Model, ()) |> WiringDiagram

# rewrite = (spanner ⊗ WiringDiagram(Hom(:id, Model, Model))) ⊚ dpo ⊚
#     to_wiring_diagram(otimes(delete(Model),
#            delete(Model)))

id_model = id(Ports([Model]))
rewrite = (spanner ⊗ id_model) ⊚ dpo

delete_model = delete(Ports([Model]))
rewritetwice = (( (spanner ⊗ id_model) ⊚ dpo ) ⊗
    (id_model ⊗ id_model) ⊚
    (delete_model ⊗ spanner) ⊗ id_model) ⊚
    dpo

# rewritetwice = ⊚(
#     otimes(
#         compose(
#             otimes(
#                 ⊚(
#                     otimes(spanner,
#                            id_model),
#                     dpo),
#                 otimes(id_model, id_model)),
#             otimes(delete_model, spanner)),
#         id_model),
#     dpo)


rewritetwice = (( (spanner ⊗ id_model) ⊚ dpo ) ⊗
    (id_model ⊗ id_model) ⊚
    (delete_model ⊗ spanner) ⊗ id_model) ⊚
    dpo

rewritetwice = spanner ⊗ (rewrite ⊚ (delete_model ⊗ id_model)) ⊚ dpo ⊚ (delete_model ⊗ id_model)

M2 = id_model ⊗ id_model
M3 = M2 ⊗ id_model
M4 = M3 ⊗ id_model
rewritemodule = WiringDiagram(Hom(:dpor, Model⊗Model⊗Model⊗Model, Model))
rewritemoduleleft = WiringDiagram(Hom(:dpol, Model⊗Model⊗Model⊗Model, Model))

rw2mod = ((M3) ⊗ rewritemodule) ⊚ rewritemodule

X, Y, β, R = Ob(FreeSymmetricMonoidalCategory, :X, :Y, :β, :R)
p = Hom(:p, X, Y) |> WiringDiagram
id_wire(x) = id(Ports([x]))
fit = Hom(:fit, X⊗Y, β) |> WiringDiagram
predict = Hom(:predict, X⊗β, Y) |> WiringDiagram
genloss = Hom(:loss, Y⊗Y, R) |> WiringDiagram

regression = (fit ⊗ id_wire(X) ⊗ id_wire(Y)) ⊚ (predict ⊗ id_wire(Y))
validation = (regression) ⊚ genloss



# save the image
modelnames = ["flow", "rewrite", "rewrite_twice", "rewrite_twice_modular", "regression", "validation"]
models = [flow, rewrite, rewritetwice, rw2mod, regression, validation]

try
    mkpath("img")
    writesvg.(zip(["img/$f.svg"
                   for f in modelnames],
                  models))
catch e
    error("Could not write images, does ./img exist?\n $e")
end
println("Model Drawings are in ./img")
