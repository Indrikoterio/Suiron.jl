# Anonymous.jl - Anonymous variables.
#
# This file defines the anonymous variable: $_. The anonymous
# variable unifies with any term. Eg.
#
#  check_noun_verb($_, $_, $_, past).
#
# When matching against the above goal, the anonymous variables
# match with any term.
#
# Cleve Lendon
# 2022

struct Anonymous <: Unifiable
end

#===============================================================
  unify - Unifies the anonymous variable with another unifiable
  expression. This function always succeeds.
  Params: logic variable
          other unifiable
          substitution set
  Return: substitution set
          success flag
===============================================================#
function unify(a::Anonymous, other::Unifiable,
               ss::SubstitutionSet)::Tuple{SubstitutionSet, Bool}
    return ss, true
end # unify()

# to_string - Formats as string for display.
# Params: built in predicate
# Return: string representation
function to_string(a::Anonymous)::String
    return "\$_"
end

# For printing.
Base.show(io::IO, a::Anonymous) = print(io, "\$_")
