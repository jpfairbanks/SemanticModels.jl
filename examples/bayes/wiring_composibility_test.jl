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
# -

#Create Equations
rain_equation = randn(100)
sprinkler_equation = randn(100) .+ 2 * rain_equation
grasswet_equation_r = randn(100) .+ 2 * rain_equation
grasswet_equation_s = randn(100) .+ 2 * sprinkler_equation

#Build Rain, Sprinkler, GrassWet Example BayesNet
data = DataFrame(rain=rain_equation, sprinkler=sprinkler_equation, grasswet_r=grasswet_equation_r, grasswet_s = grasswet_equation_s)
cpdr = fit(StaticCPD{Normal}, data, :rain)
cpds = fit(LinearGaussianCPD, data, :sprinkler, [:rain])
cpdg_r = fit(LinearGaussianCPD, data, :grasswet_r, [:rain])
cpdg_s = fit(LinearGaussianCPD, data, :grasswet_s, [:sprinkler])

bn1 = BayesNet([cpdr, cpds, cpdg_r])
bn2 = BayesNet([cpdr, cpds, cpdg_s])

wiringDiagram_1 = getWiringDiagram(bn1)
to_graphviz(wiringDiagram, labels=true)

wiringDiagram_2 = getWiringDiagram(bn2)
to_graphviz(wiringDiagram, labels=true)

w_3 = wiringDiagram_1 ⊗ wiringDiagram_2
to_graphviz(w_3, labels=true)


