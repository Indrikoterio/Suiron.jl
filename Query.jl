# Query.jl - allows a user to query a Suiron knowledge base.
#
# Usage:
#
# > julia Query.jl test/kings.txt
#
# The command above will load facts and rules from kings.txt,
# and then prompt for a query with:
#
# Successfully loaded facts and rules from test/kings.txt
# ?- 
#
# To find the grandchildren of Godwin, the user would type in
# the following query:
#
# ?- grandfather(Godwin, $X)
#
# ($X is a variable.)
#
# The Suiron inference engine will output one result after each
# press of 'enter'. When solutions are exhausted, the inference
# engine will print out 'No'.
#
# grandfather(Godwin, Harold)
# grandfather(Godwin, Skule)
# No
# ?-
#
# Type <enter> to end the program.
#
# Cleve Lendon

push!(LOAD_PATH, ".")

using Suiron
const sr = Suiron

function main(args)

    kb = sr.KnowledgeBase()

    # Is there a file name?
    if length(args) > 0

        file_name = args[1]

        if isfile(file_name)

            # Read in facts and rules.
            err = sr.load_kb_from_file(kb, file_name)
            if length(err) > 0
                println(err)
                return
            end
            print("Successfully loaded facts and rules from $file_name\n")
        else
            print("The file $file_name does not exist.\n")
            return
        end

    else
        println("This is Suiron, an inference engine written ",
                "in Julia by Cleve Lendon.")
        println("To load knowledge> julia Query.jl rules.txt")
    end

    previous = ""   # Previous query.

    while true
        print("?- ")  # Prompt for query.

        q = readline()
        query = string(strip(q))
        if length(query) == 0 break end

        if query == "."
            query = previous
        else
            previous = query
        end

        goal, err = sr.parse_goal(query)
        if length(err) > 0
            println(err)
            continue
        end

        # Get the root solution node.
        root = sr.get_solver(goal, kb, sr.SubstitutionSet(), nothing)

        while true
            solution, found = sr.next_solution(root)
            if !found
                println("No")
                break
            end
            result = sr.format_solution(goal, solution)
            print(result)
            readline()
        end

    end  # while

end  # main

main(ARGS)
