# Capitalize - this function capitalizes a word or name.
#
# It accepts one argument (currently), an Atom, or a LogicVar
# bound to an Atom, and capitalizes it. (tokyo becomes Tokyo.)
#
# Note: Unlike a predicate, which returns a substitution set,
# a function returns a unifiable term. Therefore, it must be
# used with unification. Eg.
#
#    ..., $CapName = capitalize($Name),...
#
# Cleve Lendon 2022

struct Capitalize <: sr.SFunction
    type::Symbol
    terms::Vector{sr.Unifiable}
    function Capitalize(t::Vector{sr.Unifiable})
        if length(t) != 1
            throw(ArgumentError("Capitalize - accepts only 1 argument."))
        end
        new(:CAPITALIZE, t)
    end
end

# make_capitalize - makes a 'capitalize' function.
# Params: list of Unifiable terms (Atoms)
# Return: capitalize function
function make_capitalize(terms::sr.Unifiable...)::Capitalize
    t::Vector{sr.Unifiable} = [terms...]
    return Capitalize(t)
end  # make_capitalize()

# make_capitalize - makes a 'capitalize' function.
# Params: list of string
# Return: capitalize function
function make_capitalize(args::String...)::Capitalize
    terms = Vector{sr.Unifiable}()
    for str in args
        if str isa String
            term = sr.Atom(str)
        else
            throw(ArgumentError("Capitalize - not a string: $str"))
        end
        push!(terms, term)
    end
    return Capitalize(terms)
end  # make_capitalize()

#----------------------------------------------------------------
# sr_capitalize - Capitalizes the first letter of the given word(s).
#
# Params:
#     list of arguments
#     substitution set
# Returns:
#    new unifiable
#    success/failure flag
#
function sr_capitalize(arguments::Vector{sr.Unifiable},
                       ss::sr.SubstitutionSet)::Tuple{sr.Unifiable, Bool}

    term, ok = sr.cast_atom(ss, arguments[1])
    if !ok
        return sr.Atom("?"), false
    end
    lc = lowercase(term.str)
    str = uppercasefirst(lc)
    return sr.Atom(str), true

end # sr_capitalize

#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. Please refer to LogicVar.jl.

 Params:  built in predicate
          previously recreated variables
 Return:  expression
===============================================================#
function sr.recreate_variables(c::Capitalize,
                               vars::sr.DictLogicVars)::sr.Expression
    new_terms = sr.recreate_vars(c.terms, vars)
    return Capitalize(new_terms)
end

#===============================================================
  unify - unifies the result of a function with another term,
  usually a variable.

  Params:
     other unifiable term
     substitution set
  Returns:
     updated substitution set
     success/failure flag
===============================================================#
function sr.unify(c::Capitalize, other::sr.Unifiable,
               ss::sr.SubstitutionSet)::Tuple{sr.SubstitutionSet, Bool}
    result, ok = sr_capitalize(c.terms, ss)
    if !ok return ss, false end
    return sr.unify(result, other, ss)
end
