# TestSolve.jl
#
# Tests functions which search for solutions.
# Specifically, solve() and solve_all().
#
# The predicate TooLong is used to test the "Time Out" feature.
#
# Cleve Lendon
# 2022

function test_solve()

    println("Test solve() and solve_all()")

    sr.set_max_time(0.3)

    # Set up the knowledge base.
    kb = sr.KnowledgeBase()
    ss = sr.SubstitutionSet()

    hobby     = sr.Atom("hobby")
    chess     = sr.Atom("chess")
    dance     = sr.Atom("dance")
    gardening = sr.Atom("gardening")

    tim    = sr.Atom("Tim")
    robert = sr.Atom("Robert")
    sarah  = sr.Atom("Sarah")

    c1 = sr.SComplex(hobby, tim, dance)
    c2 = sr.SComplex(hobby, robert, gardening)
    c3 = sr.SComplex(hobby, sarah, chess)

    f1 = sr.Fact(c1)
    f2 = sr.Fact(c2)
    f3 = sr.Fact(c3)

    # Add facts to the knowledge base.
    sr.add_facts_rules(kb, f1, f2, f3)

    X = sr.LogicVar("X")

    # Do not use make_complex() to create a query, because logic
    # variables must have unique IDs. make_query() ensures that
    # each variable is assigned a unique ID.

    query = sr.make_query(hobby, tim, X)  # Goal is: hobby(Tim, $X)

    expected = "hobby(Tim, dance)"
    actual, failure = sr.solve(query, kb, ss)

    if length(failure) != 0
        println("Test solve() - $failure")
        return
    end

    s = sr.to_string(actual)
    if s != expected
        println("Test solve() - expected: $expected")
        println("                    was: $s")
    end

    Y = sr.LogicVar("Y")

    # make_query() ensures that each variable is assigned a unique ID.
    query = sr.make_query(hobby, X, Y)

    results, failure = sr.solve_all(query, kb, ss)
    if length(failure) != 0
        println("Test solve_all() - $failure")
        return
    end

    exp1 = "hobby(Tim, dance)"
    exp2 = "hobby(Robert, gardening)"
    exp3 = "hobby(Sarah, chess)"

    if length(results) != 3
        println("Test solve_all() - There should be 3 results.")
        return
    end

    s = sr.to_string(results[1])
    if exp1 != s
        println("Test solve_all() - expected: $exp1")
        println("                        was: $s")
    end

    s = sr.to_string(results[2])
    if exp2 != s
        println("Test solve_all() - expected: $exp2")
        println("                        was: $s")
    end

    s = sr.to_string(results[3])
    if exp3 != s
        println("Test solve_all() - expected: $exp3")
        println("                        was: $s")
    end

    println("Test Time Out 1")

    c4 = sr.SComplex(sr.Atom("Time out test"))

    # The predicate too_long has a sleep timer
    # which should cause a timeout error.
    r1 = sr.Rule(c4, TooLong())
    sr.add_facts_rules(kb, r1)

    # Even though c4 does not contain variables, it's better to
    # create a goal with make_query(), because make_query() sets
    # the next_var_id to 0.
    query = sr.make_query(sr.Atom("Time out test"))
    _, failure = sr.solve(query, kb, ss)
    if failure !== "Timed out."
        println("Test Time Out 1 - Should time out.\n", failure)
        return
    end

    println("Test Time Out 2")
    # Second timeout test. Escape from endless loop.
    # endless($X) :- endless($X)

    endless = sr.Atom("endless")

    cEndless = sr.SComplex(endless, X)  # Term is: endless($X)
    r2 = sr.Rule(cEndless, cEndless)   # Rule is: endless($X) :- endless($X).
    sr.add_facts_rules(kb, r2)

    query = sr.make_query(endless, sr.Atom("loop"))     # Goal is: endless(loop)
    _, failure = sr.solve(query, kb, sr.SubstitutionSet())

    if failure != "Timed out."
        println("Test Time Out 2 - Should time out.\n", failure)
    end

end # test_solve
