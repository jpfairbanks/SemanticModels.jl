# Multiple Knowledge Graphs

The input data is a model as defined in a script which contains 1 top level module and a
main function. The default name for the main function is main but you could pass in a
different name if you wanted to.

Example:

```julia
module Foo
using Roots
a = 3
b = 4
c = -1
f(x,y) = c*x*y + a*x + b

function main()
    x0 = [0.0,0.0]
    xstar = RootProblem(f, x0)
    @show xstar
end
end #module
```

There are a few different forms of knowledge graphs that can be extracted from codes.

1. The type graph: Vertices are types, edges are functions between types
2. Vertices are functions and variables, edges represent dataflow, function references
   variable or function calls function.
3. Conceptual knowledge graph from text, vertices are concepts edges are relations between concepts.

## Linking KGs
Between different scripts we should be able to link the graph by defining an alias
relation that says "these vertices are equivalent" and then merging the graphs.

With a script we should be able to merge the types of graph by converting the type graph
into its pseudodual. The pseudodual is constructed by take a type-function graph and
constructing a new graph where functions and types are both vertices, if `U =
typeof(f(::V))` then there is a pair of edges `V -> f -> U` and there are edges for the
functions `getindex(u::U, v::V) ie (U, V) -> getindex -> typeof(u[v])` for all the values
of `v`. These represent *untupling* and accessing fields of structs.

## How do KGs related to Use Cases?

The different types of knowledge graph that can be extracted can help address the use cases in different ways.

1. Model Augmentation: we need dataflow, types, and concepts for implementing the
   "frontend" of ModelTool. This is an informative step to show a person extending
   SemanticModels how to implement ingestion for a new class of models. Once we have the
   new class of models implemented, we only need Exprs and do not necessarily need the KG
   to do model augmentation.

2. Metamodel construction: We need the type graph for program refinement and the dataflow
   and concept graphs to do the metamodeling reasoning. This part will probably leverage
   all the graphs at run time when solving for the combined model.

3. Model Validation: we need the structured representation of the model that is used in
   model augmentation and the trace of execution that follows the same lines as the traces
   used to build the dataflow and type-function graph. I don't think this needs the KG
   directly unless we find that we can build better models with the KG than with the
   trace. I think the trace is more useful because it is hierarchical and DNNs work better
   on trees than on general graphs.
