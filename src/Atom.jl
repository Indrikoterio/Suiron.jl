# Atom.jl
#
# Atoms are strings. In this inference engine, an atom can start
# with an upper case or a lower case letter. (Unlike Prolog.)
#
# Cleve Lendon
# 2022

struct Atom <: Unifiable
    str::String
end

#===============================================================
  unify - unifies an Atom with another term. If both terms are
  Atoms, and equal, then unify succeeds. If they are not equal,
  unify fails.

  If the second term is an unbound LogicVar, then unify binds
  the LogicVar to the Atom, and records the binding in the
  substitution set.

  If the LogicVar is already bound to a different Atom, unify
  will fail.

  The function returns the substitution set and a flag which
  indicates success or failure.

  Params: atom
          other unifiable
          substitution set
  Return: substitution set
          success flag
===============================================================#
function unify(a::Atom, other::Unifiable,
               ss::SubstitutionSet)::Tuple{SubstitutionSet, Bool}

    other_type = typeof(other)

    if other_type == Atom
        if a === other
            return ss, true
        end
        if a.str == other.str
            return ss, true
        end
        return ss, false
    end
    if other_type == LogicVar
        return unify(other, a, ss)
    end
    if other_type == Anonymous
        return ss, true
    end
    return ss, false
end

# to_string - converts an Atom to a string for display.
# Params: Atom
# Return: string representation
function to_string(a::Atom)::String
    return a.str
end  # to_string

# For printing.
Base.show(io::IO, a::Atom) = print(io, a.str)

export Atom
