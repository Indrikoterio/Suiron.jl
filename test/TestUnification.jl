# TestUnification.jl
#
# Tests the unification predicate. Eg. $X = pronoun
#
# Note: It takes time to initialize Julia. Because of this,
# the first query takes a long time. (260 milliseconds.)
#
# Cleve Lendon
# 2022

function test_unification()

    println("Test unification() 1")

    sr.set_max_time(0.7)

    # First test is:
    # test($X) :- $X = pronoun.
    # Query is test($X)

    X       = sr.LogicVar("X")
    pronoun = sr.Atom("pronoun")
    test    = sr.Atom("test")
    head    = sr.SComplex(test, X)

    body = sr.Unification(X, pronoun)
    r1   = sr.Rule(head, body)

    # Set up the knowledge base.
    kb = sr.KnowledgeBase()

    sr.add_facts_rules(kb, r1)  # Add rule to knowledge base.

    query = sr.make_query(test, X)

    solution, failure = sr.solve(query, kb, sr.SubstitutionSet())

    if length(failure) > 0
        println("Test unification() - Failure: ", failure)
        return
    end

    expected = "test(pronoun)"
    actual = sr.to_string(solution)
    if expected != actual
        println("Test unification() - expected: $expected" *
                "                          was: $actual")
    end

    # Second test is:
    # test2($A, $B, $C) := [eagle, parrot, raven, sparrow] = [$A, $B | $C].
    # Query is test2($A, $B, $C)

    A = sr.LogicVar("A")
    B = sr.LogicVar("B")
    C = sr.LogicVar("C")

    eagle   = sr.Atom("eagle")
    parrot  = sr.Atom("parrot")
    raven   = sr.Atom("raven")
    sparrow = sr.Atom("sparrow")
    birds   = sr.make_linked_list(false, eagle, parrot, raven, sparrow)
    list    = sr.make_linked_list(true, A, B, C)

    test2  = sr.Atom("test2")
    head2  = sr.SComplex([test2, A, B, C])
    body2  = sr.Unification(birds, list)

    r2 = sr.Rule(head2, body2)
    sr.add_facts_rules(kb, r2)

    query = sr.make_query(test2, A, B, C)
    solution, failure = sr.solve(query, kb, sr.SubstitutionSet())

    if length(failure) > 0
        println("Test unification() - Failure: ", failure)
        return
    end

    expected = "test2(eagle, parrot, [raven, sparrow])"
    actual   = sr.to_string(solution)

    if expected != actual
        println("Test unification() - Expected: $expected" *
                "\n                        Was: $actual")
    end

    println("Test unification() 2")  #-------------

    #=
     Test the parsing functionality for 
        unification_test($X, $Y, $Z) :- lawyer = lawyer,
                                        job(programmer, $Z) = job($Y, janitor),
                                        $W = $X, job($W).
    =#

    lawyer = sr.Atom("lawyer")

    c1, _ = sr.parse_complex("job(lawyer)")
    c2, _ = sr.parse_complex("job(teacher)")
    c3, _ = sr.parse_complex("job(programmer)")
    c4, _ = sr.parse_complex("job(janitor)")

    f1 = sr.Fact(c1)
    f2 = sr.Fact(c2)
    f3 = sr.Fact(c3)
    f4 = sr.Fact(c4)
    sr.add_facts_rules(kb, f1, f2, f3, f4)

    #u1 = Unification(lawyer, lawyer)
    u1, _ = sr.parse_unification("lawyer = lawyer")
    u2, _ = sr.parse_unification("job(programmer, \$Z) = job(\$Y, janitor)")
    u3, _ = sr.parse_unification("\$W = \$X")

    head, _ = sr.parse_complex("unification_test(\$X, \$Y, \$Z)")
    c, _    = sr.parse_complex("job(\$W)")
    body3 = sr.SOperator(:AND, u1, u2, u3, c)
    r1 = sr.Rule(head, body3)
    sr.add_facts_rules(kb, r1)

    query, _ = sr.parse_query("unification_test(\$X, \$Y, \$Z)")
    solutions, failure = sr.solve_all(query, kb, sr.SubstitutionSet())

    # Expected solutions of unification_test($X, $Y, $Z).
    expected2::Vector{String} = ["unification_test(lawyer, programmer, janitor)",
                                 "unification_test(teacher, programmer, janitor)",
                                 "unification_test(programmer, programmer, janitor)",
                                 "unification_test(janitor, programmer, janitor)"]

    if length(solutions) != 4
        println("sr.parse_unification() - Expecting 4 solutions.")
        return
    end

    for i in 1:4
        solution = solutions[i]
        actual = sr.to_string(solution)
        exp = expected2[i]
        if actual != exp
            println("Test unification() - Expected: $exp")
            println("                          Was: $actual")
            return
        end
    end

    # Test the parsing functionality for 
    println("Test unification() 3")   #-------------

    #=
      second_test($Y) :- $X = up, $Y = down, $X = $Y.
      This query must fail.
    =#

    u1, _   = sr.parse_unification("\$X = up")
    u2, _   = sr.parse_unification("\$Y = down")
    u3, _   = sr.parse_unification("\$X = \$Y")
    head, _ = sr.parse_complex("second_test(\$Y)")
    body4 = sr.SOperator(:AND, u1, u2, u3)
    r2 = sr.Rule(head, body4)
    sr.add_facts_rules(kb, r2)

    query, _ = sr.parse_query("second_test(\$Y)")
    _, failure = sr.solve_all(query, kb, sr.SubstitutionSet())

    if failure != "No"
        println("Test unification() - Query must fail.")
    end

end # test_unification
