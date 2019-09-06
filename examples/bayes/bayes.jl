using Random
Random.seed!(0) # seed the random number generator to 0, for a reproducible demonstration
using BayesNets
using Pkg
using LightGraphs

a = randn(100)
b = randn(100) .+ 2*a .+ 3
c = randn(100) .+ 2*b .+ 3

data = DataFrame(a=a, b=b, c=c)
cpdA = fit(StaticCPD{Normal}, data, :a)
cpdB = fit(LinearGaussianCPD, data, :b, [:a])
cpdC = fit(LinearGaussianCPD, data, :c, [:b])

bn2 = BayesNet([cpdA, cpdB, cpdC])

println(fieldnames(BayesNet))

typeof(bn2.cpds[1])
println(bn2.cpds[1])

typeof(bn2.dag)

LightGraphs.dfs_tree(bn2.dag, a:)


