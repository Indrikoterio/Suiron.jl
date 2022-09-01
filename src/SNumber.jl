# SNumber.jl
#
# SNumber stands for Suiron Number.
#
# Cleve Lendon
# 2022

struct SNumber <: Unifiable
    n::Number
end

# unify - unifies an SNumber with another unifiable term. If both terms
# are equal, unify succeeds. Otherwise unify will fail.
#
# The function returns the substitution set and a flag which indicates
# success or failure.
# Params: suiron number
#         other unifiable
#         substitution set
# Return: substitution set
#         success flag
function unify(num::SNumber, other::Unifiable,
               ss::SubstitutionSet)::Tuple{SubstitutionSet, Bool}
    other_type = typeof(other)
    if other_type == SNumber
        if num == other
            return ss, true
        end
        if num.n == other.n
            return ss, true
        end
        return ss, false
    end
    if other_type == LogicVar
        return unify(other, num, ss)
    end
    if other_type == Anonymous
        return ss, true
    end
    return ss, false
end

# to_string - Formats an SNumber for display.
# Params: suiron number
# Return: string representation
function to_string(num::SNumber)::String
    return "$(num.n)"
end

# For printing.
Base.show(io::IO, num::SNumber) = print(io, num.n)
