using Test
using Base.Iterators
using MacroTools

using SemanticModels
using SemanticModels.ModelTools
using SemanticModels.ModelTools.Transformations
using SemanticModels.ModelTools.FunctorTransforms

@testset "FunctorTransforms.Method" begin
mth = FunctorTransforms.Method(+, (Int,Int))
@test nameof(mth.func) == :(+)
@test mth.args[1] == Int
@test mth.args[2] == Int
@test mth.ret == nothing
println(mth)
mth = FunctorTransforms.Method(+, (Int,Int), Int)
@test nameof(mth.func) == :(+)
@test mth.args[1] == Int
@test mth.args[2] == Int
@test mth.ret == Int
println(mth)
end

@testset "Gravity" begin
    ex = quote
        G = 6.754
        function force(m1, m2, r)
            G * ( m1+m2 ) / double(r)
        end
        double(a) = 2a
        x=3; y = 1.6; r = 2.1;
        F = force(x,y,r)
    end

    pix = PreimageExtension(ex) do def
        if def[:name] == :force;
            def[:body] = MacroTools.postwalk(def[:body]) do x
                if FunctorTransforms.head(x) == :call
                    if x.args[1] == :(+)
                        x.args[1] = :(*)
                    end
                end
                return x
            end
            return [def]
        end
        if def[:name] == :double; def[:body] = :(a^2);
            return [def]
        end
        return [def]
    end
    ex2 = pix.expr′
    ϕ = pix.morph
    ex2′ = ex2 |> MacroTools.striplines
    ϕ = map(ϕ) do p
        # f, g = MacroTools.splitdef.(p)
        map(MacroTools.striplines, p)
    end
    ex′ = MacroTools.striplines(ex)
    @show ex′
    println("--------------------------")
    @show ex2′
    println("==========================")
    map(ϕ) do p
        println(p[1])
        println("--------------------------")
        println(p[2])
        println("==========================")
    end

    @show eval(ex)
    @test eval(ex) > 7.39
    println("--------------------------")
    @show eval(ex2)
    @test eval(ex2) < 7.39
    println("==========================")

    @show pix
end

mutable struct GravModel
    expr::Expr
end

import Base: first, last

first(p::Product) = p.dims[1]
last(p::Product) = p.dims[end]

modoff(i::Int, n::Int) = 1+(( i-1 ) % n)
@testset "GravityXform" begin
    ops = [:(+), :(-), :(*), :(/)]
    function apply(t::Transformation, m::GravModel)
        pix = PreimageExtension(m.expr) do def
            if def[:name] == :force
                def[:body] = MacroTools.postwalk(def[:body]) do x
                    if FunctorTransforms.head(x) == :call
                        if x.args[1] == :(+)
                            x.args[1] = ops[modoff(first(t).inc,
                                                   length(ops))]
                        end
                    end
                    return x
                end
                return [def]
            end
            if def[:name] == :double
                def[:body] = :(a^$(last(t).inc))
                return [def]
            end
            return [def]
        end
        return pix
    end
    T₁ = Pow(1)
    gm = GravModel(quote
        G = 6.754
        function force(m1, m2, r)
            G * ( m1+m2 ) / double(r)
        end
        double(a) = 2a
        function main()
           x=3; y = 1.6; r = 2.1;
           F = force(x,y,r)
        end
        main()
    end)
    t = Product((T₁^3,T₁^2))
    pix = apply(t, gm)
    ex2 = pix.expr′
    ϕ = pix.morph
    ex2′ = ex2 |> MacroTools.striplines
    ϕ = map(ϕ) do p
        # f, g = MacroTools.splitdef.(p)
        map(MacroTools.striplines, p)
    end
    ex′ = MacroTools.striplines(ex) |> MacroTools.flatten
    @show ex′
    println("--------------------------")
    @show ex2′
    println("==========================")
    map(ϕ) do p
        println(p[1])
        println("--------------------------")
        println(p[2])
        println("==========================")
    end

    @show eval(gm.expr)
    @test eval(gm.expr) > 7.39
    println("--------------------------")
    @show Fstar = eval(ex2)
    @test Fstar < 7.39
    println("==========================")

    @show pix
    println("Model Search")
    println("==========================")
    results = Tuple{Int, Int, Float64, Float64}[]
    for i in 1:4
        for j in -3:3
            t = Product((T₁^i,Pow(j)))
            pix = apply(t, gm)
            ex2 = pix.expr′
            @time Fhat = eval(ex2)
            # @time Fhat = main()
            r = (i, j, round(Fhat, digits=4), round(Fhat - Fstar, digits=3))
            push!(results, r)
        end
    end
    results = sort(results, by=abs∘last)
    for row in results
        println(row)
    end
    @test -1e-3 <= results[1][end] <= 1e-3
    g = Dict{Int, Float64}()
    for row in results
        v = get(g, row[1], 0)
        v += row[end]^2
        g[row[1]] = v
    end
    @show g

    g = Dict{Int, Float64}()
    for row in results
        v = get(g, row[2], 0)
        v += (row[end])^2
        g[row[2]] = v
    end
    @show g
end
