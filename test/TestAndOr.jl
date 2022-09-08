# TestAndOr.jl
#
# Tests the AND and OR operators of the inference engine.
#
# Cleve Lendon
# 2022

function test_and_or()

    println("Test And Or")

    sr.set_max_time(0.3)

    kb = sr.KnowledgeBase()

    c1, _ = sr.parse_complex("father(George, Frank)")
    c2, _ = sr.parse_complex("father(George, Sam)")
    c3, _ = sr.parse_complex("mother(Gina, Frank)")
    c4, _ = sr.parse_complex("mother(Gina, Sam)")
    c5, _ = sr.parse_complex("mother(Maria, Marcus)")
    c6, _ = sr.parse_complex("father(Frank, Marcus)")

    f1 = sr.Fact(c1)
    f2 = sr.Fact(c2)
    f3 = sr.Fact(c3)
    f4 = sr.Fact(c4)
    f5 = sr.Fact(c5)
    f6 = sr.Fact(c6)

    sr.add_facts_rules(kb, f1, f2, f3, f4, f5, f6)  # to the knowledge base

    parent, _ = sr.parse_complex("parent(\$X, \$Y)")
    father, _ = sr.parse_complex("father(\$X, \$Y)")
    mother, _ = sr.parse_complex("mother(\$X, \$Y)")
    or = sr.SOperator(:OR, father, mother)

    r1 = sr.Rule(parent, or)

    relative, _    = sr.parse_complex("relative(\$X, \$Y)")
    grandfather, _ = sr.parse_complex("grandfather(\$X, \$Y)")
    grandmother, _ = sr.parse_complex("grandmother(\$X, \$Y)")
    or2 = sr.SOperator(:OR, grandfather, father, grandmother, mother)

    r2 = sr.Rule(relative, or2)

    father2, _ = sr.parse_complex("father(\$X, \$Z)")
    parent2, _ = sr.parse_complex("parent(\$Z, \$Y)")
    and = sr.SOperator(:AND, father2, parent2)

    r3 = sr.Rule(grandfather, and)

    sr.add_facts_rules(kb, r1, r2, r3)

    goal, _ = sr.parse_goal("relative(\$X, Marcus)")

    results, failure = sr.solve_all(goal, kb, sr.SubstitutionSet())
    if length(failure) != 0
        println("Test And Or - ", failure)
    end

    n = length(results)
    if n != 3
        println("Test And Or - expected 3 results. Got $n.")
    end

    # Check the solutions of relative($X, Marcus).
    expected::Vector{String} = ["relative(George, Marcus)",
                                "relative(Frank, Marcus)",
                                "relative(Maria, Marcus)"]

    for (i, r) in enumerate(results)
        s = sr.to_string(r)
        if s != expected[i]
            println("Test And Or - expected: ", expected[i])
            println("                   was: ", s)
        end
    end

end # test_unification
