# Epirecipes Cookbook

The Epirecipes cookbook is a textbook written by various authors and maintained by Simon Frost (@sdwfrost) at the Allen
Turing Institute for teaching the mathematical modeling techniques necessary for computational epidemiology.

We leverage this content as a corpus of instructional text written by domain experts to explain and illustrate
epidemiology concepts. We learn from both the text, equations, and source code. The source code is stored in julia
notebooks. We have updated these notebooks to use the Julia version 1.0 language and modern versions of the
DifferentialEquations ecosystem. We have also manually annotated the corpus by adding human written documentation in the
code that provides more detailed information for our information extraction tasks. This corpus is used primarily for
development of our software and techniques.

The updated code can be found in our repo at `examples/epicookbook/notebooks`. Each folder refers to a chapter of the
textbook and contains multiple notebooks from that chapter.


## Epicookbook upgrade and annotation methodology

The cookbook models were developed for Julia v0.6 and needed to be upgraded to run on
Julia v1.0. As an intermediate step, they were run on Julia v0.7 to collect depreciation
warnings and errors. Subsequently, these issues were fixed for compatibility with with
Julia 1.0.3. The most common errors were:

- zeros function 
    * zeros(tuple with size) => zeros(typecast(tuple))
- ODE output new format 
    * Flat arrays => Array{Array{Float64,n} ,1}
-  DataFrame vectors
    * DataFrame => vec(DataFrame)
- Random seed
    * srand(x) => Random.seed!(x)

Finally, test outputs for Julia v1.0.3 scripts are compared with the original to
maintain consistency. 

Function definitions were made consistent by replacing variable names with Greek names to
fully utilize Julia functionality. In addition, comments were added to describe variable
names and function usage that were extracted from previous scripts and from the research
papers that each script pertained to.
