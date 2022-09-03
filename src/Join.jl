# Join.jl
#
# This built-in function joins strings (Atoms) to form a new string.
# It is used to join words and punctuation.
#
# Words are separated by spaces, but punctuation is attached directly
# to the previous word. For example:
#
#   $D1 = coffee, $D2 = "," , $D3 = tea, $D4 = or, $D5 = juice, $D6 = "?",
#   $X = join($D1, $D2, $D3, $D4, $D5, $D6).
#
# $X is bound to the Atom "coffee, tea or juice?".
#
# Note: All terms must be grounded. If not, the function fails.
#
# Cleve Lendon  2022

struct Join <: SFunction
    type::Symbol
    terms::Vector{Unifiable}
    function Join(t::Vector{Unifiable})
        if length(t) < 2
            throw(ArgumentError("Join - requires at least 2 arguments."))
        end
        new(:JOIN, t)
    end
end

# Join - a constructor.
# Params: list of terms
# Return: Join predicate
function Join(terms::Unifiable...)::Join
    t::Vector{Unifiable} = [terms...]
    return Join(t)
end

mutable struct JoinSolutionNode <: SolutionNode
    goal::Union{Goal, SComplex}
    kb::KnowledgeBase
    parent_solution::SubstitutionSet
    parent_node::Union{SolutionNode, Nothing}
    no_back_tracking::Bool
    more_solutions::Bool
end

# join_words_and_punctuation
# Joins strings (Atoms) of words and punctuation together to form a new string.
#
# Params: list of terms
#         substitution set
# Return: new Atom
#         success/failure flag
function joins_word_and_punctuation(terms::Vector{Unifiable},
                                    ss::SubstitutionSet)::Tuple{Atom, Bool}

    str = ""

    count = 0
    for term in terms

        at, ok = cast_atom(ss, term)
        # Should I convert numbers here?
        if !ok
            return at, false
        end

        str2 = to_string(at)

        if count > 0
            if length(str2) == 1 &&
               (str2 == "," || str2 == "." || str2 == "?" || str2 == "!")
                str *= str2
            else
                str *= " $str2"
            end
        else
            str = str2
        end

        count += 1
    end  # for

    return Atom(str), true

end  # joins_word_and_punctuation


# unify - unifies the result of a function with another term
# (usually a variable).
#
# Params: Join predicate
#         other unifiable term
#         substitution set
# Return: updated substitution set
#         success/failure flag
function unify(j::Join, other::Unifiable,
               ss::SubstitutionSet)::Tuple{SubstitutionSet, Bool}
    result, ok = joins_word_and_punctuation(j.terms, ss)
    if !ok
        return ss, false
    end
    return unify(result, other, ss)
end

#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. Please refer to LogicVar.jl.

 Params:  Join predicate
          previously recreated variables
 Return:  expression
===============================================================#
function recreate_variables(j::Join, vars::DictLogicVars)::Expression
    new_terms = recreate_vars(j.terms, vars)
    return Join(new_terms)
end
