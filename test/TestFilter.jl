# TestFilter.jl
#
# Test the built-in predicates include() and exclude(). Eg.:
#
# $People = [male(Sheldon), male(Leonard), male(Raj), male(Howard),
#            female(Penny), female(Bernadette), female(Amy)]
# list_wimmin($W) :- include(female($_), $People, $W).
# list_nerds($N)  :- exclude(female($_), $People, $N).
#
# Cleve Lendon 2022

function test_filter()

    println("Test Filter")

    W = sr.LogicVar("W")
    N = sr.LogicVar("N")

    c1, _ = sr.parse_complex("male(Sheldon)")
    c2, _ = sr.parse_complex("male(Leonard)")
    c3, _ = sr.parse_complex("male(Raj)")
    c4, _ = sr.parse_complex("male(Howard)")
    c5, _ = sr.parse_complex("female(Penny)")
    c6, _ = sr.parse_complex("female(Bernadette)")
    c7, _ = sr.parse_complex("female(Amy)")

    people = sr.make_linked_list(false, c1, c2, c3, c4, c5, c6, c7)

    list_wimmin, _ = sr.parse_complex("list_wimmin(\$W)")
    list_nerds, _  = sr.parse_complex("list_nerds(\$N)")
    filter, _      = sr.parse_complex("female(\$_)")

    include = sr.Include(filter, people, W)
    exclude = sr.Exclude(filter, people, N)

    kb = sr.KnowledgeBase()
    r1 = sr.Rule(list_wimmin, include)
    r2 = sr.Rule(list_nerds, exclude)
    sr.add_facts_rules(kb, r1, r2)

    query, _ = sr.parse_query("list_wimmin(\$W)")
    result, failure = sr.solve(query, kb, sr.SubstitutionSet())
    if failure != ""
        println("Test Filter - $failure")
    end

    actual = sr.to_string(sr.get_term(result, 2))
    expected = "[female(Penny), female(Bernadette), female(Amy)]"
    if actual != expected
        println("Test Filter - expected: $expected")
        println("                   was: $actual")
    end

    query, _ = sr.parse_query("list_nerds(\$W)")
    result, failure = sr.solve(query, kb, sr.SubstitutionSet())
    if failure != ""
        println("Test Filter - $failure")
    end

    actual = sr.to_string(sr.get_term(result, 2))
    expected = "[male(Sheldon), male(Leonard), male(Raj), male(Howard)]"
    if actual != expected
        println("Test Filter - expected: $expected")
        println("                   was: $actual")
    end

end  # test_filter
