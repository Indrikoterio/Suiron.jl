# TestLinkedLists.jl
#
# Cleve Lendon
# 2022

function test_linked_lists()

    println("Test Linked Lists - make_linked_list()")

    sr.set_max_time(0.3)

    doctor        = sr.Atom("doctor")
    carpenter     = sr.Atom("carpenter")
    sales_manager = sr.Atom("sales manager")
    scientist     = sr.Atom("scientist")

    vars = sr.DictLogicVars()

    jobs1 = sr.make_linked_list(false, doctor, carpenter, sales_manager)
    jobs2 = sr.make_linked_list(false, scientist, jobs1)

    the_count = sr.get_count(jobs2)
    if the_count != 4
        println("List should have count of 4. Was: $the_count")
        return
    end

    el = sr.to_string(sr.empty_list)
    if el != "[]"
        println("Empty list should display as []. Was: $el")
        return
    end

    expected = "[scientist, doctor, carpenter, sales manager]"
    actual   = sr.to_string(jobs2)
    if actual != expected
        println("List should display as: $expected")
        println("                   Was: $actual")
        return
    end

    v1 = sr.LogicVar("X")
    list1 = sr.make_linked_list(true, scientist, doctor, v1)

    # Note: The dollar sign must be escaped.
    expected = "[scientist, doctor | \$X]"
    actual   = sr.to_string(list1)
    if actual != expected
        println("List should display as: $expected")
        println("                   Was: $actual")
        return
    end

    v2 = sr.LogicVar("Y")
    list2 = sr.make_linked_list(true, v1, doctor, v2)

    expected = "[\$X, doctor | \$Y]"
    actual   = sr.to_string(list2)
    if actual != expected
        println("List should display as: $expected")
        println("                   Was: $actual")
        return
    end

    println("Test Linked Lists - parse_linked_list()")

    list3, _ = sr.parse_linked_list("[]")
    the_count = sr.get_count(list3)
    if the_count != 0
        println("\nEmpty list should have count of 0. Was: $the_count")
    end

    _, err2 = sr.parse_linked_list("[|]")
    if length(err2) == 0
        println("Should produce error: Missing argument")
        return
    end

    expected = "parse_linked_list() - Missing argument: [|]"
    check_error_message(expected, err2)

    _, err3 = sr.parse_linked_list("[,]")
    if length(err3) == 0
        println("Should produce error: Missing argument")
        return
    end

    expected = "parse_linked_list() - Missing argument: [,]"
    check_error_message(expected, err3)

    _, err4 = sr.parse_linked_list("[a,]")
    if length(err4) == 0
        println("Should produce error: Missing argument")
        return
    end

    expected = "parse_linked_list() - Missing argument: [a,]"
    check_error_message(expected, err4)

    _, err5 = sr.parse_linked_list("[a, b")
    if length(err5) == 0
        println("Should produce error: Missing closing bracket")
        return
    end

    expected = "parse_linked_list() - Missing closing bracket: [a, b"
    check_error_message(expected, err5)

    #-------------------------------------------------------
    # Check mismatched quotes.

    _, err6 = sr.parse_linked_list("[\"a, b, c, d, e]")
    if length(err6) == 0
        println("Should produce error: Unmatched quotes: \"a")
        return
    end

    expected = "Unmatched quotes: \"a"
    check_error_message(expected, err6)

    _, err7 = sr.parse_linked_list("[a, b\"\", c, d, e]")
    if length(err7) == 0
        println("Should produce error: Text before opening quote: b\"\"")
        return
    end

    expected = "Text before opening quote: b\"\""
    check_error_message(expected, err7)

    expected = "[lawyer, teacher, programmer, janitor]"
    jobs3, _ = sr.parse_linked_list(expected)
    actual = sr.to_string(jobs3)
    if actual != expected
        println("Test SLinkedList, expected: $expected")
        println("                       Was: $actual\n")
    end

    expected = "[lawyer, teacher, programmer | \$X]"
    jobs4, _ = sr.parse_linked_list(expected)
    actual = sr.to_string(jobs4)
    if actual != expected
        println("Test SLinkedList, expected: $expected")
        println("                       Was: $actual\n")
    end

    println("Test Linked Lists - flatten()")

    ss = sr.SubstitutionSet()

    # ----- Flatten test 1. -----
    flattened, ok = sr.flatten(jobs4, 1, ss)
    flatten_errors(ok, "1", flattened, "lawyer", "[teacher, programmer | \$X]")

    # ----- Flatten test 2. -----
    flattened, ok = sr.flatten(jobs4, 2, ss)
    flatten_errors(ok, "2", flattened, "lawyer", "[programmer | \$X]")

    # ----- Flatten test 3. -----
    flattened, ok = sr.flatten(jobs4, 3, ss)
    flatten_errors(ok, "3", flattened, "lawyer", "[\$X]")

    # ----- Flatten test 4. -----
    flattened, ok = sr.flatten(jobs4, 4, ss)
    flatten_errors(ok, "4", flattened, "lawyer", "[]")

    println("Test Linked Lists - unify()")

    # Empty lists should unify.
    empty1 = sr.SLinkedList(nothing, nothing, 0, false)
    empty2 = sr.SLinkedList(nothing, nothing, 0, false)
    _, ok = sr.unify(empty1, empty2, ss)
    if !ok
        println("Unify - empty lists should unify. [] = []")
    end

    jobs5 = sr.make_linked_list(false, doctor, carpenter, sales_manager)

    _, ok = sr.unify(jobs1, jobs5, ss)
    if !ok
        println("Unify 2 LinkedLists. jobs1 and jobs5 should unify.")
    end

    v1 = sr.recreate_variables(v1, vars)
    jobs6 = sr.make_linked_list(true, doctor, carpenter, v1)
    new_ss, _ = sr.unify(jobs5, jobs6, ss)
    binding = sr.to_string(new_ss[v1.id])
    expected = "[sales manager]"
    if binding != expected
        println("Unify - \$X should unify with \$expected")
    end

    new_ss, _ = sr.unify(jobs5, v1, ss)
    binding = sr.to_string(new_ss[v1.id])
    expected = "[doctor, carpenter, sales manager]"
    if binding != expected
        println("Unify - \$X should unify with \$expected")
    end

    #-----------------------------------------------------
    println("Test Linked Lists - count()")

    # test_count($Out) :- $R = [doctor, carpenter, sales manager],
    #                     $S = [driver | $R],
    #                     count($S, $Out). 

    driver = sr.Atom("driver")
    Out    = sr.LogicVar("\$Out")
    R      = sr.LogicVar("\$R")
    S      = sr.LogicVar("\$S")
    jobs7  = sr.make_linked_list(true, driver, R)

    test_count = sr.Atom("test_count")
    head = sr.SComplex([test_count, Out])

    u1 = sr.Unification(R, jobs5)
    u2 = sr.Unification(S, jobs7)
    c3 = sr.Count(S, Out)

    body = sr.SOperator(:AND, u1, u2, c3)

    # Make rule, add to knowledge base.
    r1 = sr.Rule(head, body)
    kb = sr.KnowledgeBase()
    sr.add_facts_rules(kb, r1)

    query = sr.make_query(test_count, Out)
    ss = sr.SubstitutionSet()

    solution, failure = sr.solve(query, kb, ss)

    if length(failure) > 0
        println("Test Linked Lists - Count - $failure")
        return
    end

    count = sr.get_term(solution, 2)  # Term 1 is the functor.

    if count.n != 4
        println("Test Linked Lists - expected: 4, was: $count")
    end

end

# flatten_errors - formats error messages for testing flatten().
# Params:  ok - true if flatten succeeded
#          test number
#          flattened linked list
#          expected first term
#          expected last term
function flatten_errors(ok::Bool, test_num::String,
                        flattened::Vector{sr.Unifiable},
                        expected_first::String, expected_last::String)
    if !ok
        println("Flatten test ", test_num, " fails. Cannot flatten linked list.")
        return
    end

    n = length(flattened)
    str1 = sr.to_string(flattened[1])
    if str1 != expected_first
        println("Flatten test ", test_num, " fails.")
        println("First term should be: ", expected_first)
        println("                 was: ", str1)
    end

    str2 = sr.to_string(flattened[n])
    if str2 != expected_last
        println("Flatten test ", test_num, " fails. ")
        println("Last term should be: ", expected_last)
        println("                was: ", str2)
    end

end # flatten_errors()


# check_error_message - If the error message is different from
# expected, report an error.
# Params: expected message
#         actual message
function check_error_message(expected::String, actual::String)
    if actual != expected
        println("Error message should be: $expected")
        println("                    was: $actual")
    end
end
