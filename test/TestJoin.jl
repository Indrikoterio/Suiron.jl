# Tests the 'join' function.
#
# 'SJoin' is a built-in function which joins a list of words and
# and punctuation to form a single string (= Atom). In the following
# source example,
#
#   $D1 = coffee, $D2 = "," , $D3 = tea, $D4 = or, $D5 = juice, $D6 = "?",
#   $X = join($D1, $D2, $D3, $D4, $D5, $D6).
#
# $X is bound to the Atom "coffee, tea or juice?".
#
# A built-in function is different from a built-in predicate, in that
# a built-in function returns a value (Atom, Integer or Float), which
# must be unified with something in order to be useful. All the
# arguments of a function must be constants or grounded variables.
# If not, the function fails.
#
# Cleve Lendon  2022

function test_join()

    println("Test Join")

    D1  = sr.LogicVar("D1")
    D2  = sr.LogicVar("D2")
    D3  = sr.LogicVar("D3")
    D4  = sr.LogicVar("D4")
    D5  = sr.LogicVar("D5")
    D6  = sr.LogicVar("D6")
    Out = sr.LogicVar("Out")

    would_you_like = sr.Atom("Would you like...")

    coffee  = sr.Atom("coffee")
    comma   = sr.Atom(",")
    tea     = sr.Atom("tea")
    or      = sr.Atom("or")
    juice   = sr.Atom("juice")
    question_mark = sr.Atom("?")

    u1 = sr.Unification(D1, coffee)
    u2 = sr.Unification(D2, comma)
    u3 = sr.Unification(D3, tea)
    u4 = sr.Unification(D4, or)
    u5 = sr.Unification(D5, juice)
    u6 = sr.Unification(D6, question_mark)
    j  = sr.Join(D1, D2, D3, D4, D5, D6)
    u7 = sr.Unification(Out, j)

    # Make rule.
    head = sr.SComplex(would_you_like, Out)
    body = sr.SOperator(:AND, u1, u2, u3, u4, u5, u6, u7)
    r1 = sr.Rule(head, body)

    # Set up the knowledge base.
    kb = sr.KnowledgeBase()
    sr.add_facts_rules(kb, r1)

    ss = sr.SubstitutionSet()

    X = sr.LogicVar("X")
    query = sr.make_query(would_you_like, X)

    results, failure = sr.solve(query, kb, ss)
    if failure != ""
        println("Test Join - $failure")
        return
    end

    expected = "coffee, tea or juice?"
    actual = sr.to_string(sr.get_term(results, 2))

    if actual != expected
        println("Test Join - expected: $expected")
        println("                 was: $actual")
    end

end  # TestJoin
