
julia> using Catlab
[ Info: Precompiling Catlab [134e5e36-593f-5add-ad60-77f754baafbe]

julia> using Catlab

julia> # Low-level graph interface
       ###########################

       A, B, C, D = Ob(FreeSymmetricMonoidalCategory, :A, :B, :C, :D)
ERROR: UndefVarError: Ob not defined
Stacktrace:
 [1] top-level scope at none:0

julia> f = Hom(:f, A, B)
ERROR: UndefVarError: Hom not defined
Stacktrace:
 [1] top-level scope at none:0

julia> g = Hom(:g, B, C)
ERROR: UndefVarError: Hom not defined
Stacktrace:
 [1] top-level scope at none:0

julia> h = Hom(:h, C, D)
ERROR: UndefVarError: Hom not defined
Stacktrace:
 [1] top-level scope at none:0

julia> using Catlab.Doctrines, Catlab.WiringDiagrams
WARNING: using Doctrines.⋅ in module Main conflicts with an existing identifier.

julia> # Low-level graph interface
       ###########################

       A, B, C, D = Ob(FreeSymmetricMonoidalCategory, :A, :B, :C, :D)
4-element Array{Catlab.Doctrines.FreeSymmetricMonoidalCategory.Ob{:generator},1}:
 A
 B
 C
 D

julia> f = Hom(:f, A, B)
f

julia> g = Hom(:g, B, C)
g

julia> h = Hom(:h, C, D)
h

julia>

julia> h
h

julia> dump(h)
Catlab.Doctrines.FreeSymmetricMonoidalCategory.Hom{:generator}
  args: Array{Any}((3,))
    1: Symbol h
    2: Catlab.Doctrines.FreeSymmetricMonoidalCategory.Ob{:generator}
      args: Array{Symbol}((1,))
        1: Symbol C
      type_args: Array{GATExpr}((0,))
    3: Catlab.Doctrines.FreeSymmetricMonoidalCategory.Ob{:generator}
      args: Array{Symbol}((1,))
        1: Symbol D
      type_args: Array{GATExpr}((0,))
  type_args: Array{GATExpr}((2,))
    1: Catlab.Doctrines.FreeSymmetricMonoidalCategory.Ob{:generator}
      args: Array{Symbol}((1,))
        1: Symbol C
      type_args: Array{GATExpr}((0,))
    2: Catlab.Doctrines.FreeSymmetricMonoidalCategory.Ob{:generator}
      args: Array{Symbol}((1,))
        1: Symbol D
      type_args: Array{GATExpr}((0,))

julia> uni
union   union!   unique   unique!
julia> show_unicode(h)
h
julia> d
ERROR: UndefVarError: d not defined

julia> # Operations on boxes
       d = WiringDiagram(A, C)
WiringDiagram([:A], [:C],
[ 1 => {inputs},
  2 => {outputs},
   ],
[  ])

julia> @test nboxes(d) == 0
ERROR: LoadError: UndefVarError: @test not defined
in expression starting at REPL[85]:1

julia> @test_throws KeyError box(d,input_id(d))
ERROR: LoadError: UndefVarError: @test_throws not defined
in expression starting at REPL[86]:1

julia> @test_throws KeyError box(d,output_id(d))
ERROR: LoadError: UndefVarError: @test_throws not defined
in expression starting at REPL[87]:1

julia>

julia> d
WiringDiagram([:A], [:C],
[ 1 => {inputs},
  2 => {outputs},
   ],
[  ])

julia> box
box     box_ids  boxes
julia> box
box     box_ids  boxes
julia> box(d, input_id(d))
ERROR: KeyError: key :box not found
Stacktrace:
 [1] getindex at ./dict.jl:478 [inlined]
 [2] get_prop(::MetaGraphs.MetaDiGraph{Int64,Float64}, ::Int64, ::Symbol) at /Users/jpf/.julia/packages/MetaGraphs/kAvjf/src/MetaGraphs.jl:236
 [3] box(::WiringDiagram, ::Int64) at /Users/jpf/.julia/dev/Catlab/src/wiring_diagrams/Core.jl:265
 [4] top-level scope at none:0

julia> d
WiringDiagram([:A], [:C],
[ 1 => {inputs},
  2 => {outputs},
   ],
[  ])

julia> input_id(d)
1

julia> output_id(d)
2

julia> d.
graph        input_id      input_ports   output_id     output_ports
julia> d.graph
{2, 0} directed Int64 metagraph with Float64 weights defined by :weight (default weight 1.0)

julia> d.input_ports
1-element Array{Symbol,1}:
 :A

julia> d.output_ports
1-element Array{Symbol,1}:
 :C

julia> add_box!(d, f)
3

julia> d
WiringDiagram([:A], [:C],
[ 1 => {inputs},
  2 => {outputs},
  3 => Box(:f, [:A], [:B]) ],
[  ])

julia> box(d, 3)
Box(:f, [:A], [:B])

julia> box(d, 3).value
:f

julia> boxf = box(d, 3)
Box(:f, [:A], [:B])

julia> boxf.
input_ports  output_ports  value
julia> boxf.output_ports
1-element Array{Symbol,1}:
 :B

julia> boxf.input_ports
1-element Array{Symbol,1}:
 :A

julia> boxf.value
:f

julia> d
WiringDiagram([:A], [:C],
[ 1 => {inputs},
  2 => {outputs},
  3 => Box(:f, [:A], [:B]) ],
[  ])

julia> d.
graph        input_id      input_ports   output_id     output_ports
julia> d.output_ports
1-element Array{Symbol,1}:
 :C

julia> WiringDiagram(Hom(:f, A, B))
WiringDiagram([:A], [:B],
[ 1 => {inputs},
  2 => {outputs},
  3 => Box(:f, [:A], [:B]) ],
[ Wire((1,1) => (3,1)),
  Wire((3,1) => (2,1)) ])

julia> WiringDiagram(Hom(:f, A, B)) ⋅ WiringDiagram(Hom(:g, B, C))
ERROR: MethodError: no method matching iterate(::WiringDiagram)
Closest candidates are:
  iterate(::Core.SimpleVector) at essentials.jl:589
  iterate(::Core.SimpleVector, ::Any) at essentials.jl:589
  iterate(::ExponentialBackOff) at error.jl:171
  ...
Stacktrace:
 [1] dot(::WiringDiagram, ::WiringDiagram) at /Users/osx/buildbot/slave/package_osx64/build/usr/share/julia/stdlib/v1.0/LinearAlgebra/src/generic.jl:652
 [2] top-level scope at none:0

julia> compose(WiringDiagram(Hom(:f, A, B)),WiringDiagram(Hom(:g, B, C)))
WiringDiagram([:A], [:C],
[ 1 => {inputs},
  2 => {outputs},
  3 => Box(:f, [:A], [:B]),
  4 => Box(:g, [:B], [:C]) ],
[ Wire((1,1) => (3,1)),
  Wire((3,1) => (4,1)),
  Wire((4,1) => (2,1)) ])

julia> compose(WiringDiagram(Hom(:f, A, B)),WiringDiagram(Hom(:g, B, C)), WiringDiagram(:h, B, C))
ERROR: MethodError: no method matching WiringDiagram(::Symbol, ::Catlab.Doctrines.FreeSymmetricMonoidalCategory.Ob{:generator}, ::Catlab.Doctrines.FreeSymmetricMonoidalCategory.Ob{:generator})
Closest candidates are:
  WiringDiagram(::ObExpr, ::ObExpr) at /Users/jpf/.julia/dev/Catlab/src/wiring_diagrams/Core.jl:706
Stacktrace:
 [1] top-level scope at none:0

julia> compose(WiringDiagram(Hom(:f, A, B)),WiringDiagram(Hom(:g, B, C)), WiringDiagram(Hom(:h, B, C)))
WiringDiagram([:A], [:C],
[ 1 => {inputs},
  2 => {outputs},
  3 => Box(:g, [:B], [:C]),
  4 => Box(:h, [:B], [:C]),
  5 => Box(:f, [:A], [:B]) ],
[ Wire((1,1) => (5,1)),
  Wire((3,1) => (4,1)),
  Wire((4,1) => (2,1)),
  Wire((5,1) => (3,1)) ])

julia> compose(WiringDiagram(Hom(:f, A, B)),WiringDiagram(Hom(:g, B, C)), WiringDiagram(Hom(:h, B, C))) |> dom
Ports{Symbol}(Symbol[:A])

julia> compose(WiringDiagram(Hom(:f, A, B)),WiringDiagram(Hom(:g, B, C)), WiringDiagram(Hom(:h, B, C))) |> codom
Ports{Symbol}(Symbol[:C])

julia> compose(WiringDiagram(Hom(:f, A, B)),WiringDiagram(Hom(:g, B, C)), WiringDiagram(Hom(:h, B, C))) |> ports
ERROR: UndefVarError: ports not defined
Stacktrace:
 [1] top-level scope at none:0

julia> compose(WiringDiagram(Hom(:f, A, B)),WiringDiagram(Hom(:g, B, C)), WiringDiagram(Hom(:h, B, C))) |> boxes
3-element Array{AbstractBox,1}:
 Box(:g, [:B], [:C])
 Box(:h, [:B], [:C])
 Box(:f, [:A], [:B])

julia> WiringDiagram(Hom(:f, A, B))
WiringDiagram([:A], [:B],
[ 1 => {inputs},
  2 => {outputs},
  3 => Box(:f, [:A], [:B]) ],
[ Wire((1,1) => (3,1)),
  Wire((3,1) => (2,1)) ])

julia> WiringDiagram(Hom(:f, A, B)) ⊗ WiringDiagram(Hom(:g, A, C))
ERROR: MethodError: no method matching ⊗(::WiringDiagram, ::WiringDiagram)
Stacktrace:
 [1] top-level scope at none:0

julia> otimes(WiringDiagram(Hom(:f, A, B)),WiringDiagram(Hom(:g, A, C)))
WiringDiagram([:A,:A], [:B,:C],
[ 1 => {inputs},
  2 => {outputs},
  3 => Box(:f, [:A], [:B]),
  4 => Box(:g, [:A], [:C]) ],
[ Wire((1,1) => (3,1)),
  Wire((1,2) => (4,1)),
  Wire((3,1) => (2,1)),
  Wire((4,1) => (2,2)) ])

julia> otimes(WiringDiagram(Hom(:f, A, B)),WiringDiagram(Hom(:g, A, C))) |> x->(dom(x), codom(x))
(Ports{Symbol}(Symbol[:A, :A]), Ports{Symbol}(Symbol[:B, :C]))

julia> compose(otimes(WiringDiagram(Hom(:f, A, B)),WiringDiagram(Hom(:g, A, C))), otimes(WiringDiagram(Hom(:h, C, D)), WiringDiagram(Hom(:hh, C, D)))
       ) |> x->(dom(x), codom(x))
(Ports{Symbol}(Symbol[:A, :A]), Ports{Symbol}(Symbol[:D, :D]))

julia> compose(otimes(WiringDiagram(Hom(:f, A, B)),WiringDiagram(Hom(:g, A, C))), otimes(WiringDiagram(Hom(:h, C, D)), WiringDiagram(Hom(:hh, C, E)))
       ) |> x->(dom(x), codom(x))
ERROR: UndefVarError: E not defined
Stacktrace:
 [1] top-level scope at none:0

julia> compose(otimes(WiringDiagram(Hom(:f, A, B)),WiringDiagram(Hom(:g, A, C))), otimes(WiringDiagram(Hom(:h, C, D)), WiringDiagram(Hom(:hh, C, A)))
       ) |> x->(dom(x), codom(x))
(Ports{Symbol}(Symbol[:A, :A]), Ports{Symbol}(Symbol[:D, :A]))

julia> B
B

julia> B.
args      type_args
julia> B.args
1-element Array{Symbol,1}:
 :B

julia> B.type_args
0-element Array{GATExpr,1}

julia> dump(B)
Catlab.Doctrines.FreeSymmetricMonoidalCategory.Ob{:generator}
  args: Array{Symbol}((1,))
    1: Symbol B
  type_args: Array{GATExpr}((0,))

julia> type
type_args     typeintersect  typemax        typeof
typeassert    typejoin       typemin
julia> FreeSymmetricMonoidalCategory.
Hom       braid      compose    eval       include    otimes
Ob        codom      dom        id         munit      signature
julia> FreeSymmetricMonoidalCategory.braid
braid (generic function with 1 method)
