# TestFunctor.jl
#
# Test the functor() predicate.
#
# mouse(mammal, rodent)
# get($Y) :- functor(mouse(mammal, rodent), $X), $X = $Y.
# get($Y) :- $X = cat(mammal, carnivore), functor($X, $Y).
# Cleve Lendon
# 2022

function test_functor()

    println("Test Functor")

    sr.set_max_time(0.5)

    kb = sr.KnowledgeBase()

    # Create logic variables.
    X = sr.LogicVar("X")
    Y = sr.LogicVar("Y")

    get       = sr.Atom("get")
    animal, _ = sr.parse_complex("mouse(mammal, rodent)")

    # Make 'get' rule.
    # get($Y) :- functor(mouse(mammal, rodent), $X), $X = $Y.
    head = sr.SComplex(get, Y)
    body = sr.SOperator(:AND, sr.Functor(animal, X), sr.Unification(X, Y))
    r1 = sr.Rule(head, body)
    sr.add_facts_rules(kb, r1)

    # Does parse_rule() correctly part the functor predicate?
    r2, _ = sr.parse_rule("get($Y) :- $X = cat(mammal, carnivore), functor($X, $Y).")
    sr.add_facts_rules(kb, r2)

    goal = sr.make_goal(get, X)  # get($X)

    # Check the solutions for get($X).
    expected::Vector{String} = ["mouse", "cat"]

    # Get the root solution node.
    root = sr.get_solver(goal, kb, sr.SubstitutionSet(), nothing)

    for i in (1, 2)
        solution, found = sr.next_solution(root)
        if !found
            println("Test Functor - expected two solutions")
            return
        end
        result = sr.replace_variables(goal, solution)
        str = sr.to_string(sr.get_term(result, 2))
        if str != expected[i]
            println("Test Functor - expected: ", expected[i])
            println("                    was: ", str)
            return
        end
    end # for

    # Check to make sure we can get the arity also.
    # check_arity($X, $Y) := functor(diamonds(forever, a girl's...), $X, $Y).

    mineral, _ = sr.parse_complex("diamonds(forever, a girl's best friend)")
    check_arity = sr.Atom("check_arity")
    head  = sr.SComplex(check_arity, X, Y)
    body2 = sr.Functor(mineral, X, Y)
    r3    = sr.Rule(head, body2)
    sr.add_facts_rules(kb, r3)

    goal = sr.make_goal(check_arity, X, Y)

    # Get the root solution node.
    root = sr.get_solver(goal, kb, sr.SubstitutionSet(), nothing)

    solution, found = sr.next_solution(root)
    if !found
        println("Test Functor - no solution.")
        return
    end

    result  = sr.replace_variables(goal, solution)
    functor = sr.get_term(result, 2)
    arity   = sr.get_term(result, 3)

    if functor.str != "diamonds"
        println("Test Functor - expected: diamonds")
        println("                    was: ", functor.str)
        return
    end

    if arity.n != 2
        println("Test Functor - expected: 2")
        println("                   was: ", arity.n)
    end

end # test_functor
