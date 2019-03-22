
#
# Validation utility functions
# 

function get_data(file_name::String)
    text = collect.(readlines(file_name));
    alphabet = [union(unique.(text)...)..., '\n'];
    N = length(alphabet)

    return text, alphabet, N
end


function descr_data(dat::Array)
    alphabet = [unique(union.(collect.(dat))...)...];
    stop = Char(maximum(float.(alphabet))+1)
    push!(alphabet, stop)
    N = length(alphabet)

    return alphabet, stop, N
end

