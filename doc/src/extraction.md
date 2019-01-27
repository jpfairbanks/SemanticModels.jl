# Knowledge Extraction 

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

We can read in the file [../../examples/epicookbook/notebooks/KeelingRohani/SISModel.jl](@ref)

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
```

This extractor provides edges to the [knowledge graphs](@ref).
