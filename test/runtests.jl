# using Base.Tests
using Test
using Semantics
using Semantics.Unitful
import Semantics.Unitful: DimensionError

function test1()
    sir = Semantics.BasicSIR()
    # @show sir

    β = sir.equations[1].parameters[1]
    @show β
    @test (4*β.unit + 6β.unit) * 3u"s" == u"30person"
    @test u"24person" + u"1kperson" == u"1024person"
    @test u"24person" + u"1kperson/s"*u"3s" == u"3024person"
    @test_throws DimensionError 4*β.unit + (6β.unit) * 3u"s" 
end
test1()
