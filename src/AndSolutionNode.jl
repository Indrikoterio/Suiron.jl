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
function next_solution(n::AndSolutionNode)::Tuple{SubstitutionSet, Bool}

    if n.no_back_tracking
        return n.parent_solution, false
    end

    if n.tail_solution_node != nothing
        solution, found = next_solution(n.tail_solution_node)
        if found
            return solution, true
        end
    end

    solution, found = next_solution(n.head_solution_node)
    while found
        if length(n.operator_tail.goals) == 0
            return solution, true
        else
            # tail_solution_node has to be a new AndSolutionNode.
            n.tail_solution_node = get_solver(n.operator_tail,
                                              n.kb, solution, n)
            tail_solution, found = next_solution(n.tail_solution_node)
            if found
                return tail_solution, true
            end
        end
        solution, found = next_solution(n.head_solution_node)
    end
    return n.parent_solution, false
end

# has_next_rule - returns true if the knowledge base contains untried
# rules for this node's goal. False otherwise.
function has_next_rule(n::AndSolutionNode)::Bool
    if n.no_back_tracking
        return false
    end
    return n.rule_number <= n.count
end

# next_rule - fetches the next rule from the database, according to
# rule_number. The method has_next_rule() must called to ensure that
# a rule can be fetched from the knowledge base. If get_rule is called
# with invalid parameters, the knowledge base will throw an error.
function next_rule(n::AndSolutionNode)::Rule
    rule = get_rule(n.kb, n.goal, n.rule_number)
    n.rule_number += 1
    return rule
end

# to_string - Formats an AND solution node for display.
# This method is useful for diagnostics.
# Params: AND node
# Return: string representation
function to_string(csn::AndSolutionNode)::String
   g = to_string(csn.goal)
   if isnothing(csn.parent_node)
       pn = "parent_node = nothing"
   else
       pn = "parent_node"
   end
   no = "no_back_tracking = $(csn.no_back_tracking)"
   rn = "rule_number = $(csn.rule_number)"
   co = "count = $(csn.count)"
   str = "\n$g\nkb\nparent_solution\n$pn\n$no\n$rn\n$co\n"
   return str
end

# For printing complex solution nodes.
function Base.show(io::IO, csn::AndSolutionNode)
    print(io, to_string(csn))
end
