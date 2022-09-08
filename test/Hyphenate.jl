# Hyphenate - is a built-in predicate function which joins two
# words with a hyphen. It was written to test built-in predicate
# functionality.
#
# Hyphenate is instantiated from TestBuiltIn.jl, as follows:
#
#    c2 = Hyphenate(In, H, T, InErr, Err2)
#
# The arguments above are logic variables (type LogicVar). If
# this predicate were written in a Suiron source file, it would
# appear as follows:
#
# ..., hyphenate($In, $H, $T, $InErr, $Err2), ...
#
# Hyphenate takes the first two words from an input word list,
# and joins them with a hyphen. The new hyphenated word is bound
# to the second argument (head word). The remainder of the word
# list is bound to the third argument (tail of list). For example,
# if the input  were:
#
#    $In = [one, two, three, four]
#
# The output would be:
#
#    $H = one-two
#    $T = [three, four]
#
# The predicate also creates an error message, which is bound
# to the last argument. For the following input error list:
#
#    [first error]
#
# The output ($Err2) will be:
#
#    [another error, first error]
#
# Cleve Lendon

struct Hyphenate <: sr.BuiltInPredicate
    type::Symbol
    terms::Vector{sr.Unifiable}
    function Hyphenate(t::Vector{sr.Unifiable})
        new(:HYPHENATE, t)
    end
end

# make_hyphenate - makes a hyphenate predicate.
# Params: list of sr.Unifiable terms
# Return: hyphenate predicate
function make_hyphenate(terms::sr.Unifiable...)::Hyphenate
    if length(terms) != 5
        throw(ArgumentError(
            "Hyphenate - This predicate requires 5 arguments.")
        )
    end
    t::Vector{sr.Unifiable} = [terms...]
    return Hyphenate(t)
end

#===============================================================
# get_solver - gets a solution node for this predicate.
# Params: built in predicate
#         knowledge base
#         parent solution
#         parent node
# Return: solution node
===============================================================#
function sr.get_solver(
                goal::Hyphenate, kb::sr.KnowledgeBase,
                parent_solution::sr.SubstitutionSet,
                parent_node::Union{sr.SolutionNode, Nothing})::sr.SolutionNode
    return HyphenateSolutionNode(goal, kb, parent_solution,
                                 parent_node, false, true)
end

# A solution node holds the current state of the search for a solution.
# It contains the current goal, the number of the last rule fetched
# from the knowledge base, and a substitution set (which represents the
# solution so far).
# Built-in predicates produce only one solution for a given set of
# arguments. The boolean flag 'more_solutions' is set to false after
# the first solution is returned.

mutable struct HyphenateSolutionNode <: sr.SolutionNode
    goal::Union{sr.Goal, sr.SComplex}
    kb::sr.KnowledgeBase
    parent_solution::sr.SubstitutionSet
    parent_node::Union{sr.SolutionNode, Nothing}
    no_back_tracking::Bool
    more_solutions::Bool
end

# next_solution - calls a function (in this case, join_with_hyphen)
# to evaluate the current goal, based on its arguments and the
# substitution set.
# Params: hyphenate solution node
# Return:
#    updated substitution set
#    success/failure flag
function sr.next_solution(sn::HyphenateSolutionNode)::Tuple{sr.SubstitutionSet, Bool}
    if sn.no_back_tracking || !sn.more_solutions
        return sn.parent_solution, false
    end
    sn.more_solutions = false  # Only one solution.
    return join_with_hyphen(sn.goal.terms, sn.parent_solution)
end

# join_with_hyphen - joins the first two words in a word list with
# a hyphen, and generates an error message. For example,
#
#    $In = [one, two, three, four]
#
# becomes,
#
#    $H = one-two
#    $T = [three, four]
#
# The function also takes an error list and adds a new error message, eg:
#
#    $InErr  = [first error]
#    $OutErr = [another error, first error]
#
# The 5 arguments are:
#
#    word list     - in
#    head word     - out
#    tail of list  - out
#    error list    - in
#    error list    - out
#
# Params:
#      list of 5 arguments
#      substitution set (= solution so far)
# Return:
#      updated substitution set
#      success/failure flag
#
function join_with_hyphen(arguments::Vector{sr.Unifiable},
                          ss::sr.SubstitutionSet)::Tuple{sr.SubstitutionSet, Bool}

    # First argument must be a linked list.
    in_list, ok = sr.cast_linked_list(ss, arguments[1])
    if !ok
        return ss, false
    end

    # The fourth argument must be a linked list.
    in_errors, ok = sr.cast_linked_list(ss, arguments[4])
    if !ok
        return ss, false
    end

    err = sr.Atom("another error")
    # Add an error message to the error list
    new_error_list = sr.make_linked_list(false, err, in_errors)

    # Flatten gets the first two items of a list and the
    # rest of the list. Thus, flatten(in_list, 2, ss) returns
    # an array of 3 items: term1, term2, list of remaining terms
    terms, ok = sr.flatten(in_list, 2, ss)
    if !ok
        return ss, false
    end

    term1, _ = sr.cast_atom(ss, terms[1])
    term2, _ = sr.cast_atom(ss, terms[2])

    # Join the two terms.
    str = "$term1-$term2"
    new_head = sr.Atom(str)
    new_tail = terms[3]

    # Unify output terms.
    ss, ok = sr.unify(new_error_list, arguments[5], ss)
    if !ok
        return ss, false
    end
    ss, ok = sr.unify(new_head, arguments[2], ss)
    if !ok
        return ss, false
    end
    ss, ok = sr.unify(new_tail, arguments[3], ss)
    if !ok
        return ss, false
    end
    return ss, true

end  # join_with_hyphen

#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. Please refer to LogicVar.jl.

 Params:  built in predicate
          previously recreated variables
 Return:  expression
===============================================================#
function sr.recreate_variables(h::Hyphenate, vars::sr.DictLogicVars)::sr.Expression
    new_terms = sr.recreate_vars(h.terms, vars)
    return Hyphenate(new_terms)
end
