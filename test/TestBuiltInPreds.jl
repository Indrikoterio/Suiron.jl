# TestBuiltInPreds.jl - Test the 'built-in predicate' functionality.
#
# Suiron has built-in predicates, such as 'append', 'nl' and 'print'.
# It also provides a mechanism to allow programmers to write their own
# built-in predicates. (That is, predicates written in Julia, which can
# be called as part of Suiron's rule declaration language. The file
# bip_template.jl can be used as a template for this purpose.)
#
# The predicate to be tested here is hyphenate(...). Please refer to
# comments in hyphenate.jl for a description of how this predicate works. 
#
# In order to test this functionality, the following rules will be written
# to the knowledge base:
#
#   join_all($In, $Out, $InErr, $OutErr) :- hyphenate($In, $H, $T, $InErr, $Err2),
#                                           join_all([$H | $T], $Out, $Err2, $OutErr).
#   join_all([$H], $H, $X, $X).
#
#   bip_test($Out, $OutErr) :- join_all([sister, in, law], $Out, [first error], $OutErr).
#
# Suiron will solve for $Out and $OutErr.
#
# Cleve Lendon 2022

include("./Hyphenate.jl")

function test_built_in_predicates()

    println("Test Built-in Predicates")

    sr.set_max_time(0.3)

    kb = sr.KnowledgeBase()

    # Create logic variables.
    X = sr.LogicVar("X")
    Y = sr.LogicVar("Y")
    H = sr.LogicVar("H")
    T = sr.LogicVar("T")

    in      = sr.LogicVar("in")
    in_err  = sr.LogicVar("in_err")
    out     = sr.LogicVar("out")
    out_err = sr.LogicVar("out_err")
    err2    = sr.LogicVar("err2")

    bip_test  = sr.Atom("bip_test")
    join_all  = sr.Atom("join_all")

    c1 = sr.SComplex(join_all, in, out, in_err, out_err)
    c2 = make_hyphenate(in, H, T, in_err, err2)
    ll = sr.make_linked_list(true, H, T)
    c3 = sr.SComplex(join_all, ll, out, err2, out_err)
    body = sr.SOperator(:AND, c2, c3)
    r1 = sr.Rule(c1, body)

    l2 = sr.make_linked_list(false, H)
    c4 = sr.SComplex(join_all, l2, H, X, X)
    r2 = sr.Fact(c4)

    # bip_test($out, $out_err) :- join_all([sister, in, law], $Out, [first error], $out_err).
    c7 = sr.SComplex(bip_test, out, out_err)
    l3 = sr.make_linked_list(false, sr.Atom("sister"), sr.Atom("in"), sr.Atom("law"))
    l4 = sr.make_linked_list(false, sr.Atom("first error"))
    c8 = sr.SComplex(join_all, l3, out, l4, out_err)
    r3 = sr.Rule(c7, c8)

    sr.add_facts_rules(kb, r1, r2, r3)  # Add rules to knowledgebase.

    goal = sr.make_goal(bip_test, X, Y)
    solution, failure = sr.solve(goal, kb, sr.SubstitutionSet())

    if length(failure) != 0
        println("Test Built-in Predicates - $failure")
        return
    end

    # Check the solutions of bip_test($out, $out_error).
    expected = "sister-in-law [another error, another error, first error]"

    out     = sr.get_term(solution, 2)
    out_err = sr.get_term(solution, 3)
    actual  = "$out $out_err"

    if actual != expected
        println("Test Built-in Predicates - expected: $expected")
        println("                                was: $actual")
    end

end  # test_built_in_predicates
