using Test
using SemanticModels.Extraction

with_logger(ConsoleLogger(stderr, Logging.Debug)) do
  def_output_dir = "../test/kg"
  g = definitiongraph(def_output_dir, sequentialnamer())
  @show g
  #@show props(g)
  for (k,v) in g.vprops
      println(join(["Vertex", k, v], " "))
  end
  for (k,v) in g.eprops
      println(join(["Edge", k, v], " "))
  end
end
