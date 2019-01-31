#!/usr/bin/env bash

for f in ../notebooks/*/*.ipynb; do 
    	fname=`basename -s .ipynb $f`
	jupytext --to julia ${f} --output ../src/"${fname}".jl 
	echo "Inserting module name in Julia file ${fname}."
	julia ./insert_module_name.jl ../src/${fname}.jl ../src/${fname}_v2.jl ${fname}
	mv ../src/${fname}_v2.jl ../src/${fname}.jl
done

