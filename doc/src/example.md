# Getting Started Example

The following example should help you understand the goals of this project.
The goal of this example is to illustrate how you can ingest two scientific models and perform
a metamodeling or model modification task on the using the SemanticModels system.

Our two models are an SEIR model that has 4 subpopulations (SEIR) and a ScalingModel has 2 subpopulations (SI).
The ScalingModel has a population growth parameter to approximate a changing population size.
We want to graft the population growth component of the ScalingModel onto the SEIR model, to produce a new model
with novel capabilities.

## Extraction

The script `bin/extract.jl` can extract a knowledge graph from code and documentation.

For example the SEIR model is described in the following Julia implementation.
```julia
module SEIRmodel
using DifferentialEquations

#Susceptible-exposed-infected-recovered model function
function seir_ode(dY,Y,p,t)
    #Infected per-Capita Rate
    β = p[1]
    #Incubation Rate
    σ = p[2]
    #Recover per-capita rate
    γ = p[3]
    #Death Rate
    μ = p[4]

    #Susceptible Individual
    S = Y[1]
    #Exposed Individual
    E = Y[2]
    #Infected Individual
    I = Y[3]
    #Recovered Individual
    #R = Y[4]

    dY[1] = μ-β*S*I-μ*S
    dY[2] = β*S*I-(σ+μ)*E
    dY[3] = σ*E - (γ+μ)*I
end

#Pram (Infected Rate, Incubation Rate, Recover Rate, Death Rate)
pram=[520/365,1/60,1/30,774835/(65640000*365)]
#Initialize Param(Susceptible Individuals, Exposed Individuals, Infected Individuals)
init=[0.8,0.1,0.1]
tspan=(0.0,365.0)

seir_prob = ODEProblem(seir_ode,init,tspan,pram)

sol=solve(seir_prob);

using Plots

va = VectorOfArray(sol.u)
y = convert(Array,va)
R = ones(size(sol.t))' - sum(y,dims=1);

plot(sol.t,[y',R'],xlabel="Time",ylabel="Proportion")
end
```

We can extract out a knowledge graph that covers this model along with an Scaling Model from `examples/epicookbook/src/ScalingModel.jl`

```julia
julia> include("extract.jl")
┌ Info: Graph created from markdown has v vertices and e edges.
│   v = 0
└   e = 0
┌ Info: Parsing julia script
└   file = "../examples/epicookbook/src/ScalingModel.jl"
s = "# -*- coding: utf-8 -*-\n# ---\n# jupyter:\n#   jupytext:\n#     text_representation:\n#       extension: .jl\n#       format_name: light\n#       format_version: '1.3'\n#       jupytext_version: 0.8.6\n#   kernelspec:\n#     display_name: Julia 1.0.3\n#     language: julia\n#     name: julia-1.0\n# ---\n\nmodule ScalingModel\nusing DifferentialEquations\n\nfunction micro_1(du, u, parms, time)\n    # PARAMETER DEFS\n    # β transmition rate\n    # r net population growth rate\n    # μ hosts' natural mortality rate\n    # Κ population size\n    # α disease induced mortality rate\n\n    β, r, μ, K, α = parms\n    dS = r*(1-S/K)*S - β*S*I\n    dI = β*S*I-(μ+α)*I\n    du = [dS,dI]\nend\n\n# +\n# PARAMETER DEFS\n# w and m are used to define the other parameters allometrically\n\nw = 1;\nm = 10;\nβ = 0.0247*m*w^0.44;\nr = 0.6*w^-0.27;\nμ = 0.4*w^-0.26;\nK = 16.2*w^-0.7;\nα = (m-1)*μ;\n# -\n\nparms = [β,r,μ,K,α];\ninit = [K,1.];\ntspan = (0.0,10.0);\n\nsir_prob = ODEProblem(micro_1,init,tspan,parms)\n\nsir_sol = solve(sir_prob);\n\nusing Plots\n\nplot(sir_sol,xlabel=\"Time\",ylabel=\"Number\")\n\nm = [5,10,20,40]\nws = 10 .^collect(range(-3,length = 601,3))\nβs = zeros(601,4)\nfor i = 1:4\n    βs[:,i] = 0.0247*m[i]*ws.^0.44\nend\nplot(ws,βs,xlabel=\"Weight\",ylabel=\"\\\\beta_min\", xscale=:log10,yscale=:log10, label=[\"m = 5\" \"m = 10\" \"m = 20\" \"m = 40\"],lw=3)\n\nend\n"
[ Info: unknown expr type for metacollector
expr = :(function micro_1(du, u, parms, time)
      #= none:27 =#
      (β, r, μ, K, α) = parms
      #= none:28 =#
      dS = r * (1 - S / K) * S - β * S * I
      #= none:29 =#
      dI = β * S * I - (μ + α) * I
      #= none:30 =#
      du = [dS, dI]
  end)
[ Info: unknown expr type for metacollector
expr = :(plot(sir_sol, xlabel="Time", ylabel="Number"))
[ Info: unknown expr type for metacollector
expr = :(for i = 1:4
      #= none:62 =#
      βs[:, i] = 0.0247 * m[i] * ws .^ 0.44
  end)
[ Info: unknown expr type for metacollector
expr = :(plot(ws, βs, xlabel="Weight", ylabel="\\beta_min", xscale=:log10, yscale=:log10, label=["m = 5" "m = 10" "m = 20" "m = 40"], lw=3))
┌ Info: script uses modules
│   modules =
│    2-element Array{Any,1}:
│     Any[:DifferentialEquations]
└     Any[:Plots]
┌ Info: script defines functions
│   funcs =
│    1-element Array{Any,1}:
│     :(micro_1(du, u, parms, time)) => quote
│        #= none:27 =#
│        (β, r, μ, K, α) = parms
│        #= none:28 =#
│        dS = r * (1 - S / K) * S - β * S * I
│        #= none:29 =#
│        dI = β * S * I - (μ + α) * I
│        #= none:30 =#
│        du = [dS, dI]
└    end
┌ Info: script defines glvariables
│   funcs =
│    15-element Array{Any,1}:
│            :w => 1
│            :m => 10
│            :β => :(0.0247 * m * w ^ 0.44)
│            :r => :(0.6 * w ^ -0.27)
│            :μ => :(0.4 * w ^ -0.26)
│            :K => :(16.2 * w ^ -0.7)
│            :α => :((m - 1) * μ)
│        :parms => :([β, r, μ, K, α])
│         :init => :([K, 1.0])
│        :tspan => :((0.0, 10.0))
│     :sir_prob => :(ODEProblem(micro_1, init, tspan, parms))
│      :sir_sol => :(solve(sir_prob))
│            :m => :([5, 10, 20, 40])
│           :ws => :(10 .^ collect(range(-3, length=601, 3)))
└           :βs => :(zeros(601, 4))
funcdefs = Any[:(micro_1(du, u, parms, time))=>quote
    #= none:27 =#
    (β, r, μ, K, α) = parms
    #= none:28 =#
    dS = r * (1 - S / K) * S - β * S * I
    #= none:29 =#
    dI = β * S * I - (μ + α) * I
    #= none:30 =#
    du = [dS, dI]
end]
┌ Info: local scope definitions
│   subdefs =
│    1-element Array{Any,1}:
└     :(micro_1(du, u, parms, time)) => MetaCollector{FuncCollector{Array{Any,1}},Array{Any,1},Array{Any,1},Array{Any,1}}(Any[:((β, r, μ, K, α) = parms), :(dS = r * (1 - S / K) * S - β * S * I), :(dI = β * S * I - (μ + α) * I), :(du = [dS, dI])], FuncCollector{Array{Any,1}}(Any[]), Any[:((β, r, μ, K, α))=>:parms, :dS=>:(r * (1 - S / K) * S - β * S * I), :dI=>:(β * S * I - (μ + α) * I), :du=>:([dS, dI])], Any[])
┌ Info: micro_1(du, u, parms, time) uses modules
└   modules = 0-element Array{Any,1}
┌ Info: micro_1(du, u, parms, time) defines functions
└   funcs = 0-element Array{Any,1}
┌ Info: micro_1(du, u, parms, time) defines variables
│   funcs =
│    4-element Array{Any,1}:
│     :((β, r, μ, K, α)) => :parms
│                    :dS => :(r * (1 - S / K) * S - β * S * I)
│                    :dI => :(β * S * I - (μ + α) * I)
└                    :du => :([dS, dI])
┌ Info: Making edges
└   scope = :ScalingModel
(var, val) = (:((β, r, μ, K, α)), :parms)
(var, val) = (:dS, :(r * (1 - S / K) * S - β * S * I))
(var, val) = (:dI, :(β * S * I - (μ + α) * I))
(var, val) = (:du, :([dS, dI]))
┌ Info: Making edges
└   scope = "ScalingModel.micro_1(du, u, parms, time)"
(var, val) = (:((β, r, μ, K, α)), :parms)
(var, val) = (:dS, :(r * (1 - S / K) * S - β * S * I))
(var, val) = (:dI, :(β * S * I - (μ + α) * I))
(var, val) = (:du, :([dS, dI]))
┌ Info: Edges found
└   path = "../examples/epicookbook/src/ScalingModel.jl"
[ Info: The input graph contains 0 unique vertices
┌ Info: The input edge list refers to 26 unique vertices.
└   nv = 26
┌ Info: The size of the intersection of these two sets is: 0.
└   nv = 0
┌ Info: src vertex ScalingModel was not in G, and has been inserted.
└   vname = "ScalingModel"
┌ Info: dst vertex (β, r, μ, K, α) was not in G, and has been inserted.
└   vname = "(β, r, μ, K, α)"
[ Info: Inserting directed edge of type destructure from ScalingModel to (β, r, μ, K, α).
┌ Info: dst vertex parms was not in G, and has been inserted.
└   vname = "parms"
[ Info: Inserting directed edge of type val from (β, r, μ, K, α) to parms.
┌ Info: dst vertex parms was not in G, and has been inserted.
└   vname = "parms"
[ Info: Inserting directed edge of type comp from ScalingModel to parms.
┌ Info: dst vertex β was not in G, and has been inserted.
└   vname = "β"
[ Info: Inserting directed edge of type var from parms to β.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :comp
│   weight = 2
│   type = :comp
│   src = "ScalingModel"
└   dst = "parms"
┌ Info: dst vertex r was not in G, and has been inserted.
└   vname = "r"
[ Info: Inserting directed edge of type var from parms to r.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :comp
│   weight = 3
│   type = :comp
│   src = "ScalingModel"
└   dst = "parms"
┌ Info: dst vertex μ was not in G, and has been inserted.
└   vname = "μ"
[ Info: Inserting directed edge of type var from parms to μ.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :comp
│   weight = 4
│   type = :comp
│   src = "ScalingModel"
└   dst = "parms"
┌ Info: dst vertex K was not in G, and has been inserted.
└   vname = "K"
[ Info: Inserting directed edge of type var from parms to K.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :comp
│   weight = 5
│   type = :comp
│   src = "ScalingModel"
└   dst = "parms"
┌ Info: dst vertex α was not in G, and has been inserted.
└   vname = "α"
[ Info: Inserting directed edge of type var from parms to α.
┌ Info: dst vertex dS was not in G, and has been inserted.
└   vname = "dS"
[ Info: Inserting directed edge of type output from ScalingModel to dS.
┌ Info: dst vertex r * (1 - S / K) * S - β * S * I was not in G, and has been inserted.
└   vname = "r * (1 - S / K) * S - β * S * I"
[ Info: Inserting directed edge of type val from dS to r * (1 - S / K) * S - β * S * I.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :output
│   weight = 2
│   type = :output
│   src = "ScalingModel"
└   dst = "dS"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "exp"
│   weight = 2
│   type = "exp"
│   src = "dS"
└   dst = "r * (1 - S / K) * S - β * S * I"
┌ Info: dst vertex - was not in G, and has been inserted.
└   vname = "-"
[ Info: Inserting directed edge of type input from ScalingModel to -.
┌ Info: dst vertex Symbol[Symbol("r * (1 - S / K) * S"), Symbol("β * S * I")] was not in G, and has been inserted.
└   vname = "Symbol[Symbol(\"r * (1 - S / K) * S\"), Symbol(\"β * S * I\")]"
[ Info: Inserting directed edge of type args from - to Symbol[Symbol("r * (1 - S / K) * S"), Symbol("β * S * I")].
┌ Info: dst vertex dI was not in G, and has been inserted.
└   vname = "dI"
[ Info: Inserting directed edge of type output from ScalingModel to dI.
┌ Info: dst vertex β * S * I - (μ + α) * I was not in G, and has been inserted.
└   vname = "β * S * I - (μ + α) * I"
[ Info: Inserting directed edge of type val from dI to β * S * I - (μ + α) * I.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :output
│   weight = 2
│   type = :output
│   src = "ScalingModel"
└   dst = "dI"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "exp"
│   weight = 2
│   type = "exp"
│   src = "dI"
└   dst = "β * S * I - (μ + α) * I"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :input
│   weight = 2
│   type = :input
│   src = "ScalingModel"
└   dst = "-"
┌ Info: dst vertex Symbol[Symbol("β * S * I"), Symbol("(μ + α) * I")] was not in G, and has been inserted.
└   vname = "Symbol[Symbol(\"β * S * I\"), Symbol(\"(μ + α) * I\")]"
[ Info: Inserting directed edge of type args from - to Symbol[Symbol("β * S * I"), Symbol("(μ + α) * I")].
┌ Info: dst vertex du was not in G, and has been inserted.
└   vname = "du"
[ Info: Inserting directed edge of type takes from ScalingModel to du.
┌ Info: dst vertex [dS, dI] was not in G, and has been inserted.
└   vname = "[dS, dI]"
[ Info: Inserting directed edge of type val from du to [dS, dI].
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :has
│   weight = 2
│   type = :has
│   src = "ScalingModel"
└   dst = "du"
┌ Info: dst vertex collection was not in G, and has been inserted.
└   vname = "collection"
[ Info: Inserting directed edge of type property from du to collection.
┌ Info: src vertex ScalingModel.micro_1(du, u, parms, time) was not in G, and has been inserted.
└   vname = "ScalingModel.micro_1(du, u, parms, time)"
[ Info: Inserting directed edge of type destructure from ScalingModel.micro_1(du, u, parms, time) to (β, r, μ, K, α).
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "val"
│   weight = 2
│   type = "val"
│   src = "(β, r, μ, K, α)"
└   dst = "parms"
[ Info: Inserting directed edge of type comp from ScalingModel.micro_1(du, u, parms, time) to parms.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "var"
│   weight = 2
│   type = "var"
│   src = "parms"
└   dst = "β"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :comp
│   weight = 2
│   type = :comp
│   src = "ScalingModel.micro_1(du, u, parms, time)"
└   dst = "parms"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "var"
│   weight = 2
│   type = "var"
│   src = "parms"
└   dst = "r"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :comp
│   weight = 3
│   type = :comp
│   src = "ScalingModel.micro_1(du, u, parms, time)"
└   dst = "parms"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "var"
│   weight = 2
│   type = "var"
│   src = "parms"
└   dst = "μ"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :comp
│   weight = 4
│   type = :comp
│   src = "ScalingModel.micro_1(du, u, parms, time)"
└   dst = "parms"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "var"
│   weight = 2
│   type = "var"
│   src = "parms"
└   dst = "K"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :comp
│   weight = 5
│   type = :comp
│   src = "ScalingModel.micro_1(du, u, parms, time)"
└   dst = "parms"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "var"
│   weight = 2
│   type = "var"
│   src = "parms"
└   dst = "α"
[ Info: Inserting directed edge of type output from ScalingModel.micro_1(du, u, parms, time) to dS.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "val"
│   weight = 3
│   type = "val"
│   src = "dS"
└   dst = "r * (1 - S / K) * S - β * S * I"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :output
│   weight = 2
│   type = :output
│   src = "ScalingModel.micro_1(du, u, parms, time)"
└   dst = "dS"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "exp"
│   weight = 4
│   type = "exp"
│   src = "dS"
└   dst = "r * (1 - S / K) * S - β * S * I"
[ Info: Inserting directed edge of type input from ScalingModel.micro_1(du, u, parms, time) to -.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "args"
│   weight = 2
│   type = "args"
│   src = "-"
└   dst = "Symbol[Symbol(\"r * (1 - S / K) * S\"), Symbol(\"β * S * I\")]"
[ Info: Inserting directed edge of type output from ScalingModel.micro_1(du, u, parms, time) to dI.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "val"
│   weight = 3
│   type = "val"
│   src = "dI"
└   dst = "β * S * I - (μ + α) * I"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :output
│   weight = 2
│   type = :output
│   src = "ScalingModel.micro_1(du, u, parms, time)"
└   dst = "dI"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "exp"
│   weight = 4
│   type = "exp"
│   src = "dI"
└   dst = "β * S * I - (μ + α) * I"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :input
│   weight = 2
│   type = :input
│   src = "ScalingModel.micro_1(du, u, parms, time)"
└   dst = "-"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "args"
│   weight = 2
│   type = "args"
│   src = "-"
└   dst = "Symbol[Symbol(\"β * S * I\"), Symbol(\"(μ + α) * I\")]"
[ Info: Inserting directed edge of type takes from ScalingModel.micro_1(du, u, parms, time) to du.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "val"
│   weight = 2
│   type = "val"
│   src = "du"
└   dst = "[dS, dI]"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :has
│   weight = 2
│   type = :has
│   src = "ScalingModel.micro_1(du, u, parms, time)"
└   dst = "du"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "property"
│   weight = 2
│   type = "property"
│   src = "du"
└   dst = "collection"
┌ Info: Returning graph G
│   nedges = 24
└   cardinality = 20
┌ Info: Code graph 1 has v vertices and e edges.
│   v = 20
└   e = 24
┌ Info: Parsing julia script
└   file = "../examples/epicookbook/src/SEIRmodel.jl"
s = "# -*- coding: utf-8 -*-\n# ---\n# jupyter:\n#   jupytext:\n#     text_representation:\n#       extension: .jl\n#       format_name: light\n#       format_version: '1.3'\n#       jupytext_version: 0.8.6\n#   kernelspec:\n#     display_name: Julia 1.0.3\n#     language: julia\n#     name: julia-1.0\n# ---\n\nmodule SEIRmodel\nusing DifferentialEquations\n\n#Susceptible-exposed-infected-recovered model function\nfunction seir_ode(dY,Y,p,t)\n    #Infected per-Capita Rate\n    β = p[1]\n    #Incubation Rate\n    σ = p[2]\n    #Recover per-capita rate\n    γ = p[3]\n    #Death Rate\n    μ = p[4]\n\n    #Susceptible Individual\n    S = Y[1]\n    #Exposed Individual\n    E = Y[2]\n    #Infected Individual\n    I = Y[3]\n    #Recovered Individual\n    #R = Y[4]\n\n    dY[1] = μ-β*S*I-μ*S\n    dY[2] = β*S*I-(σ+μ)*E\n    dY[3] = σ*E - (γ+μ)*I\nend\n\n#Pram (Infected Rate, Incubation Rate, Recover Rate, Death Rate)\npram=[520/365,1/60,1/30,774835/(65640000*365)]\n#Initialize Param(Susceptible Individuals, Exposed Individuals, Infected Individuals)\ninit=[0.8,0.1,0.1]\ntspan=(0.0,365.0)\n\nseir_prob = ODEProblem(seir_ode,init,tspan,pram)\n\nsol=solve(seir_prob);\n\nusing Plots\n\nva = VectorOfArray(sol.u)\ny = convert(Array,va)\nR = ones(size(sol.t))' - sum(y,dims=1);\n\nplot(sol.t,[y',R'],xlabel=\"Time\",ylabel=\"Proportion\")\n\n\n\nend\n"
[ Info: unknown expr type for metacollector
expr = :(function seir_ode(dY, Y, p, t)
      #= none:22 =#
      β = p[1]
      #= none:24 =#
      σ = p[2]
      #= none:26 =#
      γ = p[3]
      #= none:28 =#
      μ = p[4]
      #= none:31 =#
      S = Y[1]
      #= none:33 =#
      E = Y[2]
      #= none:35 =#
      I = Y[3]
      #= none:39 =#
      dY[1] = (μ - β * S * I) - μ * S
      #= none:40 =#
      dY[2] = β * S * I - (σ + μ) * E
      #= none:41 =#
      dY[3] = σ * E - (γ + μ) * I
  end)
[ Info: unknown expr type for metacollector
expr = :(plot(sol.t, [y', R'], xlabel="Time", ylabel="Proportion"))
┌ Info: script uses modules
│   modules =
│    2-element Array{Any,1}:
│     Any[:DifferentialEquations]
└     Any[:Plots]
┌ Info: script defines functions
│   funcs =
│    1-element Array{Any,1}:
│     :(seir_ode(dY, Y, p, t)) => quote
│        #= none:22 =#
│        β = p[1]
│        #= none:24 =#
│        σ = p[2]
│        #= none:26 =#
│        γ = p[3]
│        #= none:28 =#
│        μ = p[4]
│        #= none:31 =#
│        S = Y[1]
│        #= none:33 =#
│        E = Y[2]
│        #= none:35 =#
│        I = Y[3]
│        #= none:39 =#
│        dY[1] = (μ - β * S * I) - μ * S
│        #= none:40 =#
│        dY[2] = β * S * I - (σ + μ) * E
│        #= none:41 =#
│        dY[3] = σ * E - (γ + μ) * I
└    end
┌ Info: script defines glvariables
│   funcs =
│    8-element Array{Any,1}:
│          :pram => :([520 / 365, 1 / 60, 1 / 30, 774835 / (65640000 * 365)])
│          :init => :([0.8, 0.1, 0.1])
│         :tspan => :((0.0, 365.0))
│     :seir_prob => :(ODEProblem(seir_ode, init, tspan, pram))
│           :sol => :(solve(seir_prob))
│            :va => :(VectorOfArray(sol.u))
│             :y => :(convert(Array, va))
└             :R => :((ones(size(sol.t)))' - sum(y, dims=1))
funcdefs = Any[:(seir_ode(dY, Y, p, t))=>quote
    #= none:22 =#
    β = p[1]
    #= none:24 =#
    σ = p[2]
    #= none:26 =#
    γ = p[3]
    #= none:28 =#
    μ = p[4]
    #= none:31 =#
    S = Y[1]
    #= none:33 =#
    E = Y[2]
    #= none:35 =#
    I = Y[3]
    #= none:39 =#
    dY[1] = (μ - β * S * I) - μ * S
    #= none:40 =#
    dY[2] = β * S * I - (σ + μ) * E
    #= none:41 =#
    dY[3] = σ * E - (γ + μ) * I
end]
┌ Info: local scope definitions
│   subdefs =
│    1-element Array{Any,1}:
└     :(seir_ode(dY, Y, p, t)) => MetaCollector{FuncCollector{Array{Any,1}},Array{Any,1},Array{Any,1},Array{Any,1}}(Any[:(β = p[1]), :(σ = p[2]), :(γ = p[3]), :(μ = p[4]), :(S = Y[1]), :(E = Y[2]), :(I = Y[3]), :(dY[1] = (μ - β * S * I) - μ * S), :(dY[2] = β * S * I - (σ + μ) * E), :(dY[3] = σ * E - (γ + μ) * I)], FuncCollector{Array{Any,1}}(Any[]), Any[:β=>:(p[1]), :σ=>:(p[2]), :γ=>:(p[3]), :μ=>:(p[4]), :S=>:(Y[1]), :E=>:(Y[2]), :I=>:(Y[3]), :(dY[1])=>:((μ - β * S * I) - μ * S), :(dY[2])=>:(β * S * I - (σ + μ) * E), :(dY[3])=>:(σ * E - (γ + μ) * I)], Any[])
┌ Info: seir_ode(dY, Y, p, t) uses modules
└   modules = 0-element Array{Any,1}
┌ Info: seir_ode(dY, Y, p, t) defines functions
└   funcs = 0-element Array{Any,1}
┌ Info: seir_ode(dY, Y, p, t) defines variables
│   funcs =
│    10-element Array{Any,1}:
│           :β => :(p[1])
│           :σ => :(p[2])
│           :γ => :(p[3])
│           :μ => :(p[4])
│           :S => :(Y[1])
│           :E => :(Y[2])
│           :I => :(Y[3])
│     :(dY[1]) => :((μ - β * S * I) - μ * S)
│     :(dY[2]) => :(β * S * I - (σ + μ) * E)
└     :(dY[3]) => :(σ * E - (γ + μ) * I)
┌ Info: Making edges
└   scope = :SEIRmodel
(var, val) = (:β, :(p[1]))
(var, val) = (:σ, :(p[2]))
(var, val) = (:γ, :(p[3]))
(var, val) = (:μ, :(p[4]))
(var, val) = (:S, :(Y[1]))
(var, val) = (:E, :(Y[2]))
(var, val) = (:I, :(Y[3]))
(var, val) = (:(dY[1]), :((μ - β * S * I) - μ * S))
(var, val) = (:(dY[2]), :(β * S * I - (σ + μ) * E))
(var, val) = (:(dY[3]), :(σ * E - (γ + μ) * I))
┌ Info: Making edges
└   scope = "SEIRmodel.seir_ode(dY, Y, p, t)"
(var, val) = (:β, :(p[1]))
(var, val) = (:σ, :(p[2]))
(var, val) = (:γ, :(p[3]))
(var, val) = (:μ, :(p[4]))
(var, val) = (:S, :(Y[1]))
(var, val) = (:E, :(Y[2]))
(var, val) = (:I, :(Y[3]))
(var, val) = (:(dY[1]), :((μ - β * S * I) - μ * S))
(var, val) = (:(dY[2]), :(β * S * I - (σ + μ) * E))
(var, val) = (:(dY[3]), :(σ * E - (γ + μ) * I))
┌ Info: Edges found
└   path = "../examples/epicookbook/src/SEIRmodel.jl"
[ Info: The input graph contains 20 unique vertices
┌ Info: The input edge list refers to 37 unique vertices.
└   nv = 37
┌ Info: The size of the intersection of these two sets is: 1.
└   nv = 1
┌ Info: src vertex SEIRmodel was not in G, and has been inserted.
└   vname = "SEIRmodel"
┌ Info: dst vertex β was not in G, and has been inserted.
└   vname = "β"
[ Info: Inserting directed edge of type takes from SEIRmodel to β.
┌ Info: dst vertex p[1] was not in G, and has been inserted.
└   vname = "p[1]"
[ Info: Inserting directed edge of type val from β to p[1].
┌ Info: dst vertex σ was not in G, and has been inserted.
└   vname = "σ"
[ Info: Inserting directed edge of type takes from SEIRmodel to σ.
┌ Info: dst vertex p[2] was not in G, and has been inserted.
└   vname = "p[2]"
[ Info: Inserting directed edge of type val from σ to p[2].
┌ Info: dst vertex γ was not in G, and has been inserted.
└   vname = "γ"
[ Info: Inserting directed edge of type takes from SEIRmodel to γ.
┌ Info: dst vertex p[3] was not in G, and has been inserted.
└   vname = "p[3]"
[ Info: Inserting directed edge of type val from γ to p[3].
┌ Info: dst vertex μ was not in G, and has been inserted.
└   vname = "μ"
[ Info: Inserting directed edge of type takes from SEIRmodel to μ.
┌ Info: dst vertex p[4] was not in G, and has been inserted.
└   vname = "p[4]"
[ Info: Inserting directed edge of type val from μ to p[4].
┌ Info: dst vertex S was not in G, and has been inserted.
└   vname = "S"
[ Info: Inserting directed edge of type takes from SEIRmodel to S.
┌ Info: dst vertex Y[1] was not in G, and has been inserted.
└   vname = "Y[1]"
[ Info: Inserting directed edge of type val from S to Y[1].
┌ Info: dst vertex E was not in G, and has been inserted.
└   vname = "E"
[ Info: Inserting directed edge of type takes from SEIRmodel to E.
┌ Info: dst vertex Y[2] was not in G, and has been inserted.
└   vname = "Y[2]"
[ Info: Inserting directed edge of type val from E to Y[2].
┌ Info: dst vertex I was not in G, and has been inserted.
└   vname = "I"
[ Info: Inserting directed edge of type takes from SEIRmodel to I.
┌ Info: dst vertex Y[3] was not in G, and has been inserted.
└   vname = "Y[3]"
[ Info: Inserting directed edge of type val from I to Y[3].
┌ Info: dst vertex dY[1] was not in G, and has been inserted.
└   vname = "dY[1]"
[ Info: Inserting directed edge of type output from SEIRmodel to dY[1].
┌ Info: dst vertex (μ - β * S * I) - μ * S was not in G, and has been inserted.
└   vname = "(μ - β * S * I) - μ * S"
[ Info: Inserting directed edge of type val from dY[1] to (μ - β * S * I) - μ * S.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :output
│   weight = 2
│   type = :output
│   src = "SEIRmodel"
└   dst = "dY[1]"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "exp"
│   weight = 2
│   type = "exp"
│   src = "dY[1]"
└   dst = "(μ - β * S * I) - μ * S"
[ Info: Inserting directed edge of type input from SEIRmodel to -.
┌ Info: dst vertex Symbol[Symbol("μ - β * S * I"), Symbol("μ * S")] was not in G, and has been inserted.
└   vname = "Symbol[Symbol(\"μ - β * S * I\"), Symbol(\"μ * S\")]"
[ Info: Inserting directed edge of type args from - to Symbol[Symbol("μ - β * S * I"), Symbol("μ * S")].
┌ Info: dst vertex dY[2] was not in G, and has been inserted.
└   vname = "dY[2]"
[ Info: Inserting directed edge of type output from SEIRmodel to dY[2].
┌ Info: dst vertex β * S * I - (σ + μ) * E was not in G, and has been inserted.
└   vname = "β * S * I - (σ + μ) * E"
[ Info: Inserting directed edge of type val from dY[2] to β * S * I - (σ + μ) * E.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :output
│   weight = 2
│   type = :output
│   src = "SEIRmodel"
└   dst = "dY[2]"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "exp"
│   weight = 2
│   type = "exp"
│   src = "dY[2]"
└   dst = "β * S * I - (σ + μ) * E"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :input
│   weight = 2
│   type = :input
│   src = "SEIRmodel"
└   dst = "-"
┌ Info: dst vertex Symbol[Symbol("β * S * I"), Symbol("(σ + μ) * E")] was not in G, and has been inserted.
└   vname = "Symbol[Symbol(\"β * S * I\"), Symbol(\"(σ + μ) * E\")]"
[ Info: Inserting directed edge of type args from - to Symbol[Symbol("β * S * I"), Symbol("(σ + μ) * E")].
┌ Info: dst vertex dY[3] was not in G, and has been inserted.
└   vname = "dY[3]"
[ Info: Inserting directed edge of type output from SEIRmodel to dY[3].
┌ Info: dst vertex σ * E - (γ + μ) * I was not in G, and has been inserted.
└   vname = "σ * E - (γ + μ) * I"
[ Info: Inserting directed edge of type val from dY[3] to σ * E - (γ + μ) * I.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :output
│   weight = 2
│   type = :output
│   src = "SEIRmodel"
└   dst = "dY[3]"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "exp"
│   weight = 2
│   type = "exp"
│   src = "dY[3]"
└   dst = "σ * E - (γ + μ) * I"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :input
│   weight = 3
│   type = :input
│   src = "SEIRmodel"
└   dst = "-"
┌ Info: dst vertex Symbol[Symbol("σ * E"), Symbol("(γ + μ) * I")] was not in G, and has been inserted.
└   vname = "Symbol[Symbol(\"σ * E\"), Symbol(\"(γ + μ) * I\")]"
[ Info: Inserting directed edge of type args from - to Symbol[Symbol("σ * E"), Symbol("(γ + μ) * I")].
┌ Info: src vertex SEIRmodel.seir_ode(dY, Y, p, t) was not in G, and has been inserted.
└   vname = "SEIRmodel.seir_ode(dY, Y, p, t)"
[ Info: Inserting directed edge of type takes from SEIRmodel.seir_ode(dY, Y, p, t) to β.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "val"
│   weight = 2
│   type = "val"
│   src = "β"
└   dst = "p[1]"
[ Info: Inserting directed edge of type takes from SEIRmodel.seir_ode(dY, Y, p, t) to σ.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "val"
│   weight = 2
│   type = "val"
│   src = "σ"
└   dst = "p[2]"
[ Info: Inserting directed edge of type takes from SEIRmodel.seir_ode(dY, Y, p, t) to γ.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "val"
│   weight = 2
│   type = "val"
│   src = "γ"
└   dst = "p[3]"
[ Info: Inserting directed edge of type takes from SEIRmodel.seir_ode(dY, Y, p, t) to μ.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "val"
│   weight = 2
│   type = "val"
│   src = "μ"
└   dst = "p[4]"
[ Info: Inserting directed edge of type takes from SEIRmodel.seir_ode(dY, Y, p, t) to S.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "val"
│   weight = 2
│   type = "val"
│   src = "S"
└   dst = "Y[1]"
[ Info: Inserting directed edge of type takes from SEIRmodel.seir_ode(dY, Y, p, t) to E.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "val"
│   weight = 2
│   type = "val"
│   src = "E"
└   dst = "Y[2]"
[ Info: Inserting directed edge of type takes from SEIRmodel.seir_ode(dY, Y, p, t) to I.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "val"
│   weight = 2
│   type = "val"
│   src = "I"
└   dst = "Y[3]"
[ Info: Inserting directed edge of type output from SEIRmodel.seir_ode(dY, Y, p, t) to dY[1].
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "val"
│   weight = 3
│   type = "val"
│   src = "dY[1]"
└   dst = "(μ - β * S * I) - μ * S"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :output
│   weight = 2
│   type = :output
│   src = "SEIRmodel.seir_ode(dY, Y, p, t)"
└   dst = "dY[1]"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "exp"
│   weight = 4
│   type = "exp"
│   src = "dY[1]"
└   dst = "(μ - β * S * I) - μ * S"
[ Info: Inserting directed edge of type input from SEIRmodel.seir_ode(dY, Y, p, t) to -.
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "args"
│   weight = 2
│   type = "args"
│   src = "-"
└   dst = "Symbol[Symbol(\"μ - β * S * I\"), Symbol(\"μ * S\")]"
[ Info: Inserting directed edge of type output from SEIRmodel.seir_ode(dY, Y, p, t) to dY[2].
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "val"
│   weight = 3
│   type = "val"
│   src = "dY[2]"
└   dst = "β * S * I - (σ + μ) * E"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :output
│   weight = 2
│   type = :output
│   src = "SEIRmodel.seir_ode(dY, Y, p, t)"
└   dst = "dY[2]"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "exp"
│   weight = 4
│   type = "exp"
│   src = "dY[2]"
└   dst = "β * S * I - (σ + μ) * E"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :input
│   weight = 2
│   type = :input
│   src = "SEIRmodel.seir_ode(dY, Y, p, t)"
└   dst = "-"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "args"
│   weight = 2
│   type = "args"
│   src = "-"
└   dst = "Symbol[Symbol(\"β * S * I\"), Symbol(\"(σ + μ) * E\")]"
[ Info: Inserting directed edge of type output from SEIRmodel.seir_ode(dY, Y, p, t) to dY[3].
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "val"
│   weight = 3
│   type = "val"
│   src = "dY[3]"
└   dst = "σ * E - (γ + μ) * I"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :output
│   weight = 2
│   type = :output
│   src = "SEIRmodel.seir_ode(dY, Y, p, t)"
└   dst = "dY[3]"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "exp"
│   weight = 4
│   type = "exp"
│   src = "dY[3]"
└   dst = "σ * E - (γ + μ) * I"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = :input
│   weight = 3
│   type = :input
│   src = "SEIRmodel.seir_ode(dY, Y, p, t)"
└   dst = "-"
┌ Info: Incrementing weight of existing directed edge
│   edge_type = "args"
│   weight = 2
│   type = "args"
│   src = "-"
└   dst = "Symbol[Symbol(\"σ * E\"), Symbol(\"(γ + μ) * I\")]"
┌ Info: Returning graph G
│   nedges = 59
└   cardinality = 45
┌ Info: Code graph 2 has v vertices and e edges.
│   v = 45
└   e = 59
[ Info: All markdown and code files have been parsed; writing final knowledge graph to dot file
Process(`dot -Tsvg -O ../examples/epicookbook/data/dot_file_ex1.dot`, ProcessExited(0))
```

The extraction code will generate a dot file diagram of the edges in the graph.

Due to the fact that code extraction is a heuristic, there is some cleaning of the knowledge 
graph required before it is ready for reasoning.


## Reasoning

Once the information is extracted from the documentation and code, we can visualize the
knowledge as a graph. Most edges of type `cooccur` are elided for clarity.

![Knowledge Graph from epicookbook](img/reasoning_sir.dot.svg)

This knowledge graph contains all the connections we need to combine components across
models. Once can view this combination as either a modification of one model by
substituting components of another model, or as the automatic generation of a metamodel by
synthesizing components from the knowledge graph into a single coherent model. Further
theoretical analysis of metamodeling and model modification as mathematical problems is
warranted to make these categories unambiguous and precisely defined.

Once we identify a subgraph of related components we can identify the graft point between
the two models. We look for a common variable that is used in two models, specifically in
a derivative calculation. We find the variable `S` which appears in `dS` and `dY` (as
`S=Y[1]` and `dY = derivative(Y)`). The knowledge that `dS, dY` are derivatives comes from
the background knowledge of modeling that comes from reading textbooks and general
scientific knowledge, while the fact that `S` and `Y[1]` both appear in an expression
`mu-beta*S*I - mu*S` comes from the specific documents and codebases under consideration
by the metamodeler.

![Knowledge Subgraph showing model modification](img/reasoning_sir_subgraph.dot.svg)

This subgraph must then extend out to capture all of the relevant information such as the
parameter sets encountered, the function calls that contain these variables and
expressions. We have found the *largest relevant subgraph* for some unspecified definition
of *relevance*. From this subgraph, a human modeler can easily instruct the SemanticModels
system on how to combine the `SEIRmodel` and `ScalingModel` programs into a single model
and generate a program to execute it.

## Generation

Once reasoning is complete the graft.jl program will run over the extracted knowledge graph,
and generate a new model. In this case we want to take the birth rate dynamics from the `ScalingModel`
and add them to the `SEIR` model to create an `SEIR+birth_rate` model.

Here is the code that does the grafting.
```julia
using Cassette
using DifferentialEquations
using SemanticModels.Parsers
using SemanticModels.Dubstep

# source of original problem
include("../examples/epicookbook/src/SEIRmodel.jl")

#the functions we want to modify
seir_ode = SEIRmodel.seir_ode

# source of the problem we want to take from
expr = parsefile("../examples/epicookbook/src/ScalingModel.jl")
```

Once you have identified the entry point to your model, you can identify pieces of another model that you want to graft
onto it. This piece of the other model might take significant preparation in order to be ready to fit onto the base
model. These transformations include changing variables, and other plumbing aspects. If you stick to taking whole
functions and not expressions, this prep work is reduced.

```julia
# Find the expression we want to graft
#vital dynamics S rate expression
vdsre = expr.args[3].args[5].args[2].args[4]
@show popgrowth = vdsre.args[2].args[2]
replacevar(expr, old, new) = begin
    dump(expr)
    expr.args[3].args[3].args[3] = new
    return expr
end
popgrowth = replacevar(popgrowth, :K,:N)

# generate the function newfunc
# this eval happens at the top level so should only happen once
newfunc = eval(:(fpopgrowth(r,S,N) = $popgrowth))

# This is the new problem
# notice the signature doesn't even match, we have added a new parameter
function fprime(dY,Y,p,t, ϵ)
    #Infected per-Capita Rate
    β = p[1]
    #Incubation Rate
    σ = p[2]
    #Recover per-capita rate
    γ = p[3]
    #Death Rate
    μ = p[4]

    #Susceptible Individual
    S = Y[1]
    #Exposed Individual
    E = Y[2]
    #Infected Individual
    I = Y[3]
    #Recovered Individual
    #R = Y[4]

    # here is the graft point
    dY[1] = μ-β*S*I-μ*S + newfunc(ϵ, S, S+E+I)
    dY[2] = β*S*I-(σ+μ)*E
    dY[3] = σ*E - (γ+μ)*I
end
```

Define the overdub behavior, all the fucntions needed to be defined at this point
using run time values slows down overdub.

```julia
function Cassette.overdub(ctx::Dubstep.GraftCtx, f::typeof(seir_ode), args...)
    # this call matches the new signature
    return Cassette.fallback(ctx, fprime, args..., ctx.metadata[:lambda])
end
```

The last step is to run the new model!

```julia
#set up our modeling configuration
function g()
    #Pram (Infected Rate, Incubation Rate, Recover Rate, Death Rate)
    pram=[520/365,1/60,1/30,774835/(65640000*365)]
    #Initialize Param(Susceptible Individuals, Exposed Individuals, Infected Individuals)
    init=[0.8,0.1,0.1]
    tspan=(0.0,365.0)

    seir_prob = ODEProblem(seir_ode,init,tspan,pram)

    sol=solve(seir_prob);
end

# sweep over population growth rates
function scalegrowth(λ=1.0)
    # ctx.metadata holds our new parameter
    ctx = Dubstep.GraftCtx(metadata=Dict(:lambda=>λ))
    return Cassette.overdub(ctx, g)
end

println("S\tI\tR")
for λ in [1.0,1.1,1.2]
    @time S,I,R = scalegrowth(λ)(365)
    println("$S\t$I\t$R")
end
#it works!
```

```julia
julia> include("graft.jl")
s = "# -*- coding: utf-8 -*-\n# ---\n# jupyter:\n#   jupytext:\n#     text_representation:\n#       extension: .jl\n#       format_name: light\n#       format_version: '1.3'\n#       jupytext_version: 0.8.6\n#   kernelspec:\n#     display_name: Julia 1.0.3\n#     language: julia\n#     name: julia-1.0\n# ---\n\nmodule ScalingModel\nusing DifferentialEquations\n\nfunction micro_1(du, u, parms, time)\n    # PARAMETER DEFS\n    # β transmition rate\n    # r net population growth rate\n    # μ hosts' natural mortality rate\n    # Κ population size\n    # α disease induced mortality rate\n\n    β, r, μ, K, α = parms\n    dS = r*(1-S/K)*S - β*S*I\n    dI = β*S*I-(μ+α)*I\n    du = [dS,dI]\nend\n\n# +\n# PARAMETER DEFS\n# w and m are used to define the other parameters allometrically\n\nw = 1;\nm = 10;\nβ = 0.0247*m*w^0.44;\nr = 0.6*w^-0.27;\nμ = 0.4*w^-0.26;\nK = 16.2*w^-0.7;\nα = (m-1)*μ;\n# -\n\nparms = [β,r,μ,K,α];\ninit = [K,1.];\ntspan = (0.0,10.0);\n\nsir_prob = ODEProblem(micro_1,init,tspan,parms)\n\nsir_sol = solve(sir_prob);\n\nusing Plots\n\nplot(sir_sol,xlabel=\"Time\",ylabel=\"Number\")\n\nm = [5,10,20,40]\nws = 10 .^collect(range(-3,length = 601,3))\nβs = zeros(601,4)\nfor i = 1:4\n    βs[:,i] = 0.0247*m[i]*ws.^0.44\nend\nplot(ws,βs,xlabel=\"Weight\",ylabel=\"\\\\beta_min\", xscale=:log10,yscale=:log10, label=[\"m = 5\" \"m = 10\" \"m = 20\" \"m = 40\"],lw=3)\n\nend\n"
popgrowth = (vdsre.args[2]).args[2] = :(r * (1 - S / K) * S)
Expr
  head: Symbol call
  args: Array{Any}((4,))
    1: Symbol *
    2: Symbol r
    3: Expr
      head: Symbol call
      args: Array{Any}((3,))
        1: Symbol -
        2: Int64 1
        3: Expr
          head: Symbol call
          args: Array{Any}((3,))
            1: Symbol /
            2: Symbol S
            3: Symbol K
    4: Symbol S
S	I	R
 67.554431 seconds (125.80 M allocations: 6.555 GiB, 7.52% gc time)
4.139701895048853e-5	1.512940651164174	1.2314284234326383
  4.132043 seconds (1.85 M allocations: 33.602 MiB, 0.37% gc time)
3.319429471438334e-5	1.7926581454821442	1.4394890708586585
  4.294201 seconds (1.99 M allocations: 36.084 MiB, 0.54% gc time)
2.7307348723966148e-5	2.096234030610046	1.6601782657100044
```

|                     S |                  I |                  R |
|-----------------------|--------------------|--------------------|
|  4.139701895048853e-5 |  1.512940651164174 | 1.2314284234326383 |
|  3.319429471438334e-5 | 1.7926581454821442 | 1.4394890708586585 |
| 2.7307348723966148e-5 |  2.096234030610046 | 1.6601782657100044 |

We can see from the model output that as the birth rate of the population increases,
the size of the SEIR epidemic increases. This example illustrates how we can add capabilities 
to models in a way that can augment the ability of scientists to conduct *in silico* experiments.
This augmentation will ultimately enable a faster development of scientific ideas informed by data
and simulation.

Hopefully, this example has shown you the goals and scope of this software, the remaining documentation details the
various components essential to the creation of this demonstration.
