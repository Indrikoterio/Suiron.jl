# Count.jl - This predicate counts the number of items in a linked list.
# The first argument is the list to check. The second is the result.
# For example:
#
#     ..., count([a, b, c], $X),...
#
# The variable $X will be bound to 3.
#
# If the last item in the list is a tail variable, which is bound
# to another list, the predicate 'count' will count the number of
# items in both lists.
#
# Cleve Lendon
# 2022

struct Count <: BuiltInPredicate
    type::Symbol
    terms::Vector{Unifiable}
    function Count(list::Unifiable, out::Unifiable)
        new(:COUNT, [list, out])
    end
end

mutable struct CountSolutionNode <: SolutionNode
    goal::Union{Goal, SComplex}
    kb::KnowledgeBase
    parent_solution::SubstitutionSet
    parent_node::Union{SolutionNode, Nothing}
    no_back_tracking::Bool
    more_solutions::Bool
end

# get_solver - gets a solution node for this predicate.
# This function satisfies the Goal interface.
# Params: count predicate
#         knowledge base
#         parent solution
#         parent node
# Return: solution node
function get_solver(goal::Count, kb::KnowledgeBase,
                    parent_solution::SubstitutionSet,
                    parent_node::Union{SolutionNode, Nothing})::SolutionNode

    return CountSolutionNode(goal, kb, parent_solution,
                             parent_node, false, true)
end

# next_solution - calls count_ll() to count items in the linked list.
# Params: count solution node
# Return:
#    updated substitution set
#    success/failure flag
function next_solution(sn::CountSolutionNode)::Tuple{SubstitutionSet, Bool}
    if sn.no_back_tracking || !sn.more_solutions
        return sn.parent_solution, false
    end
    sn.more_solutions = false  # Only one solution.
    return count_ll(sn.goal.terms, sn.parent_solution)
end

#===============================================================
 count_ll - counts the number of items in a linked list.
 If the last item is a tail variable, eg. [a, b | $T], and
 that variable is bound to another list, count the terms in
 the second list also.

 Params:
      list of terms (linked list, out variable)
      substitution set
 Return:
      updated substitution set
      success/failure flag
===============================================================#
function count_ll(terms::Vector{Unifiable},
                  ss::SubstitutionSet)::Tuple{SubstitutionSet, Bool}

    linked_list, ok = cast_linked_list(ss, terms[1])
    if !ok
        return ss, false
    end

    ptr::Union{SLinkedList, Nothing} = linked_list
    count = 0
    while ptr != nothing
        if ptr.is_tail_var
            v = ptr.term  # Must be logic variable.
            ground_term, ok = get_ground_term(ss, v)
            if !ok
                return ss, false
            end
            tt = typeof(ground_term)
            if tt == SLinkedList
                ptr = ground_term
            else
                count += 1
            end
        else
            count += 1
        end
        ptr = ptr.next
    end # while
    return unify(terms[2], SNumber(count), ss)
end

#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. Please refer to LogicVar.jl.

 Params:  built in predicate
          previously recreated variables
 Return:  expression
===============================================================#
function recreate_variables(c::Count, vars::DictLogicVars)::Expression
    new_terms = recreate_vars(c.terms, vars)
    return Count(new_terms[1], new_terms[2])
end
