# TestNot.jl - Lest ye be tested.
#
# Testing the Not operator.
#
# parent(Sarah, Daniel).
# parent(Richard, Daniel).
# female(Sarah).
# mother($X, $Y) :- female($X), parent($X, $Y).
# father($X, $Y) :- parent($X, $Y), not(female($X)).
#
# ?- father($X, Daniel)
#
# -----------------------------------
# A second and third test.
#
# friend(Sheldon).
# friend(Leonard).
# friend(Penny).
# invite($X) :- friend($X), not($X = Sheldon).
# invite2($X) :- friend($X), not($X = Leonard).
#
# ?- invite($X)
# ?- invite2($X)
#
# Cleve Lendon  2022

function test_not()

    println("Test Not")

    sr.set_max_time(1.0)

    # For first test.
    # ?- father($X, Daniel).

    f1, _ = sr.parse_rule("parent(Sarah, Daniel)")
    f2, _ = sr.parse_rule("parent(Richard, Daniel)")
    f3, _ = sr.parse_rule("female(Sarah)")

    r1, _ = sr.parse_rule("mother(\$X, \$Y) :- female(\$X), parent(\$X, \$Y).")
    r2, _ = sr.parse_rule("father(\$X, \$Y) :- parent(\$X, \$Y), not(female(\$X)).")

    # For second test.
    f4, _  = sr.parse_rule("friend(Sheldon)")
    f5, _  = sr.parse_rule("friend(Leonard)")
    f6, _  = sr.parse_rule("friend(Penny)")

    r3, _ = sr.parse_rule("invite(\$X)  :- friend(\$X), not(\$X = Sheldon).")
    r4, _ = sr.parse_rule("invite2(\$X) :- friend(\$X), not(\$X = Leonard).")

    kb = sr.KnowledgeBase()
    sr.add_facts_rules(kb, f1, f2, f3, f4, f5, f6, r1, r2, r3, r4)

    # ?- father($X, Daniel)
    query, _ = sr.parse_query("father(\$X, Daniel)")
    result, failure = sr.solve(query, kb, sr.SubstitutionSet())
    if failure != ""
        println("Test Not - $failure")
        return
    end

    expected = "Richard"
    actual = sr.to_string(sr.get_term(result, 2))

    if actual != expected
        println("TestNot - expected: $expected")
        println("               was: $actual")
    end

    # Second test.
    # ?- invite($X)

    query, _ = sr.parse_query("invite(\$X)")
    solutions, failure = sr.solve_all(query, kb, sr.SubstitutionSet())
    if length(failure) != 0
        println("Test Not - $failure")
        return
    end

    expected2::Vector{String} = ["Leonard", "Penny"]

    for (i, r) in enumerate(solutions)
        s = sr.to_string(sr.get_term(r, 2))
        if s != expected2[i]
            println("Test Not - expected: $(expected2[i])")
            println("                was: $s")
        end
    end

    # Third test.
    # ?- invite2($X)

    query, _ = sr.parse_query("invite2(\$X)")
    solutions, failure = sr.solve_all(query, kb, sr.SubstitutionSet())
    if length(failure) != 0
        println("Test Not - $failure")
        return
    end

    expected3::Vector{String} = ["Sheldon", "Penny"]

    for (i, r) in enumerate(solutions)
        s = sr.to_string(sr.get_term(r, 2))
        if s != expected3[i]
            println("Test Not - expected: $(expected2[i])")
            println("                was: $s")
        end
    end

end  # test_not()
