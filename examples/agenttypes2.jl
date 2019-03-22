using SemanticModels
using SemanticModels.Parsers
using SemanticModels.ModelTools
import SemanticModels.ModelTools: CallArg, RetArg, Edge, Edges, @typegraph, typegraph

using SemanticModels.Parsers
import Base: ==

expr = parsefile("agentbased.jl")
expr2 = ModelTools.typegraph(expr.args[end])
# ModEx = Expr(:Module)
expr3 = :(module Foo 
    using SemanticModels.ModelTools
    import SemanticModels.ModelTools: CallArg, RetArg
    $(expr2.args...) end)

# +
Mod = eval(expr3)
Mod.main(10)
edgelist_symbol = Mod.edgelist

E = unique((f.func, f.args, f.ret) for f in Edges(edgelist_symbol))
@show E
# -

expr = parsefile("agenttypes.jl")
expr2 = ModelTools.typegraph(expr.args[end].args[end].args[end])
expr3 = :(module ModTyped
    using SemanticModels.ModelTools
    import SemanticModels.ModelTools: CallArg, RetArg
    $(expr2.args...) end)

# +
Mod = eval(expr3)
Mod.main(10)
edgelist_typed = Mod.edgelist

E_typed = unique((f.func, f.args, f.ret) for f in Edges(edgelist_typed))
# -

println("=============\nSymbols Graph\n============")
for e in E
    println(join(e, ", "))
end
println("\n=============\nTypes Graph\n============")
for e in E_typed
    println(join(e, ", "))
end

