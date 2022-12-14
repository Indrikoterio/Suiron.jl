# Solve.jl - Functions which search the knowledge space for solutions.
#
# Cleve Lendon
# 2022

# solve - finds one solution for the given query (goal).
#
# This function returns the solution as a complex term, with the
# logic variables replaced by their bindings. The function also
# returns a string which indicates the reason for failure, if any.
#
#    "" (success)
#    "No" (no solution)
#    "Other reason"
#
# The function has a timer which will stop the query after
# a timeout. See set_max_time() in Timeout.jl.
#
# Note: This method only finds the first result. See solve_all below.
#
# Params:  query
#          knowledge base
#          substitution set (previous bindings)
# Returns: solution (SComplex)
#          reason for failure, if any
#
function solve(query::SComplex, kb::KnowledgeBase,
               ss::SubstitutionSet)::Tuple{SComplex, String}

    cond = Condition()
    set_start_time()
    error_message = ""

    # Notify when max time has elapsed.
    the_timer = Timer(_ -> notify(cond), suiron_max_time)

    # Asynchronous task, solve the query.
    found = false
    new_ss::Union{SubstitutionSet, Nothing} = nothing

    tsk = @async begin
        # Get the root solution node.
        root = get_solver(query, kb, ss, nothing)
        try
            #set_start_time()
            new_ss, found = next_solution(root)
            #elapsed_time()
        catch e
            error_message = sprint(showerror, e)
        end
        global suiron_stop_query = true
        notify(cond)
    end

    wait(cond)
    close(the_timer)

    if tsk.state == :done

        if length(error_message) > 0
            return query, error_message
        end
        if found
            solution = replace_variables(query, new_ss)
            return solution, ""
        else
            return query, "No"
        end

    end

    global suiron_stop_query = true
    return query, "Timed out."

end  # solve()

# solve_all - finds all solutions for the given query (goal).
#
# This function returns solutions as an array of complex
# terms, with their logic variables replaced by their bindings.
# The function also returns a string which indicates the reason
# for failure, if any.
#
#    "" (success)
#    "No" (no solution)
#    "Other reason"
#
# The function has a timer which will stop the query after
# a timeout. See set_max_time() in Timeout.jl.
#
# Params:  query
#          knowledge base
#          substitution set
# Returns: solutions
#          failure reason
#
function solve_all(query::SComplex, kb::KnowledgeBase,
                   ss::SubstitutionSet)::Tuple{Vector{SComplex}, String}

    solutions = Vector{SComplex}()
    cond = Condition()
    set_start_time()
    error_message = ""

    # Notify when max time has elapsed.
    the_timer = Timer(_ -> notify(cond), suiron_max_time)

    # Asynchronous task, solve the query.
    found = false
    new_ss::Union{SubstitutionSet, Nothing} = nothing

    tsk = @async begin
        # Get the root solution node.
        root = get_solver(query, kb, ss, nothing)
        try
            new_ss, found = next_solution(root)
            #elapsed_time()

            while found
                # Replace variables with their bound constants.
                sol = replace_variables(query, new_ss)
                push!(solutions, sol)
                #set_start_time()
                new_ss, found = next_solution(root)
                #elapsed_time()
            end
        catch e
            error_message = sprint(showerror, e)
        end
        global suiron_stop_query = true
        notify(cond)
    end

    wait(cond)
    close(the_timer)

    if tsk.state == :done
        if length(error_message) > 0
            return solutions, error_message
        end

        if length(solutions) == 0
            failure = "No"
        else
            failure = ""
        end
        return solutions, failure
    end

    global suiron_stop_query = true
    return solutions, "Timed out."

end  # solve_all


# format_solution - formats a string to display the variable bindings
# of a solution. For example, if the query were: grandfather(Godwin, $X),
# then the function would return: $X = Harold
# Params:
#    query
#    bindings (substitution set)
# Return:
#    solution in string format
function format_solution(query::SComplex,
                         bindings::Union{SubstitutionSet, Nothing})::String
    if !isnothing(bindings)
        str = ""
        result = replace_variables(query, bindings)
        first = true  # first variable
        for (n, term) in enumerate(query.terms)
            if typeof(term) == LogicVar
                if !first
                    str *= ", "
                end
                str *= "\$$(term.name) = $(result.terms[n])"
                first = false
            end
        end
        if length(str) == 0
            return "True "
        end
        return str *= " "
    end
    return "No"

end  # format_solution
