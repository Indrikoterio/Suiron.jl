# Functor.jl
#
# Functor() is a built-in predicate to get the functor and arity
# of a complex term. Eg.:
#
#     functor(boss(Zack, Stephen), $Func, $Arity)
#
# The first term must be the complex term to be tested.
#
# $Func will bind to 'boss' and $Arity will bind to the integer
# 2 (because there are two arguments, Zack and Stephen). Arity
# is optional:
#
#     functor(boss(Zack, Stephen), $Func)
#
# The following goal will succeed.
#
#     $X = boss(Zack, Stephen), functor($X, boss)
#
# The next goal will not succeed, because the arity is incorrect:
#
#     functor($X, boss, 3)
#
# If the second argument has an asterisk at the end, the match will
# test only the start of the string. For example, the following
# will succeed:
#
#     $X = noun_phrase(the blue sky), functor($X, noun*)
#
# TODO:
# Perhaps the functionality could be expanded to accept a regex
# string for the second argument.
#
# Cleve Lendon   2022

struct Functor <: BuiltInPredicate
    type::Symbol
    terms::Vector{Unifiable}
    function Functor(t::Vector{Unifiable})
        len = length(t)
        if len != 2 && len != 3
            throw(ArgumentError("Functor - takes 2 or 3 arguments."))
        end
        new(:FUNCTOR, t)
    end
end

# Functor - A constructor.
# Params: complex term
#         functor (out)
# Return: Functor predicate
function Functor(term::Unifiable, func::Unifiable)::Functor
    return Functor([term, func])
end

# Functor - A constructor.
# Params: complex term
#         functor (out)
#         arity   (out)
# Return: Functor predicate
function Functor(term::Unifiable, func::Unifiable,
                 arity::Unifiable)::Functor
    return Functor([term, func, arity])
end

mutable struct FunctorSolutionNode <: SolutionNode
    goal::Union{Goal, SComplex}
    kb::KnowledgeBase
    parent_solution::SubstitutionSet
    parent_node::Union{SolutionNode, Nothing}
    no_back_tracking::Bool
    more_solutions::Bool
end

# get_solver - gets solution node for Functor predicate.
# Params: Functor predicate
#         knowledge base
#         parent solution
#         parent node
# Return: solution node
function get_solver(goal::Functor, kb::KnowledgeBase,
                    parent_solution::SubstitutionSet,
                    parent_node::Union{SolutionNode, Nothing})::SolutionNode
    return FunctorSolutionNode(goal, kb, parent_solution,
                               parent_node, false, true)
end

#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. Please refer to LogicVar.jl.

 Params:  built in predicate
          previously recreated variables
 Return:  expression
===============================================================#
function recreate_variables(f::Functor, vars::NewVars)::Expression
    new_terms = recreate_vars(f.terms, vars)
    return Functor(new_terms)
end

#xxxxxxxxxxxxxxxxxxxxxxxx
# next_solution - calls include_terms() to produce a new linked list.
# Params: include solution node
# Return:
#    updated substitution set
#    success/failure flag
function next_solution(sn::IncludeSolutionNode)::Tuple{SubstitutionSet, Bool}
    if sn.no_back_tracking || !sn.more_solutions
        return sn.parent_solution, false
    end
    sn.more_solutions = false  # Only one solution.
    return include_terms(sn.goal.terms, sn.parent_solution)
end


# include_filter - determines whether the given term passes the filter.
#
# Params: term to test (Unifiable)
#         filter term  (Unifiable)
#         substitution set
# Return: true == pass, false == discard
function include_filter(term::Unifiable,
                        filter::Unifiable, ss::SubstitutionSet)::Bool
    _, ok = unify(filter, term, ss)
    if ok
        return true
    end
    return false
end

# include_terms - scans the given input list, and tries to unify
# each item with the filter goal. If unification succeeds, the
# item is included from the output list. The output list will be
# bound to the third argument.
# Params:
#      list of unifiable terms
#      substitution set
# Return:
#      new substitution set
#      success/failure flag
function include_terms(terms::Vector{Unifiable},
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
                if include_filter(ground_term, filter_term, ss)
                    push!(out_terms, ground_term)
                end
            end
        else
            if !isnothing(input_list.term)
                if include_filter(input_list.term, filter_term, ss)
                    push!(out_terms, input_list.term)
                end
            end
        end
        input_list = input_list.next
    end

    out_list = make_linked_list(false, out_terms...)
    return unify(terms[3], out_list, ss)

end  # include_terms

export Include
