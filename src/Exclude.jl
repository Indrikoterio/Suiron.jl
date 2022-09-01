# Exclude.jl
#
# The built-in predicate 'Exclude' filters terms from an input list, according
# to a filter term. Its arguments are: filter, input list, output list. Eg.
#
# ...
# $InList = [male(Sheldon), female(Penny), female(Bernadette), male(Leonard)],
# exclude(male($_), $InList, $OutList),
#
# Items in the input list which are unifiable with the filter will NOT be
# written to the output list.
#
# The output list above will contain only females,
#    [female(Penny), female(Bernadette)]
#
# Cleve Lendon   2022

struct Exclude <: BuiltInPredicate
    type::Symbol
    terms::Vector{Unifiable}
    function Exclude(t::Vector{Unifiable})
        if length(t) != 3
            throw(ArgumentError("Exclude - take 3 arguments."))
        end
        new(:EXCLUDE, t)
    end
end

# Exclude - A constructor.
# Params: filter term
#         in-list
#         out-list
# Return: Exclude predicate
function Exclude(filter::Unifiable,
                 in_list::Unifiable,
                 out_list::Unifiable)::Exclude
    return Exclude([filter, in_list, out_list])
end

mutable struct ExcludeSolutionNode <: SolutionNode
    goal::Union{Goal, SComplex}
    kb::KnowledgeBase
    parent_solution::SubstitutionSet
    parent_node::Union{SolutionNode, Nothing}
    no_back_tracking::Bool
    more_solutions::Bool
end

# get_solver - gets solution node for Exclude predicate.
# Params: Exclude predicate
#         knowledge base
#         parent solution
#         parent node
# Return: solution node
function get_solver(goal::Exclude, kb::KnowledgeBase,
                    parent_solution::SubstitutionSet,
                    parent_node::Union{SolutionNode, Nothing})::SolutionNode
    return ExcludeSolutionNode(goal, kb, parent_solution,
                               parent_node, false, true)
end


#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. Please refer to LogicVar.jl.

 Params:  built in predicate
          previously recreated variables
 Return:  expression
===============================================================#
function recreate_variables(bip::Exclude, vars::NewVars)::Expression
    new_terms = recreate_vars(bip.terms, vars)
    return Exclude(new_terms)
end

# next_solution - calls exclude_terms() to produce a new linked list.
# Params: exclude solution node
# Return:
#    updated substitution set
#    success/failure flag
function next_solution(sn::ExcludeSolutionNode)::Tuple{SubstitutionSet, Bool}
    if sn.no_back_tracking || !sn.more_solutions
        return sn.parent_solution, false
    end
    sn.more_solutions = false  # Only one solution.
    return exclude_terms(sn.goal.terms, sn.parent_solution)
end


# exclude_filter
# Determines whether the given term is excluded by the filter.
#
# Params: term to test (Unifiable)
#         filter term  (Unifiable)
#         substitution set
# Return: true == pass, false == discard
function exclude_filter(term::Unifiable,
                        filter::Unifiable, ss::SubstitutionSet)::Bool
    _, ok = unify(filter, term, ss)
    if ok
        return false
    end
    return true
end

# exclude_terms - scans the given input list, and tries to unify
# each item with the filter goal. If unification succeeds, the
# item is excluded from the output list. The output list will be
# bound to the third argument.
# Params:
#      list of unifiable terms
#      substitution set
# Return:
#      new substitution set
#      success/failure flag
function exclude_terms(terms::Vector{Unifiable},
                       ss::SubstitutionSet)::Tuple{SubstitutionSet, Bool}

    out_terms = Vector{Unifiable}()

    num_terms = length(terms)
    if num_terms != 3
        return ss, false
    end

    filter_term = terms[1]
    input_list, ok = cast_linked_list(ss, terms[2])
    if !ok
        return ss, false
    end

    # Iterate through the input list.
    while !isnothing(input_list)
        if input_list.is_tail_var
            v = input_list.term
            ground_term, ok = get_ground_term(ss, v)
            if !ok return ss, false end
            if typeof(ground_term) == SLinkedList
                input_list = ground_term
                continue
            else
                if exclude_filter(ground_term, filter_term, ss)
                    push!(out_terms, ground_term)
                end
            end
        else
            if !isnothing(input_list.term)
                if exclude_filter(input_list.term, filter_term, ss)
                    push!(out_terms, input_list.term)
                end
            end
        end
        input_list = input_list.next
    end

    out_list = make_linked_list(false, out_terms...)
    return unify(terms[3], out_list, ss)

end  # exclude_terms
