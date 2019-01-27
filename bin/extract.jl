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
subdefs = recurse(mc)
@info "local scope definitions" subdefs=subdefs

for func in subdefs
    funcname = func[1]
    mc = func[2]
    @info "$funcname uses modules" modules=mc.modc
    @info "$funcname defines functions" funcs=mc.fc.defs
    @info "$funcname defines glvariables" funcs=mc.vc
end

