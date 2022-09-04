# TimeSolutionNode.jl - Solution node for the Time operator.
#
# Cleve Lendon  2022

mutable struct TimeSolutionNode <: SolutionNode

    goal::Union{Goal, SComplex}
    kb::KnowledgeBase
    parent_solution::SubstitutionSet
    parent_node::Union{SolutionNode, Nothing}
    no_back_tracking::Bool
    more_solutions::Bool

    goal_to_time::SComplex
    gtt_solution_node::SolutionNode

    function TimeSolutionNode(g, kb, parent_solution, parent_node)
        goal_to_time = g.terms[1]
        gtt_solution_node = get_solver(goal_to_time, kb,
                                       parent_solution, parent_node)
        new(g, kb, parent_solution, parent_node, false, true,
            goal_to_time, gtt_solution_node)
    end
end


# next_solution - This function prints out the time it takes to solve
# the given goal (goal to time).
# Params: solution node
# Return: substitution set
#         success/failure flag
function next_solution(sn::TimeSolutionNode)::Tuple{SubstitutionSet, Bool}

    if sn.no_back_tracking || !sn.more_solutions
        return sn.parent_solution, false
        sn.more_solutions = false
    end

    for term in sn.goal_to_time.terms
        if typeof(term) == LogicVar
            if !is_ground_term(sn.parent_solution, term)
                println("Time: Logic variable $term is not grounded.")
                return
            end
        end
    end # for

    set_start_time()
    solution, found = next_solution(sn.gtt_solution_node)

    # time in milliseconds since the start of the query.
    elapsed_time()

    return solution, found
end

# has_next_rule - returns true if the knowledge base contains untried
# rules for this node's goal. False otherwise.
# Params: solution node
# Return: true/false
function has_next_rule(n::TimeSolutionNode)::Bool
    if n.no_back_tracking
        return false
    end
    return n.rule_number <= n.count
end

# next_rule - fetches the next rule from the database, according to
# rule_number. The method has_next_rule() must called to ensure that
# a rule can be fetched from the knowledge base. If get_rule is called
# with invalid parameters, the knowledge base will throw an error.
# Params: solution node
# Return: rule
function next_rule(n::TimeSolutionNode)::Rule
    rule = get_rule(n.kb, n.goal, n.rule_number)
    n.rule_number += 1
    return rule
end
