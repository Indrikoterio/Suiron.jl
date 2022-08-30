# SubstitutionSet.jl
#
# A substitution set is an array of bindings for logic variables.
# Each logic variable has a unique ID number, which is used to
# index into the substitution set. Each element of the substitution
# set is a unifiable term.
#
# As the inference engine searches for a solution, it adds bindings
# to the substitution set. The substitution set holds the state of
# the search. It represents the partial or complete solution to the
# original query.
#
# Cleve Lendon
# 2022

# The type SubstitutionSet is defined in Types.jl.
# For reference: const SubstitutionSet = Vector{Unifiable}

# is_bound() - A logic variable is bound if an entry for
# it exists in the substitution set.
# Params: substitution set
#         logic variable
# Return: true/false
function is_bound(ss::SubstitutionSet, v::LogicVar)::Bool
    if v.id > length(ss)
        return false
    end
    return isassigned(ss, v.id)
end

# get_binding() - Returns the binding of a logic variable.
# If there is no binding, return an error.
# Params: substitution set
#         logic variable
# Return: bound term
#         error string (empty string if no error)
function get_binding(ss::SubstitutionSet, v::LogicVar)::Tuple{Unifiable, String}
    if v.id > length(ss)
        return v, "get_binding() - Not bound: $v"
    end
    if isassigned(ss, v.id)
        return ss[v.id], ""
    else
        return v, "get_binding() - Not bound: $v"
    end
end

# is_ground_variable - A variable is 'ground' if it is ultimately
# bound to something other than a variable.
# Params: substitution set
#         logic variable
# Return: true/false
function is_ground_variable(ss::SubstitutionSet, v::LogicVar)::Bool
    while true
        if v.id > length(ss)
            return false
        end
        if isassigned(ss, v.id)
            u = ss[v.id]
            if typeof(u) != LogicVar
                return true
            end
            v = u
        else
            return false
        end
    end
    return false
end

# get_ground_term - if the given term is a ground term, return it.
# If it's a variable, try to get its ground term. If the variable
# is bound to a ground term, return the term and set the success
# flag to true. Otherwise, return the variable and set the success
# flag to false.
# Params: substitution set
#         unifiable term
# Return: ground term
#         success/failure flag
function get_ground_term(ss::SubstitutionSet,
                         u::Unifiable)::Tuple{Unifiable, Bool}
    if typeof(u) != LogicVar
        return u, true
    end
    len = length(ss)
    while true
        id = u.id
        if id > len
            return u, false
        end
        if isassigned(ss, id)
            u2 = ss[id]
            if typeof(u2) != LogicVar
                return u2, true
            end
        else
            return u, false
        end
        u = u2
    end # while
    return u2, false
end # get_ground_term()


# ground_terms - converts a list of unifiable terms to ground
# terms. (Replaces logic variables with their ground terms.)
# If the list contains unground variables, the function will
# set a flag to indicate this.
#
# Params: substitution set
#         array of unifiable terms
# Return: array of ground terms
#         has_unground  (variables)
function ground_terms(
            ss::SubstitutionSet,
            terms::Vector{Unifiable})::Tuple{Vector{Unifiable}, Bool}

    ground = Vector{Unifiable}()  # New array for ground terms.
    has_unground = false

    # Get ground terms.
    for term in terms
        c, ok = get_ground_term(ss, term)
        if !ok
            has_unground = true
        end
        push!(ground, c)
    end
    return ground, has_unground

end # ground_terms()

# cast_linked_list - if the given unifiable term is a linked list,
# return it. If it is a logic variable, get the ground term.
# If the ground term is a linked list, return it. Otherwise fail.
#
# Params: substitution set
#         unifiable term (maybe linked list)
# Return: linked list
#         success/failure flag
function cast_linked_list(ss::SubstitutionSet,
                          term::Unifiable)::Tuple{SLinkedList, Bool}
    tt = typeof(term)
    if tt == SLinkedList
        return term, true
    end
    if tt == LogicVar
        out_term, ok = get_ground_term(ss, term)
        if ok
            if typeof(out_term) == SLinkedList
                return out_term, true
            end
        end
    end
    return empty_list, false

end # cast_linked_list()

# cast_atom - if the given unifiable term is an Atom return it.
# If it is a logic variable, get the ground term. If that term
# is an Atom, return it. Otherwise fail.
#
# Params: substitution set
#         Unifiable term
# Return: Atom
#         success/failure flag
#
function cast_atom(ss::SubstitutionSet, term::Unifiable)::Tuple{Atom, Bool}
    tt = typeof(term)
    if tt == Atom
        return term, true
    end
    if tt == LogicVar
        out_term, ok = get_ground_term(ss, term)
        if ok
            if typeof(out_term) == Atom
                return out_term, true
            end
        end
    end
    return Atom(""), false
end # cast_atom()

# to_string - Formats a substitution set for display.
# Params: substitution set
# Return: string representation
function to_string(ss::SubstitutionSet)::String

    str = "\n\nindex: term -----------\n"
    len = length(ss)

    for i in 1:len
        if isassigned(ss, i)
            str *= "    $i: $(ss[i])\n"
        else
            str *= "    $i: --\n"
        end
    end

    str *= "-----------------------\n"
    return str
end

# For showing the substitution set.
function Base.show(io::IO, ss::SubstitutionSet)
    print(io, to_string(ss))
end
