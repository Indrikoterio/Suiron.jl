# ComplexSolutionNode.jl
#
# Solution node for complex terms (compound terms).
#
# This node has a child node, which is the next subgoal. The method
# next_solution() will check to see if the child has a solution.
# If it does, this solution (substitution set) is returned.
#
# Otherwise, next_solution() fetches rules/facts from the knowledge
# base, and tries to unify the head of these rules and facts with
# the goal. If a matching fact is found, the solution is returned.
# (Note, a fact is a rule without a body.)
#
# Otherwise, the body node of the rule becomes the child node, and
# the algorithm tries to find a solution (substitution set) for the
# child. It will return the child solution or for failure.
#
# Cleve Lendon
# 2022

# If matching a goal to a rule fails, restore
# the next_var_id to the fallback id. 
fallback_id = 0

mutable struct ComplexSolutionNode <: SolutionNode

    goal::Union{Goal, SComplex}
    kb::KnowledgeBase
    parent_solution::SubstitutionSet
    parent_node::Union{SolutionNode, Nothing}
    no_back_tracking::Bool
    rule_number::Integer
    count::Integer
    child::Union{SolutionNode, Nothing}

end

# next_solution - initiates or continues the search for a solution.
# If the search succeeds, the method returns the updated substitution
# set, and sets the success flag to true.
# If the search fails, the success flag is set to false.
function next_solution(n::ComplexSolutionNode)::Tuple{SubstitutionSet, Bool}

    if !isnothing(n.child)
        solution, found = next_solution(n.child)
        if found
            return solution, true
        end
    end

    n.child = nothing

    while has_next_rule(n)

        # The fallback id saves the next_var_id, in case the
        # next rule fails. Restoring this id to next_var_id
        # will keep the substitution set small.
        global fallback_id = next_var_id

        rule = next_rule(n)

        head = get_head(rule)
        solution, success = unify(head, n.goal, n.parent_solution)

        if success
            body = rule.body
            if isnothing(body)
                return solution, true
            end

            n.child = get_solver(body, n.kb, solution, n);
            child_solution, ok = next_solution(n.child)
            if ok
                return child_solution, true
            end
        else
            # No success. Fallback to previous id.
            global next_var_id = fallback_id
        end
    end

    return n.parent_solution, false
end # next_solution()

# has_next_rule - returns true if the knowledge base contains
# untried rules for this node's goal. False otherwise.
function has_next_rule(n::ComplexSolutionNode):Bool
    if n.no_back_tracking
        return false
    end
    return n.rule_number <= n.count
end

# next_rule - fetches the next rule from the database, according to
# rule_number. The method has_next_rule() must called to ensure that
# a rule can be fetched from the knowledge base. If get_rule is called
# with invalid parameters, the knowledge base will throw an error.
function next_rule(n::ComplexSolutionNode)::Rule
    rule = get_rule(n.kb, n.goal, n.rule_number)
    n.rule_number += 1
    return rule
end

# to_string - Formats a complex solution node for display.
# Params: complex solution node
# Return: string representation
function to_string(csn::ComplexSolutionNode)::String
   g = to_string(csn.goal)
   if isnothing(csn.parent_node)
       pn = "parent_node = nothing"
   else
       pn = "parent_node"
   end
   no = "no_back_tracking = $(csn.no_back_tracking)"
   rn = "rule_number = $(csn.rule_number)"
   co = "count = $(csn.count)"
   if isnothing(csn.child)
       ch = "child = nothing"
   else
       ch = "child"
   end
   str = "\n$g\nkb\nparent_solution\n$pn\n$no\n$rn\n$co\n$ch\n"
   return str
end

# For printing complex solution nodes.
function Base.show(io::IO, sn::ComplexSolutionNode)
    print(io, to_string(sn))
end
