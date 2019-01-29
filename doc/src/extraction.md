# Knowledge Extraction 

## Documents

SemanticModels.jl takes the opinion that the source code and documentation is more valuable than the scientific papers
themselves, even though traditional scientific incentive systems focus on only the papers.

Since natural language text is primarily being used for context, understanding and disambiguation of code information,
we use rules-based methods to extract definitions and conceptual connections. The Automates framework developed at the
University of Arizona is very helpful for writing rules based information extraction software. Our contributions to
automates have been contributed upstream.

The primary focus of this document is the extraction of scientific knowledge from codebases.

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


## API reference

```@autodocs
Modules = [SemanticModels.Parsers]
```
