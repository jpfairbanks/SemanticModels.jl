using Documenter
@info "Loading module"
using Semantics

@info "Makeing docs"
makedocs(
modules     = [Semantics],
format      = :html,
sitename    = "Semantics",
doctest     = false,
pages       = Any[
    "Getting Started"               => "index.md",
    "Library Reference" => "library.md",
    "Slides"               => "slides.md",
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
