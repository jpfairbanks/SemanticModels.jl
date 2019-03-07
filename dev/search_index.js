var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "SemanticModels.jl",
    "title": "SemanticModels.jl",
    "category": "page",
    "text": ""
},

{
    "location": "#SemanticModels.jl-Documentation-1",
    "page": "SemanticModels.jl",
    "title": "SemanticModels.jl Documentation",
    "category": "section",
    "text": "CurrentModule = SemanticModelsSemanticModels is a system for representing scientific knowledge inherent to scientific model structure. Our philosophy is that over the next few decades, the adoption of computation as a first class pillar of scientific thought will be complete, and scientists will do a majority of their thinking about and communicating of ideas in the form of writing and using code. Attempts to teach machines science based on reading texts intended for human consumption is overwhelming, so we use text written for computers as a starting point. This involves extracting meaning from code,  and reconciling such information with exogenous sources of information about the world.Scientists typically write procedural code based on libraries for solving mathematical models. When this procedural code is expressed in data-oriented pipelines or workflows, such workflows have limited composability. The most mature scientific field in terms of data-oriented workflows is bioinformatics, where practicing informaticists spend a great deal of time plumbing together procedural scripts and adapting data formats. Automatic adaptation of modeling codes requires a semantic understanding of the model that the code implements/computes. SemanticModels.jl is intended to augment  scientists\' modeling capabilities by extracting semantic information and facilitating different types of model  manipulation and generation.We focus on three problems:Model modification: taking an existing model and modifying its components to add features or make comparisons.\nMetamodel construction: combining models or components of models to automatically generate scientific computing workflows.\nModel Verification: given a model, corpus of previous applications of that model, and an input to the model, detect if the model is properly functioning.SemanticModels leverages technology from program analysis and natural language processing in order to build a knowledge graph representing the connections between elements of code (variables, values, functions, and expressions) and elements of scientific understanding (concepts, terms, relations). This knowledge graph supports reasoning about how to modify models, construct metamodels, and verify models.The most mature aspects of the library at this point are Knowledge Extraction and modification (Dubstep)."
},

{
    "location": "#Table-of-Contents-1",
    "page": "SemanticModels.jl",
    "title": "Table of Contents",
    "category": "section",
    "text": "Pages = [\n     \"index.md\",\n     \"usecases.md\",\n     \"news.md\",\n     \"example.md\",\n     \"dubstep.md\",\n     \"graph.md\",\n     \"extraction.md\",\n     \"validation.md\",\n     \"library.md\",\n     \"theory.md\",\n     \"approach.md\",\n     \"slides.md\",\n     \"FluModel.md\",\n     \"contributing.md\"]\nDepth = 3This material is based upon work supported by the Defense Advanced Research Projects Agency (DARPA) under Agreement No. HR00111990008."
},

{
    "location": "usecases/#",
    "page": "Intended Use Cases",
    "title": "Intended Use Cases",
    "category": "page",
    "text": ""
},

{
    "location": "usecases/#Intended-Use-Cases-1",
    "page": "Intended Use Cases",
    "title": "Intended Use Cases",
    "category": "section",
    "text": "Here are some use cases for SemanticModels.jlScientific knowledge is richer than the ability to make predictions given data. Knowledge and understanding provide the ability to reason about novel scenarios.  A crucial aspect of acquiring knowledge is asking questions about the world and answering those questions with models.Suppose the model is  dudt = f_p(ut) where u is the observable, dudt is the derivative, f is a function, t is the time variable, and p is a parameter. Scientific knowledge involves asking and answering questions about the model. For example:How does u depend on p?\nHow does u depend on f?\nHow does u depend on the implementation of f?"
},

{
    "location": "usecases/#Counterfactuals-1",
    "page": "Intended Use Cases",
    "title": "Counterfactuals",
    "category": "section",
    "text": "Scientists often want to run counterfactuals through a model. they have questions like: What if the parameters were different?\nWhat if the functional form of this equation was different?\nWhat if the implementation of this function was different?The \"how\" questions can be answered by running counterfactuals of the model. In order to run counterfactuals we need to modify the code.  The current approach is for scientists to modify code writen by other scientists. This takes a long time and requires models to be converted from the modeling level to the code level,  then someone else reads the code and converts it back to the modeling level.If we could automate these transformations, we could enable scientists to spend more time  thinking about the science and less time working with code. "
},

{
    "location": "usecases/#Model-Code-Transformations-1",
    "page": "Intended Use Cases",
    "title": "Model-Code Transformations",
    "category": "section",
    "text": "There are many places we could modify code in order to give it new features for modeling.Source Code, changing the source files on disk before they are parsed\nExpressions, after parsing, we could use macros or Meta.parse to get Exprs and make new ones to eval\nType System, using multiple dispatch with new types to get new behavior\nOverdubbing, Cassette.jl lets you change the definitions of functions with overdub\nContextual Tags, Cassette provides a tagging mechanism attach metadata to values\nCompiler Pass, Cassette lets you implement your own compiler passesDifferent code modifications will be easier at different levels of this toolchain."
},

{
    "location": "usecases/#Use-Cases-1",
    "page": "Intended Use Cases",
    "title": "Use Cases",
    "category": "section",
    "text": "Answering counterfactuals\nInstrumenting code to extract additional insight\nSemantic Model Validation"
},

{
    "location": "usecases/#Answering-Counterfactuals-1",
    "page": "Intended Use Cases",
    "title": "Answering Counterfactuals",
    "category": "section",
    "text": "Scientists want to change 1) parameters, 2) assumptions, 3) functions, orimplementations in order to determine their effects on the output of the model.Note: a paramter is an argument to the model and is intended (by the simulation author) to be changed by users. An assumption is a value in the code that could be changed, but is not exposed to the API.While making accurate predictions of measurable phenomena is a necessary condition of a scientific knowledge it is not sufficient. Scientists have knowledge that allows them to reason about novel scenarios and they do this by speculating about counterfactuals. Thus answering counterfactuals about model codes form a foundational capability of our system."
},

{
    "location": "usecases/#Instrumenting-Model-Code-1",
    "page": "Intended Use Cases",
    "title": "Instrumenting Model Code",
    "category": "section",
    "text": "In order to get additional insight out of models, we want to add instrumentation into the bodies of the functions. These instrumented values will be useful for many purposes. The simplest use is to add instrumentation of additional measurements. Scientists write code for a specific purposes and do not take the time to report all possible measurements or statistics in their code. A second scientist who is trying to repurpose that software will often need to compute different values from the internal state of the algorithm in order to understand their phenomenon of interest.A simple example is a model that simulates Lotka-Volterra population dynamics and reports the average time between local maxima of predator populations. A second scientist might want to also characterize the variance or median of the time between local maxima."
},

{
    "location": "usecases/#Semantic-Model-Validation-1",
    "page": "Intended Use Cases",
    "title": "Semantic Model Validation",
    "category": "section",
    "text": "One could trace the value of variables as the code  is run in order to build up a distribution of normal values that variable takes. This could be used to learn implied invariants in the code. Then when running the model in a new context, you could compare the instrumentation values to these invariants to validate if the model is working as intended in this new context.One of the main benefits of mechanistic modeling over statistical modeling is the generalization of mechanistic models to novel scenarios. It is difficult to determine when a model is being applied in a novel scenario where we can trust the output and a novel scenario that is beyond the bounds of the model\'s capability. By analyzing the values of the internal variables in the algorithms, we can determine whether a component of the model is operating outside of the region of inputs where it can be trusted.An example of this validation could be constructed by taking a model that uses a polynomial approximation to compute a function f(x). If this polynomial approximation has small error on a region of the input space, R then whenever x is in R, we can trust the model. But if we every run the model and evaluate the approximation on an x outside of this region, we do not know if the approximation is close, and cannot trust the model. Program analysis can help scientists to identify reasons to be sceptical of model validity."
},

{
    "location": "news/#",
    "page": "News",
    "title": "News",
    "category": "page",
    "text": ""
},

{
    "location": "news/#News-1",
    "page": "News",
    "title": "News",
    "category": "section",
    "text": ""
},

{
    "location": "news/#Release-v0.1-1",
    "page": "News",
    "title": "Release v0.1",
    "category": "section",
    "text": "Release v0.1 includes an initial version of every step in the SemanticModels pipeline.  Users can now extract information, build knowledge graphs, and generate new models.The following is a summary of the most important new features and updates:New submodules\nDubstep\nSemanticModels.Dubstep.TraceCtx builds dynamic analysis traces of a model for information extraction.\nSemanticModels.Dubstep.LPCtx allows you to modify the norms used in a model.\nSemanticModels.Dubstep.GraftCtx allows grafting components of one model onto another.\nParsers\nParsers.parsefile reads in a julia source file as an expression.\nParsers.defs extracts  all of the code definitions from a module definition expression.\nParsers.edges extracts edges for the knowledge graph from code.\nGraphs\nA knowledge graph schema Knowledge Graphs.\nGraphs.insert_edges_from_jl builds a knowledge graph from extracted edges.\nExamples\ntest/transform/ode.jl shows how to perturb an ODE with overdub.\ntest/transform/varextract.jl shows how to use a compiler pass to extract dynamic analysis information.\nScripts\nbin/extract.jl extracts knowledge elements from parsed markdown and source code files.\nbin/graft.jl performs metamodeling by grafting a component of one model onto another.\nNew docs pages\nIntended Use Cases\nDubstep\nKnowledge Graphs\nKnowledge Extraction\nModel Validation with Dynamic Analysis\nSemantic Modeling Theory\nDeveloper Guidelines"
},

{
    "location": "news/#Release-v0.0.1-1",
    "page": "News",
    "title": "Release v0.0.1",
    "category": "section",
    "text": "Initial release with documentation and some examples designed to illustrate the inteded scope of the software."
},

{
    "location": "example/#",
    "page": "Example",
    "title": "Example",
    "category": "page",
    "text": ""
},

{
    "location": "example/#Getting-Started-Example-1",
    "page": "Example",
    "title": "Getting Started Example",
    "category": "section",
    "text": "The following example should help you understand the goals of this project. The goal of this example is to illustrate how you can ingest two scientific models and perform a metamodeling or model modification task on the using the SemanticModels system.Our two models are an SEIR model that has 4 subpopulations (SEIR) and a ScalingModel has 2 subpopulations (SI). The ScalingModel has a population growth parameter to approximate a changing population size. We want to graft the population growth component of the ScalingModel onto the SEIR model, to produce a new model with novel capabilities."
},

{
    "location": "example/#Extraction-1",
    "page": "Example",
    "title": "Extraction",
    "category": "section",
    "text": "The script bin/extract.jl can extract a knowledge graph from code and documentation.For example the SEIR model is described in the following Julia implementation.module SEIRmodel\nusing DifferentialEquations\n\n#Susceptible-exposed-infected-recovered model function\nfunction seir_ode(dY,Y,p,t)\n    #Infected per-Capita Rate\n    β = p[1]\n    #Incubation Rate\n    σ = p[2]\n    #Recover per-capita rate\n    γ = p[3]\n    #Death Rate\n    μ = p[4]\n\n    #Susceptible Individual\n    S = Y[1]\n    #Exposed Individual\n    E = Y[2]\n    #Infected Individual\n    I = Y[3]\n    #Recovered Individual\n    #R = Y[4]\n\n    dY[1] = μ-β*S*I-μ*S\n    dY[2] = β*S*I-(σ+μ)*E\n    dY[3] = σ*E - (γ+μ)*I\nend\n\n#Pram (Infected Rate, Incubation Rate, Recover Rate, Death Rate)\npram=[520/365,1/60,1/30,774835/(65640000*365)]\n#Initialize Param(Susceptible Individuals, Exposed Individuals, Infected Individuals)\ninit=[0.8,0.1,0.1]\ntspan=(0.0,365.0)\n\nseir_prob = ODEProblem(seir_ode,init,tspan,pram)\n\nsol=solve(seir_prob);\n\nusing Plots\n\nva = VectorOfArray(sol.u)\ny = convert(Array,va)\nR = ones(size(sol.t))\' - sum(y,dims=1);\n\nplot(sol.t,[y\',R\'],xlabel=\"Time\",ylabel=\"Proportion\")\nendWe can extract out a knowledge graph that covers this model along with an Scaling Model from examples/epicookbook/src/ScalingModel.jljulia> include(\"extract.jl\")\n┌ Info: Graph created from markdown has v vertices and e edges.\n│   v = 0\n└   e = 0\n┌ Info: Parsing julia script\n└   file = \"../examples/epicookbook/src/ScalingModel.jl\"\ns = \"# -*- coding: utf-8 -*-\\n# ---\\n# jupyter:\\n#   jupytext:\\n#     text_representation:\\n#       extension: .jl\\n#       format_name: light\\n#       format_version: \'1.3\'\\n#       jupytext_version: 0.8.6\\n#   kernelspec:\\n#     display_name: Julia 1.0.3\\n#     language: julia\\n#     name: julia-1.0\\n# ---\\n\\nmodule ScalingModel\\nusing DifferentialEquations\\n\\nfunction micro_1(du, u, parms, time)\\n    # PARAMETER DEFS\\n    # β transmition rate\\n    # r net population growth rate\\n    # μ hosts\' natural mortality rate\\n    # Κ population size\\n    # α disease induced mortality rate\\n\\n    β, r, μ, K, α = parms\\n    dS = r*(1-S/K)*S - β*S*I\\n    dI = β*S*I-(μ+α)*I\\n    du = [dS,dI]\\nend\\n\\n# +\\n# PARAMETER DEFS\\n# w and m are used to define the other parameters allometrically\\n\\nw = 1;\\nm = 10;\\nβ = 0.0247*m*w^0.44;\\nr = 0.6*w^-0.27;\\nμ = 0.4*w^-0.26;\\nK = 16.2*w^-0.7;\\nα = (m-1)*μ;\\n# -\\n\\nparms = [β,r,μ,K,α];\\ninit = [K,1.];\\ntspan = (0.0,10.0);\\n\\nsir_prob = ODEProblem(micro_1,init,tspan,parms)\\n\\nsir_sol = solve(sir_prob);\\n\\nusing Plots\\n\\nplot(sir_sol,xlabel=\\\"Time\\\",ylabel=\\\"Number\\\")\\n\\nm = [5,10,20,40]\\nws = 10 .^collect(range(-3,length = 601,3))\\nβs = zeros(601,4)\\nfor i = 1:4\\n    βs[:,i] = 0.0247*m[i]*ws.^0.44\\nend\\nplot(ws,βs,xlabel=\\\"Weight\\\",ylabel=\\\"\\\\\\\\beta_min\\\", xscale=:log10,yscale=:log10, label=[\\\"m = 5\\\" \\\"m = 10\\\" \\\"m = 20\\\" \\\"m = 40\\\"],lw=3)\\n\\nend\\n\"\n[ Info: unknown expr type for metacollector\nexpr = :(function micro_1(du, u, parms, time)\n      #= none:27 =#\n      (β, r, μ, K, α) = parms\n      #= none:28 =#\n      dS = r * (1 - S / K) * S - β * S * I\n      #= none:29 =#\n      dI = β * S * I - (μ + α) * I\n      #= none:30 =#\n      du = [dS, dI]\n  end)\n[ Info: unknown expr type for metacollector\nexpr = :(plot(sir_sol, xlabel=\"Time\", ylabel=\"Number\"))\n[ Info: unknown expr type for metacollector\nexpr = :(for i = 1:4\n      #= none:62 =#\n      βs[:, i] = 0.0247 * m[i] * ws .^ 0.44\n  end)\n[ Info: unknown expr type for metacollector\nexpr = :(plot(ws, βs, xlabel=\"Weight\", ylabel=\"\\\\beta_min\", xscale=:log10, yscale=:log10, label=[\"m = 5\" \"m = 10\" \"m = 20\" \"m = 40\"], lw=3))\n┌ Info: script uses modules\n│   modules =\n│    2-element Array{Any,1}:\n│     Any[:DifferentialEquations]\n└     Any[:Plots]\n┌ Info: script defines functions\n│   funcs =\n│    1-element Array{Any,1}:\n│     :(micro_1(du, u, parms, time)) => quote\n│        #= none:27 =#\n│        (β, r, μ, K, α) = parms\n│        #= none:28 =#\n│        dS = r * (1 - S / K) * S - β * S * I\n│        #= none:29 =#\n│        dI = β * S * I - (μ + α) * I\n│        #= none:30 =#\n│        du = [dS, dI]\n└    end\n┌ Info: script defines glvariables\n│   funcs =\n│    15-element Array{Any,1}:\n│            :w => 1\n│            :m => 10\n│            :β => :(0.0247 * m * w ^ 0.44)\n│            :r => :(0.6 * w ^ -0.27)\n│            :μ => :(0.4 * w ^ -0.26)\n│            :K => :(16.2 * w ^ -0.7)\n│            :α => :((m - 1) * μ)\n│        :parms => :([β, r, μ, K, α])\n│         :init => :([K, 1.0])\n│        :tspan => :((0.0, 10.0))\n│     :sir_prob => :(ODEProblem(micro_1, init, tspan, parms))\n│      :sir_sol => :(solve(sir_prob))\n│            :m => :([5, 10, 20, 40])\n│           :ws => :(10 .^ collect(range(-3, length=601, 3)))\n└           :βs => :(zeros(601, 4))\nfuncdefs = Any[:(micro_1(du, u, parms, time))=>quote\n    #= none:27 =#\n    (β, r, μ, K, α) = parms\n    #= none:28 =#\n    dS = r * (1 - S / K) * S - β * S * I\n    #= none:29 =#\n    dI = β * S * I - (μ + α) * I\n    #= none:30 =#\n    du = [dS, dI]\nend]\n┌ Info: local scope definitions\n│   subdefs =\n│    1-element Array{Any,1}:\n└     :(micro_1(du, u, parms, time)) => MetaCollector{FuncCollector{Array{Any,1}},Array{Any,1},Array{Any,1},Array{Any,1}}(Any[:((β, r, μ, K, α) = parms), :(dS = r * (1 - S / K) * S - β * S * I), :(dI = β * S * I - (μ + α) * I), :(du = [dS, dI])], FuncCollector{Array{Any,1}}(Any[]), Any[:((β, r, μ, K, α))=>:parms, :dS=>:(r * (1 - S / K) * S - β * S * I), :dI=>:(β * S * I - (μ + α) * I), :du=>:([dS, dI])], Any[])\n┌ Info: micro_1(du, u, parms, time) uses modules\n└   modules = 0-element Array{Any,1}\n┌ Info: micro_1(du, u, parms, time) defines functions\n└   funcs = 0-element Array{Any,1}\n┌ Info: micro_1(du, u, parms, time) defines variables\n│   funcs =\n│    4-element Array{Any,1}:\n│     :((β, r, μ, K, α)) => :parms\n│                    :dS => :(r * (1 - S / K) * S - β * S * I)\n│                    :dI => :(β * S * I - (μ + α) * I)\n└                    :du => :([dS, dI])\n┌ Info: Making edges\n└   scope = :ScalingModel\n(var, val) = (:((β, r, μ, K, α)), :parms)\n(var, val) = (:dS, :(r * (1 - S / K) * S - β * S * I))\n(var, val) = (:dI, :(β * S * I - (μ + α) * I))\n(var, val) = (:du, :([dS, dI]))\n┌ Info: Making edges\n└   scope = \"ScalingModel.micro_1(du, u, parms, time)\"\n(var, val) = (:((β, r, μ, K, α)), :parms)\n(var, val) = (:dS, :(r * (1 - S / K) * S - β * S * I))\n(var, val) = (:dI, :(β * S * I - (μ + α) * I))\n(var, val) = (:du, :([dS, dI]))\n┌ Info: Edges found\n└   path = \"../examples/epicookbook/src/ScalingModel.jl\"\n[ Info: The input graph contains 0 unique vertices\n┌ Info: The input edge list refers to 26 unique vertices.\n└   nv = 26\n┌ Info: The size of the intersection of these two sets is: 0.\n└   nv = 0\n┌ Info: src vertex ScalingModel was not in G, and has been inserted.\n└   vname = \"ScalingModel\"\n┌ Info: dst vertex (β, r, μ, K, α) was not in G, and has been inserted.\n└   vname = \"(β, r, μ, K, α)\"\n[ Info: Inserting directed edge of type destructure from ScalingModel to (β, r, μ, K, α).\n┌ Info: dst vertex parms was not in G, and has been inserted.\n└   vname = \"parms\"\n[ Info: Inserting directed edge of type val from (β, r, μ, K, α) to parms.\n┌ Info: dst vertex parms was not in G, and has been inserted.\n└   vname = \"parms\"\n[ Info: Inserting directed edge of type comp from ScalingModel to parms.\n┌ Info: dst vertex β was not in G, and has been inserted.\n└   vname = \"β\"\n[ Info: Inserting directed edge of type var from parms to β.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :comp\n│   weight = 2\n│   type = :comp\n│   src = \"ScalingModel\"\n└   dst = \"parms\"\n┌ Info: dst vertex r was not in G, and has been inserted.\n└   vname = \"r\"\n[ Info: Inserting directed edge of type var from parms to r.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :comp\n│   weight = 3\n│   type = :comp\n│   src = \"ScalingModel\"\n└   dst = \"parms\"\n┌ Info: dst vertex μ was not in G, and has been inserted.\n└   vname = \"μ\"\n[ Info: Inserting directed edge of type var from parms to μ.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :comp\n│   weight = 4\n│   type = :comp\n│   src = \"ScalingModel\"\n└   dst = \"parms\"\n┌ Info: dst vertex K was not in G, and has been inserted.\n└   vname = \"K\"\n[ Info: Inserting directed edge of type var from parms to K.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :comp\n│   weight = 5\n│   type = :comp\n│   src = \"ScalingModel\"\n└   dst = \"parms\"\n┌ Info: dst vertex α was not in G, and has been inserted.\n└   vname = \"α\"\n[ Info: Inserting directed edge of type var from parms to α.\n┌ Info: dst vertex dS was not in G, and has been inserted.\n└   vname = \"dS\"\n[ Info: Inserting directed edge of type output from ScalingModel to dS.\n┌ Info: dst vertex r * (1 - S / K) * S - β * S * I was not in G, and has been inserted.\n└   vname = \"r * (1 - S / K) * S - β * S * I\"\n[ Info: Inserting directed edge of type val from dS to r * (1 - S / K) * S - β * S * I.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :output\n│   weight = 2\n│   type = :output\n│   src = \"ScalingModel\"\n└   dst = \"dS\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"exp\"\n│   weight = 2\n│   type = \"exp\"\n│   src = \"dS\"\n└   dst = \"r * (1 - S / K) * S - β * S * I\"\n┌ Info: dst vertex - was not in G, and has been inserted.\n└   vname = \"-\"\n[ Info: Inserting directed edge of type input from ScalingModel to -.\n┌ Info: dst vertex Symbol[Symbol(\"r * (1 - S / K) * S\"), Symbol(\"β * S * I\")] was not in G, and has been inserted.\n└   vname = \"Symbol[Symbol(\\\"r * (1 - S / K) * S\\\"), Symbol(\\\"β * S * I\\\")]\"\n[ Info: Inserting directed edge of type args from - to Symbol[Symbol(\"r * (1 - S / K) * S\"), Symbol(\"β * S * I\")].\n┌ Info: dst vertex dI was not in G, and has been inserted.\n└   vname = \"dI\"\n[ Info: Inserting directed edge of type output from ScalingModel to dI.\n┌ Info: dst vertex β * S * I - (μ + α) * I was not in G, and has been inserted.\n└   vname = \"β * S * I - (μ + α) * I\"\n[ Info: Inserting directed edge of type val from dI to β * S * I - (μ + α) * I.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :output\n│   weight = 2\n│   type = :output\n│   src = \"ScalingModel\"\n└   dst = \"dI\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"exp\"\n│   weight = 2\n│   type = \"exp\"\n│   src = \"dI\"\n└   dst = \"β * S * I - (μ + α) * I\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :input\n│   weight = 2\n│   type = :input\n│   src = \"ScalingModel\"\n└   dst = \"-\"\n┌ Info: dst vertex Symbol[Symbol(\"β * S * I\"), Symbol(\"(μ + α) * I\")] was not in G, and has been inserted.\n└   vname = \"Symbol[Symbol(\\\"β * S * I\\\"), Symbol(\\\"(μ + α) * I\\\")]\"\n[ Info: Inserting directed edge of type args from - to Symbol[Symbol(\"β * S * I\"), Symbol(\"(μ + α) * I\")].\n┌ Info: dst vertex du was not in G, and has been inserted.\n└   vname = \"du\"\n[ Info: Inserting directed edge of type takes from ScalingModel to du.\n┌ Info: dst vertex [dS, dI] was not in G, and has been inserted.\n└   vname = \"[dS, dI]\"\n[ Info: Inserting directed edge of type val from du to [dS, dI].\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :has\n│   weight = 2\n│   type = :has\n│   src = \"ScalingModel\"\n└   dst = \"du\"\n┌ Info: dst vertex collection was not in G, and has been inserted.\n└   vname = \"collection\"\n[ Info: Inserting directed edge of type property from du to collection.\n┌ Info: src vertex ScalingModel.micro_1(du, u, parms, time) was not in G, and has been inserted.\n└   vname = \"ScalingModel.micro_1(du, u, parms, time)\"\n[ Info: Inserting directed edge of type destructure from ScalingModel.micro_1(du, u, parms, time) to (β, r, μ, K, α).\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"val\"\n│   weight = 2\n│   type = \"val\"\n│   src = \"(β, r, μ, K, α)\"\n└   dst = \"parms\"\n[ Info: Inserting directed edge of type comp from ScalingModel.micro_1(du, u, parms, time) to parms.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"var\"\n│   weight = 2\n│   type = \"var\"\n│   src = \"parms\"\n└   dst = \"β\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :comp\n│   weight = 2\n│   type = :comp\n│   src = \"ScalingModel.micro_1(du, u, parms, time)\"\n└   dst = \"parms\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"var\"\n│   weight = 2\n│   type = \"var\"\n│   src = \"parms\"\n└   dst = \"r\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :comp\n│   weight = 3\n│   type = :comp\n│   src = \"ScalingModel.micro_1(du, u, parms, time)\"\n└   dst = \"parms\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"var\"\n│   weight = 2\n│   type = \"var\"\n│   src = \"parms\"\n└   dst = \"μ\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :comp\n│   weight = 4\n│   type = :comp\n│   src = \"ScalingModel.micro_1(du, u, parms, time)\"\n└   dst = \"parms\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"var\"\n│   weight = 2\n│   type = \"var\"\n│   src = \"parms\"\n└   dst = \"K\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :comp\n│   weight = 5\n│   type = :comp\n│   src = \"ScalingModel.micro_1(du, u, parms, time)\"\n└   dst = \"parms\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"var\"\n│   weight = 2\n│   type = \"var\"\n│   src = \"parms\"\n└   dst = \"α\"\n[ Info: Inserting directed edge of type output from ScalingModel.micro_1(du, u, parms, time) to dS.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"val\"\n│   weight = 3\n│   type = \"val\"\n│   src = \"dS\"\n└   dst = \"r * (1 - S / K) * S - β * S * I\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :output\n│   weight = 2\n│   type = :output\n│   src = \"ScalingModel.micro_1(du, u, parms, time)\"\n└   dst = \"dS\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"exp\"\n│   weight = 4\n│   type = \"exp\"\n│   src = \"dS\"\n└   dst = \"r * (1 - S / K) * S - β * S * I\"\n[ Info: Inserting directed edge of type input from ScalingModel.micro_1(du, u, parms, time) to -.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"args\"\n│   weight = 2\n│   type = \"args\"\n│   src = \"-\"\n└   dst = \"Symbol[Symbol(\\\"r * (1 - S / K) * S\\\"), Symbol(\\\"β * S * I\\\")]\"\n[ Info: Inserting directed edge of type output from ScalingModel.micro_1(du, u, parms, time) to dI.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"val\"\n│   weight = 3\n│   type = \"val\"\n│   src = \"dI\"\n└   dst = \"β * S * I - (μ + α) * I\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :output\n│   weight = 2\n│   type = :output\n│   src = \"ScalingModel.micro_1(du, u, parms, time)\"\n└   dst = \"dI\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"exp\"\n│   weight = 4\n│   type = \"exp\"\n│   src = \"dI\"\n└   dst = \"β * S * I - (μ + α) * I\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :input\n│   weight = 2\n│   type = :input\n│   src = \"ScalingModel.micro_1(du, u, parms, time)\"\n└   dst = \"-\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"args\"\n│   weight = 2\n│   type = \"args\"\n│   src = \"-\"\n└   dst = \"Symbol[Symbol(\\\"β * S * I\\\"), Symbol(\\\"(μ + α) * I\\\")]\"\n[ Info: Inserting directed edge of type takes from ScalingModel.micro_1(du, u, parms, time) to du.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"val\"\n│   weight = 2\n│   type = \"val\"\n│   src = \"du\"\n└   dst = \"[dS, dI]\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :has\n│   weight = 2\n│   type = :has\n│   src = \"ScalingModel.micro_1(du, u, parms, time)\"\n└   dst = \"du\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"property\"\n│   weight = 2\n│   type = \"property\"\n│   src = \"du\"\n└   dst = \"collection\"\n┌ Info: Returning graph G\n│   nedges = 24\n└   cardinality = 20\n┌ Info: Code graph 1 has v vertices and e edges.\n│   v = 20\n└   e = 24\n┌ Info: Parsing julia script\n└   file = \"../examples/epicookbook/src/SEIRmodel.jl\"\ns = \"# -*- coding: utf-8 -*-\\n# ---\\n# jupyter:\\n#   jupytext:\\n#     text_representation:\\n#       extension: .jl\\n#       format_name: light\\n#       format_version: \'1.3\'\\n#       jupytext_version: 0.8.6\\n#   kernelspec:\\n#     display_name: Julia 1.0.3\\n#     language: julia\\n#     name: julia-1.0\\n# ---\\n\\nmodule SEIRmodel\\nusing DifferentialEquations\\n\\n#Susceptible-exposed-infected-recovered model function\\nfunction seir_ode(dY,Y,p,t)\\n    #Infected per-Capita Rate\\n    β = p[1]\\n    #Incubation Rate\\n    σ = p[2]\\n    #Recover per-capita rate\\n    γ = p[3]\\n    #Death Rate\\n    μ = p[4]\\n\\n    #Susceptible Individual\\n    S = Y[1]\\n    #Exposed Individual\\n    E = Y[2]\\n    #Infected Individual\\n    I = Y[3]\\n    #Recovered Individual\\n    #R = Y[4]\\n\\n    dY[1] = μ-β*S*I-μ*S\\n    dY[2] = β*S*I-(σ+μ)*E\\n    dY[3] = σ*E - (γ+μ)*I\\nend\\n\\n#Pram (Infected Rate, Incubation Rate, Recover Rate, Death Rate)\\npram=[520/365,1/60,1/30,774835/(65640000*365)]\\n#Initialize Param(Susceptible Individuals, Exposed Individuals, Infected Individuals)\\ninit=[0.8,0.1,0.1]\\ntspan=(0.0,365.0)\\n\\nseir_prob = ODEProblem(seir_ode,init,tspan,pram)\\n\\nsol=solve(seir_prob);\\n\\nusing Plots\\n\\nva = VectorOfArray(sol.u)\\ny = convert(Array,va)\\nR = ones(size(sol.t))\' - sum(y,dims=1);\\n\\nplot(sol.t,[y\',R\'],xlabel=\\\"Time\\\",ylabel=\\\"Proportion\\\")\\n\\n\\n\\nend\\n\"\n[ Info: unknown expr type for metacollector\nexpr = :(function seir_ode(dY, Y, p, t)\n      #= none:22 =#\n      β = p[1]\n      #= none:24 =#\n      σ = p[2]\n      #= none:26 =#\n      γ = p[3]\n      #= none:28 =#\n      μ = p[4]\n      #= none:31 =#\n      S = Y[1]\n      #= none:33 =#\n      E = Y[2]\n      #= none:35 =#\n      I = Y[3]\n      #= none:39 =#\n      dY[1] = (μ - β * S * I) - μ * S\n      #= none:40 =#\n      dY[2] = β * S * I - (σ + μ) * E\n      #= none:41 =#\n      dY[3] = σ * E - (γ + μ) * I\n  end)\n[ Info: unknown expr type for metacollector\nexpr = :(plot(sol.t, [y\', R\'], xlabel=\"Time\", ylabel=\"Proportion\"))\n┌ Info: script uses modules\n│   modules =\n│    2-element Array{Any,1}:\n│     Any[:DifferentialEquations]\n└     Any[:Plots]\n┌ Info: script defines functions\n│   funcs =\n│    1-element Array{Any,1}:\n│     :(seir_ode(dY, Y, p, t)) => quote\n│        #= none:22 =#\n│        β = p[1]\n│        #= none:24 =#\n│        σ = p[2]\n│        #= none:26 =#\n│        γ = p[3]\n│        #= none:28 =#\n│        μ = p[4]\n│        #= none:31 =#\n│        S = Y[1]\n│        #= none:33 =#\n│        E = Y[2]\n│        #= none:35 =#\n│        I = Y[3]\n│        #= none:39 =#\n│        dY[1] = (μ - β * S * I) - μ * S\n│        #= none:40 =#\n│        dY[2] = β * S * I - (σ + μ) * E\n│        #= none:41 =#\n│        dY[3] = σ * E - (γ + μ) * I\n└    end\n┌ Info: script defines glvariables\n│   funcs =\n│    8-element Array{Any,1}:\n│          :pram => :([520 / 365, 1 / 60, 1 / 30, 774835 / (65640000 * 365)])\n│          :init => :([0.8, 0.1, 0.1])\n│         :tspan => :((0.0, 365.0))\n│     :seir_prob => :(ODEProblem(seir_ode, init, tspan, pram))\n│           :sol => :(solve(seir_prob))\n│            :va => :(VectorOfArray(sol.u))\n│             :y => :(convert(Array, va))\n└             :R => :((ones(size(sol.t)))\' - sum(y, dims=1))\nfuncdefs = Any[:(seir_ode(dY, Y, p, t))=>quote\n    #= none:22 =#\n    β = p[1]\n    #= none:24 =#\n    σ = p[2]\n    #= none:26 =#\n    γ = p[3]\n    #= none:28 =#\n    μ = p[4]\n    #= none:31 =#\n    S = Y[1]\n    #= none:33 =#\n    E = Y[2]\n    #= none:35 =#\n    I = Y[3]\n    #= none:39 =#\n    dY[1] = (μ - β * S * I) - μ * S\n    #= none:40 =#\n    dY[2] = β * S * I - (σ + μ) * E\n    #= none:41 =#\n    dY[3] = σ * E - (γ + μ) * I\nend]\n┌ Info: local scope definitions\n│   subdefs =\n│    1-element Array{Any,1}:\n└     :(seir_ode(dY, Y, p, t)) => MetaCollector{FuncCollector{Array{Any,1}},Array{Any,1},Array{Any,1},Array{Any,1}}(Any[:(β = p[1]), :(σ = p[2]), :(γ = p[3]), :(μ = p[4]), :(S = Y[1]), :(E = Y[2]), :(I = Y[3]), :(dY[1] = (μ - β * S * I) - μ * S), :(dY[2] = β * S * I - (σ + μ) * E), :(dY[3] = σ * E - (γ + μ) * I)], FuncCollector{Array{Any,1}}(Any[]), Any[:β=>:(p[1]), :σ=>:(p[2]), :γ=>:(p[3]), :μ=>:(p[4]), :S=>:(Y[1]), :E=>:(Y[2]), :I=>:(Y[3]), :(dY[1])=>:((μ - β * S * I) - μ * S), :(dY[2])=>:(β * S * I - (σ + μ) * E), :(dY[3])=>:(σ * E - (γ + μ) * I)], Any[])\n┌ Info: seir_ode(dY, Y, p, t) uses modules\n└   modules = 0-element Array{Any,1}\n┌ Info: seir_ode(dY, Y, p, t) defines functions\n└   funcs = 0-element Array{Any,1}\n┌ Info: seir_ode(dY, Y, p, t) defines variables\n│   funcs =\n│    10-element Array{Any,1}:\n│           :β => :(p[1])\n│           :σ => :(p[2])\n│           :γ => :(p[3])\n│           :μ => :(p[4])\n│           :S => :(Y[1])\n│           :E => :(Y[2])\n│           :I => :(Y[3])\n│     :(dY[1]) => :((μ - β * S * I) - μ * S)\n│     :(dY[2]) => :(β * S * I - (σ + μ) * E)\n└     :(dY[3]) => :(σ * E - (γ + μ) * I)\n┌ Info: Making edges\n└   scope = :SEIRmodel\n(var, val) = (:β, :(p[1]))\n(var, val) = (:σ, :(p[2]))\n(var, val) = (:γ, :(p[3]))\n(var, val) = (:μ, :(p[4]))\n(var, val) = (:S, :(Y[1]))\n(var, val) = (:E, :(Y[2]))\n(var, val) = (:I, :(Y[3]))\n(var, val) = (:(dY[1]), :((μ - β * S * I) - μ * S))\n(var, val) = (:(dY[2]), :(β * S * I - (σ + μ) * E))\n(var, val) = (:(dY[3]), :(σ * E - (γ + μ) * I))\n┌ Info: Making edges\n└   scope = \"SEIRmodel.seir_ode(dY, Y, p, t)\"\n(var, val) = (:β, :(p[1]))\n(var, val) = (:σ, :(p[2]))\n(var, val) = (:γ, :(p[3]))\n(var, val) = (:μ, :(p[4]))\n(var, val) = (:S, :(Y[1]))\n(var, val) = (:E, :(Y[2]))\n(var, val) = (:I, :(Y[3]))\n(var, val) = (:(dY[1]), :((μ - β * S * I) - μ * S))\n(var, val) = (:(dY[2]), :(β * S * I - (σ + μ) * E))\n(var, val) = (:(dY[3]), :(σ * E - (γ + μ) * I))\n┌ Info: Edges found\n└   path = \"../examples/epicookbook/src/SEIRmodel.jl\"\n[ Info: The input graph contains 20 unique vertices\n┌ Info: The input edge list refers to 37 unique vertices.\n└   nv = 37\n┌ Info: The size of the intersection of these two sets is: 1.\n└   nv = 1\n┌ Info: src vertex SEIRmodel was not in G, and has been inserted.\n└   vname = \"SEIRmodel\"\n┌ Info: dst vertex β was not in G, and has been inserted.\n└   vname = \"β\"\n[ Info: Inserting directed edge of type takes from SEIRmodel to β.\n┌ Info: dst vertex p[1] was not in G, and has been inserted.\n└   vname = \"p[1]\"\n[ Info: Inserting directed edge of type val from β to p[1].\n┌ Info: dst vertex σ was not in G, and has been inserted.\n└   vname = \"σ\"\n[ Info: Inserting directed edge of type takes from SEIRmodel to σ.\n┌ Info: dst vertex p[2] was not in G, and has been inserted.\n└   vname = \"p[2]\"\n[ Info: Inserting directed edge of type val from σ to p[2].\n┌ Info: dst vertex γ was not in G, and has been inserted.\n└   vname = \"γ\"\n[ Info: Inserting directed edge of type takes from SEIRmodel to γ.\n┌ Info: dst vertex p[3] was not in G, and has been inserted.\n└   vname = \"p[3]\"\n[ Info: Inserting directed edge of type val from γ to p[3].\n┌ Info: dst vertex μ was not in G, and has been inserted.\n└   vname = \"μ\"\n[ Info: Inserting directed edge of type takes from SEIRmodel to μ.\n┌ Info: dst vertex p[4] was not in G, and has been inserted.\n└   vname = \"p[4]\"\n[ Info: Inserting directed edge of type val from μ to p[4].\n┌ Info: dst vertex S was not in G, and has been inserted.\n└   vname = \"S\"\n[ Info: Inserting directed edge of type takes from SEIRmodel to S.\n┌ Info: dst vertex Y[1] was not in G, and has been inserted.\n└   vname = \"Y[1]\"\n[ Info: Inserting directed edge of type val from S to Y[1].\n┌ Info: dst vertex E was not in G, and has been inserted.\n└   vname = \"E\"\n[ Info: Inserting directed edge of type takes from SEIRmodel to E.\n┌ Info: dst vertex Y[2] was not in G, and has been inserted.\n└   vname = \"Y[2]\"\n[ Info: Inserting directed edge of type val from E to Y[2].\n┌ Info: dst vertex I was not in G, and has been inserted.\n└   vname = \"I\"\n[ Info: Inserting directed edge of type takes from SEIRmodel to I.\n┌ Info: dst vertex Y[3] was not in G, and has been inserted.\n└   vname = \"Y[3]\"\n[ Info: Inserting directed edge of type val from I to Y[3].\n┌ Info: dst vertex dY[1] was not in G, and has been inserted.\n└   vname = \"dY[1]\"\n[ Info: Inserting directed edge of type output from SEIRmodel to dY[1].\n┌ Info: dst vertex (μ - β * S * I) - μ * S was not in G, and has been inserted.\n└   vname = \"(μ - β * S * I) - μ * S\"\n[ Info: Inserting directed edge of type val from dY[1] to (μ - β * S * I) - μ * S.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :output\n│   weight = 2\n│   type = :output\n│   src = \"SEIRmodel\"\n└   dst = \"dY[1]\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"exp\"\n│   weight = 2\n│   type = \"exp\"\n│   src = \"dY[1]\"\n└   dst = \"(μ - β * S * I) - μ * S\"\n[ Info: Inserting directed edge of type input from SEIRmodel to -.\n┌ Info: dst vertex Symbol[Symbol(\"μ - β * S * I\"), Symbol(\"μ * S\")] was not in G, and has been inserted.\n└   vname = \"Symbol[Symbol(\\\"μ - β * S * I\\\"), Symbol(\\\"μ * S\\\")]\"\n[ Info: Inserting directed edge of type args from - to Symbol[Symbol(\"μ - β * S * I\"), Symbol(\"μ * S\")].\n┌ Info: dst vertex dY[2] was not in G, and has been inserted.\n└   vname = \"dY[2]\"\n[ Info: Inserting directed edge of type output from SEIRmodel to dY[2].\n┌ Info: dst vertex β * S * I - (σ + μ) * E was not in G, and has been inserted.\n└   vname = \"β * S * I - (σ + μ) * E\"\n[ Info: Inserting directed edge of type val from dY[2] to β * S * I - (σ + μ) * E.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :output\n│   weight = 2\n│   type = :output\n│   src = \"SEIRmodel\"\n└   dst = \"dY[2]\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"exp\"\n│   weight = 2\n│   type = \"exp\"\n│   src = \"dY[2]\"\n└   dst = \"β * S * I - (σ + μ) * E\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :input\n│   weight = 2\n│   type = :input\n│   src = \"SEIRmodel\"\n└   dst = \"-\"\n┌ Info: dst vertex Symbol[Symbol(\"β * S * I\"), Symbol(\"(σ + μ) * E\")] was not in G, and has been inserted.\n└   vname = \"Symbol[Symbol(\\\"β * S * I\\\"), Symbol(\\\"(σ + μ) * E\\\")]\"\n[ Info: Inserting directed edge of type args from - to Symbol[Symbol(\"β * S * I\"), Symbol(\"(σ + μ) * E\")].\n┌ Info: dst vertex dY[3] was not in G, and has been inserted.\n└   vname = \"dY[3]\"\n[ Info: Inserting directed edge of type output from SEIRmodel to dY[3].\n┌ Info: dst vertex σ * E - (γ + μ) * I was not in G, and has been inserted.\n└   vname = \"σ * E - (γ + μ) * I\"\n[ Info: Inserting directed edge of type val from dY[3] to σ * E - (γ + μ) * I.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :output\n│   weight = 2\n│   type = :output\n│   src = \"SEIRmodel\"\n└   dst = \"dY[3]\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"exp\"\n│   weight = 2\n│   type = \"exp\"\n│   src = \"dY[3]\"\n└   dst = \"σ * E - (γ + μ) * I\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :input\n│   weight = 3\n│   type = :input\n│   src = \"SEIRmodel\"\n└   dst = \"-\"\n┌ Info: dst vertex Symbol[Symbol(\"σ * E\"), Symbol(\"(γ + μ) * I\")] was not in G, and has been inserted.\n└   vname = \"Symbol[Symbol(\\\"σ * E\\\"), Symbol(\\\"(γ + μ) * I\\\")]\"\n[ Info: Inserting directed edge of type args from - to Symbol[Symbol(\"σ * E\"), Symbol(\"(γ + μ) * I\")].\n┌ Info: src vertex SEIRmodel.seir_ode(dY, Y, p, t) was not in G, and has been inserted.\n└   vname = \"SEIRmodel.seir_ode(dY, Y, p, t)\"\n[ Info: Inserting directed edge of type takes from SEIRmodel.seir_ode(dY, Y, p, t) to β.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"val\"\n│   weight = 2\n│   type = \"val\"\n│   src = \"β\"\n└   dst = \"p[1]\"\n[ Info: Inserting directed edge of type takes from SEIRmodel.seir_ode(dY, Y, p, t) to σ.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"val\"\n│   weight = 2\n│   type = \"val\"\n│   src = \"σ\"\n└   dst = \"p[2]\"\n[ Info: Inserting directed edge of type takes from SEIRmodel.seir_ode(dY, Y, p, t) to γ.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"val\"\n│   weight = 2\n│   type = \"val\"\n│   src = \"γ\"\n└   dst = \"p[3]\"\n[ Info: Inserting directed edge of type takes from SEIRmodel.seir_ode(dY, Y, p, t) to μ.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"val\"\n│   weight = 2\n│   type = \"val\"\n│   src = \"μ\"\n└   dst = \"p[4]\"\n[ Info: Inserting directed edge of type takes from SEIRmodel.seir_ode(dY, Y, p, t) to S.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"val\"\n│   weight = 2\n│   type = \"val\"\n│   src = \"S\"\n└   dst = \"Y[1]\"\n[ Info: Inserting directed edge of type takes from SEIRmodel.seir_ode(dY, Y, p, t) to E.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"val\"\n│   weight = 2\n│   type = \"val\"\n│   src = \"E\"\n└   dst = \"Y[2]\"\n[ Info: Inserting directed edge of type takes from SEIRmodel.seir_ode(dY, Y, p, t) to I.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"val\"\n│   weight = 2\n│   type = \"val\"\n│   src = \"I\"\n└   dst = \"Y[3]\"\n[ Info: Inserting directed edge of type output from SEIRmodel.seir_ode(dY, Y, p, t) to dY[1].\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"val\"\n│   weight = 3\n│   type = \"val\"\n│   src = \"dY[1]\"\n└   dst = \"(μ - β * S * I) - μ * S\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :output\n│   weight = 2\n│   type = :output\n│   src = \"SEIRmodel.seir_ode(dY, Y, p, t)\"\n└   dst = \"dY[1]\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"exp\"\n│   weight = 4\n│   type = \"exp\"\n│   src = \"dY[1]\"\n└   dst = \"(μ - β * S * I) - μ * S\"\n[ Info: Inserting directed edge of type input from SEIRmodel.seir_ode(dY, Y, p, t) to -.\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"args\"\n│   weight = 2\n│   type = \"args\"\n│   src = \"-\"\n└   dst = \"Symbol[Symbol(\\\"μ - β * S * I\\\"), Symbol(\\\"μ * S\\\")]\"\n[ Info: Inserting directed edge of type output from SEIRmodel.seir_ode(dY, Y, p, t) to dY[2].\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"val\"\n│   weight = 3\n│   type = \"val\"\n│   src = \"dY[2]\"\n└   dst = \"β * S * I - (σ + μ) * E\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :output\n│   weight = 2\n│   type = :output\n│   src = \"SEIRmodel.seir_ode(dY, Y, p, t)\"\n└   dst = \"dY[2]\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"exp\"\n│   weight = 4\n│   type = \"exp\"\n│   src = \"dY[2]\"\n└   dst = \"β * S * I - (σ + μ) * E\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :input\n│   weight = 2\n│   type = :input\n│   src = \"SEIRmodel.seir_ode(dY, Y, p, t)\"\n└   dst = \"-\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"args\"\n│   weight = 2\n│   type = \"args\"\n│   src = \"-\"\n└   dst = \"Symbol[Symbol(\\\"β * S * I\\\"), Symbol(\\\"(σ + μ) * E\\\")]\"\n[ Info: Inserting directed edge of type output from SEIRmodel.seir_ode(dY, Y, p, t) to dY[3].\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"val\"\n│   weight = 3\n│   type = \"val\"\n│   src = \"dY[3]\"\n└   dst = \"σ * E - (γ + μ) * I\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :output\n│   weight = 2\n│   type = :output\n│   src = \"SEIRmodel.seir_ode(dY, Y, p, t)\"\n└   dst = \"dY[3]\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"exp\"\n│   weight = 4\n│   type = \"exp\"\n│   src = \"dY[3]\"\n└   dst = \"σ * E - (γ + μ) * I\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = :input\n│   weight = 3\n│   type = :input\n│   src = \"SEIRmodel.seir_ode(dY, Y, p, t)\"\n└   dst = \"-\"\n┌ Info: Incrementing weight of existing directed edge\n│   edge_type = \"args\"\n│   weight = 2\n│   type = \"args\"\n│   src = \"-\"\n└   dst = \"Symbol[Symbol(\\\"σ * E\\\"), Symbol(\\\"(γ + μ) * I\\\")]\"\n┌ Info: Returning graph G\n│   nedges = 59\n└   cardinality = 45\n┌ Info: Code graph 2 has v vertices and e edges.\n│   v = 45\n└   e = 59\n[ Info: All markdown and code files have been parsed; writing final knowledge graph to dot file\nProcess(`dot -Tsvg -O ../examples/epicookbook/data/dot_file_ex1.dot`, ProcessExited(0))The extraction code will generate a dot file diagram of the edges in the graph.Due to the fact that code extraction is a heuristic, there is some cleaning of the knowledge  graph required before it is ready for reasoning."
},

{
    "location": "example/#Reasoning-1",
    "page": "Example",
    "title": "Reasoning",
    "category": "section",
    "text": "Once the information is extracted from the documentation and code, we can visualize the knowledge as a graph. Most edges of type cooccur are elided for clarity.(Image: Knowledge Graph from epicookbook)This knowledge graph contains all the connections we need to combine components across models. Once can view this combination as either a modification of one model by substituting components of another model, or as the automatic generation of a metamodel by synthesizing components from the knowledge graph into a single coherent model. Further theoretical analysis of metamodeling and model modification as mathematical problems is warranted to make these categories unambiguous and precisely defined.Once we identify a subgraph of related components we can identify the graft point between the two models. We look for a common variable that is used in two models, specifically in a derivative calculation. We find the variable S which appears in dS and dY (as S=Y[1] and dY = derivative(Y)). The knowledge that dS, dY are derivatives comes from the background knowledge of modeling that comes from reading textbooks and general scientific knowledge, while the fact that S and Y[1] both appear in an expression mu-beta*S*I - mu*S comes from the specific documents and codebases under consideration by the metamodeler.(Image: Knowledge Subgraph showing model modification)This subgraph must then extend out to capture all of the relevant information such as the parameter sets encountered, the function calls that contain these variables and expressions. We have found the largest relevant subgraph for some unspecified definition of relevance. From this subgraph, a human modeler can easily instruct the SemanticModels system on how to combine the SEIRmodel and ScalingModel programs into a single model and generate a program to execute it."
},

{
    "location": "example/#Generation-1",
    "page": "Example",
    "title": "Generation",
    "category": "section",
    "text": "Once reasoning is complete the graft.jl program will run over the extracted knowledge graph, and generate a new model. In this case we want to take the birth rate dynamics from the ScalingModel and add them to the SEIR model to create an SEIR+birth_rate model.Here is the code that does the grafting.using Cassette\nusing DifferentialEquations\nusing SemanticModels.Parsers\nusing SemanticModels.Dubstep\n\n# source of original problem\ninclude(\"../examples/epicookbook/src/SEIRmodel.jl\")\n\n#the functions we want to modify\nseir_ode = SEIRmodel.seir_ode\n\n# source of the problem we want to take from\nexpr = parsefile(\"../examples/epicookbook/src/ScalingModel.jl\")Once you have identified the entry point to your model, you can identify pieces of another model that you want to graft onto it. This piece of the other model might take significant preparation in order to be ready to fit onto the base model. These transformations include changing variables, and other plumbing aspects. If you stick to taking whole functions and not expressions, this prep work is reduced.# Find the expression we want to graft\n#vital dynamics S rate expression\nvdsre = expr.args[3].args[5].args[2].args[4]\n@show popgrowth = vdsre.args[2].args[2]\nreplacevar(expr, old, new) = begin\n    dump(expr)\n    expr.args[3].args[3].args[3] = new\n    return expr\nend\npopgrowth = replacevar(popgrowth, :K,:N)\n\n# generate the function newfunc\n# this eval happens at the top level so should only happen once\nnewfunc = eval(:(fpopgrowth(r,S,N) = $popgrowth))\n\n# This is the new problem\n# notice the signature doesn\'t even match, we have added a new parameter\nfunction fprime(dY,Y,p,t, ϵ)\n    #Infected per-Capita Rate\n    β = p[1]\n    #Incubation Rate\n    σ = p[2]\n    #Recover per-capita rate\n    γ = p[3]\n    #Death Rate\n    μ = p[4]\n\n    #Susceptible Individual\n    S = Y[1]\n    #Exposed Individual\n    E = Y[2]\n    #Infected Individual\n    I = Y[3]\n    #Recovered Individual\n    #R = Y[4]\n\n    # here is the graft point\n    dY[1] = μ-β*S*I-μ*S + newfunc(ϵ, S, S+E+I)\n    dY[2] = β*S*I-(σ+μ)*E\n    dY[3] = σ*E - (γ+μ)*I\nendDefine the overdub behavior, all the fucntions needed to be defined at this point using run time values slows down overdub.function Cassette.overdub(ctx::Dubstep.GraftCtx, f::typeof(seir_ode), args...)\n    # this call matches the new signature\n    return Cassette.fallback(ctx, fprime, args..., ctx.metadata[:lambda])\nendThe last step is to run the new model!#set up our modeling configuration\nfunction g()\n    #Pram (Infected Rate, Incubation Rate, Recover Rate, Death Rate)\n    pram=[520/365,1/60,1/30,774835/(65640000*365)]\n    #Initialize Param(Susceptible Individuals, Exposed Individuals, Infected Individuals)\n    init=[0.8,0.1,0.1]\n    tspan=(0.0,365.0)\n\n    seir_prob = ODEProblem(seir_ode,init,tspan,pram)\n\n    sol=solve(seir_prob);\nend\n\n# sweep over population growth rates\nfunction scalegrowth(λ=1.0)\n    # ctx.metadata holds our new parameter\n    ctx = Dubstep.GraftCtx(metadata=Dict(:lambda=>λ))\n    return Cassette.overdub(ctx, g)\nend\n\nprintln(\"S\\tI\\tR\")\nfor λ in [1.0,1.1,1.2]\n    @time S,I,R = scalegrowth(λ)(365)\n    println(\"$S\\t$I\\t$R\")\nend\n#it works!julia> include(\"graft.jl\")\ns = \"# -*- coding: utf-8 -*-\\n# ---\\n# jupyter:\\n#   jupytext:\\n#     text_representation:\\n#       extension: .jl\\n#       format_name: light\\n#       format_version: \'1.3\'\\n#       jupytext_version: 0.8.6\\n#   kernelspec:\\n#     display_name: Julia 1.0.3\\n#     language: julia\\n#     name: julia-1.0\\n# ---\\n\\nmodule ScalingModel\\nusing DifferentialEquations\\n\\nfunction micro_1(du, u, parms, time)\\n    # PARAMETER DEFS\\n    # β transmition rate\\n    # r net population growth rate\\n    # μ hosts\' natural mortality rate\\n    # Κ population size\\n    # α disease induced mortality rate\\n\\n    β, r, μ, K, α = parms\\n    dS = r*(1-S/K)*S - β*S*I\\n    dI = β*S*I-(μ+α)*I\\n    du = [dS,dI]\\nend\\n\\n# +\\n# PARAMETER DEFS\\n# w and m are used to define the other parameters allometrically\\n\\nw = 1;\\nm = 10;\\nβ = 0.0247*m*w^0.44;\\nr = 0.6*w^-0.27;\\nμ = 0.4*w^-0.26;\\nK = 16.2*w^-0.7;\\nα = (m-1)*μ;\\n# -\\n\\nparms = [β,r,μ,K,α];\\ninit = [K,1.];\\ntspan = (0.0,10.0);\\n\\nsir_prob = ODEProblem(micro_1,init,tspan,parms)\\n\\nsir_sol = solve(sir_prob);\\n\\nusing Plots\\n\\nplot(sir_sol,xlabel=\\\"Time\\\",ylabel=\\\"Number\\\")\\n\\nm = [5,10,20,40]\\nws = 10 .^collect(range(-3,length = 601,3))\\nβs = zeros(601,4)\\nfor i = 1:4\\n    βs[:,i] = 0.0247*m[i]*ws.^0.44\\nend\\nplot(ws,βs,xlabel=\\\"Weight\\\",ylabel=\\\"\\\\\\\\beta_min\\\", xscale=:log10,yscale=:log10, label=[\\\"m = 5\\\" \\\"m = 10\\\" \\\"m = 20\\\" \\\"m = 40\\\"],lw=3)\\n\\nend\\n\"\npopgrowth = (vdsre.args[2]).args[2] = :(r * (1 - S / K) * S)\nExpr\n  head: Symbol call\n  args: Array{Any}((4,))\n    1: Symbol *\n    2: Symbol r\n    3: Expr\n      head: Symbol call\n      args: Array{Any}((3,))\n        1: Symbol -\n        2: Int64 1\n        3: Expr\n          head: Symbol call\n          args: Array{Any}((3,))\n            1: Symbol /\n            2: Symbol S\n            3: Symbol K\n    4: Symbol S\nS	I	R\n 67.554431 seconds (125.80 M allocations: 6.555 GiB, 7.52% gc time)\n4.139701895048853e-5	1.512940651164174	1.2314284234326383\n  4.132043 seconds (1.85 M allocations: 33.602 MiB, 0.37% gc time)\n3.319429471438334e-5	1.7926581454821442	1.4394890708586585\n  4.294201 seconds (1.99 M allocations: 36.084 MiB, 0.54% gc time)\n2.7307348723966148e-5	2.096234030610046	1.6601782657100044S I R\n4.139701895048853e-5 1.512940651164174 1.2314284234326383\n3.319429471438334e-5 1.7926581454821442 1.4394890708586585\n2.7307348723966148e-5 2.096234030610046 1.6601782657100044We can see from the model output that as the birth rate of the population increases, the size of the SEIR epidemic increases. This example illustrates how we can add capabilities  to models in a way that can augment the ability of scientists to conduct in silico experiments. This augmentation will ultimately enable a faster development of scientific ideas informed by data and simulation.Hopefully, this example has shown you the goals and scope of this software, the remaining documentation details the various components essential to the creation of this demonstration."
},

{
    "location": "dubstep/#",
    "page": "Dubstep",
    "title": "Dubstep",
    "category": "page",
    "text": ""
},

{
    "location": "dubstep/#Dubstep-1",
    "page": "Dubstep",
    "title": "Dubstep",
    "category": "section",
    "text": "This module uses Cassette.jl (Zenodo) to modify programs by overdubbing their executions in a context.  Overdubbing allows you to define a context that defines allows a program to control the execution behavior of programs that are passed to it. Cassette is a novel approach to software development and integrates deeply with the Julia compiler to provide high performance aspect oriented programming."
},

{
    "location": "dubstep/#TraceCtx-1",
    "page": "Dubstep",
    "title": "TraceCtx",
    "category": "section",
    "text": "Builds hierarchical runtime value traces by running the program you pass it. You can change the metadata. You can change out the metadata that you pass in order to collect different information. The default is Any[]."
},

{
    "location": "dubstep/#LPCtx-1",
    "page": "Dubstep",
    "title": "LPCtx",
    "category": "section",
    "text": "Replaces all calls to norm(x,p) with norm(x,ctx.metadata[p]) so you can change the norms that a code uses to compute. "
},

{
    "location": "dubstep/#Example-1",
    "page": "Dubstep",
    "title": "Example",
    "category": "section",
    "text": "Here is an example of changing an internal component of a mathematical operation using cassette to rewrite the norm function:First we define a function that uses norm, and another function that calls it: \nsubg(x,y) = norm([x x x]/6 - [y y y]/2, 2)\n\nfunction g()\n    a = 5+7\n    b = 3+4\n    c = subg(a,b)\n    return c\nendWe use the Dubstep.LPCtx, which is shown here:Cassette.@context LPCtx\n\nfunction Cassette.overdub(ctx::LPCtx, args...)\n    if Cassette.canrecurse(ctx, args...)\n        newctx = Cassette.similarcontext(ctx, metadata = ctx.metadata)\n        return Cassette.recurse(newctx, args...)\n    else\n        return Cassette.fallback(ctx, args...)\n    end\nend\n\nusing LinearAlgebra\nfunction Cassette.overdub(ctx::LPCtx, f::typeof(norm), arg, power)\n    return f(arg, ctx.metadata[power])\nendNote the method definition of Cassette.overdub for LPCtx when called with the function LinearAlgebra.norm.We then construct an instance of the context that configures how we want to do the substitution:@testset \"LP\" begin \n@test 2.5980 < g() < 2.599\nctx = Dubstep.LPCtx(metadata=Dict(1=>2, 2=>1, Inf=>1))\n@test Cassette.recurse(ctx, g) == 4.5And just like that, we can control the execution of a program without rewriting it at the lexical level."
},

{
    "location": "dubstep/#Transformations-1",
    "page": "Dubstep",
    "title": "Transformations",
    "category": "section",
    "text": "You can also transform a model by executing it in a context that changes the function calls. Eventually we will support writing compiler passes for modifying models at the expression level, but for now, function calls are a good entry point."
},

{
    "location": "dubstep/#Example:-Perturbations-1",
    "page": "Dubstep",
    "title": "Example: Perturbations",
    "category": "section",
    "text": "This example comes from the unit tests test/transform/ode.jl.The first step is to define a context for solving models:module ODEXform\nusing DifferentialEquations\nusing Cassette\nusing SemanticModels.Dubstep\n\nCassette.@context SolverCtx\nfunction Cassette.overdub(ctx::SolverCtx, args...)\n    if Cassette.canrecurse(ctx, args...)\n        #newctx = Cassette.similarcontext(ctx, metadata = ctx.metadata)\n        return Cassette.recurse(ctx, args...)\n    else\n        return Cassette.fallback(ctx, args...)\n    end\nend\n\nfunction Cassette.overdub(ctx::SolverCtx, f::typeof(Base.vect), args...)\n    @info \"constructing a vector length $(length(args))\"\n    return Cassette.fallback(ctx, f, args...)\nend\n\n# We don\'t need to overdub basic math. this hopefully makes execution faster.\n# if these overloads don\'t actually make it faster, they can be deleted.\nfunction Cassette.overdub(ctx::SolverCtx, f::typeof(+), args...)\n    return Cassette.fallback(ctx, f, args...)\nend\nfunction Cassette.overdub(ctx::SolverCtx, f::typeof(-), args...)\n    return Cassette.fallback(ctx, f, args...)\nend\nfunction Cassette.overdub(ctx::SolverCtx, f::typeof(*), args...)\n    return Cassette.fallback(ctx, f, args...)\nend\nfunction Cassette.overdub(ctx::SolverCtx, f::typeof(/), args...)\n    return Cassette.fallback(ctx, f, args...)\nend\nend #moduleThen we define our RHS of the differential equation that is du/dt = sir_ode(du, u, p, t). This function needs to be defined before we define the method for Cassette.overdub with the signature: Cassette.overdub(ctx::ODEXform.SolverCtx, f::typeof(sir_ode), args...)  because we need to have the function we want to overdub defined before we can specify how to overdub it.using LinearAlgebra\nusing Test\nusing Cassette\nusing DifferentialEquations\nusing SemanticModels.Dubstep\n\n\"\"\"   sir_ode(du,u,p,t)\n\ncomputes the du/dt array for the SIR system. parameters p is b,g = beta,gamma.\n\"\"\"\nsir_ode(du,u,p,t) = begin\n    S,I,R = u\n    b,g = p\n    du[1] = -b*S*I\n    du[2] = b*S*I-g*I\n    du[3] = g*I\nendThis code implements the model fracdSdt = -beta S I fracdIdt = beta S I - gamma I fracdRdt = gamma IA common modeling activity is for a scientist to consider counterfactual scenarios, what if the infection was a little bit stronger. In this model the strength of infection is a direct parameter of the model, but our approach works on aspects of the model that are not so easily accessible.We want to add to the code a perturbation that allows us to examine these counterfactuals. Suppose the infection was a little stronger by a factor of alphafracdSdt = alpha (beta S I - gamma I)Then we could modify the code at run time using a Cassette Context.function Cassette.overdub(ctx::ODEXform.SolverCtx, f::typeof(sir_ode), args...)\n    y = Cassette.fallback(ctx, f, args...)\n    # add a lagniappe of infection\n    extra = args[1][1] * ctx.metadata.factor\n    push!(ctx.metadata.extras, extra)\n    args[1][1] += extra\n    args[1][2] -= extra\n    return y\nendThe key thing is that we define the execute method by specifying that we want to execute sir_ode then compute the extra amount (the lagniappe) and add that extra amount to the dS/dt. The SIR model has an invariant that dI/dt = -dS/dt + dR/dt so we adjust the dI/dt accordingly.The rest of this code runs the model in the context.function g()\n    parms = [0.1,0.05]\n    init = [0.99,0.01,0.0]\n    tspan = (0.0,200.0)\n    sir_prob = Dubstep.construct(ODEProblem,sir_ode,init,tspan,parms)\n    return sir_prob\nend\n\nfunction h()\n    prob = g()\n    return solve(prob, alg=Vern7())\nend\n\n#precompile\n@time sol1 = h()\n#timeit\n@time sol1 = h()We define a perturbation function that handles setting up the context and collecting the results. Note that we store the extras in the context.metadata using a modifying operator push!.\"\"\"    perturb(f, factor)\n\nrun the function f with a perturbation specified by factor.\n\"\"\"\nfunction perturb(f, factor)\n    t = (factor=factor,extras=Float64[])\n    ctx = ODEXform.SolverCtx(metadata = t)\n    val = Cassette.recurse(ctx, f)\n    return val, t\nendThe use of an execution context allows the programmer to capture state from the program in the context and reuse it across function calls. This solves one of the big problems  with reuse of modeling code. Scientific code is not written with extensibility in mind. There is often no way to pass information between function calls without modifying a large number of functions. Attempts to solve this with object oriented programming often lead to overly complex systems that are difficult for new scientists to use. The ability of the execution context to pass state between functions allows for redefining behavior of a complex software system without reengineering all the application programming interfaces (APIs).We collect the traces t and solutions s in order to quantify the effect of our perturbation on the answer computed by solve. We test to make sure that the bigger the perturbation, the bigger the error.traces = Any[]\nsolns = Any[]\nfor f in [0.0, 0.01, 0.05, 0.10]\n    val, t = perturb(h, f)\n    push!(traces, t)\n    push!(solns, val)\nend\n\nfor (i, s) in enumerate(solns)\n    @show s(100)\n    @show traces[i].factor\n    @show traces[i].extras[5]\n    @show sum(traces[i].extras)/length(traces[i].extras)\nend\n\n@testset \"ODE perturbation\"\n\n@test norm(sol1(100) .- solns[1](100),2) < 1e-6\n@test norm(sol1(100) .- solns[2](100),2) > 1e-6\n@test norm(solns[1](100) .- solns[2](100),2) < norm(solns[1](100) .- solns[3](100),2)\n@test norm(solns[1](100) .- solns[2](100),2) < norm(solns[1](100) .- solns[4](100),2)\n\nendThis example illustrates how you can use a Cassette.Context to highjack the execution of a scientific model in order to change the execution in a meaningful way. We also see how the execution allows use to examine the sensitivity of the solution with respect to the derivative. This technique allows scientists to answer counterfactual questions about the execution of codes, such as \"what if the model had a slightly different RHS?\"This illustrative example would be possible with a direct modification of the source code. We present this general framework for code analysis and modification because when the codes become sophisticated, complex models it is infeasible for scientists to just read the code and make the changes themselves. This is largly due to the fact that scientific models are not engineered to be extensible. The development resources are spent on innovative algorithms and mathematics and not on designing general purpose modeling frameworks that can be easily extended. When researchers do attempt to build general purpose software tools, they often lack the funding to design and maintain them at a level of utility that users expect. This leads to a cycle where scientists have bad experiences with general purpose software and thus invest fewer resources in its development in the future, perpetuating the preference for specialized use case specific software."
},

{
    "location": "dubstep/#Model-Grafting-1",
    "page": "Dubstep",
    "title": "Model Grafting",
    "category": "section",
    "text": "Once you have built a knowledge graph from other codes, you can reason over that knowledge graph to decide how to make modifications to the models. The Dubstep module provides the GraftCtx to facilitate these model modifications.using Cassette\nusing DifferentialEquations\nusing SemanticModels.Parsers\nusing SemanticModels.Dubstep\n\n# source of original problem\ninclude(\"../examples/epicookbook/src/SEIRmodel.jl\")\n\n#the functions we want to modify\nseir_ode = SEIRmodel.seir_odeOnce you have identified the entry point to your model, you can identify pieces of another model that you want to graft onto it. This piece of the other model might take significant preparation in order to be ready to fit onto the base model. These transformations include changing variables, and other plumbing aspects. If you stick to taking whole functions and not expressions, this prep work is reduced.# source of the problem we want to take from\nexpr = parsefile(\"examples/epicookbook/src/ScalingModel.jl\")\n\n\n# Find the expression we want to graft\n#vital dynamics S rate expression\nvdsre = expr.args[3].args[5].args[2].args[4]\n@show popgrowth = vdsre.args[2].args[2]\n\nreplacevar(expr, old, new) = begin\n    dump(expr)\n    expr.args[3].args[3].args[3] = new\n    return expr\nend\n\npopgrowth = replacevar(popgrowth, :K,:N)\n\n# generate the function newfunc\n# this eval happens at the top level so should only happen once\nnewfunc = eval(:(fpopgrowth(r,S,N) = $popgrowth))\n\n# This is the new problem\n# notice the signature doesn\'t even match, we have added a new parameter\nfunction fprime(dY,Y,p,t, ϵ)\n    #Infected per-Capita Rate\n    β = p[1]\n    #Incubation Rate\n    σ = p[2]\n    #Recover per-capita rate\n    γ = p[3]\n    #Death Rate\n    μ = p[4]\n\n    #Susceptible Individual\n    S = Y[1]\n    #Exposed Individual\n    E = Y[2]\n    #Infected Individual\n    I = Y[3]\n    #Recovered Individual\n    #R = Y[4]\n\n    # here is the graft point\n    dY[1] = μ-β*S*I-μ*S + newfunc(ϵ, S, S+E+I)\n    dY[2] = β*S*I-(σ+μ)*E\n    dY[3] = σ*E - (γ+μ)*I\nendDefine the overdub behavior; all the functions need to be defined at this point using run time values slows down overdub.function Cassette.overdub(ctx::Dubstep.GraftCtx, f::typeof(seir_ode), args...)\n    # this call matches the new signature\n    return Cassette.fallback(ctx, fprime, args..., ctx.metadata[:lambda])\nendThe last step is to run the new model!# set up our modeling configuration\nfunction g()\n    #Pram (Infected Rate, Incubation Rate, Recover Rate, Death Rate)\n    pram=[520/365,1/60,1/30,774835/(65640000*365)]\n    #Initialize Param(Susceptible Individuals, Exposed Individuals, Infected Individuals)\n    init=[0.8,0.1,0.1]\n    tspan=(0.0,365.0)\n\n    seir_prob = ODEProblem(seir_ode,init,tspan,pram)\n\n    sol=solve(seir_prob);\nend\n\n# sweep over population growth rates\nfunction scalegrowth(λ=1.0)\n    # ctx.metadata holds our new parameter\n    ctx = Dubstep.GraftCtx(metadata=Dict(:lambda=>λ))\n    return Cassette.overdub(ctx, g)\nend\n\nprintln(\"S\\tI\\tR\")\nfor λ in [1.0,1.1,1.2]\n    @time S,I,R = scalegrowth(λ)(365)\n    println(\"$S\\t$I\\t$R\")\nendIt works! We can see that increasing the population growth causes a larger infected and recovered population at the end of 1 year."
},

{
    "location": "dubstep/#SemanticModels.Dubstep.GraftCtx",
    "page": "Dubstep",
    "title": "SemanticModels.Dubstep.GraftCtx",
    "category": "type",
    "text": "GraftCtx\n\ngrafts an expression from one simulation onto another\n\nThis context is useful for modifying simulations by changing out components to add features\n\nsee also: Dubstep.LPCtx\n\n\n\n\n\n"
},

{
    "location": "dubstep/#SemanticModels.Dubstep.LPCtx",
    "page": "Dubstep",
    "title": "SemanticModels.Dubstep.LPCtx",
    "category": "type",
    "text": "LPCtx\n\nreplaces all calls to LinearAlgebra.norm with a different p.\n\nThis context is useful for modifying statistical codes or machine learning regularizers.\n\n\n\n\n\n"
},

{
    "location": "dubstep/#SemanticModels.Dubstep.TraceCtx",
    "page": "Dubstep",
    "title": "SemanticModels.Dubstep.TraceCtx",
    "category": "type",
    "text": "TraceCtx\n\nbuilds dynamic analysis traces of a model for information extraction\n\n\n\n\n\n"
},

{
    "location": "dubstep/#SemanticModels.Dubstep.TracedRun",
    "page": "Dubstep",
    "title": "SemanticModels.Dubstep.TracedRun",
    "category": "type",
    "text": "TracedRun{T,V}\n\ncaptures the dataflow of a code execution. We store the trace and the value.\n\nsee also trace.\n\n\n\n\n\n"
},

{
    "location": "dubstep/#SemanticModels.Dubstep.replacefunc-Tuple{Function,AbstractDict}",
    "page": "Dubstep",
    "title": "SemanticModels.Dubstep.replacefunc",
    "category": "method",
    "text": "replacefunc(f::Function, d::AbstractDict)\n\nrun f, but replace every call to f using the context GraftCtx. in order to change the behavior you overload overdub based on the context. Metadata used to influence the context is stored in d.\n\nsee also: bin/graft.jl for an example.\n\n\n\n\n\n"
},

{
    "location": "dubstep/#SemanticModels.Dubstep.replacenorm-Tuple{Function,AbstractDict}",
    "page": "Dubstep",
    "title": "SemanticModels.Dubstep.replacenorm",
    "category": "method",
    "text": "replacenorm(f::Function, d::AbstractDict)\n\nrun f, but replace every call to norm using the mapping in d.\n\n\n\n\n\n"
},

{
    "location": "dubstep/#SemanticModels.Dubstep.trace-Tuple{Function}",
    "page": "Dubstep",
    "title": "SemanticModels.Dubstep.trace",
    "category": "method",
    "text": "trace(f)\n\nrun the function f and return a TracedRun containing the trace and the output.\n\n\n\n\n\n"
},

{
    "location": "dubstep/#Reference-1",
    "page": "Dubstep",
    "title": "Reference",
    "category": "section",
    "text": "Modules = [SemanticModels.Dubstep]"
},

{
    "location": "graph/#",
    "page": "Knowledge Graphs",
    "title": "Knowledge Graphs",
    "category": "page",
    "text": ""
},

{
    "location": "graph/#Knowledge-Graphs-1",
    "page": "Knowledge Graphs",
    "title": "Knowledge Graphs",
    "category": "section",
    "text": "We use MetaGraphs.jl MetaDiGraphs to represent the knowledge we have extracted from code and text. "
},

{
    "location": "graph/#Schema-1",
    "page": "Knowledge Graphs",
    "title": "Schema",
    "category": "section",
    "text": "To construct our knowledge graph, we have developed a schema with defined vertex and edge types; the metadata associated with a given vertex or edge will depend on its type. The diagram below visually represents this schema:(Image: Schema Diagram)"
},

{
    "location": "graph/#Vertex-Types-1",
    "page": "Knowledge Graphs",
    "title": "Vertex Types",
    "category": "section",
    "text": "using CSV\nusing Latexify\ndf = CSV.read(\"../../examples/knowledge_graph/data/kg_vertex_types.csv\")\nmdtable(df,latex=false)"
},

{
    "location": "graph/#Edge-Types-1",
    "page": "Knowledge Graphs",
    "title": "Edge Types",
    "category": "section",
    "text": "using CSV\nusing Latexify\ndf = CSV.read(\"../../examples/knowledge_graph/data/kg_edge_types.csv\")\nmdtable(df,latex=false)Since those types are abstract, here are some examples that should make clear what is happening."
},

{
    "location": "graph/#Example-Vertices-1",
    "page": "Knowledge Graphs",
    "title": "Example Vertices",
    "category": "section",
    "text": "using CSV\nusing Latexify\ndf = CSV.read(\"../../examples/knowledge_graph/data/kg_vertices.csv\")\nmdtable(df,latex=false)"
},

{
    "location": "graph/#Example-Edges-1",
    "page": "Knowledge Graphs",
    "title": "Example Edges",
    "category": "section",
    "text": "using CSV\nusing Latexify\ndf = CSV.read(\"../../examples/knowledge_graph/data/synth_kg_edges.csv\")\nmdtable(df,latex=false)"
},

{
    "location": "graph/#SemanticModels.Graphs.copy_input_graph_to_new_graph-Tuple{MetaGraphs.MetaDiGraph}",
    "page": "Knowledge Graphs",
    "title": "SemanticModels.Graphs.copy_input_graph_to_new_graph",
    "category": "method",
    "text": "copy_input_graph_to_new_graph(input_graph::MetaDiGraph)\n\nHelper function that instantiates a new MetaDiGraph and inserts vertices/edges from an (existing) input graph.\n\nsee also: insert_edges_from_jl\n\n\n\n\n\n"
},

{
    "location": "graph/#SemanticModels.Graphs.gen_rand_vertex_name",
    "page": "Knowledge Graphs",
    "title": "SemanticModels.Graphs.gen_rand_vertex_name",
    "category": "function",
    "text": "gen_rand_vertex_name(vertex_type::String, tag::String)\n\nThis function outputs a vertex name that reflects the provided type and tag, and includes a random component to ensure uniqueness.\n\nsee also: Graphs.generate_synthetic_vertices, gen_vertex_hash\n\n\n\n\n\n"
},

{
    "location": "graph/#SemanticModels.Graphs.gen_vertex_hash-Tuple{String,String}",
    "page": "Knowledge Graphs",
    "title": "SemanticModels.Graphs.gen_vertex_hash",
    "category": "method",
    "text": "gen_vertex_hash(vertex_name::String, vertex_type::String)\n\nThis function computes the hash of a vertex\'s name and type; this combination is assumed to be unique within the graph.\n\nsee also: generate_synthetic_vertices, gen_rand_vertex_name\n\n\n\n\n\n"
},

{
    "location": "graph/#SemanticModels.Graphs.generate_synthetic_edges-Tuple{String,DataFrames.DataFrame,String}",
    "page": "Knowledge Graphs",
    "title": "SemanticModels.Graphs.generate_synthetic_edges",
    "category": "method",
    "text": "generate_synthetic_edges(edge_type_defs::String, synth_vertex_df::DataFrame, output_path::String)\n\nGenerate synthetic test data. The synthetic edges are returned as a dataframe that can be used for testing/debugging/developing the knowledge graph.\n\nsee also: generate_synthetic_vertices\n\n\n\n\n\n"
},

{
    "location": "graph/#SemanticModels.Graphs.generate_synthetic_vertices-Tuple{String,String}",
    "page": "Knowledge Graphs",
    "title": "SemanticModels.Graphs.generate_synthetic_vertices",
    "category": "method",
    "text": "generate_synthetic_vertices(vertex_type_defs::String, output_path::String)\n\nGenerate synthetic test data. The synthetic vertices are returned as a dataframe that can be used for testing/debugging/developing the knowledge graph.\n\nsee also: generate_synthetic_edges\n\n\n\n\n\n"
},

{
    "location": "graph/#SemanticModels.Graphs.insert_edges_from_jl-Tuple{DataFrames.DataFrame,MetaGraphs.MetaDiGraph}",
    "page": "Knowledge Graphs",
    "title": "SemanticModels.Graphs.insert_edges_from_jl",
    "category": "method",
    "text": "insert_edges_from_jl(edges_file::String, input_graph::MetaDiGraph)\n\nTakes as input an existing graph and an edge file. Each edge in the file is either inserted (if new) or (if already in G), an associated integer weight is incremented.\n\nsee also: insert_vertices_from_jl, copy_input_graph_to_new_graph\n\n\n\n\n\n"
},

{
    "location": "graph/#SemanticModels.Graphs.insert_edges_from_jl-Tuple{String,MetaGraphs.MetaDiGraph}",
    "page": "Knowledge Graphs",
    "title": "SemanticModels.Graphs.insert_edges_from_jl",
    "category": "method",
    "text": "insert_edges_from_jl(edges_file::String, input_graph::MetaDiGraph)\n\nTakes as input an existing graph and an edge file. Each edge in the file is either inserted (if new) or (if already in G), an associated integer weight is incremented.\n\nsee also: insert_vertices_from_jl, copy_input_graph_to_new_graph\n\n\n\n\n\n"
},

{
    "location": "graph/#SemanticModels.Graphs.insert_vertices_from_jl-Tuple{String,MetaGraphs.MetaDiGraph}",
    "page": "Knowledge Graphs",
    "title": "SemanticModels.Graphs.insert_vertices_from_jl",
    "category": "method",
    "text": "insert_vertices_from_jl(vertices_file::String, input_graph::MetaDiGraph)\n\nIngests and evaulates a Julia file containing vertex information; instantiates an empty knowledge graph and inserts each unique vertex into this graph.\n\nsee also: insert_edges_from_jl\n\n\n\n\n\n"
},

{
    "location": "graph/#SemanticModels.Graphs.insert_vertices_from_jl-Tuple{String,Nothing}",
    "page": "Knowledge Graphs",
    "title": "SemanticModels.Graphs.insert_vertices_from_jl",
    "category": "method",
    "text": "insert_vertices_from_jl(vertices_file::String, input_graph::Nothing)\n\nIngests and evaulates a Julia file containing vertex information; instantiates an empty knowledge graph and inserts each unique vertex into this graph.\n\nsee also: insert_edges_from_jl\n\n\n\n\n\n"
},

{
    "location": "graph/#SemanticModels.Graphs.load_graph_data-Tuple{Any}",
    "page": "Knowledge Graphs",
    "title": "SemanticModels.Graphs.load_graph_data",
    "category": "method",
    "text": "load_graph_data(input_data::Array{Any,1})\n\nHelper function that allows a synthetic set of vertices or edges to be represented as an array for the purpose of serialization.\n\n\n\n\n\n"
},

{
    "location": "graph/#API-reference-1",
    "page": "Knowledge Graphs",
    "title": "API reference",
    "category": "section",
    "text": "Modules = [SemanticModels.Graphs]"
},

{
    "location": "extraction/#",
    "page": "Knowledge Extraction",
    "title": "Knowledge Extraction",
    "category": "page",
    "text": ""
},

{
    "location": "extraction/#Knowledge-Extraction-1",
    "page": "Knowledge Extraction",
    "title": "Knowledge Extraction",
    "category": "section",
    "text": ""
},

{
    "location": "extraction/#Documents-1",
    "page": "Knowledge Extraction",
    "title": "Documents",
    "category": "section",
    "text": "SemanticModels.jl takes the opinion that the source code and documentation is more valuable than the scientific papers themselves, even though traditional scientific incentive systems focus on only the papers.Since natural language text is primarily being used for context, understanding, and disambiguation of code information, we use rules-based methods to extract definitions and conceptual connections. The Automates framework developed at the University of Arizona is very helpful for writing rules-based information extraction software. We have made upstream contributions to the Automates repository.The primary focus of this document is the extraction of scientific knowledge from codebases. We start by describing the natural language information extraction pipeline."
},

{
    "location": "extraction/#Information-Extraction-for-Semantic-Modeling-1",
    "page": "Knowledge Extraction",
    "title": "Information Extraction for Semantic Modeling",
    "category": "section",
    "text": "To select knowledge elements that should be present in knowledge graphs, we conduct information extraction on various components of our source files, including:Scientist/programmer-contributed comments within source code files.\nCode phenomena such as function names, parameters, and values.Ongoing work involves building extractors for:Research publications.\nDocumentation for libraries and frameworks utilized within the domains of epidemiology and information diffusion."
},

{
    "location": "extraction/#Information-Extraction-Pipeline-1",
    "page": "Knowledge Extraction",
    "title": "Information Extraction Pipeline",
    "category": "section",
    "text": "Process source files including research papers, source code, and documentation files into plain text or JSON document formats.\nExtract natural language text such as docstrings and comments.\nParse source code with to identify function names and parameters.\nMatch modeling text concepts with code variables using lexical-tokens.\nRun Automates rule-based extraction on the text associated with each code concept.\nCreate knowledge elements (e.g., vertices and edges) from the tuples associated with rule matches.SemanticModels has created rules to extract phenomena such as definitions of parameters. These same parameters can then be recognized within source code, beginning with lexical matching for mapping human language definitions to specific source code instantiations.We are currently in the process of collecting and annotating ground truth data to use in constructing machine learning models to do information extractions based on information elements of interest that we identify in use case planning for  meta-modeling related functionalities users will be able to work with."
},

{
    "location": "extraction/#Code-1",
    "page": "Knowledge Extraction",
    "title": "Code",
    "category": "section",
    "text": "SemanticModels currently supports extracting knowledge from the static syntactic level information that is accessible from the source code. We use the same Julia code parser as the julia program.This parser takes text representations of Julia code and returns an abstract syntax tree (AST). We then walk this AST looking for Julia program expressions that create information. For example, function definitions, variable assignments and module imports. We recurse into the function definitions to find the local variable definitions (and closures) used in implementing the functions. This form of static program analysis provides a more direct way to access user defined functions. However it cannot access the type information and run time values. For this we use Cassette.jl, which is a library for context-dependent execution. SemanticModels uses a custom compiler pass to access code infomation and extract information at compile time. In addition, we use the overdub component of Cassette to build a tracer for capturing run time values. Since Julia syntax is very regular and metaprogramming is a standard (albeit advanced) practice in the Julia community, the syntax trees and CodeInfo objects are designed to be manipulated programmatically, which makes writing recursive generic syntax extraction rules straightforward."
},

{
    "location": "extraction/#Example-1",
    "page": "Knowledge Extraction",
    "title": "Example",
    "category": "section",
    "text": "We can read in the file examples/epicookbook/notebooks/KeelingRohani/SISModel.jlusing DifferentialEquations\n\n# # Model Specifications\n# - SH num of high risk susceptible\n# - IH num of high risk infected \n# - SL num of low risk susceptible\n# - IL num of low risk infected\n# # Parameters\n# - beta represents the determines the contact and transmission rates\n# - gamma the rate at which treatment is sought\n\nfunction sis_ode(du,u,p,t)\n        SH,IH,SL,IL = u\n        betaHH,betaHL,betaLH,betaLL,gamma=p\n        du[1]=-(betaHH*IH+betaHL*IL)*SH+gamma*IH\n        du[2]=+(betaHH*IH+betaHL*IL)*SH-gamma*IH\n        du[3]=-(betaLH*IH+betaLL*IL)*SL+gamma*IL\n        du[4]=+(betaLH*IH+betaLL*IL)*SL-gamma*IL\nend\n\nparms =[10,0.1,0.1,1,1]\ninit=[0.19999,0.00001,0.799,0.001]\ntspan=tspan = (0.0,15.0)\n\nsis_prob = ODEProblem(sis_ode,init,tspan,parms)\nsis_sol = solve(sis_prob,saveat=0.1);\n\nusing Plots\nplot(sis_sol,xlabel=\"Time (Years)\",ylabel=\"Proportion of Population\")and run it through the code syntactic extractor, which will produce the following information:┌ Info: script uses modules\n│   modules =\n│    2-element Array{Any,1}:\n│     Any[:DifferentialEquations]\n└     Any[:Plots]\n\n┌ Info: script defines functions\n│   funcs =\n│    1-element Array{Any,1}:\n│     :(sis_ode(du, u, p, t)) => quote\n│        #= none:28 =#\n│        (SH, IH, SL, IL) = u\n│        #= none:29 =#\n│        (betaHH, betaHL, betaLH, betaLL, gamma) = p\n│        #= none:30 =#\n│        du[1] = -((betaHH * IH + betaHL * IL)) * SH + gamma * IH\n│        #= none:31 =#\n│        du[2] = +((betaHH * IH + betaHL * IL)) * SH - gamma * IH\n│        #= none:32 =#\n│        du[3] = -((betaLH * IH + betaLL * IL)) * SL + gamma * IL\n│        #= none:33 =#\n│        du[4] = +((betaLH * IH + betaLL * IL)) * SL - gamma * IL\n└    end\n\n┌ Info: script defines glvariables\n│   funcs =\n│    5-element Array{Any,1}:\n│        :parms => :([10, 0.1, 0.1, 1, 1])\n│         :init => :([0.19999, 1.0e-5, 0.799, 0.001])\n│        :tspan => :(tspan = (0.0, 15.0))\n│     :sis_prob => :(ODEProblem(sis_ode, init, tspan, parms))\n└      :sis_sol => :(solve(sis_prob, saveat=0.1))\n\n┌ Info: sis_ode(du, u, p, t) uses modules\n└   modules = 0-element Array{Any,1}\n┌ Info: sis_ode(du, u, p, t) defines functions\n└   funcs = 0-element Array{Any,1}\n┌ Info: sis_ode(du, u, p, t) defines glvariables\n│   funcs =\n│    6-element Array{Any,1}:\n│                            :((SH, IH, SL, IL)) => :u\n│     :((betaHH, betaHL, betaLH, betaLL, gamma)) => :p\n│                                       :(du[1]) => :(-((betaHH * IH + betaHL * IL)) * SH + gamma * IH)\n│                                       :(du[2]) => :(+((betaHH * IH + betaHL * IL)) * SH - gamma * IH)\n│                                       :(du[3]) => :(-((betaLH * IH + betaLL * IL)) * SL + gamma * IL)\n└                                       :(du[4]) => :(+((betaLH * IH + betaLL * IL)) * SL - gamma * IL)\n┌ Info: Edges found\n└   path = \"examples/epicookbook/notebooks/KeelingRohani/SISModel.jl\"\n(:Modeling, :takes, :parms, :([10, 0.1, 0.1, 1, 1]))\n(:Modeling, :has, :parms, :prop_collection)\n(:Modeling, :takes, :init, :([0.19999, 1.0e-5, 0.799, 0.001]))\n(:Modeling, :has, :init, :prop_collection)\n(:Modeling, :structure, :tspan, :((0.0, 15.0)))\n(:Modeling, :comp, :tspan, 0.0)\n(:Modeling, :comp, :tspan, 15.0)\n(:Modeling, :output, :sis_prob, :(ODEProblem(sis_ode, init, tspan, parms)))\n(:Modeling, :input, :sis_ode, Symbol[:init, :tspan, :parms])\n(:Modeling, :output, :sis_sol, :(solve(sis_prob, saveat=0.1)))\n(:Modeling, :input, :sis_prob, Symbol[Symbol(\"saveat=0.1\")])\n(\"Modeling.sis_ode(du, u, p, t)\", :destructure, :((SH, IH, SL, IL)), :u)\n(\"Modeling.sis_ode(du, u, p, t)\", :comp, :u, :SH)\n(\"Modeling.sis_ode(du, u, p, t)\", :comp, :u, :IH)\n(\"Modeling.sis_ode(du, u, p, t)\", :comp, :u, :SL)\n(\"Modeling.sis_ode(du, u, p, t)\", :comp, :u, :IL)\n(\"Modeling.sis_ode(du, u, p, t)\", :destructure, :((betaHH, betaHL, betaLH, betaLL, gamma)), :p)\n(\"Modeling.sis_ode(du, u, p, t)\", :comp, :p, :betaHH)\n(\"Modeling.sis_ode(du, u, p, t)\", :comp, :p, :betaHL)\n(\"Modeling.sis_ode(du, u, p, t)\", :comp, :p, :betaLH)\n(\"Modeling.sis_ode(du, u, p, t)\", :comp, :p, :betaLL)\n(\"Modeling.sis_ode(du, u, p, t)\", :comp, :p, :gamma)\n(\"Modeling.sis_ode(du, u, p, t)\", :output, :(du[1]), :(-((betaHH * IH + betaHL * IL)) * SH + gamma * IH))\n(\"Modeling.sis_ode(du, u, p, t)\", :input, :(-((betaHH * IH + betaHL * IL)) * SH), Symbol[Symbol(\"gamma * IH\")])\n(\"Modeling.sis_ode(du, u, p, t)\", :output, :(du[2]), :(+((betaHH * IH + betaHL * IL)) * SH - gamma * IH))\n(\"Modeling.sis_ode(du, u, p, t)\", :input, :(+((betaHH * IH + betaHL * IL)) * SH), Symbol[Symbol(\"gamma * IH\")])\n(\"Modeling.sis_ode(du, u, p, t)\", :output, :(du[3]), :(-((betaLH * IH + betaLL * IL)) * SL + gamma * IL))\n(\"Modeling.sis_ode(du, u, p, t)\", :input, :(-((betaLH * IH + betaLL * IL)) * SL), Symbol[Symbol(\"gamma * IL\")])\n(\"Modeling.sis_ode(du, u, p, t)\", :output, :(du[4]), :(+((betaLH * IH + betaLL * IL)) * SL - gamma * IL))\n(\"Modeling.sis_ode(du, u, p, t)\", :input, :(+((betaLH * IH + betaLL * IL)) * SL), Symbol[Symbol(\"gamma * IL\")])This extractor provides edges to the Knowledge Graphs. Once the extraction is complete, the knowledge graph can be stored and transmitted to scientists across many disciplines. These knowledge graphs are a compact representation of the code and text. As new papers and codes are written, they can be ingested into an online graph database providing access to many scholars."
},

{
    "location": "extraction/#Reconciliation-and-Disambiguation-1",
    "page": "Knowledge Extraction",
    "title": "Reconciliation and Disambiguation",
    "category": "section",
    "text": "As our information extraction pipeline outlined above illustrates, the task of knowledge graph construction implicitly requires us to either assert or infer a crosswalk between (1) vertices extracted from text and vertices extracted from code with a common higher-level source (e.g., a published paper that is associated with source code that also includes comments); and (2) vertices (and by extension, edges) that are already present in the graph, when the combined information conveyed by the user-provided vertex name, and provided/inferred vertex type is not a sufficient guarantee of uniqueness, and/or a reliable signal of user intent (e.g., the user may seek to (1) enforce uniqueness by differentiating a new vertex, v_i, from lexically identical but semantically different vertices in V, or (2) insert v_i iff V cap_semantic v_i = emptyset, regardless of their lexical (dis)similarity).When two or more knowledge artifacts share provenance (e.g., the narrative text, programmer-provided comments, and source code that, when taken in tandem, represent a single recipe in the Epicookbook), we currently consider code text and markdown/comments text as strings, and use rule based learning to associate text with code objects; these lexical matches are then parsed in an effort to extract edges of the type representation (abbreviated repr), which connect a (code) type source vertex to a (scientific) concept destination vertex.We intend to extend this approach in the future by: (1) creating new syntactical parsing rules to capture additional relationships; (2) considering the ways in which information related to scope, and/or position within the program-level call graph can be informative for the purpose of co-reference resolution; and/or (3) representing both sources of text sequences as real-valued vectors, to determine whether cosine similarity and/or RNN-based approaches can help to detect co-referential lexical elements [1].With respect to the question of how to best assess/resolve ambiguity surrounding the uniqueness of a vertex upon ingestion, we currently guarantee uniqueness by appending a randomly generated string to the concatenation of the (raw-text) vertex name and the (schema-consistent) vertex type. This approach biases the graph toward smaller, disconnected subgraphs, and makes it harder for us to benefit from the semantic equivalence that often exists when different text and/or code artifacts from the same domain are parsed for the purpose of ingestion.We intend to develop a more nuanced approach to vertex ingestion that incorporates exogenous, domain-specific information (for example, a lookup table of parameters that are commonly used within the epidemiological literature; known model imports, etc.). We can begin by manually constructing a dataset with examples of how these known elements are represented in code, and can then train an NER model to detect such references when they occur, so that we can avoid insertion of lexically distinct but (fuzzily) semantically equivalent vertices and encourage semantically meaningful consolidation, resulting in a more connected, parsimonious graph.We may also find it helpful to leverage user-provided metadata (such as source/provenance information), and/or unsupervised learning techniques, including clustering methods, for this task as the complexity of the graph grows, and/or knowledge artifacts from additional domains with potentially conflicting named entities are introduced. We may also find it helpful to compare the semantic saliency of the (graph-theoretic) neighborhood(s) that might result from either the source or destination vertex of a new edge being mapped to each of a set of feasible existing vertices; this approach could also benefit from provenance-related metadata."
},

{
    "location": "extraction/#Reasoning-1",
    "page": "Knowledge Extraction",
    "title": "Reasoning",
    "category": "section",
    "text": "Once the information is extracted from the documentation and code, we can visualize the knowledge as a graph.(Image: Knowledge Graph from epicookbook)This knowledge graph contains all the connections we need to combine components across models. Once can view this combination as either a modification of one model by substituting components of another model, or as the automatic generation of a metamodel by synthesizing components from the knowledge graph into a single coherent model. Further theoretical analysis of metamodeling and model modification as mathematical problems is warranted to make these categories unambiguous and precisely defined.Once we identify a subgraph of related components we can identify the graft point between the two models. We look for a common variable that is used in two models, specifically in a derivative calculation. We find the variable S which appears in dS and dY (as S=Y[1] and dY = derivative(Y)). The knowledge that dS, dY are derivatives comes from the background knowledge of modeling that comes from reading textbooks and general scientific knowledge, while the fact that S and Y[1] both appear in an expression mu-beta*S*I - mu*S comes from the specific documents and codebases under consideration by the metamodeler.(Image: Knowledge Subgraph showing model modification)This subgraph must then extend out to capture all of the relevant information such as the parameter sets encountered, the function calls that contain these variables and expressions. We have found the largest relevant subgraph for some unspecified definition of relevance. From this subgraph, a human modeler can easily instruct the SemanticModels system on how to combine the SEIRmodel and ScalingModel programs into a single model and generate a program to execute it.In order to move beyond this relatively manual approach to model modification and metamodeling, it is helpful to frame each of our intended use cases as an optimization problem, in which the scientist\'s required unitful input(s) and/or unitful output(s) (including expected deviation from observed/expected patterns, in the case of model validation) can be formally expressed as constraints, and relevance can be objectively and quantifiably represented, so that competing feasible flows can be assessed, ranked, and returned to the scientist to augment their understanding. The specification of the objective function, choice of traversal algorithm(s), and the use of edge weights to convey algorithmically meaningful information, will vary by use case.For example, the metamodeling use case, in which the scientist begins with a vector of known unitful input and a vector of unitful output whose value is unknown, can be formulated as an s-t max flow problem, with our input vertex as s, our output vertex as t, and edge weights corresponding to the frequency with which a given edge is empirically observed within a domain-specific text and code corpus. To ensure tractability at scale, we may want to consider a weighting scheme to avoid integer constraints. This approach may also help us to identify disconnected subgraphs, which, if linked by cut-crossing edges, would represent a feasible flow; the scientific insight here is that such a set of edges might represent \"missing\" functions capable of transforming the \"input\" src vertex of a cut-crossing edge with its output dst vertex. These function(s) could then be ingested or written by scientists.While we intend to proceed with algorithmic development of this nature in the near term, it\'s worth noting that the goal of this project is to augment scientists and their workflows. As such, we envision a human-in-the-loop, semi-automated approach, in which the scientist is in control and has the ability to instruct the machine by providing information about what the scientist already knows, and what they wish to do with that knowledge (e.g., modify, combine, validate) existing models and scripts. Any API that supports augmenting scientists will require some human intervention in the reasoning and generation stages as the system must get input from the user as to the questions being asked of it. We view this to analogous to a data analyst working with a database system: a query planning system is able to optimize queries based on knowledge about the schema and data statistics, but it must still wait for a human to provide a query. In this way, even as our development efforts proceed, SemanticModels will rely upon user guidance for reasoning and generation tasks."
},

{
    "location": "extraction/#SemanticModels.Parsers.AbstractCollector",
    "page": "Knowledge Extraction",
    "title": "SemanticModels.Parsers.AbstractCollector",
    "category": "type",
    "text": "AbstractCollector\n\nsubtypes of AbstractCollector support extracting and collecting information from input sources.\n\n\n\n\n\n"
},

{
    "location": "extraction/#SemanticModels.Parsers.FuncCollector",
    "page": "Knowledge Extraction",
    "title": "SemanticModels.Parsers.FuncCollector",
    "category": "type",
    "text": "FuncCollector{T} <: AbstractCollector\n\ncollects function definitions and names\n\n\n\n\n\n"
},

{
    "location": "extraction/#SemanticModels.Parsers.MetaCollector",
    "page": "Knowledge Extraction",
    "title": "SemanticModels.Parsers.MetaCollector",
    "category": "type",
    "text": "MetaCollector{T,U,V,W} <: AbstractCollector\n\ncollects multiple pieces of information such as\n\nexprs: expressions\nfc: functions\nvc: variable assignments\nmodc: module imports\n\n\n\n\n\n"
},

{
    "location": "extraction/#SemanticModels.Parsers.defs-Tuple{Any}",
    "page": "Knowledge Extraction",
    "title": "SemanticModels.Parsers.defs",
    "category": "method",
    "text": "defs(body)\n\ncollect the function definitions and variable assignments from a module expression.\n\n\n\n\n\n"
},

{
    "location": "extraction/#SemanticModels.Parsers.findassign-Tuple{Expr,Symbol}",
    "page": "Knowledge Extraction",
    "title": "SemanticModels.Parsers.findassign",
    "category": "method",
    "text": "findassign(expr::Expr, name::Symbol)\n\nfindassign walks the AST of expr to find the assignments to a variable called name.\n\nThis function returns a reference to the original expression so that you can modify it inplace and is intended to help users rewrite expressions for generating new models.\n\nSee also: findfunc.\n\n\n\n\n\n"
},

{
    "location": "extraction/#SemanticModels.Parsers.findfunc-Tuple{Expr,Symbol}",
    "page": "Knowledge Extraction",
    "title": "SemanticModels.Parsers.findfunc",
    "category": "method",
    "text": "findfunc(expr::Expr, name::Symbol)\n\nfindfunc walks the AST of expr to find the definition of function called name.\n\nThis function returns a reference to the original expression so that you can modify it inplace and is intended to help users rewrite the definitions of functions for generating new models.\n\n\n\n\n\n"
},

{
    "location": "extraction/#SemanticModels.Parsers.funcs-Tuple{Any}",
    "page": "Knowledge Extraction",
    "title": "SemanticModels.Parsers.funcs",
    "category": "method",
    "text": "funcs(body)\n\ncollect the function definitions from a module expression.\n\n\n\n\n\n"
},

{
    "location": "extraction/#SemanticModels.Parsers.inexpr-Tuple{Any,Any}",
    "page": "Knowledge Extraction",
    "title": "SemanticModels.Parsers.inexpr",
    "category": "method",
    "text": "inexpr(expr, x)\n\nSimple expression match; will return true if the expression x can be found inside expr.     inexpr(:(2+2), 2) == true\n\n\n\n\n\n"
},

{
    "location": "extraction/#SemanticModels.Parsers.parsefile",
    "page": "Knowledge Extraction",
    "title": "SemanticModels.Parsers.parsefile",
    "category": "function",
    "text": "parsefile(path)\n\nread in a julia source file and parse it.\n\nNote: If the top level is not a simple expression or module definition the file is wrapped in a Module named modprefix.\n\n\n\n\n\n"
},

{
    "location": "extraction/#SemanticModels.Parsers.postwalk-Tuple{Any,Any}",
    "page": "Knowledge Extraction",
    "title": "SemanticModels.Parsers.postwalk",
    "category": "method",
    "text": "postwalk(f, expr)\n\nApplies f to each node in the given expression tree, returning the result. f sees expressions after they have been transformed by the walk. See also prewalk.\n\n\n\n\n\n"
},

{
    "location": "extraction/#SemanticModels.Parsers.prewalk-Tuple{Any,Any}",
    "page": "Knowledge Extraction",
    "title": "SemanticModels.Parsers.prewalk",
    "category": "method",
    "text": "prewalk(f, expr)\n\nApplies f to each node in the given expression tree, returning the result. f sees expressions before they have been transformed by the walk, and the walk will be applied to whatever f returns. This makes prewalk somewhat prone to infinite loops; you probably want to try postwalk first.\n\n\n\n\n\n"
},

{
    "location": "extraction/#API-reference-1",
    "page": "Knowledge Extraction",
    "title": "API reference",
    "category": "section",
    "text": "Modules = [SemanticModels.Parsers][1]: https://arxiv.org/abs/1803.09473"
},

{
    "location": "validation/#",
    "page": "Validation",
    "title": "Validation",
    "category": "page",
    "text": ""
},

{
    "location": "validation/#Model-Validation-with-Dynamic-Analysis-1",
    "page": "Validation",
    "title": "Model Validation with Dynamic Analysis",
    "category": "section",
    "text": "Validation of scientific models is a type of program verification, but is complicated by the fact that there are no global explicit rules about what defines a valid scientific models. In a local sense many disciplines of science have developed rules for valid computations. For example unit checking and dimensional analysis and conservation of physical laws. Dimensional analysis provides rules for arithmetic of unitful numbers. The rules of dimensional analysis are \"you can add numbers if the units match, when you multiply/divide, the powers of the units add/subtract.\" Many physical computations obey conservation rules that provide a form of program verification. Based on a law of physics such as \"The total mass of the system is constant,\" one can build a program checker that instruments a program with the ability to audit the fact that sum(mass, system[t]) == sum(mass, system[t0]), these kinds of checks may be expressed in codes.We can use Cassette.jl to implement a context for validating these computations. The main difficulty is converting the human language expressed rule into a mathematical test for correctness. A data driven method is outlined below."
},

{
    "location": "validation/#DeepValidate-1",
    "page": "Validation",
    "title": "DeepValidate",
    "category": "section",
    "text": "There are an intractable number of permutations of valid deep learning model architectures, each providing different levels of performance (both in terms of efficiency and accuracy of output) on different datasets. One current predicament in the field is an inability to rigorously define an optimal architecture starting from the types of inputs and outputs; preferred solutions are instead chosen based on empirical processes of trial and error. In light of this, it has become common to start deep learning model efforts from architectures established by previous research, especially ones which have been adopted by a significant portion of the deep learning community, for similar tasks, and then tweak and modify hyper parameters as necessary. We adopt this typical approach, beginning with a standard architecture and leaving open the possibility of optimizing the architecture as training progresses. Given that our deep learning task in this instance is relatively straightforward and supportive of the overall thrust of this project rather than central to it, we adopt a common and well tested <a href=\'http://www.bioinf.jku.at/publications/older/2604.pdf\'>long short-term memory</a> (LSTM) recurrent neural network (RNN) architecture for our variable-length sequence classification task. LSTM models have a rich history of success in complex natural language processing tasks, specifically where <a href=\'https://towardsdatascience.com/how-to-create-data-products-that-are-magical-using-sequence-to-sequence-models-703f86a231f8\'>comprehension</a> and classification of computer programming code is concernd, and they remain the most popular and <a href=\'https://www.microsoft.com/en-us/research/wp-content/uploads/2016/04/Intent.pdf\'>effective</a> approach to these tasks. Our base model will use binary cross entropy as its cost function given our task is one of binary classification, and an Adam optimizer for training optimization. Introduced in 2014, the <a href=\'https://arxiv.org/abs/1412.6980\'>Adam</a> optimization algorithm generally remains the most robust and efficient back propagation optimization method in deep learning. Input traces are first tokenized as indices representing specific functions, variables, and types in vocabularies compiled from our modeling corpus, while values are passed as is. These sequences are fed in to a LSTM layer which reads each token/value in sequence and calculates activations on them, while also passing values ahead in the chain subject to functions which either pass, strengthen or “forget” the memory value. As mentioned, this LSTM RNN model will be written using Julia’s Flux.jl package, and a preliminary outline is provided below:model = Chain(\n  LSTM(128, 256, X),\n  Dropout(0.5),\n  Dense(768, 128),\n  BatchNormalization(),\n  Dropout(0.5),\n  Dense(768, 2),\n  BatchNormalization(),\n  softmax)\n\nloss(X, Y) = crossentropy(model(X), Y)\n\nFlux.train!(loss, data, ADAM(...))In the above example, outputs of the LSTM layer are subject to 50% dropout as a regularization measure to avoid over-fitting, and then fed to a densely connected neural network layer for computation of non-linear feature functions. Outputs of this dense layer are normalized for each batch of training data as another regularization measure to constrict extreme weights. This sequence of dropout-dense-normalization layers is repeated once more to add depth to the non-linear features learned by the model. Finally, a softmax activation function is calculated on the outputs and a binary classification is completed on each case in our dataset. To train this DeepValidate model, we execute the following steps:Collect a sample of known “good” inputs matched with their corresponding “good” outputs, and a sample of known “bad” inputs matched with their corresponding “bad” outputs.\n“Good” here is defined as: given these input(s), the model output(s)/prediction(s) correspond to expected or observedempirical reality, within an acceptable error tolerance.     + Edge cases to note but not heavily consider at this point:         1. For “good” input to “bad” output, we can just corrupt the “good” inputs at various points along the computation.         1. If assumption that code is correct and does not contain bugs holds, then it is ok to assume we will not observe “bad” input to “good” output. Run the simulation to collect a sample of known good outputs.\nInstrument the code to log all SSA assignments from the function calls\nTrain an RNN on the sequence of [(func, var, val)...] where the labels are “good input vs bad input”\nBy definition, any SSA “sentence” generated by a known “good” input is assumed to be “good”; thus, these labels essentially propagate down. \nPartial evaluations of the RNN model and output can point to “where things went wrong.\" Specifically, layer-wise relevance propagation can be employed to identify the most powerful factors in input sequences, as well as their valence (good input, bad input) for case by case error analysis in deep learning models. This approach was effectively extended to LSTM RNN models by Arras et al. (http://www.aclweb.org/anthology/W17-5221) in 2017. In step 1: for an analytically tractable model, we can generate an arbitrarily large collection of known good and bad inputs."
},

{
    "location": "validation/#Required-Data-Format-1",
    "page": "Validation",
    "title": "Required Data Format",
    "category": "section",
    "text": "We need to build a Tensorflow.jl or Flux.jl RNN model that will work on sequences [(func, var, val, type)] and produce labels of good/badTraces will be communicated 1 trace per file\nEach line is a tuple module.func, var,val,type with quotes as necessary for CSV storage. \nThe files will be organized into folders program/{good,bad}/tracenumber.txt\nTraces will be variable length."
},

{
    "location": "validation/#Datasets-for-empirical-validation-1",
    "page": "Validation",
    "title": "Datasets for empirical validation",
    "category": "section",
    "text": "Observed empirical reality is represented in selected real world epidemiological datasets covering multiple collection efforts in different environments. These datasets have been identified as promising candidates for demonstrating how modeling choices can affect the quality of models and how ranges of variables can change when one moves between environments or contexts with the same types of data. To ensure a broad selection of types of epidemiological model options during examination of this data, we will combine key disease case data with various environmental data sources covering weather, demography, healthcare infrastructure, and travel patterns wherever possible. These datasets will be of varying levels of geographic and temporal granularity, but always at least monthly in order to model seasonal variations in infected populations. The validation datasets cover three main disease topics: 1.	Influenza cases in the United States: The Centers for Disease Control and Prevention (CDC) maintains publicly available data containing weekly influenza activity levels per state (https://gis.cdc.gov/grasp/fluview/fluportaldashboard.html). This weekly data is provided for all states from the 2010-2011 to 2018-2019 flu seasons, comprising over 23,000 rows with columns indicating percentage of influenza-like-illnesses, raw case count, number of providers and total numbers of patients for each state in each week of each year. A sample of the data is presented below for reference This data will be supplemented by monthly influenza vaccine reports provided by the CDC (https://www.cdc.gov/flu/fluvaxview/coverage-1718estimates.htm) for different age ranges (6 months – 4 years of age, 5-12 years of age, 13-17 years of age, 18-49 years of age, and 50 – 64 years of age). In addition, data is split by different demographic groups (Caucasian, African American and Hispanic). This data is downloaded directly into .csv dataset from the above cited webpage. For application to our weekly datasets, weekly values can be interpolated based on the monthly aggregates. <center>REGION YEAR WEEK %UNWEIGHTED ILI ILITOTAL NUM. OF PROVIDERS TOTAL PATIENTS\nAlabama 2010 40 2.13477 249 35 11664\nAlaska 2010 40 0.875146 15 7 1714\nArizona 2010 40 0.674721 172 49 25492</center>2.	Zika virus cases in the Americas: This data catalogues 108,000 reported cases of Zika, along with their report date and country/city (for geo-spatial location). This dataset is provided by the publicly available Zika Data Repository (https://github.com/cdcepi/zika) hosted on Github. One dozen countries throughout the Americas are included, as well as two separate Caribbean U.S. territories (Puerto Rico and U.S. Virgin Islands). A sample of the data is presented below for reference:<center>report_date location data_field value\n6/2/18 Mexico-Guanajuato weeklyzikaconfirmed 3\n6/2/18 Mexico-Guerrero weeklyzikaconfirmed 0\n6/2/18 Mexico-Hidalgo weeklyzikaconfirmed 5\n6/2/18 Mexico-Jalisco weeklyzikaconfirmed 21</center>3.	Dengue fever cases in select countries around the world: The Pan-American Health Organization reports weekly dengue fever case levels in 53 countries throughout the Americas and at sub-national geographic units in Brazil, covering years 2014-2019. This data is available at http://www.paho.org/data/index.php/en/mnu-topics/indicadores-dengue-en/dengue-nacional-en/252-dengue-pais-ano-en.html and a sample of the data is presented below for reference:<center>Geo Type Year Confirmed Deaths Week Incidence Rate Population X 1000 Severe Dengue Total Cases\nCuraçao  2018 0 0 52 0 162 0 0\nHonduras DEN 1,2,3 2018 Null 3 52 84.34 9,417 1,172 7,942\nArgentina DEN 1 2018 1,175 0 52 4.09 44,689 0 1,829\nAruba DEN 2018 75 Null 52 70.75 106 Null 75\nMexico DEN 1,2,3,4 2018 12,706 45 52 60.13 130,759 858 78,621</center>Our supplementary environmental datasets will be variably sourced depending on the target geographies, but will include: 1.	Weather: Historical weather data aggregated to the target geography and unit of time. This data is pulled directly from the Global Historical Climate Network (GHCN), an integrated database of climate summaries from land surface stations across the globe that have been subjected to a common suite of quality assurance reviews, and updated hourly. This database is maintained by the National Oceanic and Atmospheric Agency (NOAA) at https://www.ncdc.noaa.gov/data-access/land-based-station-data/land-based-datasets/global-historical-climatology-network-ghcn. A variety of weather and climate indicators are available, but for completeness of coverage and relevance, we will target high/low/mean temperatures and total precipitation data for each geography and time period.  2.	Demography: Demographic information such as total population, population density, population share by age, gender, education level, by target geography. For the United States, American Community Survey data is conveniently from the IPUMS repositories (https://usa.ipums.org/usa/) and also includes highly relevant additional variables such as health insurance coverage. Basic demographic data is available for international geographies as well through national statistics office websites (such as the Department of Statistics for Singapore at https://www.singstat.gov.sg/) or international governmental organizations (such as the World Bank for Bangladesh at http://microdata.worldbank.org/index.php/catalog/2562/sampling). These may be less current and frequently updated, especially in less developed countries, but should still serve as reasonable approximations for our purposes. Some variables such as health coverage or access to healthcare may be more sparsely available internationally.Similarly, for the United States influenza data, we will include reports and estimates of flu vaccination rates (sourced from CDC https://www.cdc.gov/flu/fluvaxview/coverage-1718estimates.htm). Rates over time within years can be interpolated from CDC estimates.\nAs one potential outcome variable in flu modeling, we leverage recent research on costs of seasonal influenza outbreaks by different population breaks (https://www.ncbi.nlm.nih.gov/pubmed/29801998). 3.	Mobility: Airline Network News and Analysis (ANNA) provides monthly passenger traffic numbers from hundreds of major airports around the world (over 300 in Europe, over 250 in the Americas, and over 50 in the rest of the world) updated weekly and dating back to 2014 (https://www.anna.aero/databases/). These will be aggregated by geographic unit and time period to model external population flows as an additional disease vector. For application to weekly datasets, weekly numbers can be interpolated based on the monthly aggregates.  4.	Online indicators: Online activity proxies such as Google Trends data on disease relevant searches. This type of data has been shown to be useful in modeling and predicting disease outbreaks in recent years, and may be of interest for our own models. These data are no longer actively updated or maintained, but historical data covering most of the time periods and geographies of interest are available at https://www.google.org/flutrends/about/      a.	Similarly, keyword searches on Twitter for ‘Dengue/aegypti’ and or ‘Influenza/Flu’ can be used to supplement our datasets. These will be GPS tagged and stored by Twitter for each returned tweet. If GPS is not provided we use the location the user reported to twitter during their user registration. This data provides spatially localized social messaging that can be mapped to the Dengue Fever and Influenza/Flu case datasets provided above, by assigning each GPS tagged tweet to its most likely state (Influenza/Flu) or country (Dengue). These would then be aggregated to the time level (weekly, monthly or yearly) for comparison to the Flu and Dengue Fever databases."
},

{
    "location": "library/#",
    "page": "Library Reference",
    "title": "Library Reference",
    "category": "page",
    "text": ""
},

{
    "location": "library/#SemanticModels.SemanticModels",
    "page": "Library Reference",
    "title": "SemanticModels.SemanticModels",
    "category": "module",
    "text": "SemanticModels\n\nprovides the AbstractModel type and constructors for building hierarchical model representations.\n\n\n\n\n\n"
},

{
    "location": "library/#SemanticModels.CombinedModel",
    "page": "Library Reference",
    "title": "SemanticModels.CombinedModel",
    "category": "type",
    "text": "CombinedModel\n\nrepresents a model that has a fixed set of dependencies. It is the basic building block of a model DAG.\n\n\n\n\n\n"
},

{
    "location": "library/#SemanticModels.SpringModel",
    "page": "Library Reference",
    "title": "SemanticModels.SpringModel",
    "category": "type",
    "text": "SpringModel\n\nrepresents the second order linear ODE goverened by hookeslaw.\n\n\n\n\n\n"
},

{
    "location": "library/#DiffEqBase.solve-Tuple{CombinedModel}",
    "page": "Library Reference",
    "title": "DiffEqBase.solve",
    "category": "method",
    "text": "solve(m::AbstractModel)\n\nexecutes the solving of a model for models with dependencies, those deps are executed first and then the node is solved. This is the function that evaluates the model DAG.\n\n\n\n\n\n"
},

{
    "location": "library/#SemanticModels.BasicSIR-Tuple{}",
    "page": "Library Reference",
    "title": "SemanticModels.BasicSIR",
    "category": "method",
    "text": "BasicSIR\n\ndefines a representation of Susceptible Infected Recovered models using Unitful numbers and expressions.\n\n\n\n\n\n"
},

{
    "location": "library/#SemanticModels.hookeslaw-NTuple{4,Any}",
    "page": "Library Reference",
    "title": "SemanticModels.hookeslaw",
    "category": "method",
    "text": "hookeslaw\n\nthe ODE representation of a spring. The solutions are periodic functions.\n\n\n\n\n\n"
},

{
    "location": "library/#Library-Reference-1",
    "page": "Library Reference",
    "title": "Library Reference",
    "category": "section",
    "text": "Modules = [SemanticModels]"
},

{
    "location": "library/#Index-1",
    "page": "Library Reference",
    "title": "Index",
    "category": "section",
    "text": ""
},

{
    "location": "theory/#",
    "page": "Theory",
    "title": "Theory",
    "category": "page",
    "text": ""
},

{
    "location": "theory/#Semantic-Modeling-Theory-1",
    "page": "Theory",
    "title": "Semantic Modeling Theory",
    "category": "section",
    "text": "We can consider three different problems for semantic modelingModel Modification: Given a model M and a transformation T construct a new model T(M).\nMetamodel construction: Given a set of a possible component models mathcalM, known independent variables mathcalI, and a set of desired dependent variables V, and a set of rules for combining models Rconstruct a combination of models minmathcalR(M) that takes as input mathcalI and evaluates the dependent variables V.\nModel Validation: Given a model M and a set of properties P and input x, determine if the model satisfies all properties P when evaluated on xA model M=(DRf) is a tuple containing a set D, called the domain, and a set R, called the co-domain with a function fDmapto R. If D is the cross product of sets D_1 times D_2 cdots D_k then the and f = f(x_1dots x_k) where x are the independent variables of M. If R=R_1times R_2cdots r_d then R_i are the dependent variables of M. A Modeling framework (UMR)is a universe of sets U, class of models mathcalM, and a set of rules R. Such that the domains and co-domains of all models in mathcalM are elements of mathcalU, and the class of models is closed under composition when the rules are satisfied. If R(M_1 dots M_n) then odotleft(M_1dotsM_nright)in mathcalM. Composition of models is defined as $\\odot(M1, \\dots, \\Mn)=(D1\\times\\dots\\times D{n-1},                            R1\\times\\dots\\times R{n-1},                              fn(x1,\\dots x{n-1})(f1(x1),\\dots f{n1}(x{n-1})) $ In order to build a useful DAG, a class of models should contain models such as constants, identity, projections, boolean logic, arithmetic, and elementary functions.We also need to handle the case of model identification. There are certain models within a framework that are essentially equivalent. For example if D_1 and D_2 are sets with homomorphism gD_2mapsto D_1, then M_1 = (D_1 R f) = (D_2 R f odot g) are equivalent as models. In fact (D_2 D_1 g) should be included in the class of models in a modeling framework.We need a good theoretical foundation for proving theorems about manipulating models and combining them. Categories for Science may be that foundation.The work of Evan Patterson on building semantic representations of data science programs is particularly relevant to these modeling questions SRDSP. Patterson 2018 "
},

{
    "location": "theory/#Categories-for-Science-1",
    "page": "Theory",
    "title": "Categories for Science",
    "category": "section",
    "text": "Dan Spivak wrote a wonderful book on category theory for scientists based on his lectures at MIT http://math.mit.edu/~dspivak/CT4S.pdf.Data gathering is ubiquitous in science. Giant databases are currently being mined for unknown patterns, but in fact there are many (many) known patterns that simply have not been catalogued. Consider the well-known case of medical records. A patient’s medical history is often known by various individual doctor-offices but quite inadequately shared between them. Sharing medical records often means faxing a hand-written note or a filled-in house-created form between offices.Similarly, in science there exists substantial expertise making brilliant connections between concepts, but it is being conveyed in silos of English prose known as journal articles. Every scientific journal article has a methods section, but it is almost impossible to read a methods section and subsequently repeat the experiment—the English language is inadequate to precisely and concisely convey what is being doneThis is the point of our project, to mine the code and docs for the information necessary to repeat and expand scientific knowledge. Reproducible research is focused on getting the code/data to be shared and runnable with VMs/Docker etc are doing the first step. Can I repeat your analysis? We want to push that to expanding."
},

{
    "location": "theory/#Ologs-1",
    "page": "Theory",
    "title": "Ologs",
    "category": "section",
    "text": "Ontology logs are a diagrammatic approach to formalizing scientific methodologies. They can be used to precisely specify what a scientist is talking about. Spivak, D.I., Kent, R.E. (2012) “Ologs: A Categorical Framework for Knowledge Representation.” PLoS ONE 7(1): e24274. doi:10.1371/journal.pone.0024274.An olog is composed of types (the boxes) and aspects (the edges). The labels on the edges is the name of the aspect. An aspect is valid if it is a function (1-many relation). (Image: Birthday olog)We can represent an SIR model as an olog as shown below.(Image: SIR olog)Another category theory representation without the human readable names used in an olog shows a simpler representation.(Image: SIR Category)"
},

{
    "location": "theory/#Models-in-the-Category-of-Types-1",
    "page": "Theory",
    "title": "Models in the Category of Types",
    "category": "section",
    "text": "All programs in a strongly typed language have a set of types and functions that map values between those types. For example the Julia programa = 5.0\nb = 1\nc = 2*a\nd = b + cHas the types Int, Float and functions *, + which are both binary functions. These types and functions can be represented as a category, where the objects are the types and the morphisms are the functions. We refer to the input type of a function as the domain and the output type as the codomain of the function. Multi-argument functions are represented with tuple types representing their argument. For example +(a::Int,b::Int)::Int is a function + Inttimes Int - Int. These type categories are well studied in the field of Functional Programming. We apply these categories to the study of mathematical models. One can use a combination of static and dynamic analysis to extract this category representation from a program and use it to represent the model implemented by the code.The most salient consequence of programming language theory is that the more information that a programmer can encode in the type system, the more helpful the programming language can be for improving performance, quality, and correctness.We want to leverage the type system to verify the semantic integrity of a model. This is critical when pursuing automatic model modification. Model developers use any number of conventions to encode semantic constraints into their code for example, prefacing all variables that refer to time with a t, such as t_start, s_end. This semantic constraint that all variables named t_ are temporal variables is not encoded in the type system because all those variables are still floats. Another example is that vectors of different lengths are incompatible. In a compartment model, the number of initial conditions must match the number of compartments, and the number of parameters may be different. For example in an SIR model there are 3 initial conditions, SIR and there are 2 parameters beta gamma. These vectors are incompatible, you cannot perform arithmetic or comparisons on them directly. Most computational systems employed by scientists will use a runtime check on dimensions to prevent a program from crashing on malformed linear algebra. Scientists rely on this limited from of semantic integrity checking provided by the language. Our goal is to extract and encode the maximum amount of information from scientific codes into the type system. The type system is analyzable as a category. Thus we can look at the category of types and analyze the integrety of the programs. For example if there are two types ST and two functions fg Sarrow T such that Codom(f) = Codom(g) but Range(f) cap Range(g), then we say that the type system is ambiguous in that there are two functions that use disjoint subsets of their common codomain. In order to more fully encode program semantics into the type system, the programmer (or an automated system) should introduce new types to the program to represent these disjoint subsets. (Image: Ambiguous types in the SIR Model) Returning to the SIR model example, the .param and .initial functions both map Problem to Vector{Float} but have disjoint ranges. From our mathematical understanding of the model, we know that parameters and initial conditions are incompatible types of vectors, for one thing the output of .param is length 2 and the output of .initial is length 3. Any program analysis of the model will be hampered by the ambiguity introduced by using the same type to represent two different concepts. On the other hand, .first and .second have overlapping ranges and are comparable as times.(Image: Unambiguous types in the SIR Model)This is an example of how PL theory ideas can improve the analysis of computational models."
},

{
    "location": "approach/#",
    "page": "Approaches",
    "title": "Approaches",
    "category": "page",
    "text": ""
},

{
    "location": "approach/#Approaches-1",
    "page": "Approaches",
    "title": "Approaches",
    "category": "section",
    "text": "Architecture, Approaches, and TechniquesWe provide a high-level overview of the open-source epidemiological modeling software packages that we have reviewed, and outlines our intended approach for extracting information from scientific papers that cite one or more of these packages. Our extraction efforts are directed toward the construction of a knowledge graph that we can traverse to reason about how to best map a set of known, unitful inputs to a set of unknown, unitful outputs via parameter modification, hyperparamter modification, and/or sequential chaining of models present in the knowledge graph. Our overarching purpose in this work is to reduce the cost of conducting incremental scientific research, and facilitate communication and knowledge integration across different research domains."
},

{
    "location": "approach/#Introduction-1",
    "page": "Approaches",
    "title": "Introduction",
    "category": "section",
    "text": "The ASKE program aims to extract knowledge from the body of scientific work. Our view is that the best way to prove that you have extracted knowledge is to show that you can build new models out of the components of old models. The purpose of these new models may be to improve the fidelity of the original model with respect to the phenomenon of interest or to probe the mechanistic relationships between phenomena. Another use case for adapting models to new contexts is in order to use a simulation to provide data that cannot be obtained through experimentation or observation.Our initial scientific modeling domain is the epidemiological study of disease spread, commonly called compartmental or SIR models. These models are compelling because the literature demonstrates the use of a repetitive model structure with many variations. The math represented therein spans both discrete and continuous equations, and the algorithms that solve these models are diverse. Additionally, this general model may apply to various national defense related phenomena, such as viruses on computer networks [@cohenefficient2003] or misinformation in online media [@budaklimiting2011].The long term goal for our project is to reduce the labor cost of integrating models between scientists so that researchers can more efficiently build on the research of others. Such an effort is usefully informed by prior work and practices within the areas of software engineering and open source software development. Having the source code for a library or package is essential to building on it, but perhaps even more important are the affordances provided by open source licensing models and (social) software distribution systems that can significantly reduce the effort required to download others\' code and streamline execution from hours to minutes. This low barrier to entry is responsible for the proliferation of open source software that we see today. By extracting knowledge from scientific software and representing that knowledge, including model semantics, in knowledge graphs, along with leveraging type systems to conduct program analysis, we aim to increase the interoperability and development of scientific models at large scale."
},

{
    "location": "approach/#Scientific-Domain-and-Relevant-Papers-1",
    "page": "Approaches",
    "title": "Scientific Domain and Relevant Papers",
    "category": "section",
    "text": "We have focused our initial knowledge artifact gathering efforts on the scientific domain of epidemiology broadly defined, so as to render the diffusion of both disease and information in scope. Given that our ultimate goal is to automate the extraction of calls to epidemiological modeling libraries and functions, as well as the unitful parameters contained therein, we have conducted a preliminary literature review for the purpose of: (1) identifying a subset of papers published in this domain that leverage open-source epidemiological modeling libraries, and/or agent-based simulation packages, and make their code available to other researchers; and (2) identifying causally dependent research questions that could benefit from, and/or be addressed by the modification and/or chaining of individual models, as these questions can serve as foundational test cases for the meta-models we develop."
},

{
    "location": "approach/#Papers-and-Libraries-1",
    "page": "Approaches",
    "title": "Papers and Libraries",
    "category": "section",
    "text": "We began the literature review and corpus construction process by identifying a representative set of open-source software (OSS) frameworks for epidemiological modeling, and/or agent-based simulation, including: NDLib, EMOD, Pathogen, NetLogo, EpiModels, and FRED. These frameworks were selected for initial consideration based on: (1) the scientific domains and/or research questions they are intended to support (specifically, disease transmission and information diffusion); (2) the programming language(s) in which they are implemented (Julia, Python, R, C++); and (3) the extent to which they have been used in peer-reviewed publications that include links to their source code. We provide a brief overview of the main components of each package below, as well as commentary on the frequency with which each package has been used in relevant published works."
},

{
    "location": "approach/#NDLib-1",
    "page": "Approaches",
    "title": "NDLib",
    "category": "section",
    "text": "NDLib is an open-source package developed by a research team from the Knowledge Discovery and Data Mining Laboratory (KDD-lab) at the University of Pisa, and written in Python on top of the NetworkX library. NDLib is intended to aid social scientists, computer scientists, and biologists in modeling/simulating the dynamics of diffusion processes in social, biological, and infrastructure networks [@NDlib1; @NetworkX]. NDLib includes built-in implementations of many common epidemiological models (e.g., SIR, SEIR, SEIS, etc.), as well as models of opinion dynamics (e.g., Voter, Q-Voter, Majority Rule, etc.). In addition, there are several features intended to make NDLib available to non-developer domain experts, including an abstract Network Diffusion Query Language (NDQL), an experiment server that is query-able through a RESTful API to allow for remote execution, and a web-based GUI that can be used to visualize and run epidemic simulations [@NDlib1].The primary disadvantage of NDLib is that it is relatively new: the associated repository on GitHub was created in 2016, with the majority of commits beginning in 2017; two supporting software system architecture papers were published in 2017-2018 [@ndlibDocs; @NDlib1; @NDlib2]. As such, while there are several factors which bode well for future adoption (popularity of Python for data science workflows and computer science education; user-friendliness of the package, particularly for users already familiar with NetworkX, etc.), the majority of published works citing NDLib are papers written by the package authors themselves, and focus on information diffusion."
},

{
    "location": "approach/#Epimodels-1",
    "page": "Approaches",
    "title": "Epimodels",
    "category": "section",
    "text": "EpiModel is an R package, written by researchers at Emory University and The University of Washington, that provides tools for simulating and analyzing mathematical models of infectious disease dynamics. Supported epidemic model classes include deterministic compartmental models, stochastic individual contact models, and stochastic network models. Disease types include SI, SIR, and SIS epidemics with and without demography, with utilities available for expansion to construct and simulate epidemic models of arbitrary complexity. The network model class is based on the statistical framework of temporal exponential random graph models (ERGMs) implementated in the Statnet suite of software for R. [@JSSv084i08] The library is widely used and the source code is available. The library would make a great addition to the system we are building upon integration. EpiModels has received several grants from the National Institutes of Health (NIH) for funding its development. There are several publications utilizing the library at highly elite research journals, including PLoS ONE and Infectious Diseases, as well as the Journal of Statistical Software."
},

{
    "location": "approach/#NetLogo-1",
    "page": "Approaches",
    "title": "NetLogo",
    "category": "section",
    "text": "NetLogo, according to the User Manual, is a programmable modeling environment for simulating natural and social phenomena. It was authored by Uri Wilensky in 1999 and has been in continuous development ever since at the Center for Connected Learning and Computer-Based Modeling. NetLogo is particularly well suited for modeling complex systems developing over time. Modelers can give instructions to hundreds or thousands of \"agents\" all operating independently. This makes it possible to explore the connection between the micro-level behavior of individuals and the macro-level patterns that emerge from their interaction. NetLogo lets students open simulations and \"play\" with them, exploring their behavior under various conditions. It is also an authoring environment which enables students, teachers and curriculum developers to create their own models. NetLogo is simple enough for students and teachers, yet advanced enough to serve as a powerful tool for researchers in many fields. NetLogo has extensive documentation and tutorials. It also comes with the Models Library, a large collection of pre-written simulations that can be used and modified. These simulations address content areas in the natural and social sciences including biology and medicine, physics and chemistry, mathematics and computer science, and economics and social psychology. Several model-based inquiry curricula using NetLogo are available and more are under development. NetLogo is the next generation of the series of multi-agent modeling languages including StarLogo and StarLogoT. NetLogo runs on the Java Virtual Machine, so it works on all major platforms (Mac, Windows, Linux, et al). It is run as a desktop application. Command line operation is also supported. [@tisue2004netlogo; @nlweb] NetLogo has been widely used by the simulation research community at-large for well over nearly two decades. Although there is a rich literature that mentions its use, it may be more difficult to identify scripts that have been authored and that pair with published research papers using the modeling library due to the amount of time that has passed and that researcher may no longer monitor the email addresses listed on their publications for various reasons."
},

{
    "location": "approach/#EMOD-1",
    "page": "Approaches",
    "title": "EMOD",
    "category": "section",
    "text": "Epidemiological MODeling (EMOD) is an open-source agent-based modeling software package developed by the Institute for Disease Modeling (IDM), and written in C++ [@emodRepo; @emodDocs]. The primary use case that EMOD is intended to support is the stochastic agent-based modeling of disease transmission over space and time. EMOD has built-in support for modeling malaria, HIV, tuberculosis, sexually transmitted infections (STIs), and vector-borne diseases; in addition, a generic modeling class is provided, which can be inherited from and/or modified to support the modeling of diseases that are not explicitly supported [@emodDocs; @emodRepo].The documentation provided is thorough, and the associated GitHub repo has commits starting in July 2015; the most recent commit was made in July 2018 [@emodRepo; @emodDocs]. EMOD also includes a regression test suite, so that stochastic simulation results can be compared to a reference set of results and assessed for statistical similarity within an acceptable range. In addition, EMOD leverages Message Passing Interface (MPI) to support within- and among-simulation(s)-level parallelization, and outputs results as JSON blobs. The IDM conducts research, and as such, there are a relatively large number of publications associated with the institute that leverage EMOD and make their data and code accessible. One potential drawback of EMOD relative to more generic agent-based modeling packages is that domain-wise, coverage is heavily slanted toward epidemiological models; built-in support for information diffusion models is not included."
},

{
    "location": "approach/#Pathogen-1",
    "page": "Approaches",
    "title": "Pathogen",
    "category": "section",
    "text": "Pathogen is an open-source epidemiological modeling package written in Julia [@pathogenRepo]. Pathogen is intended to allow researchers to model the spread of infectious disease using stochastic, individual-level simulations, and perform Bayesian inference with respect to transmission pathways [@pathogenRepo]. Pathogen includes built-in support for SEIR, SEI, SIR, and SI models, and also includes example Jupyter notebooks and methods to visualize simulation results (e.g., disease spread over a graph-based network, where vertices represent individual agents). With respect to the maturity of the package, the first commit to an alpha version of Pathogen occurred in 2015, and the master branch contains commits within the last month (e.g., November 2018) [@pathogenRepo]. Pathogen is appealing because it could be integrated into our Julia-based meta-modeling approach without incurring the overhead associated with wrapping non-Julia-based packages. However, one of the potential disadvantages of the Pathogen package is that there is no associated software or system architecture paper; as such, it is difficult to locate papers that use this package."
},

{
    "location": "approach/#FRED-1",
    "page": "Approaches",
    "title": "FRED",
    "category": "section",
    "text": "FRED, which stands for a Framework for Reconstructing Epidemic Dynamics, is an open-source, agent-based modeling software package written in C++, developed by the Pitt Public Health Dynamics Laboratory for the purpose of modeling the spread of disease(s) and assessing the impact of public health intervention(s) (e.g., vaccination programs, school closures, etc.) [@pittir24611; @fredRepo]. FRED is notable for its use of synthetic populations that are based on U.S. Census Data, and as such, allow for the instantiation of agents whose spatiotemporal and sociodemographic characteristics, including household membership and location, as well as income level and patterns of employment and/or school attendance, reflect the actual distribution of the population in the selected geographic area(s) within the United States [@pittir24611]. FRED is modular and paramterized to allow for support of different diseases, and the associated software paper, as well as the GitHub repository, provide clear, robust documentation for use. One advantage of FRED relative to some of the other packages we have reviewed is that it is relatively mature. Commits range from 2014-2016, and the associated software paper was published in 2013; as such, epidemiology researchers have had more time to become familiar with the software and cite it in their works [@pittir24611; @fredRepo]. A related potential disadvantage is that FRED does not appear to be under active development [@pittir24611; @fredRepo]."
},

{
    "location": "approach/#Evaluation-1",
    "page": "Approaches",
    "title": "Evaluation",
    "category": "section",
    "text": "The packages outlined in the preceding section are all open-source, and written in Turing-complete programming languages; thus, we believe any subset of them would satisfy the open-source and complexity requirements for artifact selection outlined in the solicitation. As such, the primary dimensions along which we have evaluated and compared our initial set of packages include: (1) the frequency with which a given package has been cited in published papers that include links or references to their code; (2) the potential trend of increasing adoption/citation over the near-to-medium term; (3) the existence of thorough documentation; and (4) the feasibility of cross-platform and/or cross-domain integration.With respect to the selection of specific papers and associated knowledge artifacts, our intent at this point in the knowledge discovery process is to prioritize the packages outlined above based on their relative maturity, and proceed to conduct additional, augmenting bibliometric exploration in the months ahead. Our view is that EMOD, Epimodels, NetLogo, and FRED can be considered established packages, given their relative maturity and the relative availability of published papers citing these packages. Pathogen and NDLib can be considered newer packages, in that they are relatively new and lack citations, but have several positive features that bode well for an uptick in use and associated citation in the near- to medium-term. It is worth noting that while the established packages provide a larger corpus of work from which to select a set of knowledge artifacts, the newer packages are more modern, and as such, we expect them to be easier to integrate into the type of data science/meta-modeling pipelines we will develop. Additionally, we note that should the absence of published works prove to be an obstacle for a package we ultimately decide to support via integration into our framework, we are able to generate feasible examples by writing them ourselves.For purposes of development and testing, we will need to use simple or contrived models that are presented in a homogeneous framework. Pedagogical textbooks [@voitfirst2012] and lecture notes[1] will be a resource for these simple models that are well characterized."
},

{
    "location": "approach/#Information-Extraction-1",
    "page": "Approaches",
    "title": "Information Extraction",
    "category": "section",
    "text": "In order to construct the knowledge graph that we will traverse to generate metamodel directed acyclic graphs (DAGs), we will begin by defining a set of knowledge artifacts and implementing (in both code and process/system design) an iterative, expert-in-the-loop knowledge extraction pipeline. The term \"knowledge artifacts\" is intended to refer to the set of open-source software packages (e.g., their code-bases), as well as a curated subset of published papers in the scientific domains of epidemiology and/or information diffusion that cite one or more of these packages and make their own code and/or data (if relevant) freely available. Our approach to the selection of packages and papers has been outlined in the preceding section, and is understood to be both iterative and flexible to the incorporation of additional criteria/constraints, and/or the inclusion/exclusion of (additional) works as the knowledge discovery process proceeds.Given a set of knowledge artifacts, we plan to proceed with information extraction as follows: First, we will leverage an expert system\'s based approach to derive rules to automatically recognize and extract relevant phenomena; see Table [table:info_extract]{reference-type=\"ref\" reference=\"table:info_extract\"} for details. The rules will be built using the outputs of language parsers and applied to specific areas of source code that meet other heuristic criteria e.g. length, association with other other functions/methods. Next, we will also experiment with supervised approaches (mentioned in our proposal) and utilize information from static code analysis tools, programming language parsers, and lexical and orthographic features of the source code and documentation. For example, variables that are calculated as a result of running a for loop within code and whose characters, lexically speaking, occur within source code documentation and or associated research publications are likely related to specific models being proposed or extended in publications.We will also be performing natural language parsing [@manning] on research papers themselves to provide cues for how we perform information extraction on associated scripts with references to known libraries. For example, a research paper will reference a library that our system is able to reason about and extend models from and so if no known library is identified then the system will not attempt to engage in further pipeline steps. For example, a paper that leverages the EpiModels library will contain references to the EpiModels library itself and in one set of cases, reference a particular family of models e.g. \"Stochastic Individual Contact Models\". The paper will likely not mention any references to actual library functions/methods that were used but will reference particular circumstances related to using a particular model such as e.g. model parameters that were the focus of the research paper\'s investigation. These kinds of information will be used in supervised learning to build the case for different kinds of extractions. In order to do supervised learning, we will be developing ground truth annotations to train models with. To gain a better sense of the kinds of knowledge artifacts we will be working with, below we present an example paper that a metamodel can be built from and from whence information can be extracted to help in the creation of that metamodel."
},

{
    "location": "approach/#EpiModels-Example-1",
    "page": "Approaches",
    "title": "EpiModels Example",
    "category": "section",
    "text": "In [@doi:10.1111/oik.04527] the authors utilize the EpiModels library and provide scripts for running the experiments they describe. We believe this is an example of the kind of material we will be able to perform useful information extractions on to inform the development of metamodels. Figure [fig:img/covar_paper1]{reference-type=\"ref\" reference=\"fig:covar_paper1\"} is an example of script code from [@doi:10.1111/oik.04527]:(Image: Example script excerpt associated with [@doi:10.1111/oik.04527] setting parameters for use in an ERGM model implemented by EpiModels library.){width=\"70%\"}[[fig:covar_paper1]]{#fig:covarpaper1 label=\"fig:covarpaper1\"}Table [table:info_extract]{reference-type=\"ref\" reference=\"table:info_extract\"} is a non-exhaustive list of the kinds of information extractions we are currently planning and the purposes they serve in supporting later steps:Extraction Type    Description                                                                         Sources   ––––––––– –––––––––––––––––––––––––––––––––––––––––- ––––––––-   Code References    Creation and selection of metamodels to extend or utilize depending on user goals   Papers, Scripts   Model Parameters   Natural language variable names, function parameters                                Papers, Scripts   Function Names     Names of library model functions used to run experiments in papers                  Scripts   Library Names      Include statements to use specific libraries. Identification of libraries           Scripts: Planned information extractions. A non-exhaustive list of   information extractions, their purposes, and sources.[[table:info_extract]]{#table:infoextract label=\"table:infoextract\"}The information extractions we produce here will be included as annotations in the knowledge representations we describe next."
},

{
    "location": "approach/#Knowledge-Representation-1",
    "page": "Approaches",
    "title": "Knowledge Representation",
    "category": "section",
    "text": "On the topic of dimensionality / complexity reduction (in an entropic sense) and knowledge representation: (1) we will begin by passing the code associated with each knowledge artifact through static analysis tools. Static analysis tools include linters intended to help programmers debug their code and correct syntax, stylistic, and/or security-related errors. As the knowledge artifacts in our set are derived from already published works, we do not anticipate syntax errors. Rather, our objective is to use the abstract syntax trees (ASTs), call graphs, control flow graphs, and/or dependency graphs that are produced during static analysis to extract both discrete model instantiation(s) (along with arguments, which can be mapped back to parameters which may have associated metadata, including required object type and units), as well as sequential function call information.The former can be thought of as contributing a connected subgraph to the knowledge graph, such that G_i subseteq G, in which model classes and variable data/unit types are represented as vertices and connected by directed \"requires/accepts\" edges. The latter can be thought of as contributing information about the mathematical and/or domain-specific legality and/or frequency with which a given subset of model types can be sequentially linked; this information can be used to weight edges connecting model nodes in the knowledge graph.The knowledge graph approach will help identify relevant pieces of context. For example the domain of a scientific paper or code will be necessary for correct resolution of scientific terms which are used to refer to multiple phenomena in different contexts. For example, in a paper about biological cell signalling pathways the term \"death\" is likely to refer to the death of individual cells, while in a paper about disease prevalence in at-risk populations, the same term is likely referring to the death of individual people. This will be further complicated by figurative language in the expository aspects of paper where \"death\" might be used as a metaphor when a cultural behavior or meme \"dies out\" because people stop spreading the behavior to their social contacts."
},

{
    "location": "approach/#Schema-Design-1",
    "page": "Approaches",
    "title": "Schema Design",
    "category": "section",
    "text": "We will represent the information extracted from the artifacts using a knowledge graph. And while knowledge graphs are very flexible in how they represent data, it helps to have a schema describing the vertex and edge types along with the metadata that will be stored on the vertices and edges.In our initial approach, the number of libraries that models can be implemented with will be small enough that schema design can be done by hand. We expect that this schema will evolve as features are added to the system, but remain mostly stable as new libraries, models, papers, and artifacts are added.When a new paper/code comes in, we will extract edges and vertices automatically with code which represents those edges and vertices in the predefined schema.Many of the connections will be from artifacts to their components, which will connect to concepts. When papers are connected to other papers, they are connected indirectly (e.g., via other vertices), except for edges that represent citations directly between papers.(Image: An example of the knowledge graph illustrating the nature of the schema.[]{label=\"fig:schema.\"})It is an open question for this research whether the knowledge graph should contain models with the parameters bound to values, or the general concept of a model with parameters available for instantiation. Our initial approach will be to model both the general concept of a model such as HookesLawModel along with the specific instantiation HookesLawModel{k=5.3} from specific artifacts."
},

{
    "location": "approach/#Data-Sets-in-the-Knowledge-Graph-1",
    "page": "Approaches",
    "title": "Data Sets in the Knowledge Graph",
    "category": "section",
    "text": "A big component of how papers refer to the same physical phenomenon is that they use the same data sets. These common datasets which become benchmarks that are leveraged widely in the research community are highly concentrated in a small number of widely cited papers. This is good for our task because we know that if two papers use the same dataset then they are talking about the same phenomenon.The most direct overlap of datasets is to go through papers that provide the canonical source for that dataset. But we can also think of similarity of datasets in terms of the schema(s) of the datasets. This requires a more detailed dataset representation than just the column names commonly found on CSV files. Google\'s open dataset search has done a lot of the work necessary for annotating the semantics for features of datasets. The DataDeps.jl system includes programmatic ways to access this information for many of the common open science data access protocols[2] By linking dataset feature (column) names to knowledge graph concepts, we will be able to compare datasets for similarity and conceptual overlap. The fact that two models are connected to the same dataset(s) or concept(s) is an important indicator that the two models are compatible or interchangeable."
},

{
    "location": "approach/#Schema.org-1",
    "page": "Approaches",
    "title": "Schema.org",
    "category": "section",
    "text": "Schema.org is one of the largest and most diverse knowledge graph systems.It includes virtually no coverage of scientific concepts. There are no schema.org nodes for Variable, Function, Equation. The most relevant schema.org concepts are given in the following list.https://schema.org/ScholarlyArticle\nhttps://schema.org/SoftwareSourceCode.\nhttps://schema.org/ComputerLanguage\nhttps://schema.org/variableMeasured\nhttps://meta.schema.org/Property\nhttps://schema.org/DataFeedItem\nhttps://schema.org/Quantity which has more specific types\nhttps://schema.org/Distance\nhttps://schema.org/Duration\nhttps://schema.org/Energy\nhttps://schema.org/MassThe focus of schema.org is driven by its adoption in the web document community. Schema.org concepts are used for tagging documents in order for search engines or automated information extraction systems to find structured information in documents. Often it is catalogue or indexing sites that use schema.org concepts to describe the items or documents in their collections.The lack of coverage for scientific concepts is surprising given that we think of academic research on publication mining to be focused on their own fields, for example papers about mining bibliographic databases often use examples of database researchers themselves.You could model the relationships between papers using this schema.org schema. But that takes place at the bibliometric level instead of the the model semantics level. There are no entries for expressing that these two papers solve the same equation. Or model the same physical phenomena. Of course schema.org is organized so that everything can be expressed as a https://schema.org/Thing, but there is no explicit representation for these concepts. There is a Schema.org schema for heath and life science https://health-lifesci.schema.org/. As we define the schema of our knowledge graph, we will link up with the schema.org concepts as much as possible and could add an extension to the schema.org in order to represent scientific concepts."
},

{
    "location": "approach/#Model-Representation-and-Execution-1",
    "page": "Approaches",
    "title": "Model Representation and Execution",
    "category": "section",
    "text": "Representation of models occurs at four levels:Executable: the level of machine or byte-code instructions\nLexical: the tradition code representation assignment,   functions, and loops\nSemantic: a declarative language or computation graph   representation with nodes linked to the knowledge graph\nHuman: a description in natural language as in a research paper   or textbookThe current method of scientific knowledge extraction is to take a Human level description and have a graduate student build a Lexical level description by reading papers and implementing new codes. We aim to introduce the Semantic level which is normally stored only in the brains of human scientists, but must be explicitly represented in machines in order to automate scientific knowledge extraction. A scientific model represented at the Semantic level will be easy to modify computationally and be describable for the automatic description generation component. The Semantic level representation of a model is a computation DAG. One possible description is to represent the DAG in a human-friendly way, such as in Figure [fig:flu]{reference-type=\"ref\" reference=\"fig:flu\"}.(Image: An example pipeline and knowledge graph elements for a flu response model.[]{label=\"fig:flu\"})"
},

{
    "location": "approach/#Scientific-Workflows-(Pipelines)-1",
    "page": "Approaches",
    "title": "Scientific Workflows (Pipelines)",
    "category": "section",
    "text": "Our approach will need to be differentiated from scientific workflow managers that are based on conditional evaluation tools like Make. Some examples include Make for scientists, Scipipe, and the Galaxy project. These scientific workflows focus on representing the relationships between intermediate data products without getting into the model semantics. While scientific workflow managers are a useful tool for organizing the work of a scientist, they do not have a particularly detailed representation of the modeling tasks. Workflow tools generally accept the UNIX wisdom that text is the universal interface and communicate between programs using files on disk or in memory pipes, sockets, or channels that contain lines of text.Our approach will track a higher fidelity representation of the model semantics in order to enable computational reasoning over the viability of combined models. Ideas from static analysis of computer programs will enable better verification of metamodels before we run them."
},

{
    "location": "approach/#Metamodels-as-Computation-Graphs-1",
    "page": "Approaches",
    "title": "Metamodels as Computation Graphs",
    "category": "section",
    "text": "Our position is that if you have a task currently solved with a general purpose programming language, you cannot replace that solution with anything less powerful than a general purpose programming language. The set of scientific modeling codes is just too diverse, with each part a custom solution, to be solved with a limited scope solution like a declarative model specification. Thus we embed our solution into the general purpose programming language Julia.We use high level programming techniques such as abstract types and multiple dispatch in order to create a hierarchical structure to represent a model composed of sub-models. These hierarchies can lead to static or dynamic DAGs of models. Every system that relies on building an execution graph and then executing it finds the need for dynamically generated DAGs at some point. For sufficiently complicated systems, the designer does not know the set of nodes and dependencies until execution has started. Examples include recursive usage of the make build tool, which lead to techniques such as cmake, Luigi, and Airflow, and Deep Learning which has both static and dynamic computation graph implementations for example TensorFlow and PyTorch. There is a tradeoff between the static analysis that helps optimize and validate static representations and the ease of use of dynamic representations. We will explore this tradeoff as we implement the system.For a thorough example how to use our library to build a metamodel see the notebook FluExample.ipynb. This example uses Julia types system to build a model DAG that represents all of the component models in a machine readable form. This DAG is represented in Figure [fig:flu]{reference-type=\"ref\" reference=\"fig:flu\"}. Code snippets and rendered plots appear in the notebook."
},

{
    "location": "approach/#Metamodel-Constraints-1",
    "page": "Approaches",
    "title": "Metamodel Constraints",
    "category": "section",
    "text": "When assembling a metamodel, it is important to eliminate possible combinations of models that are scientifically or logically invalid. One type of constraint is provided by units and dimensional analysis. Our flu example pipeline uses Unitful.jl to represent the quantities in the models including Csdperson for Celsius, second, day, and person. While Csd are SI defined units that come with Unitful.jl, person is a user defined type that was created for this model. These unit constraints enable a dynamic analysis tool (the Julia runtime system) to invalidate combinations of models that fail to use unitful numbers correctly, i.e., in accordance with the rules of dimensional analysis taught in high school chemistry and physics. In order to make rigorous combinations of models, more information will need to be captured about the component models. It is necessary but not sufficient for a metamodel to be dimensionally consistent. We will investigate the additional constraints necessary to check metamodels for correctness."
},

{
    "location": "approach/#Metamodel-Transformations-1",
    "page": "Approaches",
    "title": "Metamodel Transformations",
    "category": "section",
    "text": "Metamodel transformations describe high-level operations the system will perform based on the user\'s request and the information available to it in conjunction with using a particular set of open source libraries; examples of these are as follows:utilize an existing metamodel and modifying parameters;\nmodifying the functional form in a model such as adding terms to an  equation\nchanging the structure of the metamodel by modifying the structure  of the computation graph\nintroducing new nodes to the model[3]"
},

{
    "location": "approach/#Types-1",
    "page": "Approaches",
    "title": "Types",
    "category": "section",
    "text": "This project leverages the Julia type system and code generation toolchain extensively.Many Julia libraries define and abstract interface for representing the problems they can solve for exampleDifferentialEquations.jl   https://github.com/JuliaDiffEq/DiffEqBase.jl defines   DiscreteProblem, ODEProblem, SDEProblem, DAEProblem which   represent different kinds of differential equation models that can   be used to represent physical phenomena. Higher level concepts such   as a MonteCarloProblem can be composed of subproblems in order to   represent more complex computations. For example a   MonteCarloProblem can be used to represent situations where the   parameters or initial conditions of an ODEProblem are random   variables, and a scientist aims to interrogate the distribution of   the solution to the ODE over that distribution of input.\nMathematicalSystems.jl   https://juliareach.github.io/MathematicalSystems.jl/latest/lib/types.html   defines an interface for dynamical systems and controls such as   LinearControlContinuousSystem and   ConstrainedPolynomialContinuousSystem which can be used to   represent Dynamical Systems including hybrid systems which combine   discrete and continuous phenomena. Hybrid systems are of particular   interest to scientists examining complex phenomena at the interface   of human designed systems and natural phenomena.\nAnother library for dynamical systems includes   https://juliadynamics.github.io/DynamicalSystems.jl/, which takes   a timeseries and physics approach to dynamical systems as compared   to the engineering and controls approach taken in   MathematicalSystems.jl.\nMADs http://madsjulia.github.io/Mads.jl/ offers a modeling   framework that supports many of the model analysis and decision   support tasks that will need to be performed on metamodels that we   create.Each of these libraries will need to be integrated into the system by understanding the types that are used to represent problems and developing constraints for how to create hierarchies of problems that fit together. We think that the number of libraries that the system understands will be small enough that the developers can do a small amount of work per library to integrate it into the system, but that the number of papers will be too large for manual tasks per paper.When a new paper or code snippet is ingested by the system, we may need to generate new leaf types for that paper automatically.By hooking into the Julia type system we are able to use multidispatch to reprogram existing functions. Our approach takes this to the next level by using Cassette.jl contexts and overdubbing to reprogram code to provide new functionality without changing the architecture of the existing software."
},

{
    "location": "approach/#User-Interface-1",
    "page": "Approaches",
    "title": "User Interface",
    "category": "section",
    "text": "Our system is used by expert scientists who want to reduce their time spent writing code and plumbing models together. As an input it would take a set of things known or measured by the scientist and a set of variables or quantities of interest that are unknown. The output of the program is a program that calculates the unknowns as a function of the known input(s) provided by the user, potentially with holes that require expert knowledge to fill in."
},

{
    "location": "approach/#Generating-new-models-1",
    "page": "Approaches",
    "title": "Generating new models",
    "category": "section",
    "text": "We will use metaprogramming to build a library that takes data structures, derived partially using information previously extracted from research publication and associated scripts, which represent models as input and transform and combine them into new models, then generates executable code based on the these new, potentially larger models.One foreseeable technical risk is that the Julia compiler and type inference mechanism could be overwhelmed by the number of methods and types that our system defines. In a fully static language like C++ the number of types defined in a program is fixed at compile time and the compile burden is paid once for many executions of the program. In a fully dynamic language like Python, there is no compilation time and the cost of type checking is paid at run time. However, in Julia, there is both compile time analysis and run time type computations.In Julia, changing the argument types to a function causes a round of LLVM compilation for the new method of that function. When using Unitful numbers in calculations, changes to the units of the numbers create new types and thus additional compile time overhead. This overhead is necessary to provide unitful numbers that are no slower for calculations than primitive number types provided by the processor. As we push more information into the type system, this trade-off of additional compiler overhead will need to be managed."
},

{
    "location": "approach/#Validation-1",
    "page": "Approaches",
    "title": "Validation",
    "category": "section",
    "text": "There are many steps to this process and at each step there is a different process for validating the system.Extraction of knowledge elements from artifacts: we will need to   assess the accuracy of knowledge elements extracted from text, code   and documentation to ensure that the knowledge graph is correct.   This will require some manual annotation of data from artifacts and   quality measures such as precision and recall. The precision is the   number of edges in the knowledge graph that are correct, and the   recall is the fraction of correct edges that were recovered by the   information extraction approach.\nMetamodel construction: once we have a knowledge graph, we will   need to ensure that combinations of metamodels are valid, and   optimal. We will aim to produce the simpliest metamodel that relates   the queried concepts this will be measured in terms of number of   metamodel nodes, number of metamodel dependency onnections, number   of adjustment or transformation functions. We will design test cases   that increase in complexity from pipelines with no need to transform   variables, to pipelines with variable transformations, to directed   acyclic graphs (DAGs).\nModel Accuracy: as the metamodels are combinations of models that   are imperfect, there will be compounding error within the metamodel.   We will need to validate that our metamodel execution engine does   not add error unnecessarily. This will involve numerical accuracy   related to finite precision arithmetic, as well as statistical   accuracy related to the ability to learn parameters from data.   Additionally, since we are by necessity doing some amount of domain   adaptation when reusing models, we will need to quantify the domain   adaptation error generated by applying a model developed for one   context in a different context. These components of errors can be   thought of as compounding loss in a signal processing system where   each component of the design introduces loss with a different   response to the input.Our view is to analogize the metamodel construction error and the model accuracy to the error and residual in numerical solvers. For a given root finding problem, such as f(x)=0 solve for x the most common way to measure the quality of the solution is to measure both the error and the residual. The error is defined as mid x-x^starmid, which is the difference from the correct solution in the domain of x and the residual is mid f(x) - f(x^star)mid or the difference from the correct solution in the codomain. We will frame our validation in terms of error and residual, where the error is how close did we get to the best metamodel, and residual is the difference between the observed versus predicted phenomena.These techniques need to generate simple, explainable models for physical phenomena that are easy for scientists to generate, probe, and understand, while being the best possible model of the phenomena under investigation."
},

{
    "location": "approach/#Next-Steps-1",
    "page": "Approaches",
    "title": "Next Steps",
    "category": "section",
    "text": "Our intended path forward following the review of this report is as follows:Incorporation of feedback received from DARPA PM, including  information related to: the types of papers we consider to be in  scope (e.g., those with and without source code); domain coverage  and desired extensibility; expressed preference for  inclusion/exclusion of particular package(s) and/or knowledge  artifact(s).\nConstruction of a proof-of-concept version of our knowledge graph  and end-to-end pipeline, in which we begin with a motivating example  and supporting documents (e.g., natural language descriptions of the  research questions and mathematical relationships modeled; source  code), show how these documents can be used to construct a knowledge  graph, and show how traversal of this knowledge graph can  approximately reproduce a hand-written Julia meta-modeling pipeline.  The flu example outlined above is our intended motivating example,  although we are open to tailoring this motivating example to  domain(s) and/or research questions that are of interest to DARPA.\nA feature of the system not yet explored is automatic transformation  of models at the Semantic Level. These transformations will be  developed in accordance with interface expectations from downstream  consumers including the TA2 performers.Executing on this proof-of-concept deliverable will allow us to experience the iterative development and research life-cycle that end-users of our system will ultimately participate in. We anticipate that this process will help us to identify gaps in our knowledge and framing of the problem at hand, and/or shortcomings in our methodological approach that we can enhance through the inclusion of curated domain-expert knowledge (e.g., to supplement the lexical nodes and edges we are able to extract from source code). In addition, we expect the differences between our hand-produced meta-model and our system-produced meta-model to be informative and interpretable as feedback which can help us to improve the system architecture and associated user experience. It\'s also worth noting that over the medium term, we anticipate that holes in the knowledge graph (e.g., missing vertices and/or edges; missing conversion steps to go from one unit of analysis to another, etc.) may help us to highlight areas where either additional research, and/or expert human input is needed.[1]: http://alun.math.ncsu.edu/wp-content/uploads/sites/2/2017/01/epidemic_notes.pdf[2]: http://white.ucc.asn.au/DataDeps.jl/latest/z20-for-pkg-devs.html#Registering-a-DataDep-1[3]: new model nodes must first be ingested into the system in order to be made available to users."
},

{
    "location": "slides/#",
    "page": "Slides",
    "title": "Slides",
    "category": "page",
    "text": ""
},

{
    "location": "slides/#Slides-1",
    "page": "Slides",
    "title": "Slides",
    "category": "section",
    "text": ""
},

{
    "location": "slides/#Extracting-Model-Structure-for-Improved-Semantic-Modeling-1",
    "page": "Slides",
    "title": "Extracting Model Structure for Improved Semantic Modeling",
    "category": "section",
    "text": "James Fairbanks, GTRI\ncomputational representations of model semantics with knowledge graphs formetamodel reasoning."
},

{
    "location": "slides/#Goals-1",
    "page": "Slides",
    "title": "Goals",
    "category": "section",
    "text": "Extract a knowledge graph from Scientific Artifacts (code, papers, datasets)\nRepresent scientific models in a high level way, (code as data)\nBuild metamodels by combining models in hierarchical expressions using reasoning over KG (1)."
},

{
    "location": "slides/#Running-Example:-Influenza-1",
    "page": "Slides",
    "title": "Running Example: Influenza",
    "category": "section",
    "text": "Modeling the cost of treating a flu season taking into account weather effects.Seasonal temperature is a dynamical system\nFlu infectiousness is a function of temperature"
},

{
    "location": "slides/#Running-Example:-Modeling-types-1",
    "page": "Slides",
    "title": "Running Example: Modeling types",
    "category": "section",
    "text": "Modeling the cost of treating a flu season taking into account weather effects.Seasonal temperature is approximated by 2nd order linear ODE\nFlu cases is an SIR model 1st oder nonlinear ode\nMitigation cost is Linear Regression on vaccines and cases"
},

{
    "location": "slides/#Scientific-Domain-1",
    "page": "Slides",
    "title": "Scientific Domain",
    "category": "section",
    "text": "We focus on Susceptible Infected Recovered model of epidemiology.Precise, concise mathematical formulation\nDiverse class of models, ODE vs Agent based, determinstic vs stochastic\nFOSS implementations are available in all three Scientific programming languages"
},

{
    "location": "slides/#Graph-of-SIR-Model-1",
    "page": "Slides",
    "title": "Graph of SIR Model",
    "category": "section",
    "text": "(Image: Graph of SIR model)"
},

{
    "location": "slides/#Knowledge-Extraction-Architecture-1",
    "page": "Slides",
    "title": "Knowledge Extraction Architecture",
    "category": "section",
    "text": "(Image: Knowledge Extraction Architecture)"
},

{
    "location": "slides/#Example-Input-Packages-1",
    "page": "Slides",
    "title": "Example Input Packages",
    "category": "section",
    "text": "EMOD, Epimodels, NetLogo, and FRED are established packages, given their maturity and availability of published papers citing these packages. \nPathogen and NDLib are newer packages, we expect easier to work with and more future adoption.\nTextbooks [@voitfirst2012] and lecture notes[1] will be a resource for these simple models that are well characterized."
},

{
    "location": "slides/#Model-Representation-and-Execution-1",
    "page": "Slides",
    "title": "Model Representation and Execution",
    "category": "section",
    "text": "Representation of models occurs at four levels:Executable: the level of machine or byte-code instructions\nLexical: the tradition code representation assignment,   functions, and loops\nSemantic: a declarative language or computation graph   representation with nodes linked to the knowledge graph\nHuman: a description in natural language as in a research paper   or textbook"
},

{
    "location": "slides/#Knowledge-Graph-1",
    "page": "Slides",
    "title": "Knowledge Graph",
    "category": "section",
    "text": "(Image: Hypothetical Knowledge Graph Sample)Hypothetical Knowledge Graph Sample"
},

{
    "location": "slides/#Knowledge-Graph-Schema-1",
    "page": "Slides",
    "title": "Knowledge Graph Schema",
    "category": "section",
    "text": "A preliminary design for types of knowledge in our knowledge graph. (Image: Knowledge Graph Schema)Artifacts\nComponents\nModels\nVariables\nEquations\nConcepts\nValues"
},

{
    "location": "slides/#Flu-Metamodel-Pipeline-1",
    "page": "Slides",
    "title": "Flu Metamodel Pipeline",
    "category": "section",
    "text": "Here is the DAG for our running example. (Image: A pipeline for modeling flu vaccination requirements)See FluModel for worked out example."
},

{
    "location": "slides/#Knowledge-Graph-Reasoning-1",
    "page": "Slides",
    "title": "Knowledge Graph Reasoning",
    "category": "section",
    "text": "Define Model representations / KG schema\nExtract KG from artifacts\nReason over KG to build metamodel\nCodeGen/Execution of Metamodel"
},

{
    "location": "slides/#How-do-we-get-from-Weather-to-Cost?-1",
    "page": "Slides",
    "title": "How do we get from Weather to Cost?",
    "category": "section",
    "text": "(Image: How do we get from Weather to Cost?){ width=80% }(Image: How do we get from Weather to Cost?){ width=80% }Shortest path!"
},

{
    "location": "slides/#How-do-we-get-from-WeatherDemographics-to-Cost?-1",
    "page": "Slides",
    "title": "How do we get from Weather+Demographics to Cost?",
    "category": "section",
    "text": "(Image: How do we get from Weather to Cost?){ width=80% }Minimum ST flow!"
},

{
    "location": "slides/#Knowledge-Graph-Reasoning-Open-Questions-1",
    "page": "Slides",
    "title": "Knowledge Graph Reasoning Open Questions",
    "category": "section",
    "text": "What rules for path/flow computations are necessary and sufficient for a metamodel?\nCan we implement those rules by choosing weights?\nHow do we handle uncertainty and near matches?\nHow do we determine \"necessary dependencies\" better than \"connected component\"\nWhat about supplying expert information?"
},

{
    "location": "slides/#Infectious-Disease-Metamodel-1",
    "page": "Slides",
    "title": "Infectious Disease Metamodel",
    "category": "section",
    "text": "A more ambitious example of a metamodel\nRequires Agent based simulations of information diffuision and disease spread(Image: A DAG of model dependencies)"
},

{
    "location": "slides/#Static-vs-Dynamic-Graph-1",
    "page": "Slides",
    "title": "Static vs Dynamic Graph",
    "category": "section",
    "text": "Inherent tradeoff between flexibility and static analysis\nWe will build the computation graph through the execution of code\nMetaprogramming will be used to generate the executable codes"
},

{
    "location": "slides/#Validation-1",
    "page": "Slides",
    "title": "Validation",
    "category": "section",
    "text": "Extraction of KG elements from artifacts\nMetamodel construction\nMetamodel quality"
},

{
    "location": "slides/#Error-and-Residual-1",
    "page": "Slides",
    "title": "Error and Residual",
    "category": "section",
    "text": "Analogize the metamodel construction error and the model quality to the error and residual in numerical solvers. Given f(x)=0 solve for xMeasure both the error and the residual.\nError mid x-x^starmid, the difference from the correct solution \nResidual mid f(x) - f(x^star)mid or the difference from quality of optimal solution"
},

{
    "location": "slides/#Next-Steps-1",
    "page": "Slides",
    "title": "Next Steps",
    "category": "section",
    "text": "Incorporation of feedback today\nthe types of artifacts in scope\ndomain coverage and desired extensibility\ninclusion/exclusion of particular package(s) and/or knowledge artifact(s)\nConstruction of a proof-of-concept version of our knowledge graph and end-to-end pipeline\nTailor running example to DARPA objectives\nA automatic transformation of models at the Semantic Level[1]: http://alun.math.ncsu.edu/wp-content/uploads/sites/2/2017/01/epidemic_notes.pdf"
},

{
    "location": "FluModel/#",
    "page": "Flu Model",
    "title": "Flu Model",
    "category": "page",
    "text": ""
},

{
    "location": "FluModel/#FluModel-1",
    "page": "Flu Model",
    "title": "FluModel",
    "category": "section",
    "text": "using Pkg\nPkg.activate(\".\")\nusing SemanticModels\nusing SemanticModels.Unitful: DomainError, s, d, C, uconvert, NoUnits\nusing DifferentialEquations\nusing DataFrames\nusing Unitful\nusing Test\n\nusing Distributions: Uniform\nusing GLM\nusing DataFrames\nusing Plotsstripunits(x) = uconvert(NoUnits, x)stripunits (generic function with 1 method)function flusim(tfinal)\n    # annual cycle of temperature control flu infectiousness\n    springmodel = SpringModel([u\"(1.0/(365*8))d^-2\"], # parameters (frequency)\n                              (u\"0d\",tfinal), # time domain\n                              [u\"25.0C\", u\"0C/d\"]) # initial_conditions T, T\'\n    function create_sir(m, solns)\n        sol = solns[1]\n        initialS = u\"10000person\"\n        initialI = u\"1person\" \n        initialpop = [initialS, initialI, u\"0.0person\"]\n        β = u\"1.0/18\"/u\"d*C\" * sol(sol.t[end-2])[1] #infectiousness\n        @show β\n        sirprob = SIRSimulation(initialpop, #initial_conditions S,I,R\n                                (u\"0.0d\", u\"20d\"), #time domain\n                                SIRParams(β, u\"40.0person/d\")) # parameters β, γ\n        return sirprob\n    end\n\n    function create_flu(cm, solns)\n        sol = solns[1]\n        finalI = stripunits(sol(u\"8.0d\")[2]) # X\n        population = stripunits(sol(sol.t[end])[2])\n        # population = stripunits(sum(sol.u[end]))\n        df = SemanticModels.generate_synthetic_data(population, 0,100)\n        f = @formula(vaccines_produced ~ flu_patients)\n        model =  lm(f,\n            df[2:length(df.year),\n            [:year, :flu_patients, :vaccines_produced]])\n        println(\"GLM Model:\")\n        println(model)\n\n        year_to_predict = 1\n        num_flu_patients_from_sim = finalI\n        vaccines_produced = missing\n        targetDF = DataFrame(year=year_to_predict,\n            flu_patients=num_flu_patients_from_sim, \n            vaccines_produced=missing)\n        @show targetDF\n\n\n        return RegressionProblem(f, model, targetDF, missing)\n    end\n    cm = CombinedModel([springmodel], create_sir)\n    flumodel = CombinedModel([cm], create_flu)\n    return flumodel\nend\n\ntfinal = 240π*u\"d\" #(~2 yrs)\nflumodel = flusim(tfinal)\nCombinedModel{Array{CombinedModel{Array{SpringModel{Array{Quantity{Float64,𝐓^-2,Unitful.FreeUnits{(d^-2,),𝐓^-2,nothing}},1},Tuple{Quantity{Int64,𝐓,Unitful.FreeUnits{(d,),𝐓,nothing}},Quantity{Float64,𝐓,Unitful.FreeUnits{(d,),𝐓,nothing}}},Array{Quantity{Float64,D,U} where U where D,1}},1},getfield(Main, Symbol(\"#create_sir#9\"))},1},getfield(Main, Symbol(\"#create_flu#10\"))}(CombinedModel{Array{SpringModel{Array{Quantity{Float64,𝐓^-2,Unitful.FreeUnits{(d^-2,),𝐓^-2,nothing}},1},Tuple{Quantity{Int64,𝐓,Unitful.FreeUnits{(d,),𝐓,nothing}},Quantity{Float64,𝐓,Unitful.FreeUnits{(d,),𝐓,nothing}}},Array{Quantity{Float64,D,U} where U where D,1}},1},getfield(Main, Symbol(\"#create_sir#9\"))}[CombinedModel{Array{SpringModel{Array{Quantity{Float64,𝐓^-2,FreeUnits{(d^-2,),𝐓^-2,nothing}},1},Tuple{Quantity{Int64,𝐓,FreeUnits{(d,),𝐓,nothing}},Quantity{Float64,𝐓,FreeUnits{(d,),𝐓,nothing}}},Array{Quantity{Float64,D,U} where U where D,1}},1},#create_sir#9}(SpringModel{Array{Quantity{Float64,𝐓^-2,Unitful.FreeUnits{(d^-2,),𝐓^-2,nothing}},1},Tuple{Quantity{Int64,𝐓,Unitful.FreeUnits{(d,),𝐓,nothing}},Quantity{Float64,𝐓,Unitful.FreeUnits{(d,),𝐓,nothing}}},Array{Quantity{Float64,D,U} where U where D,1}}[SpringModel{Array{Quantity{Float64,𝐓^-2,FreeUnits{(d^-2,),𝐓^-2,nothing}},1},Tuple{Quantity{Int64,𝐓,FreeUnits{(d,),𝐓,nothing}},Quantity{Float64,𝐓,FreeUnits{(d,),𝐓,nothing}}},Array{Quantity{Float64,D,U} where U where D,1}}(Quantity{Float64,𝐓^-2,Unitful.FreeUnits{(d^-2,),𝐓^-2,nothing}}[0.000342466 d^-2], (0 d, 753.982 d), Quantity{Float64,D,U} where U where D[25.0 C, 0.0 C d^-1])], #create_sir#9())], getfield(Main, Symbol(\"#create_flu#10\"))())springmodel = flumodel.deps[1].deps[1]\nsirmodel = flumodel.deps[1]\nsol = solve(springmodel)\nplot(sol.t./d, map(x->x[1], sol.u) ./ C)(Image: svg)sirsol = solve(sirmodel)β = 1.0854014119706108 d^-1\n\n\n\n\n\nretcode: Success\nInterpolation: specialized 9th order lazy interpolation\nt: 16-element Array{Quantity{Float64,𝐓,Unitful.FreeUnits{(d,),𝐓,nothing}},1}:\n                0.0 d\n 0.2503747748877873 d\n 0.9420079061012359 d\n 1.9002912698756584 d\n  2.972126338526902 d\n  4.147568957524303 d\n  5.418240373678765 d\n 6.7948860959760315 d\n  8.400900825017708 d\n 10.236958450599571 d\n  12.30882380127413 d\n 13.728455901957311 d\n 15.710893594828972 d\n  17.26796601078083 d\n 19.522036174270298 d\n               20.0 d\nu: 16-element Array{Array{Quantity{Float64,NoDims,Unitful.FreeUnits{(person,),NoDims,nothing}},1},1}:\n [10000.0 person, 1.0 person, 0.0 person]           \n [9999.69 person, 1.31091 person, 0.00115006 person]\n [9998.22 person, 2.76907 person, 0.0065442 person] \n [9993.17 person, 7.80133 person, 0.0251661 person] \n [9976.09 person, 24.8203 person, 0.0882149 person] \n [9912.76 person, 87.9172 person, 0.322914 person]  \n [9661.17 person, 338.559 person, 1.27032 person]   \n [8652.58 person, 1343.08 person, 5.33359 person]   \n [5308.5 person, 4669.16 person, 23.338 person]     \n [1351.18 person, 8576.06 person, 73.7647 person]   \n [166.552 person, 9683.51 person, 150.933 person]   \n [37.1606 person, 9757.62 person, 206.214 person]   \n [4.57084 person, 9712.98 person, 283.447 person]   \n [0.889612 person, 9656.35 person, 343.763 person]  \n [0.0847902 person, 9570.48 person, 430.432 person] \n [0.0516352 person, 9552.24 person, 448.71 person]plot(sirsol.t./d,map(x->stripunits.(x)[2], sirsol.u))(Image: svg)sol = solve(flumodel)β = 1.0854014119706108 d^-1\nGLM Model:\nStatsModels.DataFrameRegressionModel{LinearModel{LmResp{Array{Float64,1}},DensePredChol{Float64,LinearAlgebra.Cholesky{Float64,Array{Float64,2}}}},Array{Float64,2}}\n\nFormula: vaccines_produced ~ 1 + flu_patients\n\nCoefficients:\n                 Estimate Std.Error    t value Pr(>|t|)\n(Intercept)       4892.06   342.292    14.2921   <1e-24\nflu_patients  -0.00529781 0.0655031 -0.0808788   0.9357\n\ntargetDF = 1×3 DataFrame\n│ Row │ year  │ flu_patients │ vaccines_produced │\n│     │ Int64 │ Float64      │ Missing           │\n├─────┼───────┼──────────────┼───────────────────┤\n│ 1   │ 1     │ 3627.46      │ missing           │\n\n\n┌ Warning: In the future eachcol will have names argument set to false by default\n│   caller = evalcontrasts(::DataFrame, ::Dict{Any,Any}) at modelframe.jl:124\n└ @ StatsModels /Users/jamesfairbanks/.julia/packages/StatsModels/AYB2E/src/modelframe.jl:124\n┌ Warning: In the future eachcol will have names argument set to false by default\n│   caller = getmaxwidths(::DataFrame, ::UnitRange{Int64}, ::UnitRange{Int64}, ::Symbol) at show.jl:105\n└ @ DataFrames /Users/jamesfairbanks/.julia/packages/DataFrames/5Rg4Y/src/abstractdataframe/show.jl:105\n┌ Warning: In the future eachcol will have names argument set to false by default\n│   caller = evalcontrasts(::DataFrame, ::Dict{Symbol,StatsModels.ContrastsMatrix}) at modelframe.jl:124\n└ @ StatsModels /Users/jamesfairbanks/.julia/packages/StatsModels/AYB2E/src/modelframe.jl:124\n\n\n\n\n\n1-element Array{Union{Missing, Float64},1}:\n 4872.838053691122"
},

{
    "location": "contributing/#",
    "page": "Contributing",
    "title": "Contributing",
    "category": "page",
    "text": ""
},

{
    "location": "contributing/#Developer-Guidelines-1",
    "page": "Contributing",
    "title": "Developer Guidelines",
    "category": "section",
    "text": "This document explains the process for development on this project. We are using a PR model, so file an issue on the repo proposing your change so that the developers can discuss and provide early feedback, then make a pull request with your changes. Tag the relevant developers with their names in the comments on the PR so their attention can be called to the PR. Shorter PRs get reviewed faster and get more meaningful feedback."
},

{
    "location": "contributing/#Code-Style-1",
    "page": "Contributing",
    "title": "Code Style",
    "category": "section",
    "text": "Docstrings on every function and type.\nUse multiple dispatch or default arguments.\nUse logging with key word arguments for example, @info(\"Inserting new vertex into graph\", vertex=v).\nCreate non-allocating versions of functions such as buildgraph!(g, edges) and allocating versions for end users such as buildgraph(edges) = buildgraph(Graph(), edges).\nUse simple function names when possible."
},

{
    "location": "contributing/#Testing-1",
    "page": "Contributing",
    "title": "Testing",
    "category": "section",
    "text": "Every file in /src should have a test in /test.\nPut tests in their own test set.\nTests are an opportunity to add usage examples.\nTravis-CI will check that tests pass."
},

{
    "location": "contributing/#Documentation-1",
    "page": "Contributing",
    "title": "Documentation",
    "category": "section",
    "text": "Every concept should have an example in the docs.\nIf you need to add a page to the HTML docs add it as /doc/src/file.md and add the corresponding line in /doc/make.jl.\nMake sure the docs build locally before merging with master. Travis will test that the docs build so it is important to make sure you can build locally.\nInstall graphviz locally so that you can test the .dot files."
},

{
    "location": "contributing/#Code-of-Conduct-1",
    "page": "Contributing",
    "title": "Code of Conduct",
    "category": "section",
    "text": "Be nice. Answer questions and provide feedback on PRs and Issues. Help out with what you can, and ask questions about what you don\'t understand."
},

]}
