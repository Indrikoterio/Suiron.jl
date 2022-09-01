# Unification.jl - This file defines the unification predicate,
# which attempts to unify (bind) two terms. If the terms can be
# unified, the predicate succeeds. In a Suiron file, unification
# is defined by an equal sign, as in Prolog.
#
#  $X = pronoun
#
# In a Julia source file, the unification predicate can be defined
# as follows:
#
#  X = LogicVar("x")
#  pronoun = Atom("pronoun")
#  uni_pred = Unification(X, pronoun)
#
# In the examples above, unification will succeed if $X is unbound,
# or already bound to 'pronoun'.
#
# Note: Sometimes this is referred to as the unification operator,
# but it's actually a predicate. (I think.)
#
# Cleve Lendon
# 2022

struct Unification <: BuiltInPredicate
    type::Symbol
    terms::Vector{Unifiable}
    function Unification(term1::Unifiable, term2::Unifiable)
        new(:UNIFICATION, [term1, term2])
    end
end

# parse_unification - creates a logical Unification predicate from
# a string. If the string does not contain "=", the function will
# return with the success flag set to false.
# If there is an error in parsing one of the terms, the function
# throws an error.
# Params:
#     string, eg.: $X = verb
# Return:
#     unification predicate
#     success/failure flag
function parse_unification(str::String)::Tuple{Unification, Bool}
    infix, index = identify_infix(str)
    if infix != :UNIFICATION  # If not Unification...
        throw(ArgumentError("parse_unification() - Invalid: $str"))
    end
    term1, term2 = get_left_and_right(str, index, 1)
    return Unification(term1, term2), true
end

# get_solver - gets a solution node for this predicate.
# get_solver() is implemented for all goals and complex terms.
# Params: unification predicate
#         knowledge base
#         parent solution
#         parent node
# Return: solution node
function get_solver(goal::Unification, kb::KnowledgeBase,
                    parent_solution::Vector{Unifiable},
                    parent_node::Union{SolutionNode, Nothing})::SolutionNode

    return UnificationSolutionNode(goal, kb, parent_solution,
                                   parent_node, false, 0, 0, true)

end

#===============================================================
 recreate_variables - Please refer to LogicVar.jl.

 Params:  unification predicate
          previously recreated variables
 Return:  expression
===============================================================#
function recreate_variables(uni::Unification,
                            vars::Dict{String, LogicVar})::Expression
    arg1 = recreate_variables(uni.terms[1], vars)
    arg2 = recreate_variables(uni.terms[2], vars)
    return Unification(arg1, arg2)
end

# to_string - Formats a unification predicate for display.
# This method is useful for diagnostics.
# Params: unification predicate
# Return: string representation
function to_string(up::Unification):String
    return "$(up.terms[1]) = $(up.terms[2])"
end

# For printing the unification predicate. Eg.: $X = noun.
function Base.show(io::IO, up::Unification)
    print(to_string(up))
end

# A solution node holds the current state of the search for a solution.
# It contains the current goal, the number of the last rule fetched
# from the knowledge base, and a substitution set (which represents the
# solution so far).
# Built-in predicates produce only one solution for a given set of
# arguments. The boolean flag 'moreSolutions' is set to false after
# the first solution is returned.

mutable struct UnificationSolutionNode <: SolutionNode

    goal::Union{Goal, SComplex}
    kb::KnowledgeBase
    parent_solution::Vector{Unifiable}
    parent_node::Union{SolutionNode, Nothing}
    no_back_tracking::Bool
    rule_number::Integer
    count::Integer
    more_solutions::Bool

end

# next_solution - calls unify() to attempt to unify two terms.
# Returns:
#    updated substitution set
#    success/failure flag
function next_solution(usn::UnificationSolutionNode)::Tuple{SubstitutionSet, Bool}

    if usn.no_back_tracking || !usn.more_solutions
        return usn.parent_solution, false
    end
    usn.more_solutions = false  # Only one solution.
    goal  = usn.goal
    term1 = goal.terms[1]
    term2 = goal.terms[2]

    return unify(term1, term2, usn.parent_solution)
end

# to_string - Formats a unification solution node for display.
# This method is useful for diagnostics.
# Params: unification solution node
# Return: string representation
function to_string(sn::UnificationSolutionNode)::String
   g = to_string(sn.goal)
   if isnothing(sn.parent_node)
       pn = "parent_node = nothing"
   else
       pn = "parent_node"
   end
   no = "no_back_tracking = $(sn.no_back_tracking)"
   rn = "rule_number = $(sn.rule_number)"
   co = "count = $(sn.count)"
   ms = "more_solutions = $(sn.more_solutions)"
   str = "\n$g\nkb\nparent_solution\n$pn\n$no\n$rn\n$co\n$ms\n"
   return str
end

# For printing complex solution nodes.
function Base.show(io::IO, sn::UnificationSolutionNode)
    print(io, to_string(sn))
end
