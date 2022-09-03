# NotSolutionNode.jl - Solution node for the :NOT operator.
#
# Eg.:  not($X = noun)
#
# Cleve Lendon  2022

mutable struct NotSolutionNode <: SolutionNode

    goal::Union{Goal, SComplex}
    kb::KnowledgeBase
    parent_solution::Union{SubstitutionSet, Nothing}
    parent_node::Union{SolutionNode, Nothing}
    no_back_tracking::Bool
    rule_number::Integer
    count::Integer
    operand_solution_node::Union{SolutionNode, Nothing}

    function NotSolutionNode(g, kb, parent_solution, parent_node)
        operand = g.goals[1]  # There must be 1 operand.
        osn = get_solver(operand, kb, parent_solution, parent_node)
        new(g, kb, parent_solution, parent_node, false, 0, 0, osn)
    end
end


# next_solution - calls next_solution() on the operand (which is a Goal).
# If there is a solution, the function will set the success flag to false.
# If there is no solution, the function will set the success flag to true.
# ('Not' means 'not unifiable'.)
# Params: solution node
# Return: substitution set
#         success/failure flag
function next_solution(sn::NotSolutionNode)::Tuple{SubstitutionSet, Bool}

    if sn.no_back_tracking || sn.parent_solution == nothing
        return SubstitutionSet(), false
    end

    _, found = next_solution(sn.operand_solution_node)
    if found
        return sn.parent_solution, false
    else
        solution = sn.parent_solution
        sn.parent_solution = nothing
        return solution, true
    end
end

# has_next_rule - Returns true if the knowledge base contains
# untried rules for this node's goal. False otherwise.
# Params: 'not' solution node
# Return: true/false
function has_next_rule(sn::NotSolutionNode)::Bool
    if sn.no_back_tracking
        return false
    end
    return sn.rule_number < sn.count
end

# next_rule - Fetches the next rule from the database, according to
# rule_number. The method has_next_rule() must be called to ensure that
# a rule can be fetched from the knowledge base. If get_rule() is called
# with invalid parameters, the knowledge base will throw an error.
# Params: 'not' solution node
# Return: rule
function next_rule(sn::NotSolutionNode)::Rule
    rule = get_rule(sn.kb, sn.goal, sn.rule_number)
    sn.rule_number += 1
    return rule
end
