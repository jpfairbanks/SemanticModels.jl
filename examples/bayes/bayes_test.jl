# ---
# jupyter:
#   jupytext:
#     text_representation:
#       extension: .jl
#       format_name: light
#       format_version: '1.4'
#       jupytext_version: 1.2.1
#   kernelspec:
#     display_name: Julia 1.0.3
#     language: julia
#     name: julia-1.0
# ---

# +
using Random
Random.seed!(0) # seed the random number generator to 0, for a reproducible demonstration
using BayesNets
using Pkg
using LightGraphs
using Catlab.WiringDiagrams

import Catlab.Graphics: to_graphviz
include("bayesUtil.jl")
# -

#Create Equations
a_equation = randn(100)
b_equation = randn(100) .+ 2*a_equation .+ 3
c_equation = randn(100) .+ 2*b_equation .+ 3

#Build Rain, Sprinkler, GrassWet Example BayesNet
data = DataFrame(rain=a_equation, sprinkler=b_equation, grasswet=c_equation)
cpdA = fit(StaticCPD{Normal}, data, :rain)
cpdB = fit(LinearGaussianCPD, data, :sprinkler, [:rain])
cpdC = fit(LinearGaussianCPD, data, :grasswet, [:rain,:sprinkler])

bn2 = BayesNet([cpdA, cpdB, cpdC])

wiringDiagram = getWiringDiagram(bn2)
to_graphviz(wiringDiagram, labels=true)

print(fieldnames(Doctrines.FreeSymmetricMonoidalCategory.Hom))
print(typeof(wiringDiagram))

println(typeof(wiringDiagram.args))
# println(fieldnames(Doctrines.FreeSymmetricMonoidalCategory.Hom))
print(wiringDiagram.args)

function rpxe_esrap(S_expr::Tuple)
  return Expr( Tuple( isa(i, Tuple) ? rpxe_esrap(i) : i for i in S_expr )... );
end

temp = wiringDiagram
B = IOBuffer() 
Meta.show_sexpr(B, wiringDiagram)      
seek(B, 0);                   
SExprStr = read(B, String)  
close(B)
print(SExprStr)



