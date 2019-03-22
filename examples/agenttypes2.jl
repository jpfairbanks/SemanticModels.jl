# -*- coding: utf-8 -*-
using SemanticModels
using SemanticModels.Parsers
using SemanticModels.ModelTools
import SemanticModels.ModelTools: CallArg, RetArg, Edge, Edges, @typegraph, typegraph

# +
using SemanticModels.Parsers
import Base: ==

shorttype(T::Type) = T.name.name

# -

expr = parsefile("agentbased2.jl")
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
E = unique(("\"$(f.func)\"", tuple(shorttype.(f.args)...), shorttype.(f.ret)) for f in Edges(edgelist_symbol))
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

E_typed = unique(("\"$(f.func)\"", tuple(shorttype.(f.args)...), shorttype.(f.ret)) for f in Edges(edgelist_typed))
# -

println("=============\nSymbols Graph\n============")
for e in E
    println(join(e, ", "))
end
println("\n=============\nTypes Graph\n============")
for e in E_typed
    println(join(e, ", "))
end


# ## visualizing the edges
#
# Now that we have extracted the relevant type information, we want to visualize these transformations in a knowledge graph.

using MetaGraphs;
using LightGraphs;
# patch for https://github.com/JuliaGraphs/MetaGraphs.jl/pull/71/files
function escapehtml(i::AbstractString)
    # Refer to http://stackoverflow.com/a/7382028/3822752 for spec. links
    replace=Main.replace
    o = replace(i, "&" =>"&amp;")
    o = replace(o, "\""=>"&quot;")
    o = replace(o, "'" =>"&#39;")
    o = replace(o, "<" =>"&lt;")
    o = replace(o, ">" =>"&gt;")
    return o
end


# +
function buildgraph(E)
    g = MetaDiGraph();
    set_indexing_prop!(g,:label);

    for e in E
        try
            g[e[2],:label]
        catch
            add_vertex!(g,:label,e[2]) # add ags
        end
        
        try
            g[e[3],:label]
        catch
            add_vertex!(g,:label,e[3]) # add rets
        end
        
        try
            add_edge!(g,g[e[2],:label],g[e[3],:label],:label,e[1])#escapehtml(string(e[1]))) # add func edges
        catch
            nothing
        end
    end
    return g
end

# for e in edges(g)
#     sn, dn = g[src(e),:label], g[dst(e), :label]
#     # f = g[sn, :label, dn, :label]
#     @show g.eprops[e][:label]
#     println(sn, "--->", dn)
# end
function projectors(g, key=:label)
    newedges = []
for v in vertices(g)
    args = g.vprops[v][key]
    if isa(args, Tuple)
        for (i, a) in enumerate(args)
            push!(newedges, ("π$i", a, args))
        end
    end
    end
        return newedges
end

function add_projectors!(g, key=:label)
    πs = projectors(g)
    for e in πs
        add_edge!(g,g[e[2],:label],g[e[3],:label],:label,e[1])
    end
    return g, πs
end
# -

g = buildgraph(E)
add_projectors!(g)
savegraph("exampletypegraph.dot",g,DOTFormat());

run(`dot -Tsvg -O exampletypegraph.dot`);

s = read("exampletypegraph.dot.svg",String);
display("image/svg+xml",s)

g = buildgraph(E_typed)
g, πs = add_projectors!(g);
g

savegraph("exampletypegraph_2.dot",g,DOTFormat());
run(`dot -Tsvg -O exampletypegraph_2.dot`);

s = read("exampletypegraph_2.dot.svg",String);
display("image/svg+xml",s)
