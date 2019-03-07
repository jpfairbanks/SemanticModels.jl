"""
    postwalk(f, expr)
Applies `f` to each node in the given expression tree, returning the result.
`f` sees expressions *after* they have been transformed by the walk. See also
`prewalk`.
"""
postwalk(f, x) = walk(x, x -> postwalk(f, x), f)

"""
    prewalk(f, expr)
Applies `f` to each node in the given expression tree, returning the result.
`f` sees expressions *before* they have been transformed by the walk, and the
walk will be applied to whatever `f` returns.
This makes `prewalk` somewhat prone to infinite loops; you probably want to try
`postwalk` first.
"""
prewalk(f, x)  = walk(f(x), x -> prewalk(f, x), identity)

replace(ex, s, s′) = prewalk(x -> x == s ? s′ : x, ex)

"""
    inexpr(expr, x)
Simple expression match; will return `true` if the expression `x` can be found
inside `expr`.
    inexpr(:(2+2), 2) == true
"""
function inexpr(ex, x)
  result = false
  postwalk(ex) do y
    if y == x
      result = true
    end
    return y
  end
  return result
end
