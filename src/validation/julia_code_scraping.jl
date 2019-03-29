
#
# Julia implementation of LSTM/RNN classifier for classifying program
# execution traces. 
# 

#
# Loop to check if packages are installed and install them if not, then 
# import.
# 

using DelimitedFiles

include("../parse.jl")

#
# Set up inputs for model
#

maxlen = 500
# dir = "~/Documents/git/julia"
file_type = "jl"

#
# use parsefile function - get Expr tree object
#     cycle through tree - pull strings of Expr objects

function read_code(dir, maxlen=500, file_type="jl", verbose=false)
    comments = r"\#.*\n"
    docstring = r"\"{3}.*?\"{3}"s

    all_funcs = []
    sources = []

    for (root, dirs, files) in walkdir(dir)
        for file in files
            if endswith(file, "."*file_type)
              s = Parsers.parsefile(joinpath(root, file))
              if !isa(s, Nothing)
                all_funcs = vcat(all_funcs, get_expr(s, joinpath(root, file), verbose));
              end
            end
        end
    end

    filter!(x->x!="",all_funcs)
    filter!(x -> length(x)<=maxlen, all_funcs)
    all_funcs = unique(all_funcs)

    return all_funcs
end


function get_expr(exp_tree, path, verbose=false)
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
                push!(leaves, (string(arg), path))
            else
                if verbose
                    println("Recursing!")
                end
                leaves = vcat(leaves, get_expr(arg, path, verbose))
            end
        end
    end

    return leaves
end

all_funcs = read_code(dir, maxlen, file_type, false);
writedlm("all_funcs.csv", all_funcs, quotes=true);



#
# For constructing auto_encoder in Julia: WIP
# 

using Flux
using Flux: onehot, onehotbatch, shuffle
using Flux: throttle, params
using Flux: mse, crossentropy
using MLDataPattern: splitobs
using Statistics

include("utils.jl")

alphabet, stop, N = descr_data(all_funcs)
stop_hot = onehot(stop, alphabet);

# Transform our sequences to one hot matrices, and pad sequences to equal
# lengths.

Xs = [[onehotbatch(x_1, alphabet, stop) for x_1 in x] for x in all_funcs];
Xs = [hcat(x...) for x in Xs];
Xs = [hcat(x,repeat(stop_hot,1,maxlen-size(x)[2])) for x in Xs];

Xs = [reshape(x, (N*maxlen)) for x in Xs]
Xs = [reshape(x, (N, maxlen)) for x in Xs]

train, test = splitobs(Xs, 0.7)

Flux.shuffle!(train);

auto_encoder_mod = Chain(Dense(N*maxlen, 128, leakyrelu), 
                         Dense(128, N*maxlen, leakyrelu))

encoder = LSTM(N, 128)
decoder = Chain(Dense(128, maxlen), LSTM(maxlen, N))

function auto_encoder(x)
  enc = encoder(x)
  # reset!(encoder)
  softmax(decoder(enc))
end


function loss(x)
	l = crossentropy(auto_encoder(x), x)
	return l
end

testloss() = mean(loss(t) for t in test)

opt = ADAM(0.01)
ps = params(auto_encoder)
evalcb = () -> @show testloss()

@epochs 10 Flux.train!(loss, ps, zip(train), opt, cb = throttle(evalcb, 10))


