# SOperator.jl - Base type for And, Or, 'Not' logic operators, etc.
#
# Cleve Lendon
# 2022

# SOperator - Base type for :AND, :OR, :NOT logic operators, etc.
# An operator consists of a list of operands (Goals).
struct SOperator <: Goal
    type::Symbol
    goals::Vector{Union{Goal, SComplex}}
    function SOperator(t::Symbol, goals::Union{Goal, SComplex}...)
        new(t, [goals...])
    end
end

# copy - makes a copy of this operator.
# Params: operator (array of goals)
# Return: new operator
function copy(operator::SOperator)::SOperator
    t::Symbol = operator.type
    new_operator = SOperator(t)
    for g in operator.goals
        push!(new_operator.goals, g)
    end
    return new_operator
end

# get_operand - gets operand by index.
# Params: operator (array of goals)
#         index
# Return: operand (goal)
function get_operand(op::SOperator, i::Integer)::Union{Goal, SComplex}
    return op.goals[i]
end

# get_head_operand - gets the first operand of the operand list.
# Params: operator (array of goals)
# Return: operand (goal)
function get_head_operand(op::SOperator)::Union{Goal, SComplex}
    return op.goals[1]
end

# get_tail_operands - gets the tail of the operand list.
# (All operands except head.)
# Params: operator (array of goals)
# Return: operator
function get_tail_operands(operator::SOperator)::SOperator
    new_operator = SOperator(operator.type)
    first = true
    for operand in operator.goals
        if first
            first = false
        else
            push!(new_operator.goals, operand)
        end
    end
    return new_operator
end

#===============================================================
  get_solver - Returns a solution node for an operator.
  Params:  operator
           knowledge base
           parent solution (substitution set)
           parent node
  Return:  solution node
===============================================================#
function get_solver(op::SOperator, kb::KnowledgeBase,
                    parent_solution::SubstitutionSet,
                    parent_node::Union{SolutionNode, Nothing})::SolutionNode
    if op.type == :AND
        return make_and_solution_node(op, kb, parent_solution, parent_node)
    elseif op.type == :OR
        return make_or_solution_node(op, kb, parent_solution, parent_node)
    elseif op.type == :CUT
        return CutSolutionNode(op, kb, parent_solution, parent_node, false)
    elseif op.type == :FAIL
        return FailSolutionNode(op, kb, parent_solution, parent_node, false)
    elseif op.type == :NOT
        return NotSolutionNode(op, kb, parent_solution, parent_node)
    end
#    return make_complex_solution_node(op, kb, parent_solution, parent_node)
end

#===============================================================
 recreate_variables - The scope of a logic variable is the rule
 in which it is defined. When the inference engine tries to solve
 a goal, it calls this function to ensure that the variables are
 unique.

 Please refer to LogicVar.jl for a detailed description of this
 function.

 Params:  logical operator
          previously recreated variables
 Return:  expression
===============================================================#
function recreate_variables(op::SOperator, vars::DictLogicVars)::Expression
    if op.type == :CUT || op.type == :FAIL
        return op
    end
    new_operator = SOperator(op.type)
    for i in 1:length(op.goals)
        goal = op.goals[i]
        push!(new_operator.goals, recreate_variables(goal, vars))
    end
    return new_operator
end

#===============================================================
  replace_variables - replaces variables with their bindings.
  This is required in order to display solutions.

  Params: logical operator
          substitution set (contains bindings)
  Return: expression
===============================================================#
function replace_variables(op::SOperator, ss::SubstitutionSet)::Expression
    if op.type == :CUT || op.type == :FAIL
        return op
    end
    new_operator = SOperator(op.type)
    for i in 1:length(op.goals)
        goal = op[i]
        push!(new_operator.goals, replace_variables(goal, ss))
    end
    return new_operator
end

# to_string - Formats an operator as a string for display.
# Params: operator (AND, OR)
# Return: string representation
function to_string(op::SOperator)::String

    if op.type == :CUT  return "!"    end
    if op.type == :FAIL return "fail" end

    str = lowercase("$(op.type)(")
    first = true
    for arg in op.goals
        s = to_string(arg)
        if first
            str *= s
            first = false
        else
            str *= ", $s"
        end
    end
    str *= ")"
    return str

end

# For printing operators
function Base.show(io::IO, op::SOperator)
    print(io, to_string(op))
end
