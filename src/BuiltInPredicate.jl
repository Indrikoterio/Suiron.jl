# BuiltInPredicate.jl - This file contains the functions which
# are common to all of Suiron's built-in predicates.
#
# Cleve Lendon
# 2022

# BuiltInPredicate is defined in Types.jl.
# For reference: abstract type BuiltInPredicate <: Goal end

# recreate_one_var - recreates one variable.
#
# This function assists recreate_variables(). If the given term
# is a LogicVar, this function will return a new unique variable.
# If the term is a linked list, recreate_one_var() will call its
# recreate_variables() function, to recreate all the elements of
# the linked list. Otherwise, it will return the term as is.
#
# Params: Unifiable term
#         list of previously recreated Variables
# Return: new Unifiable term
function recreate_one_var(term::Unifiable, vars::DictLogicVars)::Unifiable
    tt = typeof(term)
    if tt == LogicVar || tt == SComplex ||
       tt == SLinkedList || tt == SFunction
        return recreate_variables(term, vars)
    end
    return term
end # recreate_one_var()

#===============================================================
  recreate_vars - recreates all LogicVars in an array of
  Unifiable terms.
  Params: array of Unifiable terms
          previously recreated logic vars
  Return: array of new terms
===============================================================#
function recreate_vars(terms::Vector{Unifiable},
                       vars::DictLogicVars)::Vector{Unifiable}
    new_terms = Vector{Unifiable}()
    for term in terms
        v = recreate_one_var(term, vars)
        push!(new_terms, v)
    end
    return new_terms
end # recreate_vars()

#===============================================================
  replace_variables - replaces variables with their bindings.
  This is required in order to display solutions.

  Params:  built in predicate
           substitution set (contains bindings)
  Return:  expression
===============================================================#
function replace_variables(bip::BuiltInPredicate,
                           ss::SubstitutionSet)::Expression

    for arg in bip.terms
        tt = typeof(arg)
        if tt == Atom || tt == SNumber
            return arg
        elseif tt == SComplex
            return replace_variables(arg, ss)
        elseif tt == LogicVar
            the_var = arg
            if is_bound(ss, the_var)
                return replace_variables(the_var, ss)
            else
                return the_var
            end
        else
            return Atom("BIP error 2")
        end
    end
    return Atom("BIP error 3")

end  # replace_variables

# to_string - Formats a built in predicate for display.
# Format:  PredName(arg1, arg2, arg3)
# This method is useful for diagnostics.
# Params: built in predicate
# Return: string representation
function to_string(bip::BuiltInPredicate)::String
    str = lowercase("$(bip.type)(")
    first = true
    for arg in bip.terms
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

