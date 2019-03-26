# -*- coding: utf-8 -*-
# # @typegraph example
#
# In this notebook, we will be going through a tutorial on how to use the `typegraph` functionality to extract the relationships between types and functions within programs.

using SemanticModels
using SemanticModels.Parsers
using SemanticModels.ModelTools
import SemanticModels.ModelTools: CallArg, RetArg, Edge, Edges, @typegraph, typegraph

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
E = unique(("\"$(f.func)\"", tuple(shorttype.(f.args)...), shorttype.(f.ret)) for f in Edges(edgelist_symbol))
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

# +
function draw(g, filename)
    savegraph(filename, g, DOTFormat())
    try
        run(`dot -Tsvg -O $filename`)
    catch ex
        @warn "Problem running dot" error=ex
        try
            run(`dot --version`)
        catch
            @warn "Dot is not installed"
        end
    end
    display("image/svg+xml", read("$filename.svg", String))
end

using Colors
cm = Colors.colormap("RdBu", 2nv(h))
# -

g = buildgraph(E)
add_projectors!(g)

# We will draw the graph of types in initial model that uses symbols to represent the agent states. Remember that Symbol is type that represents "things that are like variable names" and in this case we are using the Symbol type to represent the agent states of :Susceptible, :Infected, and :Recovered. 
#
# In this drawing each vertex has its own color. These colors will be used again when drawing the next graph.

color(v) = "#$(hex(cm[v + floor(Int, nv(h)/2)]))" #"gray$(100 - 3v)"
for v in vertices(g)
    g.vprops[v][:color] = color(v)
    g.vprops[v][:style] = "filled"
end
draw(g, "exampletypegraph.dot")

# We then onstruct the typegraph for the program 2, which uses singleton types to represent the state of the agents. One of the central tennants of this project is that the more information you inject into the julia type system, the more the compiler can help you. Here we will see that they type system knows about the structure of the agents behavior now that the we have encoded their states as types.

h = deepcopy(g)
g = buildgraph(E_typed)
g, πs = add_projectors!(g);
g

# now we draw the new, bigger type graph with the same color scheme as before. We define a graph homomorphism $\phi$ that maps every type to one of the vertices of the original graph show above. This homomorphism from $\phi: G \mapsto H$ shows how the semantics of the first program is embedded in the semantics of the second program. 

# +
color(v) = "#$(hex(cm[v + floor(Int, nv(h)/2)]))" #"gray$(100 - 3v)"
ϕ(t) = begin
    d=Dict{Symbol,Symbol}(:Susceptible=>:Symbol,
        :Infected=>:Symbol,
        :Recovered=>:Symbol,
    )
    val = get(d, t, t)
    return val
end

for v in vertices(g)
    vname = ϕ.(g[v,:label])
    try
        vh = h[vname, :label]
        g.vprops[v][:fillcolor]=color(vh)
        g.vprops[v][:style]="filled"
    catch ex
        @warn ex
    end
end

# -

draw(g, "typegraphmorphism.dot")

# Note that the type Symbol does not appear in the second program at all, but instead the types Susceptible, Infected, and Recovered play the role of the Symbol vertex in this new graph. The graph is bigger and harder to visualize, but it contains the same structure. You can chack that for every edge in the $g$ there is an edge in $h$ that has the same color vertices as endpoints.
#
# In this new model the structure of the agents states is readily apparant in the type system.

tedges = filter((p) -> p[2][:label]=="\"transition\"", g.eprops)
tv = src.(keys(tedges)) ∪ dst.(keys(tedges))
DFA = g[tv]
draw(DFA, "type_DFA.dot")

# By contracting the edges labeled $\pi_3$ you identify a minor of 
# the typegraph isomorphic to the discrete finite automata or 
# finite state machine representation of the agents in our agent based simulation.
#
#
# Since the typegraph contains this information, we can say that the julia compiler "understands" 
# a semantic feature of the model. We can introduce compile time logic based on these properties of
# the model. ANy changes to the underlying code that changed the state space of the agents, or the 
# possible transitions they undergo would affect the type graph of the model.
#
# For the model version that used :Symbols, or categorical states, the julia type system is blissfully 
# ignorant of the relationships between the states. However once we introduce types to the model, the 
# compiler is able to represent the structure of the model. Any changes to the model will either preserve 
# or disrupt this type graph and we will be able to identify and quantify that change to the structure of the model.  
#
# This example is an instance of a large phenomenon that we hope to advance in modeling.
# Programs that implement models can get more out of the compiler if they add more information.
# In this case we declared the states of our agents as types and the compiler was able to infer
# the state transition graph from the our code.

# ## Conclusions
#
# We can see from the examples presented here that similar models produce similar type graphs. In this case we have two programs that impement the same model and have homomorphic type graphs. This homomorphism is natural in the sense that every vertex that appears in both graphs satisfies $\phi(v) = v$. Adding information to the type system in the julia program allows the type graph of the model to understand more of the program semantics. This powerful insight can teach the machines to reason about the behaviour of computational models.


