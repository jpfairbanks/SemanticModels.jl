module OpenModels
import Base: ==
using SemanticModels.ModelTools
import SemanticModels.ModelTools: model
using Catlab.Graphics.Graphviz
import Catlab.Graphics.Graphviz: Graph, Edge


export OpenModel

struct OpenModel{V,M} <: AbstractModel
    dom::V
    model::M
    codom::V
end

"""    Graph(f::OpenModel)

convert an OpenModel into a GraphViz Graph. This calls Graph(::Model) and then adds vertices (and edges) for the domain and codomain of the open model.
"""
function Graph(f::OpenModel)
    g = Graph(f.model)
    A, M, B = f.dom, f.model, f.codom
    stmts_dom = map(enumerate(A)) do (i,a)
        m = M.S[a]
        Edge(["I$i", "$m"], Attributes(:style=>"dashed"))
    end
    stmts_codom = map(enumerate(B)) do (i,a)
        m = M.S[a]
        Edge(["$m", "O$i"], Attributes(:style=>"dashed"))
    end
    append!(g.stmts, append!(stmts_dom, stmts_codom))
    return g
end

function ==(f::OpenModel,g::OpenModel)
    all(isequal.(f.dom, g.dom)) && all(isequal.(f.codom, g.codom)) && f.model == g.model
end

# otimes and compose general that use disjoin union functions

end