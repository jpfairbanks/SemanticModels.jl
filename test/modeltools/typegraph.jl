ex = quote begin
    function foo(x,z)
        y = x+2
        return y,y/z
        end
    end
    println(foo(3, 1))
    println(foo(3.0, 1))
end
ex′ = postwalk(annotate, ex)
ex2 = wrap(ex′)

calls = Edges(eval(ex2))
@test length(calls) == 2

edgelist = @typegraph begin
    function foo(x)
        return x/2
    end
    function bar(x)
        return 3x+1
    end

    function g(y)
        if y < 2
            return 1
        end
        if mod(y,2) == 0
            return g(foo(y))
        else
            return g(bar(y))
        end
        return 0
    end
    #g(4)
    println("====")
    g(5)
end



#TODO: figure out why unique(edgelist doesn't work, I think it is == of arrays of types or something.
@test length(unique([(f.func, f.args, f.ret) for f in  Edges(edgelist)])) == 5
