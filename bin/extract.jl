using SemanticModels.Parsers
@debug "Done Loading Package"

if length(ARGS) < 1
    error("You must provide a file path to a .jl file", args=ARGS)
end
path = ARGS[1]
@info "Parsing julia script" file=path
expr = parsefile(path)
mc = defs(expr.args[3].args)
@info "script uses modules" modules=mc.modc
@info "script defines functions" funcs=mc.fc.defs
@info "script defines glvariables" funcs=mc.vc
