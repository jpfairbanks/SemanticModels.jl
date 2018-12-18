using Documenter

function makefigs(ext="svg")
    try
        dotfiles = filter(x->endswith(x, ".dot"), readdir("src/img"))
        run(`dot -T$ext -O src/img/$dotfiles`)
    catch ex
        @warn "Could not update figures, perhaps dot is not installed."
        @warn ex
    end

end

@info "Making Figures"
makefigs()
makefigs("png")

@info "Loading module"
using SemanticModels
@info "Making docs"
makedocs(
modules     = [SemanticModels],
format      = :html,
sitename    = "SemanticModels",
doctest     = false,
pages       = Any[
    "SemanticModels.jl"               => "index.md",
    "Approaches" => "approach.md",
    "Library Reference" => "library.md",
    "Slides"               => "slides.md",
    "Dubstep" => "dubstep.md",
    "Flu Model" => "FluModel.md"
    # "Model Types"                   => "types.md",
    # # "Reading / Writing Models"    => "persistence.md",
    # # "Plotting"                    => "plotting.md",
    # # "Parallel Algorithms"         => "parallel.md",
    # "Contributing"                  => "contributing.md",
    # "Developer Notes"               => "developing.md",
    # "License Information"           => "license.md",
    # "Citing SemanticModels"         => "citing.md"
]
)

# # deploydocs(
# # deps        = nothing,
# # make        = nothing,
# # repo        = "github.com/jpfairbanks/SemanticModels.jl.git",
# # target      = "build",
# # julia       = "stable",
# # osname      = "linux"
# # )

# # rm(normpath(@__FILE__, "../src/contributing.md"))
# # rm(normpath(@__FILE__, "../src/license.md"))
