# AndSolutionNode.jl - Solution node for the :AND operator.
#
# The 'And' operator (SOperator) is an array of goals (and complex terms).
# In a Suiron source file the goals are separated by commas.
#
#   goal1, goal2, goal3
#
# Cleve Lendon
# 2022

mutable struct AndSolutionNode <: SolutionNode

    goal::Union{Goal, SComplex}
    kb::KnowledgeBase
    parent_solution::SubstitutionSet
    parent_node::Union{SolutionNode, Nothing}
    no_back_tracking::Bool
    rule_number::Integer
    count::Integer

    head_solution_node::Union{SolutionNode, Nothing}
    tail_solution_node::Union{SolutionNode, Nothing}
    operator_tail::SOperator

    function AndSolutionNode(g, kb, parent_solution, parent_node)
        new(g, kb, parent_solution, parent_node, false, 0, 0, nothing, nothing)
    end
end

# make_and_solution_node - for the AND operator.
# Params:  goal
#          knowledge base
#          parent solution (substitution set)
#          solution node of parent
# Return:  a solution node
function make_and_solution_node(
         op::Union{Goal, SComplex}, kb::KnowledgeBase,
         parent_solution::Vector{Unifiable},
         parent_node::Union{SolutionNode, Nothing})::SolutionNode

    head_op  = get_head_operand(op)
    tail_ops = get_tail_operands(op)

    node = AndSolutionNode(op, kb, parent_solution, parent_node)

    hsn = get_solver(head_op, kb, parent_solution, parent_node)
    node.head_solution_node = hsn
    node.operator_tail = tail_ops
    return node
end


# next_solution - recursively calls next_solution on all subgoals.
# If the search succeeds, the success flag is set to true, and
# the substitution set is updated.
# If the search fails, the success flag is false.
# Params: and solution node
# Return: substitution set
#         success flag
function next_solution(sn::AndSolutionNode)::Tuple{SubstitutionSet, Bool}

    if sn.no_back_tracking
        return sn.parent_solution, false
    end

    if sn.tail_solution_node != nothing
        solution, found = next_solution(sn.tail_solution_node)
        if found
            return solution, true
        end
    end

    solution, found = next_solution(sn.head_solution_node)
    while found
        if length(sn.operator_tail.goals) == 0
            return solution, true
        else
            # tail_solution_node has to be a new AndSolutionNode.
            sn.tail_solution_node = get_solver(sn.operator_tail,
                                               sn.kb, solution, sn)
            tail_solution, found = next_solution(sn.tail_solution_node)
            if found
                return tail_solution, true
            end
        end
        solution, found = next_solution(sn.head_solution_node)
    end
    return sn.parent_solution, false
end

# has_next_rule - returns true if the knowledge base contains untried
# rules for this node's goal. False otherwise.
function has_next_rule(sn::AndSolutionNode)::Bool
    if sn.no_back_tracking
        return false
    end
    return sn.rule_number <= sn.count
end

# next_rule - fetches the next rule from the database, according to
# rule_number. The method has_next_rule() must called to ensure that
# a rule can be fetched from the knowledge base. If get_rule is called
# with invalid parameters, the knowledge base will throw an error.
function next_rule(sn::AndSolutionNode)::Rule
    rule = get_rule(sn.kb, sn.goal, sn.rule_number)
    sn.rule_number += 1
    return rule
end

# to_string - Formats an AND solution node for display.
# This method is useful for diagnostics.
# Params: AND node
# Return: string representation
function to_string(sn::AndSolutionNode)::String
   g = to_string(sn.goal)
   if isnothing(sn.parent_node)
       pn = "parent_node = nothing"
   else
       pn = "parent_node"
   end
   no = "no_back_tracking = $(sn.no_back_tracking)"
   rn = "rule_number = $(sn.rule_number)"
   co = "count = $(sn.count)"
   str = "\n$g\nkb\nparent_solution\n$pn\n$no\n$rn\n$co\n"
   return str
end

# For printing complex solution nodes.
function Base.show(io::IO, csn::AndSolutionNode)
    print(io, to_string(csn))
end
