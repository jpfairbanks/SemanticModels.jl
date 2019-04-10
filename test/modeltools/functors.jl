using Test
using Base.Iterators
using MacroTools

using SemanticModels
using SemanticModels.ModelTools
using SemanticModels.ModelTools.FunctorTransforms

@testset "Method" begin
mth = Method(+, (Int,Int))
@test nameof(mth.func) == :(+)
@test mth.args[1] == Int
@test mth.args[2] == Int
@test mth.ret == nothing
println(mth)
mth = Method(+, (Int,Int), Int)
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
                if head(x) == :call
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
