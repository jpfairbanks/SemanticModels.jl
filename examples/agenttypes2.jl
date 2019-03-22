# # @typegraph example
#
# In this notebook, we will be going through a tutorial on how to use the `@typegraph` macro to extract the mapping of how type are transformed through functions.

using SemanticModels
using SemanticModels.Parsers
using SemanticModels.ModelTools
import SemanticModels.ModelTools: CallArg, RetArg, Edge, Edges, @typegraph, typegraph

?@typegraph

# After loading `@typegraph` in to our workspace, we simply begin the extraction by calling the macro immediately followed by an `Expr` which will return an edge list which is easily passed through to `MetaGraphs.jl` to visualize the transformations that are taking place throughout the code.
#
# *_To learn more about `Expr` & metaprogramming, we recommend looking at the offcial [Julia docs](@https://docs.julialang.org/en/v1.0/manual/metaprogramming/) on the topic._

# +
using SemanticModels.Parsers
import Base: ==

shorttype(T::Type) = T.name.name
# -

# Below we are using our `parsefile` function to take scripts and wrap them around in `module` headings that way they can be consumed by our other API's. We then pass off our `Expr`s to our `typegraph` function which collects all the type information we would like extracted from the code.

expr = parsefile("agentbased2.jl")
expr2 = ModelTools.typegraph(expr.args[end])
expr3 = :(module Foo 
    using SemanticModels.ModelTools
    import SemanticModels.ModelTools: CallArg, RetArg
    $(expr2.args...) end);

# In the above example, we have a simple agent based simulation where we defined new stucts to collect the singltonian type information for our simulation. To reduce the nosie from collecting the iterations throughout the runtime of our model we need to collect the unique calls through our our example which contain the relevant information.

# +
Mod = eval(expr3)
Mod.main(10)
edgelist_symbol = Mod.edgelist

E = unique((f.func, f.args, f.ret) for f in Edges(edgelist_symbol))
E = unique(("\"$(f.func)\"", shorttype.(f.args), shorttype.(f.ret)) for f in Edges(edgelist_symbol))
@show E
# -

# We are going to repeat the process again for another similar script to see if we are able to detect the differences between the two programs.

expr = parsefile("agenttypes.jl")
expr2 = ModelTools.typegraph(expr.args[end].args[end].args[end])
expr3 = :(module ModTyped
    using SemanticModels.ModelTools
    import SemanticModels.ModelTools: CallArg, RetArg
    $(expr2.args...) end);

# +
Mod = eval(expr3)
Mod.main(10)
edgelist_typed = Mod.edgelist

E_typed = unique(("\"$(f.func)\"", shorttype.(f.args), shorttype.(f.ret)) for f in Edges(edgelist_typed));
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
g = buildgraph(E)
savegraph("exampletypegraph.dot",g,DOTFormat());

run(`dot -Tsvg -O exampletypegraph.dot`);

s = read("exampletypegraph.dot.svg",String);
display("image/svg+xml",s)

g = buildgraph(E_typed)
savegraph("exampletypegraph_2.dot",g,DOTFormat());

run(`dot -Tsvg -O exampletypegraph_2.dot`);

s = read("exampletypegraph_2.dot.svg",String);
display("image/svg+xml",s)

# ## comparing programs
#
# From the knowledge graphs, we can see how the two programs are difference from each other. 


