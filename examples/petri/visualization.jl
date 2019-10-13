module Visualization
using Catlab.Graphics.Graphviz
import Catlab.Graphics.Graphviz: Graph
import Base.Iterators: flatten
using ModelingToolkit
using Petri

graph_attrs = Attributes(:rankdir=>"LR")
node_attrs  = Attributes(:shape=>"plain", :style=>"filled", :color=>"white")
edge_attrs  = Attributes(:splines=>"splines")

include("malaria.jl")
STATELOOKUP = Malaria.STATELOOKUP


function edgify(root::Operation, transition::Int, reverse::Bool)
    attr = Attributes()
    i = transition
    if root.op == (+)
        return map(root.args) do x
            weight = ""
            if x.op == (*)
                a = x.args[2].op.name
                weight = "$(x.args[1].value)"
            else
                a = x.op.name
            end
            b = STATELOOKUP[a]
            attr =  Attributes(:label=>"$weight", :labelfontsize=>"6")
            return Edge(reverse ? ["T$i", "X$b"] : ["X$b", "T$i"],attr)
        end
    end
    if root.op == (*)
        b = STATELOOKUP[root.args[2].op.name]
        weight = "$(root.args[1].value)"
        attr =  Attributes(:label=>"$weight", :labelfontsize=>"6")
    else
        b = STATELOOKUP[root.op.name]
    end
    return [Edge(reverse ? ["T$i", "X$b"] : ["X$b", "T$i"], attr)]
end

function Graph(model::Petri.Model)
    statenodes = [Node(string("X$s"), Attributes(:shape=>"circle", :color=>"dodgerblue2")) for s in model.S]
    transnodes = [Node("T$i", Attributes(:shape=>"square", :color=>"forestgreen")) for i in 1:length(model.Δ)]

    stmts = vcat(statenodes, transnodes)
    edges = map(enumerate(model.Δ)) do (i,t)
        vcat(edgify(t[1], i, false), edgify(t[2], i, true))
    end |> flatten |> collect
    stmts = vcat(stmts, edges)
    g = Graphviz.Graph("G", true, stmts, graph_attrs, node_attrs,edge_attrs)
    return g
end

function Graph(f::Malaria.OpenModel)
    g = Graph(f.model)
    A, M, B = f.dom, f.model, f.codom
    stmts_dom = map(A) do a
        m = M.S[a]
        Edge(["I$a", "X$m"], Attributes(:style=>"dashed"))
    end
    stmts_codom = map(A) do a
        m = M.S[a]
        Edge(["X$m", "O$a"], Attributes(:style=>"dashed"))
    end
    append!(g.stmts, append!(stmts_dom, stmts_codom))
    return g
end



f = Malaria.foodchain
g = Graph(f)
pprint(g)
output = run_graphviz(g, prog="dot", format="svg")
write("img/foodchain.svg", output)

f = Malaria.foodstar
g = Graph(f)
pprint(g)
output = run_graphviz(g, prog="dot", format="svg")
write("img/foodstar.svg", output)

end
