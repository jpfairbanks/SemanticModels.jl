# -*- coding: utf-8 -*-
# ---
# jupyter:
#   jupytext:
#     formats: ipynb,jl:light
#     text_representation:
#       extension: .jl
#       format_name: light
#       format_version: '1.3'
#       jupytext_version: 1.0.4
#   kernelspec:
#     display_name: Julia 1.0.2
#     language: julia
#     name: julia-1.0
# ---

using SemanticModels
using Random
using LightGraphs
using MetaGraphs
using DataFrames
using GraphPlot
using DifferentialEquations
using Plots

# ## Dynamic Analysis and Dataflow Graph Construction for Type Disambiguation
#
# Our objective in this task is to ingest the main method of a program, and recursively enumerate: (1) the set of subroutines, S = {s | s is called by main} that main calls; (2) the set of variables that main interacts with (as args, or in the form of locally scoped assignment statements), V = {v | v is passed to main, or is a local variable inside of main}; (3) the set of sub-subroutines (e.g., subroutines called by each sub-routine called by main), $S_{sr}$ = {s.sr | s.sr called by s; $s \in S$}; and (4) the set of variables that the set of methods, $S$, interacts with, which may be global (w/respect to main) or local (w/respect to S) in scope, $V_{sr}$ = {s.sr.v | v is passed to an s.sr $\in S_{sr}$, or is a local variable inside of an s.sr $\in S_{sr}$}.
#
# Our hypothesis is that if we `extract method -> subroutine calls`, and `method -> variable interactions`, and use the union of these tuples and their associated metadata to construct a (directed) dataflow graph, we can use this graph to identify patterns in method call stacks, variable co-location, and different variables whose types are the same in the program as it is currently written, and as such, are candidates for type disambiguation vis-a-vis struct creation.
#
# A basic workflow that this type of formalization can support would be:
#
# Let $C$ be a class of models and $f$ be an oracle that determines $f(m) = true \iff m \in C$. Define a function `swap(m, a, b)` that takes the model $m$ and swaps all occurances of the value $a$ with the value $b$. If `f(swap(m,a,b)) = f(m)` then $a$ and $b$ are interchangeable.
#
# 1. For a given program $p_1$, identify/detect potentially ambiguous types.
# 2. For all elements of a given data type, perform pairwise swaps, and observe whether oracle still returns true. 
#     - Note that we assume here that we're able to filter the set of candidate data types, to avoid (in most cases) primitive-level swaps.
# 3. Transform $p_1$ to $p_2$ by introducing structs and/or more precise data types to resolve ambiguities.
#     - Most likely a human (expert)-in-the-loop process, where we programatically generate viable stubs, and the scientist fills in these stubs with implementations.
# 4. If we iteratively apply step one to $p_2$, the ambiguities we initially detected will have been resolved, and will not be identified as candidates for type disambiguation.
#
# This workflow touches on validation-related tasks in that we should expect some swaps to result in alterations to programs that do not halt execution, but do meaningfully alter results. Ideally, we'd be able to flag inappropriate swaps of this nature by observing cases where the results represent marked deviations from previously observed values/outputs.
#
# For demonstration purposes, we begin by defining a set of extraction, graph construction, and graph visualization methods. We then provide example "programs" to illustrate how the analytical pipeline outlined above can be beneficially applied.

# ### 1. Define Structs and Code Annotation Methods 
# The data structures and methods defined below are intended to facilitate the annotation of our input "program" via injection (e.g., we insert data structures into the toy methods defined above for the purpose of extracting information that we can use to build the dataflow graph, including directed relationships of the types: `method -calls-> method`; `method -interacts_with-> variable`; `method -returns-> variable`; and `variable -takes-> value`).

# +
"""
Struct to hold a single method, its args, and its caller method, when recovered from parsing a program's AST.
"""
mutable struct Method{name, args, expression, called_by}
    name::name
    args::args
    expression::expression
    called_by::called_by
end

"""
Struct to hold declared methods extracted from parsing a program's AST.
"""
mutable struct DeclaredMethodsCollector{declared_methods}
    declared_methods::declared_methods
end

"""
Struct to hold called methods extracted from parsing a program's AST.
"""
mutable struct CalledMethodsCollector{called_methods}
    called_methods::called_methods
end

"""
Struct to hold a single variable with its current (updateable) value(s), along with the function performing i/o related operation with this variable.
Note that a single variable can be interact with (e.g., be passed as args to, be instantiated/modified by, and/or be returned by, multiple functions)
"""
mutable struct Variable{name, cur_val, read_write_by}
    name::name
    cur_val::cur_val
    read_write_by::read_write_by
end

"""
    set_val!(v::Variable, new_val::Any)
A method to update the "current value" of a Variable struct as a value modification (e.g., assignment or math operation) is encountered in the code.
"""
set_val!(v::Variable, new_val::Any) = (v.cur_val = new_val)


"""
Struct to hold called variables extracted from parsing and evaling a program's AST.
"""
mutable struct VariableCollector{vars}
    vars::vars
end

# +
"""
    get_all_top_level_signatures(expr_to_parse::Expr, expr_name::String, decl_methods_col::DeclaredMethodsCollector, called_methods_col::CalledMethodsCollector)
Take a Julia program (wrapped in quote), parses the AST, and recover all top level method signatures from declared and called methods.
"""
function get_all_top_level_signatures(expr_to_parse::Expr, expr_name::String, decl_methods_col::DeclaredMethodsCollector, called_methods_col::CalledMethodsCollector)
    
    for ex in expr_to_parse.args
        
        if isa(ex, LineNumberNode)
            continue
        end
        
        if ex.head == :function
            
            # the first arg of each function expression will be the function call 
            signature = ex.args[1]
            
            # the remainder of the expression args will be the args that are passed into the function
            args = signature.args[2:length(signature.args)]
            
            decl_method = Method(signature, args, ex, "$expr_name")
            push!(decl_methods_col.declared_methods, decl_method)
        end
        
        if (ex.head == :macrocall)
            
            # arg 1 is the :macrocall head; arg 2 is the line number 
            signature = ex.args[3]
            args = signature.args[2:length(signature.args)]
            called_method = Method(signature, args, Expr(:call, signature, args...), "$expr_name")
            push!(called_methods_col.called_methods, called_method)
        end

    end

    return decl_methods_col, called_methods_col
    
end
# -

"""
    collect_method_info(expr_to_parse::Expr)
Helper function that ingests an expression to parse, and outputs collector structs containing all declared and called methods
"""
function collect_method_info(expr_to_parse::Expr)
    
    delc_methods = DeclaredMethodsCollector(Method[])
    called_methods = CalledMethodsCollector(Method[])
    delc_methods, called_methods = get_all_top_level_signatures(expr_to_parse, "toy_expr",
        delc_methods, called_methods)
end



# +
"""
    nametype(ex::Expr)
Returns the value and type of the expression
"""
nametype(ex::Expr) = begin
    ex.head == :(::) || error("$ex is not a type assertion")
    avar = ex.args[1]
    atyp = ex.args[2]
    return avar, atyp
end

nametype(s::Symbol) = (s, :Any)


# +
"""
    collect_subroutine_calls(collector, subtree_root, caller_func)
Collects all first-level subroutine calls made by the caller_func. Note that this is (by design) not currently recursively applied. 
"""

function collect_subroutine_calls(collector, subtree_root, caller_func)

    if subtree_root.head == :call
        
        subroutine_name = subtree_root.args[1]
        sr_args = subtree_root.args[2:end]
        subroutine = Method(subroutine_name, sr_args, subtree_root, caller_func)
        push!(collector, subroutine)
    end    
end
# -


"""
    describe_args(fu::Expr, collector::Array)
A function to inject variable collection commands into the Expr representation of the program so that when the program is evaled, variables (and their values) can be collected. 
"""
function describe_args(fu::Expr, collector::Array)
    f = fu
    @show argl = f.args[1].args[2:end]
    @show argl
    @show body = f.args[2].args

    fname = string(f.args[1])
    
    for a in reverse(argl)
        avar, atyp = nametype(a)
        varname = string(avar)
        type_avar = typeof(avar)
        pushfirst!(body,
            :(println("F: ", $fname, "; ",
                $varname, " = ", $avar, " :: ", $type_avar, " <: ", $atyp))
        )
        
        variable_obj = Variable(varname, avar, fname)
        pushfirst!(body, :(push!($collector, $variable_obj)))

    end
    return f
end

# +
"""
annotate_program(input_expr::Expr)
Takes a program (represented as an expression), and injects annotations such that first and second-level method calls, along with variable assignment statements, can be parsed/collected when the expression is evaled.  
"""
function annotate_program(input_expr::Expr)
    
    expr_to_annotate = copy(input_expr)
    declared, called = collect_method_info(expr_to_annotate)

    first_and_second_order_method_calls = CalledMethodsCollector([])
    program_level_variables = VariableCollector([])

    for method in declared.declared_methods
        
        f = method.expression
        
        describe_args(f, program_level_variables.vars)
        
        fname = string(f.args[1])
        func_obj = f.args[1]
        body = f.args[2].args
        
        # We want to put the top-level function call with its args into our called methods collector
        method_obj = Method(func_obj, body, func_obj, func_obj)
        pushfirst!(body, :(push!($first_and_second_order_method_calls.called_methods, $method_obj)))

        for ex in body
            
            if (isa(ex,LineNumberNode)) || (ex.head == :push!) || (ex.head == :println)
                continue
            end
            
            if ex.head == :(=) 
                a = ex.args[1]
                b = ex.args[2]
                varname = string(a)
                
                insert!(body, length(body)-1,:(println("A: ", $fname, "; " , $varname, " = ", $b)))
                insert!(body, length(body)-1,:(push!($program_level_variables.vars, Variable($varname, $b, $fname))))  

                # Collect second-level method calls
                if isa(b, Expr)
                    collect_subroutine_calls(first_and_second_order_method_calls.called_methods, b, func_obj)
                end

            end
            
           if ex.head in (:(*=), :(+=), :(-=), :(/=))
                
                a = ex.args[1]
                varname = string(a)
                b = ex.args[2]

                # The math op is the symbol right before the equals sign in the ex.head
                math_op = string(ex.head)[1] 
                
                insert!(body, length(body)-1,:(println("A: ", $fname, "; " , $varname, " = ", $varname, " ", $math_op, " ", $b, "; == ", $a)))
                insert!(body, length(body)-1,:(push!($program_level_variables.vars, Variable($varname, $a, $fname))))
                
                # Collect second-level method calls
                if isa(b, Expr)
                    collect_subroutine_calls(first_and_second_order_method_calls.called_methods, b, func_obj)
                end

            end
            
            # The last line is a return statement; we want to capture the method -returns-> variable relationship
            if ex.head == :return && isa(body[length(body)-1],LineNumberNode)
                return_vals = ex.args[1:end]
                
                # can catch all assgmts take lhs and print out values of lhs
                insert!(body, length(body), :(println("R: ", $fname, " returns ", $return_vals)))
                
                # When we're about to return, update the value attribute of each variable 
                for v in program_level_variables.vars                    
                    insert!(body, length(body), :(set_val!(v, v.name)))
                end
            end
            
            # We've reached the last line and this program doesn't contain a return statement; capture var values.
            if (ex == body[length(body)])
                
                if !(isa(body[length(body)-2], LineNumberNode)) && (body[length(body)-2].args[1] == :push!)

                    for v in program_level_variables.vars  
                        insert!(body, length(body), :(set_val!(v, v.name)))
                    end
                
                    break
                    
                end
            end
        end
    end    
    return expr_to_annotate, first_and_second_order_method_calls, program_level_variables
    
end

# +
# Graph construction helper methods
function create_vertex_metadata_dict(vertex_struct)
    
    meta_data = Dict()
    
    for f in fieldnames(typeof(vertex_struct))
        meta_data[f] = getfield(vertex_struct, f)
    end
    
    return meta_data
end

function get_method_calls_method_edges(called_methods)
    
    methods_df = DataFrame(caller=Expr[], callee=Expr[])
    
    for m in called_methods
        push!(methods_df, [m.called_by, m.expression])
    end
    
    @show methods_df
    return methods_df
end

function get_method_rw_variable_edges(prog_variables)
    
    vars_df = DataFrame(method=String[], variable=String[])
    
    for v in prog_variables
        push!(vars_df, [v.read_write_by, v.name])
    end
    
    @show vars_df
    return vars_df
end

function add_vertices!(vertices_to_add, g, counter)
    
    for x in vertices_to_add
        v_name = string(x.name)

        try
            g[string(v_name), :v_name] 
    
        catch error

            if isa(error, ErrorException) 
                
                meta_data = create_vertex_metadata_dict(x)
                v_name = string(meta_data[:name])
                vertex_props = Dict(:v_type=> typeof(x), :meta_data=> meta_data)

                add_vertex!(g)
                set_indexing_prop!(g, counter, :v_name, v_name)
                set_props!(g, counter, vertex_props)

                counter += 1
            end
        end

    end
    
    return g, counter
   
end

# need to be able to make this conditional on the array type (Eg methods vs variables)

function add_directed_edges!(g, edge_collector::CalledMethodsCollector, edge_type::String)
    
    for method_call in edge_collector.called_methods
        
        src_id = g[string(method_call.called_by.args[1]), :v_name]
        dst_id = g[string(method_call.name), :v_name]

        # Check if \e \in G; if Y, increment counter 
        if has_edge(g, src_id, dst_id)
            cur_freq = get_prop(g, Edge(src_id, dst_id), :weight)
            updated_props = Dict(:weight => cur_freq + 1, :type => edge_type)
            set_props!(g, Edge(src_id, dst_id), updated_props)
        else
            
            e_props = Dict(:weight => 1, :type => edge_type)
            add_edge!(g, Edge(src_id, dst_id))
            set_props!(g, Edge(src_id, dst_id), e_props)
        end
    end
end
    

function add_directed_edges!(g, edge_collector::VariableCollector, edge_type::String)
    
    for var in edge_collector.vars
            
        src_name = split(string(var.read_write_by), "(")[1]
        src_id = g["$src_name", :v_name]
        dst_id = g[string(var.name), :v_name]

        # Check if \e \in G; if Y, increment counter 
        if has_edge(g, src_id, dst_id)
            cur_freq = get_prop(g, Edge(src_id, dst_id), :weight)
            updated_props = Dict(:weight => cur_freq + 1, :type => edge_type)
            set_props!(g, Edge(src_id, dst_id), updated_props)
        else
            
            e_props = Dict(:weight => 1, :type => edge_type)
            add_edge!(g, Edge(src_id, dst_id))
            set_props!(g, Edge(src_id, dst_id), e_props)
        end
    end
end


function create_dataflow_graph(called_methods, prog_vars, m_df, v_df)
    
    g = MetaDiGraph()
    
    set_indexing_prop!(g, :v_name)
    
    # THIS HAS TO START AT ONE, NOT ZERO.
    counter = 1
    
    # Add the method vertices representing called methods
    g, counter = add_vertices!(called_methods.called_methods, g, counter) 
    
    # Add the caller methods
    callers = [v.called_by for v in called_methods.called_methods]
    caller_methods = [Method(c.args[1], c.args[2:end], c, :nothing) for c in callers]
    
    g, counter = add_vertices!(caller_methods, g, counter)

    # Add the variable vertices 
    g, counter = add_vertices!(prog_vars.vars, g, counter)
    
    # Add the method -calls-> method edges
    add_directed_edges!(g, called_methods, "calls")
    
    add_directed_edges!(g, prog_vars, "interacts_with")
    
    return g

end
  


# +
# Graph visualization helper method
function plot_dataflow_graph(g)
    println(ne(g))
    
    edge_labels = [(get_prop(g,e, :type),get_prop(g,e, :weight))  for e in edges(g)]

    vertex_labels = []
    
    for v in vertices(g)
        
        if get_prop(g,v, :v_type) <: Variable
            v_name = get_prop(g,v, :v_name)
            v_type = typeof(get_prop(g,v, :meta_data)[:cur_val])
            push!(vertex_labels, (string(v_name, "::", v_type)))
        else
            push!(vertex_labels, (get_prop(g,v, :v_name)))
        end
    end

    node_sizes = [LightGraphs.outdegree(g, v) + 3 for v in vertices(g)]
    
    # Our nodes either represent methods or variables 
    node_colors = [get_prop(g,v, :v_type) <: Variable ? "#6682E0" : "#D5635C"  for v in vertices(g)]
    node_strokes = [get_prop(g,v, :v_type) <: Variable ? "#4063D8" : "#CB3C33"  for v in vertices(g)]
    
    node_label_sizes = [LightGraphs.outdegree(g, v) for v in vertices(g)]
    
    layout=(args...)->spring_layout(args...; C=40)
    
    gplot(g, 
        edgelabel=edge_labels, 
        nodelabel=vertex_labels, 
        nodesize=node_sizes, 
        edgelabelsize=2.0, 
        nodelabelsize=2.5,
        #layout=stressmajorize_layout,
        layout=layout,
        nodefillc=node_colors,
        nodestrokec= node_strokes,
        nodestrokelw = 1.0,
        nodelabeldist=1.5, 
        nodelabelangleoffset=π/4,
        NODELABELSIZE = 3.5,
        EDGELABELSIZE = 3.5)

end


# -

# ### 2. Define Example Programs 
# To begin, we can define some toy methods with useful properties (e.g., sub-routine calls; recursive calls, empty args). We wrap our method declarations and calls in a `quote` so that we can parse the program (and its component pieces) as `Expr` objects; this allows us to traverse the ASTs.

sir_expr = quote
function sir_ode(du, u, p, t)
    #Infected per-Capita Rate
    β = p[1]
    #Recover per-capita rate
    γ = p[2]
    #Susceptible Individuals
    S = u[1]
    #Infected by Infected Individuals
    I = u[2]

    du[1] = -β * S * I
    du[2] = β * S * I - γ * I
    du[3] = γ * I
end
function sir_ode2(du,u,p,t)
    S,I,R = u
    b,g = p
    du[1] = -b*S*I
    du[2] = b*S*I-g*I
    du[3] = g*I
end
parms = [0.1,0.05]
init = [0.99,0.01,0.0]
tspan = (0.0,200.0)
sir_prob2 = ODEProblem(sir_ode2,init,tspan,parms)
@show sir_sol = solve(sir_prob2,saveat = 0.1)
end

# + {"endofcell": "--"}
macro_parasite_expr = quote
function main()
# # +
function macroParasiteModelFunction(dY,Y,p,t)
    #Host Birth Rate
    a = p[1]
    #Parasite Influence on host birth rate
    b = p[2]
    #Parasite induced host mortality
    α = p[3]
    #Parasite induced decrease in host reproduction
    β = p[4]
    #Intrinsic death rate of parasites
    μ = p[5]
    #dispersion aggregation parameter
    k = p[6]
    #Rate of production of new free-living stages
    λ = p[7]
    #Death Rate of Free-Living Stages
    γ = p[8]
    
    #Host Population
    H = Y[1]
    #Parasite Population
    P = Y[2]
    #Infective Stages
    W = Y[3]
    
dY[1] = (a-b)*H - α*P
dY[2] = β*H*W - (μ + α + b) * P - (α*((P^2)/H)*((k+1)/k)) 
dY[3] = λ*P - (γ*W) - (β*H*W)
end

# -

par=[1.4,1.05,0.0003,0.01,0.5,0.1,10.0,10.0]
init=[100.0,10.0,10.0]
tspan=(0.0,100.0)


macro_odeProblem = ODEProblem(macroParasiteModelFunction,init,tspan,par)


@show sol=solve(macro_odeProblem);


plot(sol,xlabel="Time",yscale=:log10)
end
@show main()
end
# --

# +
# Let's define some toy functions with useful properties (e.g., sub-routine calls; recursive calls, empty args):
example_expr = quote 
    
function fib(n::Int64)
    if n <= 2
        return 1
    else 
        return fib(n-1) + fib(n-2)
    end
end

function circumference(r)
    circum = 2*pi*r
    return circum
end

function exp_decay(init_value, decay_rate, t)
    y = init_value(1-decay_rate)^t
    return y
end
    
function compute_circle_metrics(r)
    c = circumference(r)
    a = pi*r^2
    return c,a
end
    
function add_some_noise(x)
    rng = MersenneTwister(1234);
    x *= Base.randn(rng,1)
    return x
end
    
function combine_fib_and_circle(x::Int64)
    fib_res = fib(x)
    circum, area = compute_circle_metrics(fib_res)
    return circum, area
end

@show combine_fib_and_circle(7)
end


# +
# Let's define some toy functions with useful properties (e.g., sub-routine calls; recursive calls, empty args):
example_expr_fib = quote 
    
function fib(n::Int64)
    if n <= 2
        return 1
    else 
        return fib(n-1) + fib(n-2)
    end
end
function main(n::Int64)
    out = fib(n)
    return out
end
        
@show main(5)
end
# -


# ### 3. Use code annotation script to collect metadata to build dataflow graph

# +
# First, let's run our annotation method on the example expression. 
# When we do this, we'll get back a revised (annotated) expression that can be evaluated to yield the information
# we can use to build the dataflow graph.

annotated_expr, first_and_second_order_calls, prog_vars = annotate_program(sir_expr)
#annotated_expr, first_and_second_order_calls, prog_vars = annotate_program(macro_parasite_expr)
#annotated_expr, first_and_second_order_calls, prog_vars = annotate_program(example_expr)
# -


eval(annotated_expr)

methods_df = get_method_calls_method_edges(first_and_second_order_calls.called_methods)
vars_df = get_method_rw_variable_edges(prog_vars.vars)
g_out = create_dataflow_graph(first_and_second_order_calls, prog_vars, methods_df, vars_df)  

plot_dataflow_graph(g_out)







