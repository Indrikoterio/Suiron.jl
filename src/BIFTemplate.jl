# BIFTemplate
#
# This file is a template for writing built-in functions (BIF) for Suiron.
#
# Search and replace the string 'BIFTemplate', everywhere it appears,
# with the name of your new function. Write your function specific code
# in evaluate(), and rename 'evaluate' to something meaningful.
# Adjust comments appropriately and rename this file.
#
# Cleve Lendon 2022

struct BIFTemplate <: SFunction
    type::Symbol
    terms::Vector{Unifiable}
    # Constructor params: an array of unifiable terms.
    function BIFTemplate(t::Vector{Unifiable})
        if length(t) != 2
            throw(ArgumentError("BIFTemplate - requires 2 arguments."))
        end
        new(:NAME_OF_FUNCTION, t)
    end
end

# make_function - A constructor. Rename this.
# Params: list of Unifiable terms
# Return: built-in function struct
function make_function(terms::Unifiable...)::BIFTemplate
    t::Vector{Unifiable} = [terms...]
    return BIFTemplate(t)
end  # make_function()

#----------------------------------------------------------------
# evaluate - Do something with the arguments.
# Refer to Capitalize.jl in the test folder for reference.
#
# Params:
#     list of unifiable arguments
#     substitution set
# Returns:
#    new unifiable
#    success/failure flag
#
function evaluate(arguments::Vector{Unifiable},
                  ss::SubstitutionSet)::Tuple{Unifiable, Bool}
    return Atom("Return something."), true
end # evaluate

#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. Please refer to LogicVar.jl.

 Params:  built in predicate
          previously recreated variables
 Return:  expression
===============================================================#
function Suiron.recreate_variables(c::BIFTemplate,
                               vars::NewVars)::Suiron.Expression
    new_terms = Suiron.recreate_vars(c.terms, vars)
    return BIFTemplate(new_terms)
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
function Suiron.unify(f::BIFTemplate, other::Unifiable,
               ss::SubstitutionSet)::Tuple{SubstitutionSet, Bool}
    result, ok = evaluate(f.terms, ss)
    if !ok return ss, false end
    return unify(result, other, ss)
end

export BIFTemplate
