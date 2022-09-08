# TestPrintList.jl - Tests 'print_list' predicate.
#
# Cleve Lendon 2022

function test_print_list()

    #----------------------------------------------------
    println("Test Print List: - should print:\n1, 2, 3, a, b, c")

    kb = sr.KnowledgeBase()

    head, _  = sr.parse_complex("print_list_test")
    u1, _    = sr.parse_unification("\$X = [a, b, c]")
    u2, _    = sr.parse_unification("\$List = [1, 2, 3 | \$X]")
    p, _     = sr.parse_subgoal("print_list(\$List)")
    body     = sr.SOperator(:AND, u1, u2, p)

    r1 = sr.Rule(head, body)
    sr.add_facts_rules(kb, r1)

    goal, _ = sr.parse_goal("print_list_test")
    sr.solve(goal, kb, sr.SubstitutionSet())

end  # test_print_list
