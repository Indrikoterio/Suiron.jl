# GreaterThan.jl
# Compares numbers and string (SNumbers and Atoms).
#
#    >($X, 18)
# or
#    $X > 18
#
# In the example above, the goal will succeed if $X is
# bound to a number (SNumber) which is greater than 18.
# Otherwise, the goal will fail.
#
# This predicate can also compare strings (Atoms):
#
#   XYZ > ABC
#
# If either side of the comparison is ungrounded, the
# predicate will throw an error.
#
# Cleve Lendon

struct GreaterThan <: BuiltInPredicate
    type::Symbol
    terms::Vector{Unifiable}
    function GreaterThan(left::Unifiable, right::Unifiable)
        new(:GREATER_THAN, [left, right])
    end
end

mutable struct GreaterThanSolutionNode <: SolutionNode
    goal::Union{Goal, SComplex}
    kb::KnowledgeBase
    parent_solution::SubstitutionSet
    parent_node::Union{SolutionNode, Nothing}
    no_back_tracking::Bool
    more_solutions::Bool
end

# parse_greater_than - creates a greater-than predicate from
# a string. If there is an error in parsing one of the terms,
# the function returns an error string.
# Params: string representation, eg.: $X > 18
# Return: greater-than predicate
#         error message
function parse_greater_than(str::String)::Tuple{GreaterThan, Bool}
    infix, index = identify_infix(str)
    if infix != :GREATER_THAN
        return GreaterThan(Atom(">"), Atom(">")),
               "parse_greater_than() - Invalid infix: $infix"
    end
    left, right = get_left_and_right(str, index, 1)
    return GreaterThan(left, right), ""
end # parse_greater_than()

# get_solver - gets a solution node for this predicate.
# Params: greater-than predicate
#         knowledge base
#         parent solution
#         parent node
# Return: solution node
function get_solver(goal::GreaterThan, kb::KnowledgeBase,
                    parent_solution::SubstitutionSet,
                    parent_node::SolutionNode)::SolutionNode
    return GreaterThanSolutionNode(goal, kb, parent_solution,
                                   parent_node, false, true)
end

#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. Please refer to LogicVar.jl.

 Params:  built in predicate
          previously recreated variables
 Return:  expression
===============================================================#
function recreate_variables(gt::GreaterThan, vars::NewVars)::Expression
    new_terms = recreate_vars(gt.terms, vars)
    return GreaterThan(new_terms[1], new_terms[2])
end

# next_solution - compares two numbers, or strings.
# Params: greater-than solution node
# Return:
#    updated substitution set
#    success/failure flag
function next_solution(sn::GreaterThanSolutionNode)::Tuple{SubstitutionSet, Bool}

    if sn.no_back_tracking || !sn.more_solutions
        return sn.parent_solution, false
    end
    sn.more_solutions = false  # Only one solution.

    term1, ok = get_ground_term(sn.parent_solution, sn.goal.terms[1])
    if !ok
        throw(ArgumentError("GreaterThan - Unground term: $(n.goal.terms[1])"))
    end

    term2, ok = get_ground_term(sn.parent_solution, sn.goal.terms[2])
    if !ok
        throw(ArgumentError("GreaterThan - Unground term: $(n.goal.terms[2])"))
    end

    type1 = typeof(term1)
    type2 = typeof(term2)

    if type1 == Atom && type2 == Atom
        result = cmp(term1.str, term2.str)
        # If greater than.
        if result == 1
            return sn.parent_solution, true
        end
        return sn.parent_solution, false
    end

    if type1 == SNumber && type2 == SNumber
        if term1.n > term2.n
             return sn.parent_solution, true
        end
    end

    return sn.parent_solution, false

end  # next_solution

# to_string - Formats as string for display.
# Format:  term1 > term2
# Params: built in predicate
# Return: string representation
function to_string(gt::GreaterThan)::String
    return "$(gt.terms[1]) > $(gt.terms[2])"
end
