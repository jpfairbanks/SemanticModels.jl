
#
# Validation utility functions
# 

function get_data(file_name)
    text = collect.(readlines(file_name));
    alphabet = [union(unique.(text)...)..., '\n'];
    N = length(alphabet)

    return text, alphabet, N
end

