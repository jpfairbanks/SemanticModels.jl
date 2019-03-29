# +
module Extraction
using Logging
using LightGraphs, MetaGraphs

import JSON

# TODO: Create functions for each
# Cause - is concept label, Effect - definition label
# within a RelationMention with labels "Definition, Entity"

"""    definitiongraph(dir::String, namefunc)

read a directory of json files and ingest all the Automates matches into a metagraph.

dir is the directory containing the json files and
namefunc is a function to convert objects into vertex names.

See also: sequentialnamer
"""
function definitiongraph(dir::String, namefunc)
    files = [joinpath(dir, f) for f in readdir(dir)]
    @info "Processing files: $files"
    return definitiongraph(files, namefunc)
end

"""    term(record)

get the text of a definition's term
"""
function term(record)
    return record["arguments"]["cause"][1]["text"]
end

"""    definition(record)

get the text of a definition's body
"""
function definition(record)
    return record["arguments"]["effect"][1]["text"]
end

"""    sequentialnamer(prefix="")

A closure used to get sequential vertex names from a stream of strings.
"""
function sequentialnamer(prefix="")
    i = 0
    function genname(s)
        i += 1
        return "$prefix$i"
    end
    return genname
end

function definitiongraph(files::Vector{String}, namefunc)
    graph = DiGraph()
    changes_recorded = []
    v_count = 0
    for def_file in files
        @info "Reading Definitions from: $def_file"
        json_res = JSON.parsefile(def_file)
        mentions = json_res["mentions"]
   
        for val in mentions

            if haskey(val,"type") && val["type"] == "RelationMention"
                @debug "Parsed JSON record" json=val
                v_count += 1
                cause = term(val)
                effect = definition(val)
                @info "Found Definition" term=cause definition=effect
                @debug("Add new vertex for Concept to Graph")
                add_vertex!(graph)
                push!(changes_recorded, Dict(:v_id=>v_count,
                                             :type=> "AddVertex",
                                             :values => Dict(:name=> string("Term_", namefunc(effect)),
                                                             :id => v_count,
                                                             :text => cause)))
                v_count += 1
                add_vertex!(graph)
                push!(changes_recorded, Dict(:v_id=>v_count,
                                             :type=> "AddVertex",
                                             :values => Dict(:name=> string("Def_",namefunc(effect)),
                                                             :id => v_count,
                                                             :text => effect)))
                @debug("Adding edge from Concept to Definition")
                add_edge!(graph, v_count-1, v_count)
                push!(changes_recorded, Dict(:edge=> Edge(v_count-1,v_count),
                                             :type=> "AddEdge",
                                             :values=> Dict(:name=> "is defined as")))
            end
        end
    end

    # Create MetaGraph after digraph is created using changes record
    metagraph = MetaDiGraph(graph)
    for change in changes_recorded
        if change[:type] == "AddEdge"
            set_props!(metagraph, change[:edge], change[:values])
            @info("Adding Edge",edge=change[:edge], props(metagraph, change[:edge])...)
        end
        if change[:type] == "AddVertex"
            set_props!(metagraph, change[:v_id], change[:values])
            @info("Adding Vertex",vertex=change[:v_id], props(metagraph, change[:v_id])...)
        end
    end
    set_indexing_prop!(metagraph, :name)
    return metagraph
end

end
