# TestFail.jl - Tests the Fail predicate.
#
# Fail causes the rule to fail. It is used to force backtracking.
#
# count(1).
# count(2).
# count(3).
# test :- count($X), print($X), fail.
# test :- nl, fail.
#
# This rule should print 1, 2 and 3 on separate lines.
#
# Cleve Lendon  2022

function test_fail()

    print("Test Fail - ")

    sr.set_max_time(1.0)

    count = sr.Atom("count")
    test  = sr.Atom("test")
    X     = sr.LogicVar("X")

    # Set up the knowledge base.
    kb = sr.KnowledgeBase()
    ss = sr.SubstitutionSet()

    c1 = sr.SComplex(count, sr.SNumber(1))
    c2 = sr.SComplex(count, sr.SNumber(2))
    c3 = sr.SComplex(count, sr.SNumber(3))

    f1 = sr.Fact(c1)
    f2 = sr.Fact(c2)
    f3 = sr.Fact(c3)

    sr.add_facts_rules(kb, f1, f2, f3)

    head = sr.SComplex(test)
    body = sr.SOperator(
                :AND,
                sr.SComplex(count, X),
                sr.Print(sr.Atom("%s "), X),
                sr.SOperator(:FAIL)
            )

    r1 = sr.Rule(head, body)
    sr.add_facts_rules(kb, r1)

    body2 = sr.SOperator(:AND, sr.NL(), sr.SOperator(:FAIL) )
    r2 = sr.Rule(head, body2)
    sr.add_facts_rules(kb, r2)

    query = sr.make_query(test)

    #sr.set_start_time()
    _, failure = sr.solve_all(query, kb, ss)
    #sr.elapsed_time()

    if failure == ""
        println("Test Fail - $failure")
    end

end  # TestFail
