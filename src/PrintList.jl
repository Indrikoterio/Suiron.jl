# PrintList.jl - Prints out a linked list in a readable form.
# It's mainly for debugging purposes. For example:
#
# a_rule :- $X = [a, b, c], $List = [1, 2, 3 | $X], print_list($List).
#
# The rule above should print out: 1, 2, 3, a, b, c
#
# print_list() skips terms which are not ground.
#
# Cleve Lendon  2022

struct PrintList <: BuiltInPredicate
    type::Symbol
    terms::Vector{Unifiable}
    function PrintList(t::Vector{Unifiable})
        if length(t) < 1
            throw(ArgumentError("PrintList - requires at least 1 argument."))
        end
        new(:PRINT_LIST, t)
    end
end

# PrintList() - a constructor. Creates a Suiron print_list predicate. 
# Params: array of Unifiable terms
# Return: print_list predicate
function PrintList(terms::Unifiable...)::PrintList
    t::Vector{Unifiable} = [terms...]
    return PrintList(t)
end

mutable struct PrintListSolutionNode <: SolutionNode
    goal::Union{Goal, SComplex}
    kb::KnowledgeBase
    parent_solution::SubstitutionSet
    parent_node::Union{SolutionNode, Nothing}
    no_back_tracking::Bool
    more_solutions::Bool
end

# get_solver - gets solution node for print_list predicate.
# Params: PrintList predicate
#         knowledge base
#         parent solution
#         parent node
# Return: solution node
function get_solver(goal::PrintList, kb::KnowledgeBase,
                    parent_solution::SubstitutionSet,
                    parent_node::Union{SolutionNode, Nothing})::SolutionNode
    return PrintListSolutionNode(goal, kb, parent_solution,
                                 parent_node, false, true)
end

#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. Please refer to LogicVar.jl.

 Params:  built in predicate
          previously recreated variables
 Return:  expression
===============================================================#
function recreate_variables(p::PrintList, vars::DictLogicVars)::Expression
    new_terms = recreate_vars(p.terms, vars)
    return PrintList(new_terms)
end


# next_solution - calls show_linked_list() to solve the goal.
# Params: print solution node
# Return:
#    updated substitution set
#    success/failure flag
function next_solution(sn::PrintListSolutionNode)::Tuple{SubstitutionSet, Bool}

    ss = sn.parent_solution
    if sn.no_back_tracking || !sn.more_solutions
        return sn.parent_solution, false
    end
    sn.more_solutions = false  # Only one solution.

    if length(sn.goal.terms) == 0
        return ss, false
    end

    for term in sn.goal.terms
        term2, ok = get_ground_term(ss, term)
        if !ok
            continue
        end
        if typeof(term2) == SLinkedList
            show_linked_list(term2, ss)
        end
    end
    return ss, true  # Can't fail.
end

# show_linked_list - Prints out all terms in a Suiron linked list.
#
# Params: linked list
#         substitution set
#
function show_linked_list(the_list::SLinkedList, ss::SubstitutionSet)

    first = true

    while !isnothing(the_list)

        term = the_list.term
        if isnothing(term)
            break
        end

        gt, ok = get_ground_term(ss, term)
        if ok
            if the_list.is_tail_var
                if typeof(gt) == SLinkedList
                    the_list = gt
                    gt, ok = get_ground_term(ss, the_list.term)
                end
            end
            if ok
                if !first
                    print(", ")
                end
                first = false
                print(gt)
            end
        end
        the_list = the_list.next
    end

    print("\n")

end  # show_linked_list
