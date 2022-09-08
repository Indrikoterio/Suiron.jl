# Punctuation.jl
#
# punctuation - makes logic terms for punctuation symbols: ()?![] etc.
#
# Cleve (Klivo) Lendon

# make_punctuation_term - makes a complex term for punctuation.
# Params: symbol (string)
# Return: complex term (or nothing)
function make_punctuation_term(symbol::String)::Union{sr.SComplex, Nothing}

    c::Union{sr.SComplex, Nothing} = nothing

    if length(symbol) != 1
        return c    # fail
    end

    if (symbol == ".")
        c, _ = sr.parse_complex("period(.)")
    elseif (symbol == ",")
        c, _ = sr.parse_complex("comma(\\,)")  # Must escape the comma with backslash.
    elseif (symbol == "?")
        c, _ = sr.parse_complex("question_mark(?)")
    elseif (symbol == "!")
        c, _ = sr.parse_complex("exclamation_mark(!)")
    elseif (symbol == ":")
        c, _ = sr.parse_complex("colon(:)")
    elseif (symbol == ";")
        c, _ = sr.parse_complex("semicolon(;)")
    elseif (symbol == "-")
        c, _ = sr.parse_complex("dash(-)")
    elseif (symbol == "\"")
        # The second argument is for comparisons.
        c, _ = sr.parse_complex("quote_mark(\", \")")
    elseif (symbol == "'")
        c, _ = sr.parse_complex("quote_mark(', ')")
    elseif (symbol == "«")
        c, _ = sr.parse_complex("quote_mark(«, «)")
    elseif (symbol == "»")
        c, _ = sr.parse_complex("quote_mark(», «)")
    elseif (symbol == "‘")
        c, _ = sr.parse_complex("quote_mark(‘, ‘)")
    elseif (symbol == "’")
        c, _ = sr.parse_complex("quote_mark(’, ‘)")
    elseif (symbol == "“")
        c, _ = sr.parse_complex("quote_mark(“, “)")
    elseif (symbol == "”")
        c, _ = sr.parse_complex("quote_mark(”, “)")
    elseif (symbol == "(")
        c, _ = sr.parse_complex("bracket((, ()")
    elseif (symbol == ")")
        c, _ = sr.parse_complex("bracket(), ()")
    elseif (symbol == "[")
        c, _ = sr.parse_complex("bracket([, [)")
    elseif (symbol == "]")
        c, _ = sr.parse_complex("bracket(], [)")
    elseif (symbol == "<")
        c, _ = sr.parse_complex("bracket(<, <)")
    elseif (symbol == ">")
        c, _ = sr.parse_complex("bracket(>, <)")
    end

    return c

end  # make_punctuation_term
