# TestSFunctions.jl - Tests the built-in function feature.
#
# Suiron allows programmers to write their own built-in functions.
# (That is, to write functions for Suiron's rule declaration language
# in Julia. bif_template.jl can be used as a template for this purpose.)
#
# The function to be tested here is capitalize(), which capitalizes
# the first letter in a word. This function is implemented in Capitalize.jl.
#
# The following rule will be written to the knowledge base:
#
#   test($In, $Out) :- capitalize($In) = $Out.
#
# The goal to be tested is:
#
#   test(london, $X).
#
# $X should bind to 'London'.
#
# Cleve Lendon  2022

include("./Capitalize.jl")

function test_sfunctions()

    println("Test SFunctions")

    sr.set_max_time(1.0)

    kb = sr.KnowledgeBase()

    # Create logic variables.
    X   = sr.LogicVar("X")
    In  = sr.LogicVar("In")
    Out = sr.LogicVar("Out")

    test  = sr.Atom("test")

    c1 = sr.SComplex(test, In, Out)
    fn = make_capitalize(In)
    c2 = sr.Unification(fn, Out)
    r1 = sr.Rule(c1, c2)

    sr.add_facts_rules(kb, r1)  # Add rule to knowledge base.

    query = sr.make_query(test, sr.Atom("london"), X)
    solution, failure = sr.solve(query, kb, sr.SubstitutionSet())

    if length(failure) != 0
        println("Test SFunctions - $failure")
        return
    end

    expected = "London"
    t = sr.get_term(solution, 3)
    actual = t.str

    if actual != expected
        println("Test SFunctions - expected: $expected")
        println("                       was: $actual")
    end

end  # test_sfunctions()
