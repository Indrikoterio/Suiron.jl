# TestTime.jl
#
# Tests the Time predicate, which measures execution time
# of a goal. The test loads a qsort algorithm from the file
# qsort.txt, and runs it.
#
# Cleve Lendon

function test_time()

    println("Test Time:")

    kb = sr.KnowledgeBase()
    err = sr.load_kb_from_file(kb, "qsort.txt")
    if length(err) > 0 
        println("  Test Time:\n $err")
        return
    end

    goal, _ = sr.parse_goal("measure")
    ss = sr.SubstitutionSet()

    for i in 1:2
        sr.reset_next_var_id()  # For speed
        _, failure = sr.solve(goal, kb, ss)
        if length(failure) > 0
            println("  Test Time: $failure")
        end
        #println("              LogicVar ID:", sr.next_var_id)
    end

end # test_time
