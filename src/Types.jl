# Types.jl
#
# This file contains basic abstract types used by Suiron,
# and some default methods associated with these types.
#
# Cleve Lendon
# 2022

# Expression - is the base type of goals and unifiable terms.
# The functions recreate_variables() and replace_variables()
# (see below) can be called for any Expression typed item.
abstract type Expression end

# Atoms, SIntegers, SFloats, SComplex terms, and Linked Lists
# are Unifiable. The function unify() operates on these terms.
abstract type Unifiable <: Expression end

# Goal - is the base type of goal objects (operators such as
# And and Or, etc). The function get_solver() is called on
# goals (and complex terms) to acquire a solution node.
abstract type Goal <: Expression end

# SolutionNode - represents a node in a 'proof tree'.
abstract type SolutionNode end

# A BuiltInPredicate records the name of the predicate,
# and holds its arguments, an array of Unifiables.
abstract type BuiltInPredicate <: Goal end

# SFunction is the base type of built in functions.
# It records the name of the function, and holds its
# arguments, an array of Unifiables.
abstract type SFunction <: Unifiable end

# See comments in SubstitutionSet.jl.
const SubstitutionSet = Vector{Unifiable}

# See comments in KnowledgeBase.jl.
const KnowledgeBase = Dict{String, Vector{Expression}}

#----------------------- default methods

#===============================================================
  recreate_variables - creates unique variables whenever the
  inference engine fetches a rule from the knowledge base.

  Please refer to comments in LogicVar.jl for a detailed
  description of this function.

  The method defined here handles constant expressions, such as
  Atoms, SIntegers and SFloats. These are returned unchanged.

  Params:  expression
           previously recreated variables
  Return:  expression
===============================================================#
function recreate_variables(expr::Expression, previous_vars::Dict)::Expression
    return expr
end

#===============================================================
  replace_variables - replaces variables with their bindings.
  This is required in order to display solutions.

  The method defined here is the default method. Constant
  expressions such as Atoms, SIntegers and SFloats are returned
  unchanged. Methods which handle LogicVars, SComplex terms, etc.
  are defined in LogicVar.jl, SComplex.jl, etc.

  Params:  expression
           substitution set (contains bindings)
  Return:  expression
===============================================================#
function replace_variables(expr::Expression, ss::Vector{Unifiable})::Expression
    return expr
end

#===============================================================
  unify - is called to unify terms (Atoms, LogicVars, SComplex
  terms, etc.).

  If a logic variable, $X, is unbound, it is free to be unified
  with any term. For example:
     $X = 73
  The new binding ($X to 73) is recorded in the substitution set.
  Subsequently, an attempt to rebind $X will fail.
     $X = 38  <--- fails, $X is bound to 73
     $X = 73  <--- succeeds, because 73 unifies with 73

  The method 'unify' should be defined for every unifiable term.
  The default method given here should probably never be called.

  Params: unifiable term
          other unifiable term
          substitution set
  Return: substitution set
          error message
===============================================================#
function unify(u1::Unifiable, u2::Unifiable,
               ss::Vector{Unifiable})::Tuple{Vector{Unifiable}, Bool}
    if u1 === u2
        return ss, ""   # Success
    end
    return ss, "Cannot unify."
end
