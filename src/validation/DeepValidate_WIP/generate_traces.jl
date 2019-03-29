
#
# WIP: work in progress on deepvalidate. This code is not expected to work at this time
#


using Distributions
using DelimitedFiles
using SemanticModels
using Suppressor
using Test

include("varextract.jl")

@testset "TraceExtract" begin
    out_file = "traces.dat";
    mode = "w"
    traces = 300;

    function add(a, b)
        c = a + b
        return c
    end
    g(x) = begin
        y = add(x.*x, -x)
        z = 1
        v = y .- z
        s = sum(v)
        return s
    end
    h(x) = begin
        z = g(x)
        zed = sqrt(z)
        return zed
    end
    
    # Error conditions happen when our inputs are sufficiently small, so 
    # Normal(0,2) gives us a good range of values to generate a reasonable
    # percentage of "bad" traces on which to train.

    if isfile(out_file)
        mode = "a"
    end
    
    seeds = rand(Normal(0,2),traces,3)

    for i=1:size(seeds,1)
        orig_stdout = stdout
        (read_in, write_out) = redirect_stdout()
        ctx = Extract.TraceCtx(pass=Extract.ExtractPass, metadata = (Any[], Any[]))

        try
            result = Extract.OverDub(ctx, h, seeds[i,:])
        catch DomainError
            dump(ctx.metadata)
        finally
            println()
        end

        open(out_file, mode) do f
            write(f, read(read_in))            
        end

        redirect_stdout(orig_stdout)
        close(write_out)

        if i%1000 == 0
            @info string(i)
        end
    end
end

