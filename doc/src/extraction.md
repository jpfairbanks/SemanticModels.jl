# Knowledge Extraction 

## Documents

SemanticModels.jl takes the opinion that the source code and documentation is more valuable than the scientific papers
themselves, even though traditional scientific incentive systems focus on only the papers.

Since natural language text is primarily being used for context, understanding and disambiguation of code information,
we use rules-based methods to extract definitions and conceptual connections. The Automates framework developed at the
University of Arizona is very helpful for writing rules based information extraction software. Our contributions to
automates have been contributed upstream.

The primary focus of this document is the extraction of scientific knowledge from codebases. We start by describing the
natural language information extraction pipeline

### Information Extraction for Semantic Modeling

To select knowledge elements that should be present in knowledge graphs we conduct information extraction
on various sources files including:

1. Comments within source code files
2. Code phenomena such as function names and parameters

Ongoing work involves building extractors for:
3. Research Publications
4. Documentation for Libraries and Frameworks utilized within domain

#### Information Extraction Pipeline

1. Process source files including research papers, source code, and documentation files into plain text or JSON document
   formats
2. Extract natural language text such as docstrings and comments 
3. Parse source code with to identify function names and parameters
4. Match modeling text concepts with code variables using lexical-tokens 
6. Run [Automates](https://github.com/ml4ai/automates) rule-based extraction on the text associated with a code concepts
7. Create knowledge elements from rule matches
 
SemanticModels has created rules to extract phenomena such as definitions of parameters. These same parameters can then
be recognized within source code beginning with lexical matching for mapping human language definitions to specific
source code instantiations.

We are currently in the process of collecting and annotating ground truth data to
use in constructing machine learning models to do information extractions based on
information elements of interest that we identify in use case planning for 
meta-modeling related functionalities users will be able to work with.

## Code

SemanticModels supports extracting knowledge from both the static syntactic level information that is accessible from
the source code. We use the same Julia code parser as the `julia`` program.

This parser takes text representations of julia code and returns an abstract syntax tree (AST).
We then walk this AST looking for julia program expressions that create information. For example function definitons,
variable assignments and module imports. We recurse into the function definitions to find the local variable definitions
(and closures) used in implementing the functions. 

This form of static program analysis provides the more direct way to access user defined functions. However it cannot
access the type information and run time values. For this we use Cassette.jl which is a library for context dependent
execution. SemanticModels uses a custom compiler pass to access code infomation and extract information at compile time.
In addition we use the overdub component of Cassette to build a tracer for capturing run time values. Since Julia syntax
is very regular and metaprogramming is a standard (abeit advanced) practice in the julia community the syntax trees and
CodeInfo objects are designed to be manipulated programmatically, which makes writing recursive generic syntax
extraction rules straightforward.

### Example

We can read in the file `examples/epicookbook/notebooks/KeelingRohani/SISModel.jl`

```julia
using DifferentialEquations

# # Model Specifications
# - SH num of high risk susceptible
# - IH num of high risk infected 
# - SL num of low risk susceptible
# - IL num of low risk infected
# # Parameters
# - beta represents the determines the contact and transmission rates
# - gamma the rate at which treatment is sought

function sis_ode(du,u,p,t)
        SH,IH,SL,IL = u
        betaHH,betaHL,betaLH,betaLL,gamma=p
        du[1]=-(betaHH*IH+betaHL*IL)*SH+gamma*IH
        du[2]=+(betaHH*IH+betaHL*IL)*SH-gamma*IH
        du[3]=-(betaLH*IH+betaLL*IL)*SL+gamma*IL
        du[4]=+(betaLH*IH+betaLL*IL)*SL-gamma*IL
end

parms =[10,0.1,0.1,1,1]
init=[0.19999,0.00001,0.799,0.001]
tspan=tspan = (0.0,15.0)

sis_prob = ODEProblem(sis_ode,init,tspan,parms)
sis_sol = solve(sis_prob,saveat=0.1);

using Plots
plot(sis_sol,xlabel="Time (Years)",ylabel="Proportion of Population")
```

and run it through the code syntactic extractor which will produce the following information.


```julia
┌ Info: script uses modules
│   modules =
│    2-element Array{Any,1}:
│     Any[:DifferentialEquations]
└     Any[:Plots]

┌ Info: script defines functions
│   funcs =
│    1-element Array{Any,1}:
│     :(sis_ode(du, u, p, t)) => quote
│        #= none:28 =#
│        (SH, IH, SL, IL) = u
│        #= none:29 =#
│        (betaHH, betaHL, betaLH, betaLL, gamma) = p
│        #= none:30 =#
│        du[1] = -((betaHH * IH + betaHL * IL)) * SH + gamma * IH
│        #= none:31 =#
│        du[2] = +((betaHH * IH + betaHL * IL)) * SH - gamma * IH
│        #= none:32 =#
│        du[3] = -((betaLH * IH + betaLL * IL)) * SL + gamma * IL
│        #= none:33 =#
│        du[4] = +((betaLH * IH + betaLL * IL)) * SL - gamma * IL
└    end

┌ Info: script defines glvariables
│   funcs =
│    5-element Array{Any,1}:
│        :parms => :([10, 0.1, 0.1, 1, 1])
│         :init => :([0.19999, 1.0e-5, 0.799, 0.001])
│        :tspan => :(tspan = (0.0, 15.0))
│     :sis_prob => :(ODEProblem(sis_ode, init, tspan, parms))
└      :sis_sol => :(solve(sis_prob, saveat=0.1))

┌ Info: sis_ode(du, u, p, t) uses modules
└   modules = 0-element Array{Any,1}
┌ Info: sis_ode(du, u, p, t) defines functions
└   funcs = 0-element Array{Any,1}
┌ Info: sis_ode(du, u, p, t) defines glvariables
│   funcs =
│    6-element Array{Any,1}:
│                            :((SH, IH, SL, IL)) => :u
│     :((betaHH, betaHL, betaLH, betaLL, gamma)) => :p
│                                       :(du[1]) => :(-((betaHH * IH + betaHL * IL)) * SH + gamma * IH)
│                                       :(du[2]) => :(+((betaHH * IH + betaHL * IL)) * SH - gamma * IH)
│                                       :(du[3]) => :(-((betaLH * IH + betaLL * IL)) * SL + gamma * IL)
└                                       :(du[4]) => :(+((betaLH * IH + betaLL * IL)) * SL - gamma * IL)
┌ Info: Edges found
└   path = "examples/epicookbook/notebooks/KeelingRohani/SISModel.jl"
(:Modeling, :takes, :parms, :([10, 0.1, 0.1, 1, 1]))
(:Modeling, :has, :parms, :prop_collection)
(:Modeling, :takes, :init, :([0.19999, 1.0e-5, 0.799, 0.001]))
(:Modeling, :has, :init, :prop_collection)
(:Modeling, :structure, :tspan, :((0.0, 15.0)))
(:Modeling, :comp, :tspan, 0.0)
(:Modeling, :comp, :tspan, 15.0)
(:Modeling, :output, :sis_prob, :(ODEProblem(sis_ode, init, tspan, parms)))
(:Modeling, :input, :sis_ode, Symbol[:init, :tspan, :parms])
(:Modeling, :output, :sis_sol, :(solve(sis_prob, saveat=0.1)))
(:Modeling, :input, :sis_prob, Symbol[Symbol("saveat=0.1")])
("Modeling.sis_ode(du, u, p, t)", :destructure, :((SH, IH, SL, IL)), :u)
("Modeling.sis_ode(du, u, p, t)", :comp, :u, :SH)
("Modeling.sis_ode(du, u, p, t)", :comp, :u, :IH)
("Modeling.sis_ode(du, u, p, t)", :comp, :u, :SL)
("Modeling.sis_ode(du, u, p, t)", :comp, :u, :IL)
("Modeling.sis_ode(du, u, p, t)", :destructure, :((betaHH, betaHL, betaLH, betaLL, gamma)), :p)
("Modeling.sis_ode(du, u, p, t)", :comp, :p, :betaHH)
("Modeling.sis_ode(du, u, p, t)", :comp, :p, :betaHL)
("Modeling.sis_ode(du, u, p, t)", :comp, :p, :betaLH)
("Modeling.sis_ode(du, u, p, t)", :comp, :p, :betaLL)
("Modeling.sis_ode(du, u, p, t)", :comp, :p, :gamma)
("Modeling.sis_ode(du, u, p, t)", :output, :(du[1]), :(-((betaHH * IH + betaHL * IL)) * SH + gamma * IH))
("Modeling.sis_ode(du, u, p, t)", :input, :(-((betaHH * IH + betaHL * IL)) * SH), Symbol[Symbol("gamma * IH")])
("Modeling.sis_ode(du, u, p, t)", :output, :(du[2]), :(+((betaHH * IH + betaHL * IL)) * SH - gamma * IH))
("Modeling.sis_ode(du, u, p, t)", :input, :(+((betaHH * IH + betaHL * IL)) * SH), Symbol[Symbol("gamma * IH")])
("Modeling.sis_ode(du, u, p, t)", :output, :(du[3]), :(-((betaLH * IH + betaLL * IL)) * SL + gamma * IL))
("Modeling.sis_ode(du, u, p, t)", :input, :(-((betaLH * IH + betaLL * IL)) * SL), Symbol[Symbol("gamma * IL")])
("Modeling.sis_ode(du, u, p, t)", :output, :(du[4]), :(+((betaLH * IH + betaLL * IL)) * SL - gamma * IL))
("Modeling.sis_ode(du, u, p, t)", :input, :(+((betaLH * IH + betaLL * IL)) * SL), Symbol[Symbol("gamma * IL")])
```

This extractor provides edges to the [Knowledge Graphs](@ref).

## Reasoning

Once the information is extracted from the documentation and code, we can visualize the knowledge as a graph.

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
of *relevant*. From this subgraph a human modeler can easily instruct the SemanticModels
system on how to combine the `SEIRmodel` and `ScalingModel` programs into a single model
and generate a program to execute it.

Since the goal of this project is to augment scientists through knowledge extraction,
reasoning, and generation, we leave some decisions up to the human user. The user must
program the library to build the metamodel. This requires some way for the user to
instruct the machine on what they want to know. Any API that supports augmenting
scientists will require some human intervention in the reasoning and generation stages as
the system must get input from the user as to the questions being asked of it. We veiw
this to analogous to a data analyst working with a database system, a query planner is
able to optimize queries based on knowledge about the schema and data statistics, but it
must still wait for a human to provide a query. In this way `SemanticModels` similarly
uses user guidance for reasoning and generation tasks.

## API reference

```@autodocs
Modules = [SemanticModels.Parsers]
```

