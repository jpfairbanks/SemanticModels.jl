using ArgParse

export append_module_info

function append_module_info(input_jl_file::String, output_jl_file::String, module_name::String )
    
    open(output_jl_file, "w") do out_file
    
        open(input_jl_file) do in_file

            module_inserted = false
            for ln in eachline(in_file)

                if (ln == "# # Load Packages for Julia") && !(module_inserted)
                    write(out_file, "\n")
                    write(out_file, "module $module_name \n")
                    module_inserted = true

                else 
                    write(out_file, "$(ln) \n")

                end

            end

            write(out_file, "\nend \n")

        end
        
    end

end

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "input_jl_file"
            help = "Path to the input Julia file."
            required = true
        "output_jl_file"
            help = "Path to write the output (julia file) to."
            required = true
        "module_name"
            help = "The module name to insert into the Julia code."
            required = true
    end

    return parse_args(s)
end

function main()
    parsed_args = parse_commandline()
    for (arg,val) in parsed_args
        println("  $arg  =>  $val")
    end
    append_module_info(parsed_args["input_jl_file"], parsed_args["output_jl_file"], parsed_args["module_name"])
end

main()


# usage:
# julia insert_module_name.jl ../src/DiscreteStochErlangEpidModel.jl ../src/DiscreteStochErlangEpidModel_v2.jl DiscreteStochErlangEpidModel

    
