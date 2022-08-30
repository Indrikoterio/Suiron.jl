# SFunction.jl - This file contains the functions which
# are common to all of Suiron's built-in functions.
#
# Cleve Lendon
# 2022

# SFunction is defined in Types.jl.
# For reference: abstract type SFunction <: Unifiable end

# to_string - Formats a built in function for display.
# Format:  FunctionName(arg1, arg2, arg3)
# This method is useful for diagnostics.
# Params: built in function
# Return: string representation
function to_string(sfunc::SFunction)::String
    lc_type = lowercase(string(sfunc.type))
    str = "$(lc_type)("
    first = true
    for arg in sfunc.terms
        s = to_string(arg)
        if first
           str *= s
           first = false
        else
            str *= ", $s"
        end
    end
    str *= ")"
    return str
end

# For printing operators
function Base.show(io::IO, sf::SFunction)
    print(io, to_string(sf))
end
