# Append.jl - appends terms to make a SLinkedList.
#
# For example:
#
#   ..., $X = a, append($X, b, [c, d, e], [f, g], $Out), ...
#
# The last argument of the append predicate is the output argument.
# The variable $Out will be bound to [a, b, c, d, e, f, g].
#
# Input arguments can be SNumbers, Atoms, LogicVars, SComplex terms
# or SLinkedLists.
#
# There must be at least 2 arguments.
#
# Cleve Lendon
# 2022

struct Append <: BuiltInPredicate
    type::Symbol
    terms::Vector{Unifiable}
    function Append(t::Vector{Unifiable})
        if length(t) < 2
            throw(ArgumentError("Append - requires at least 2 arguments."))
        end
        new(:APPEND, t)
    end
end

# Append - a constructor.
# Params: list of terms
# Return: Append predicate
function Append(terms::Unifiable...)::Append
    t::Vector{Unifiable} = [terms...]
    return Append(t)
end

mutable struct AppendSolutionNode <: SolutionNode
    goal::Union{Goal, SComplex}
    kb::KnowledgeBase
    parent_solution::SubstitutionSet
    parent_node::Union{SolutionNode, Nothing}
    no_back_tracking::Bool
    more_solutions::Bool
end

# get_solver - gets solution node for Append predicate.
# Params: Append predicate
#         knowledge base
#         parent solution
#         parent node
# Return: solution node
function get_solver(goal::Append, kb::KnowledgeBase,
                    parent_solution::SubstitutionSet,
                    parent_node::Union{SolutionNode, Nothing})::SolutionNode
    return AppendSolutionNode(goal, kb, parent_solution,
                              parent_node, false, true)
end

#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. Please refer to LogicVar.jl.

 Params:  built in predicate
          previously recreated variables
 Return:  expression
===============================================================#
function recreate_variables(a::Append, vars::DictLogicVars)::Expression
    new_terms = recreate_vars(a.terms, vars)
    return Append(new_terms)
end

# next_solution - calls append_terms() to produce a new linked list.
# Params: append solution node
# Return:
#    updated substitution set
#    success/failure flag
function next_solution(csn::AppendSolutionNode)::Tuple{SubstitutionSet, Bool}
    if csn.no_back_tracking || !csn.more_solutions
        return csn.parent_solution, false
    end
    csn.more_solutions = false  # Only one solution.
    return append_terms(csn.goal.terms, csn.parent_solution)
end

# append_terms - appends n - 1 arguments together in a linked list
# and binds the result to last argument.
function append_terms(arguments::Vector{Unifiable},
                      ss::SubstitutionSet)::Tuple{SubstitutionSet, Bool}

    len = length(arguments)
    if len < 2
        return ss, false
    end

    arg_list = Vector{Unifiable}()

    for i in 1:(len - 1)

        term = arguments[i]

        # Get ground term.
        tt = typeof(term)
        if tt == LogicVar
            if (is_ground_variable(ss, term))
                term, _ = get_ground_term(ss, term)
            end
        end

        tt = typeof(term)
        if tt == Atom || tt == SNumber
            arg_list = push!(arg_list, term)
        elseif tt == SComplex
            arg_list = push!(arg_list, term)
        elseif tt == SLinkedList
            list = term
            while true
               head = list.term
               if head == nothing
                   break
               end
               arg_list = push!(arg_list, head)
               list = list.next
               if list.term == nothing
                   break
               end
            end
        end
    end # for

    out_list = make_linked_list(false, arg_list...)
    last_term = arguments[end]
    return unify(last_term, out_list, ss)

end  # append_terms
