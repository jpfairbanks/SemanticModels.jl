notebooks = ["agentbased.jl",
             "agentgraft.jl",
             "modelmacro.jl",
             "monomial_regression.jl",
             "multivariate_regression.jl",
             "polynomial_regression.jl",
             "workflow.jl",
             "pseudo_polynomial_regression.jl",
             "odegraft.jl",
             ]
for nb in notebooks
    @info "Running example notebook" file=nb
    include(nb)
end
