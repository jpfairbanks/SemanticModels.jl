
#
# Julia implementation of LSTM/RNN classifier for classifying program
# execution traces. 
# 

#
# Loop to check if packages are installed and install them if not, then 
# import.
# 

using DelimitedFiles
using Flux
using Flux: onehot, throttle, crossentropy, onehotbatch, params, shuffle
using MLDataPattern: stratifiedobs, splitobs
using Base.Iterators: partition
using Statistics

include("../../src/validation/utils.jl")
include("../../src/parse.jl")

#
# Set up inputs for model
#

# Read lines from trace_test.dat text in to arrays of characters
# Convert to onehot matrices

maxlen = 500
dir = "~/Documents/git/julia"
file_type = "jl"

#
# use parsefile function - get Expr tree object
#     cycle through tree - pull strings of Expr objects

function read_code(dir, maxlen=500, file_type="jl")
    comments = r"\#.*\n"
    docstring = r"\"{3}.*?\"{3}"s

    all_funcs = []

    for (root, dirs, files) in walkdir(dir)
        for file in files
            if endswith(file, "."*file_type)
              s = Parsers.parsefile(joinpath(root, file))
              if !isa(s, Nothing)
                all_funcs = vcat(all_funcs, get_expr(s, true));
              end
            end
        end
    end

    filter!(x->x!="",all_funcs)
    filter!(x -> length(x)<=maxlen, all_funcs)
    all_funcs = unique(all_funcs)

    return all_funcs
end


function get_expr(exp_tree, verbose=false)
    leaves = []

    for arg in exp_tree.args
        if verbose
            println(arg)
        end
        if typeof(arg) == Expr
            if arg.head != :block
                if verbose
                    println("Pushed!")
                end
                push!(leaves, string(arg))
            else
                if verbose
                    println("Recursing!")
                end
                leaves = vcat(leaves, get_expr(arg, verbose))
            end
        end
    end

    return leaves
end

all_funcs = read_code(dir, maxlen, file_type)

alphabet, stop, N = descr_data(all_funcs)
stop_hot = onehot(stop, alphabet);

# Transform our sequences to one hot matrices, and pad sequences to equal
# lengths.

Xs = [[onehotbatch(x_1, alphabet, stop) for x_1 in x] for x in all_funcs];
Xs = [hcat(x...) for x in Xs];
Xs = [hcat(x,repeat(stop_hot,1,maxlen-size(x)[2])) for x in Xs];

Xs = [reshape(x, (N*maxlen)) for x in Xs]
train, test = splitobs(Xs, 0.7)

train = batches(part for part in chunk(train, 32))...)

auto_encoder_mod = Chain(Dense(N*maxlen, 256, leakyrelu), 
                         Dense(256, 128), 
                         Dense(128, 256), 
                         Dense(256, N*maxlen, leakyrelu))

function loss(x)
	l = mse(auto_encoder_mod(x), x)
	return l
end

testloss() = mean(loss(t) for t in test)

opt = ADAM(0.01)
ps = params(auto_encoder_mod)
evalcb = () -> @show testloss()

Flux.train!(loss, ps, zip(train), opt, cb = throttle(evalcb, 10))


