# Goals.jl
#
# Goal - Complex terms and operators such as And and Or etc. are goals.
#
# The method get_solver() provides a solution node.
#
# Cleve Lendon
# 2022

function make_goal(terms::Unifiable...)::SComplex

    # The main bottleneck in Suiron is the time it takes
    # to copy the substitution set. The substitution set
    # is as large as the highest variable ID. Therefore
    # next_var_id should be set to 0 for every query.
    global next_var_id = 0

    new_terms = make_logic_variables_unique(terms...)
    return SComplex(new_terms)

end # make_goal

# parse_goal - creates a goal (SComplex term) from a text string,
# and ensures that all logic variables have unique IDs.
# Params: string representation of goal
# Return: complex term (array of Unifiables)
#         error message
function parse_goal(str::String)::Tuple{SComplex, String}

    # The main bottleneck in Suiron is the time it takes
    # to copy the substitution set. The substitution set
    # is as large as the highest variable ID. Therefore
    # next_var_id should be set to 0 for every query.
    global next_var_id = 0

    c, err = parse_complex(str)
    if length(err) != 0
        return c, err
    end

    new_terms = make_logic_variables_unique(c.terms...)
    return SComplex(new_terms), ""

end # parse_goal

# make_logic_variables_unique - Long explanation.
# A substitution set keeps track of the bindings of logic variables.
# In order to avoid the overhead of hashing, the substitution set is
# indexed by the ID numbers of these variables. If two logic vars had
# the same ID, this would cause the search for a solution to fail.
# The function LogicVar() creates logic variables with a name and an
# ID number, which is always 0. This is OK, because whenever a rule
# is fetched from the knowledge base, its variables are recreated,
# by calling recreate_variables().
# However, goals are not fetched from the knowledge base. If a goal
# is created, it is necessary to ensure that any logic variables it
# contains do not have an index of 0.
function make_logic_variables_unique(terms::Unifiable...)::Vector{Unifiable}
    new_terms = Vector{Unifiable}()
    vars = NewVars()
    for term in terms
        new_term = recreate_variables(term, vars)
        push!(new_terms, new_term)
    end
    return new_terms
end # make_logic_variables_unique
