# -*- coding: utf-8 -*-
# + {}
using Random
Random.seed!(0) # seed the random number generator to 0, for a reproducible demonstration
using BayesNets
using Pkg
using LightGraphs
using Catlab.WiringDiagrams

import Catlab.Graphics: to_graphviz
include("bayesUtil.jl")

⊗(a::WiringDiagram, b::WiringDiagram) = otimes(a,b)
import Base: ∘
∘(a::WiringDiagram, b::WiringDiagram) = compose(b, a)
⊚(a,b) = b ∘ a
⊚(a...) = foldl(⊚,a)
# -

#Create Equations
a_equation = randn(100)
b_equation = randn(100) .+ 2*a_equation .+ 3
d_equation = randn(100) .+ 2*a_equation .+ 3
c_equation = randn(100) .+ 2*b_equation .+ 2*d_equation .+ 3
e_equation = randn(100) .+ 2*d_equation .+ 3

#https://link.springer.com/chapter/10.1007/978-3-030-17127-8_18
data = DataFrame(a=a_equation, b=b_equation, c=c_equation, d=d_equation, e=e_equation)
cpdA = fit(StaticCPD{Normal}, data, :a)
cpdB = fit(LinearGaussianCPD, data, :b, [:a])
cpdD = fit(LinearGaussianCPD, data, :d, [:a])
cpdC = fit(LinearGaussianCPD, data, :c, [:b,:d])
cpdE = fit(LinearGaussianCPD, data, :e, [:d])

bn1 = BayesNet([cpdA, cpdB, cpdD, cpdC, cpdE])

wiringDiagram1 = getWiringDiagram(bn1)
to_graphviz(wiringDiagram1, labels=true)


