# KnowledgeBase.jl - defines a dictionary of rules and facts.
#
# The dictionary is indexed by a key, which is created from the functor
# and arity. For example, for the fact mother(Carla, Caitlyn), the key
# would be "mother/2".
#
# Each key indexes an array of Rules which have the same key.
#
# Cleve Lendon
# 2022

# KnowledgeBase is defined in Types.jl.
# For reference: const KnowledgeBase = Dict{String, Vector{Rule}}

# add_facts_rules - adds facts and rules to the knowledge base.
# Eg.  add_facts_rules(kb, fact1, fact2, rule1, rule2)
# Params:  knowledge base
#          tuple of rules and/or facts
function add_facts_rules(kb::KnowledgeBase, rules::Rule...)
    for rule in rules
        key = get_key(rule)
        if haskey(kb, key)
            arr = kb[key]
        else
            arr = Vector{Rule}()
        end
        push!(arr, rule)
        kb[key] = arr
    end
end # add_facts_rules

# get_rule - fetches a rule (or fact) from the knowledge base.
# Rules are indexed by functor/arity (eg. sister/2) and by index number.
# The variables of the retrieved rule must be made unique, by calling
# recreate_variables().
# Params:  knowledge base
#          goal
#          index of rule
# Return:  rule
function get_rule(kb::KnowledgeBase,
                  goal::Union{Goal, SComplex}, i::Integer)::Rule

    yield() # Allow the timeout timer to run.

    key = get_key(goal)

    if !haskey(kb, key)
        # Should never happen.
        throw(ArgumentError(
              "KnowledgeBase, get_rule() - rule does not exist: $key\n")
             )
    end
    list = kb[key]
    if i > length(list)
        # Should never happen.
        throw(ArgumentError(
              "KnowledgeBase, get_rule() - index out of range: $key $i\n")
             )
    end
    rule = list[i]
    return recreate_variables(rule, NewVars())

end # get_rule()


# get_rule_count - counts the number of rules for the given goal.
# When the execution time has been exceeded, this function will
# return 0. Zero indicates that all rules have been exhausted.
# Params:  knowledge base
#          goal
# Returns: count
function get_rule_count(kb::KnowledgeBase, goal::Union{Goal, SComplex})::Integer

    # The following line will stop the search for a solution if
    # the execution time (300 msecs by default) has timed out.
    if suiron_stop_query
        return 0
    end

    key = get_key(goal)
    try
        list_of_rules = kb[key]
        return length(list_of_rules)
    catch e
        return 0
    end

end # get_rule_count

# to_string - Formats the knowledge base facts and rules for display.
# This method is useful for diagnostics. The keys are sorted.
# Params: knowledge base
# Return: string representation
function to_string(kb::KnowledgeBase):String
    sb = "\n------- Contents of Knowledge Base -------\n"
    keys = Vector{String}()
    for (k, v) in kb
        push!(keys, k)
    end
    sort!(keys)
    for k in keys
        sb *= "$k\n"
        i = 1
        rules = kb[k]
        while i <= length(rules)
            rule = rules[i]
            sb *= "   $(rule)\n"
            i += 1
        end
    end
    sb *= "------------------------------------------"
    return sb
end # to_string

# For printing complex terms. Eg.: employee(John, president)
function Base.show(io::IO, kb::KnowledgeBase)
    print(io, to_string(kb))
end

export KnowledgeBase, add_facts_rules
