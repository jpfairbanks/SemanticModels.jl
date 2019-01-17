
using LightGraphs, MetaGraphs

import JSON

# TODO: Create functions for each
# Cause - is concept label, Effect - definition label
# within a RelationMention with labels "Definition, Entity"

definitions_output_file = "/Users/scott/Documents/JuliaProjects/SemanticModels.jl/test/definitions.jl/automates_output_1sentence_definition.json"
def_output_dir = "/Users/scott/Documents/JuliaProjects/SemanticModels.jl/test/definitions.jl"


function info_extract_from_automates(output_dir::String)
    file_list = readdir(output_dir)
    graph = DiGraph()
    changes_recorded = []
    v_count = 0
    for def_file in file_list
        json_res = JSON.parsefile(string(def_output_dir, "/",def_file))
        # json_res = JSON.parsefile(definitions_output_file)
        mentions = json_res["mentions"]
        # println("JSON Mentions is:\n")
        # println(mentions)
        # println("End mentions\n")
        for val in mentions
            if haskey(val,"type") && val["type"] == "RelationMention"
                JSON.print(val, 4)
                v_count += 1
                cause = val["arguments"]["cause"][1]["text"]
                effect = val["arguments"]["effect"][1]["text"]
                println(string("Cause is: ", cause, "\n"))
                println(string("Effect is: ", effect, "\n"))
                println("Add new vertex for Concept to Graph")
                add_vertex!(graph)
                push!(changes_recorded, Dict(:v_id=>v_count, :type=> "AddVertex", :values => Dict(:name=> string(cause, hash(effect)), :id => v_count, :cause => cause)))
                v_count += 1
                add_vertex!(graph)
                push!(changes_recorded, Dict(:v_id=>v_count, :type=> "AddVertex", :values => Dict(:name=> string("Def_",hash(effect)), :id => v_count, :definition => effect)))
                println("Adding edge from Concept to Definition")
                add_edge!(graph, v_count-1, v_count)
                push!(changes_recorded, Dict(:edge=> Edge(v_count-1,v_count), :type=> "AddEdge", :values=> Dict(:name=> "is defined by")))
                # JSON.print(val["arguments"]["effect"][1]["text"])
                # println("\n")
            end 
        end
    end

    # Create MetaGraph after digraph is created using changes record
    meta_graph = MetaGraph(graph)
    for change in changes_recorded
        println("Change keys are: ")
        println(keys(change))
        println("\n")
        if change[:type] == "AddEdge"
            set_props!(meta_graph, change[:edge], change[:values])
            # set_props!(meta_graph, Edge(change["from"], change["to"]), Dict(:name=> "is defined by"))
            println("Print edge details:")
            println(props(meta_graph, change[:edge]))
        end
        if change[:type] == "AddVertex"
            # set_props!(meta_graph, v_count, Dict(:name=> string(cause, hash(effect)), :id => v_count))
            # set_props!(meta_graph, v_count, Dict(:name=> string("Def_",hash(effect)), :id => v_count, :definition => effect))
            set_props!(meta_graph, change[:v_id], change[:values])
            println("Print vertex details:")
            println(props(meta_graph, change[:v_id]))
        end
    end
    println("MetaGraph is: ")
    println(props(meta_graph))
    return meta_graph
end

info_extract_from_automates(def_output_dir)
