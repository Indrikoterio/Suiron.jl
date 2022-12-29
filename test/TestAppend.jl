# TestAppend.jl
#
# Test the 'append' predicate. The append predicate is used to join
# terms into a list. For example:
#
# $X = raspberry, append(cherry, [strawberry, blueberry], $X, $Out).
#
# The last term of append() is an output term. For the above, $Out
# should unify with: [cherry, strawberry, blueberry, raspberry]
#
# Cleve Lendon
# 2022

function test_append()

    println("Test Append")

    sr.set_max_time(1.0)

    X   = sr.LogicVar("X")
    Y   = sr.LogicVar("Y")
    Out = sr.LogicVar("Out")

    test_append = sr.Atom("test_append")
    orange      = sr.Atom("orange")
    red         = sr.Atom("red")
    green       = sr.Atom("green")
    blue        = sr.Atom("blue")
    purple      = sr.Atom("purple")
    colours     = sr.make_linked_list(false, green, blue, purple)

    # test_append($Out) :- $X = red, $Y = colours, append($X, orange, $Y, $Out).

    ss = sr.SubstitutionSet()

    head = sr.SComplex(test_append, Out)
    u1   = sr.Unification(X, red)
    u2   = sr.Unification(Y, colours)
    ap   = sr.Append(red, orange, colours, Out)
    body = sr.SOperator(:AND, u1, u2, ap)
    r1   = sr.Rule(head, body)

    kb = sr.KnowledgeBase()
    sr.add_facts_rules(kb, r1)
    query = sr.make_query(test_append, Out)

    results, failure = sr.solve_all(query, kb, ss)

    if failure != ""
        println("Test Append - $failure")
    end

    if length(results) < 1
        println("Test Append - no results.")
        return
    end

    result = sr.to_string(results[1])
    expected = "test_append([red, orange, green, blue, purple])"
    if result != expected
        println("Test Append - expected: $expected")
        println("                   was: $result")
    end

end # test_append
