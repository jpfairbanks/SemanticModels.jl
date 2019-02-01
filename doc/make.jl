using Documenter
using Latexify
using CSV

function makefigs(ext="svg")
    try
        imgdir = "doc/src/img"
        dotfiles = filter(x->endswith(x, ".dot"), readdir(imgdir))
        for dotfile in dotfiles
            run(`dot -T$ext -O doc/src/img/$dotfile`)
        end

    catch ex
        @warn "Could not update figures, perhaps dot is not installed."
        @warn ex
    end

end

function printmdtable(dir, outdir=".")
    for path in readdir(dir)
        df = CSV.read("$dir/$path")
        s = mdtable(df,latex=false)
        open("$outdir/$path.md", "w") do fp
            print(fp, string(s))
        end
    end
end


@info "Making Figures"
makefigs()
makefigs("png")

# printmdtable("examples/knowledge_graph/data", "doc/src/schema/")

@info "Loading module"
using SemanticModels
@info "Making docs"
makedocs(
modules     = [SemanticModels],
root        = "doc",
format      = Documenter.HTML(),
sitename    = "SemanticModels",
doctest     = false,
pages       = Any[
    "SemanticModels.jl"               => "index.md",
    "Intended Use Cases" => "usecases.md",
    "News" => "news.md",
    "Example" => "example.md",
    "Approaches" => "approach.md",
    "Slides"               => "slides.md",
    "Flu Model" => "FluModel.md",
    "Dubstep" => "dubstep.md",
    "Knowledge Graphs" => "graph.md",
    "Knowledge Extraction" => "extraction.md",
    "Validation" => "validation.md",
    "Library Reference" => "library.md",
    "Theory" =>"theory.md",
    # "Model Types"                   => "types.md",
    # # "Reading / Writing Models"    => "persistence.md",
    # # "Plotting"                    => "plotting.md",
    # # "Parallel Algorithms"         => "parallel.md",
    "Contributing"                  => "contributing.md",
    # "License Information"           => "license.md",
    # "Citing SemanticModels"         => "citing.md"
]
)

deploydocs(
root        = "doc",
target      = "build",
deps        = nothing,
make        = nothing,
repo        = "github.com/jpfairbanks/SemanticModels.jl.git",
# julia       = "stable",
# osname      = "linux"
)

# # rm(normpath(@__FILE__, "../src/contributing.md"))
# # rm(normpath(@__FILE__, "../src/license.md"))
