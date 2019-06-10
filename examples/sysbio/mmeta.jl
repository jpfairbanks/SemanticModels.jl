module MMDyn

using SemanticModels
using SemanticModels.ModelTools
using SemanticModels.ModelTools.Transformations
using SemanticModels.ModelTools.ExpODEModels
using SemanticModels.Parsers

using DiffEqBiological


struct MMModel <: AbstractModel
    expr::Expr
    matches
    funcs
    vars
    tdomain
    initial
    params
end

function funker(expr::Expr, rhs::Expr)
    try
        return findfunc(expr, rhs.args[2])[1]
    catch
        @warn "could not findfunc $(rhs.args[2])"
        t = findassign(expr, rhs.args[2])
        @show t
        return t[1]
    end
end


function model(::Type{MMModel}, expr::Expr)
    matches = callsites(expr, :ODEProblem)
    @show matches
    # params(x) = x.args[2].args[4:end]
    # states(x) = structured(x, x.args[1].args[3])
    # fluxes(x) = structured(x, x.args[1].args[2], false)
    # equations(x) = x.args[2].args[3].args |>
    #     y -> filter(y) do z
    #         typeof(z) == Expr
    #     end

    funcs = [funker(expr, rhs) for rhs in matches]
    @show funcs
    dump(funcs[1].args[2])
    vars = map(funcs) do x
        rs = eval(x.args[2])
        # (rxns = rs,
        #  vars = rs.syms,
        #  eqns=equations(x),
        #  params=params(x))
        #  eqns=equations(x),
        #  params=params(x))
    end
    # vars = map(x->(state=states(x),
    #                flux=fluxes(x),
    #                params=params(x)), funcs)
    tdomain = map(m->findassign(expr, m.args[4]), matches)
    initial = map(m->findassign(expr, m.args[3]), matches)
    params = map(matches) do x
        p = findassign(expr, x.args[end])
        @show p
        return p
    end

    return MMModel(expr, matches, funcs, vars, tdomain, initial, params)
end

exp = parsefile("michaelismentin.jl")
@info "The parsed expr is"
@show exp
m = model(MMModel, exp)
@info "The extracted model is"
@show m

@info "Making Changes add Eqn P -c4-> P1+P2"
push!(m.funcs[1].args[2].args[3].args, :(c4, P --> P1 + P2))
push!(m.funcs[1].args[2].args, :c4)
push!(m.params[1][1].args[2].args, 0.02)
push!(m.initial[1][1].args[2].args, 0.05)


end #module


