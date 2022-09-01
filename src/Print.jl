# Print.jl - prints out a list of terms. These terms can be any unifiable,
# such as Atoms, SNumbers, LogicVars, etc. Logic variables are replaced
# with their ground terms. In a Suiron program, 'print' can be included in
# a rule as follows:
#
#   rule1 :- ..., print($X, b, c), ...
#
# Assuming that the variable $X is bound to 'a', the above would print out:
#
#   a, b, c
#
# In a Julia program, the above is equivalent to:
#
#   print(x, b, c)
#
# (Assuming that x is a variable bound to 'a'.)
#
# If the first term is an Atom (string) which contains format specifiers
# (%s), it is treated as a format string. For example,
#
#   $Name = John, $Age = 23, print(%s is %s years old., $Name, $Age).
#
# will print out,
#
#   John is 23 years old.
#
# Commas which do not separate arguments, but are intended to be printed,
# can be escaped with a backslash, for example:
#
#   print(%s\, my friend\, is $s years old.\n, $Name, $Age)
#
# will print out,
#
#   John, my friend, is 23 years old.
#
# Alternatively, instead of using backslashes, a string can be enclosed
# within double quotes:
#
#   print("%s, my friend, is $s years old.\n", $Name, $Age)
#
# Cleve Lendon

const FORMAT_SPECIFIER = "%s"

struct Print <: BuiltInPredicate
    type::Symbol
    terms::Vector{Unifiable}
    function Print(t::Vector{Unifiable})
        if length(t) < 1
            throw(ArgumentError("Print - requires at least 1 argument."))
        end
        new(:PRINT, t)
    end
end

# Print() - a constructor. Creates a Suiron Print predicate. 
# Params: array of Unifiable terms
# Return: print predicate
function Print(terms::Unifiable...)::Print
    t::Vector{Unifiable} = [terms...]
    return Print(t)
end

mutable struct PrintSolutionNode <: SolutionNode
    goal::Union{Goal, SComplex}
    kb::KnowledgeBase
    parent_solution::SubstitutionSet
    parent_node::Union{SolutionNode, Nothing}
    no_back_tracking::Bool
    more_solutions::Bool
end

# get_solver - gets solution node for Print predicate.
# Params: Print predicate
#         knowledge base
#         parent solution
#         parent node
# Return: solution node
function get_solver(goal::Print, kb::KnowledgeBase,
                    parent_solution::SubstitutionSet,
                    parent_node::Union{SolutionNode, Nothing})::SolutionNode
    return PrintSolutionNode(goal, kb, parent_solution,
                             parent_node, false, true)
end

#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. Please refer to LogicVar.jl.

 Params:  built in predicate
          previously recreated variables
 Return:  expression
===============================================================#
function recreate_variables(p::Print, vars::DictLogicVars)::Expression
    new_terms = recreate_vars(p.terms, vars)
    return Print(new_terms)
end

# next_solution - calls print_terms() to solve the goal.
# Params: print solution node
# Return:
#    updated substitution set
#    success/failure flag
function next_solution(sn::PrintSolutionNode)::Tuple{SubstitutionSet, Bool}
    if sn.no_back_tracking || !sn.more_solutions
        return sn.parent_solution, false
    end
    sn.more_solutions = false  # Only one solution.
    return print_terms(sn.goal.terms, sn.parent_solution)
end

#---------------------------------------------------------

# index_at - gets the index of a substring within a string,
# starting from the given index.
# Params: string
#         substring to find
#         index of start of search
# Return: index or nothing
function index_at(str::String, substr::String, start::Integer)::Union{Integer, Nothing}
    indices = findfirst(substr, str[start:end])  # a tuple
    if !isnothing(indices)
        index, _ = indices
        return index + start - 1
    end
    return nothing
end

# split_format_string
#
# A format string looks like this:
#   "Hello %s, my name is %s."
# This function will divide a string into substrings:
#   "Hello ", "%s", ", my name is ", "%s", "."
# Params: original string
# Return: array of substrings
function split_format_string(str::String)::Vector{String}
    sections = Vector{String}()
    start = 1
    len = length(str)
    while start <= len
        index = index_at(str, FORMAT_SPECIFIER, start)
        if isnothing(index)
            push!(sections, str[start: end])
            return sections
        else
            push!(sections, str[start: index - 1])
            start = index
            index += 1
            push!(sections, str[start: index])
            start = index + 1
        end
    end
    return sections
end  # split_format_string


# print_terms - prints out the ground terms of all arguments.
# If the first term has a format specifier, treat it as a format string.
# Params: list of unifiables
# Return: substitution set
#         success/failure flage
function print_terms(arguments::Vector{Unifiable},
                     ss::SubstitutionSet)::Tuple{SubstitutionSet, Bool}

    if length(arguments) == 0
        return ss, false
    end

    # Get first argument.
    term1, _  = get_ground_term(ss, arguments[1])
    term1_str = to_string(term1)
    if occursin(FORMAT_SPECIFIER, term1_str)
        format_substrings = split_format_string(term1_str)
        count = 2
        for format in format_substrings
            if format == FORMAT_SPECIFIER
                if count <= length(arguments)
                    t = arguments[count]
                    t, _ = get_ground_term(ss, t)
                    print("$t")
                    count += 1
                else
                    print(format)
                end
            else
                print(format)
            end
        end  # for
    else   # Not a format string.
        print(term1_str)
        first = true
        for term in arguments
            if first
                first = false
            else
                term, _ = get_ground_term(ss, term)
                print(", $term")
            end
        end
    end
    return ss, true  # Can't fail.

end  # print_terms
