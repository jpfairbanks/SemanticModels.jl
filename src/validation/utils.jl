
#
# Validation utility functions
# 

function get_data(file_name)
    text = collect.(readdlm(file_name));
    alphabet = [unique(vcat(text...))..., '\n'];
    N = length(alphabet)

    return text, alphabet, N
end

