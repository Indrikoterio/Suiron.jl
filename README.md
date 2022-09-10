# Suiron.jl - An Inference Engine written in Julia.

Suiron is an inference engine written in Julia. The rule declaration syntax is similar to Prolog, but there are differences.

This brief README does not present a detailed explanation of how inference engines work, so a basic understanding of Prolog is a prerequisite. Documentation will be expanded in time.

## Briefly

An inference engine responds to queries about facts recorded in a knowledgebase. By using logic
rules, it can infer information which is not explicitly recorded.

For example, if the knowledgebase records that Frank is the father of Marcus, and that George is the father of Frank, the inference engine can infer that George is the grandfather of Marcus, even though the knowledgebase has no grandfather-facts. (The knowledgebase does need a rule which defines grandfather as a father's father or a mother's father.)

## Interpreter

Suiron reads facts and rules from a text-format source file, parses them, and
writes them into the knowledgebase.

Below is an example of a fact, which means "June is the mother of Theodore":

```
mother(June, Theodore).
```

Here we see the main difference between Suiron and Prolog. In Prolog, lower case words are 'atoms' (that is, string constants) and upper case words are variables. In Suiron, atoms can be lower case or upper case. Thus 'mother', 'June' and 'Theodore' are all atoms. Suiron's atoms can even contain spaces.

```
mother(June, The Beaver).
```

Suiron's variables are defined by putting a dollar sign in front of the variable name, for example, $Child. A query to determine June's children would be written:

```
mother(June, $Child).
```

Please refer to [LogicVar.jl](src/LogicVar.jl).

In Prolog, the anonymous variable (which matches anything) is an underscore: \_ .
In Suiron, it must begin with a dollar sign: $\_ .

Below is an example of a rule which contains anonymous variables. If a knowledgebase
contains facts about employees, for example, employee(Julia, cashier, 2000),
then a rule to list high wage employees would be:

```
high_wage($Emp) :- $Emp = employee($_, $_, $Salary), $Salary >= 5000.
```

<hr>

Facts and rules can also be created immediately within a Julia program, without
loading them from a file. The fact mother(June, Theodore) could be created by calling
the function parse_complex().

```
fact = parse_complex("mother(June, Theodore).")
```

'Complex term' means the same as 'compound term'.

Please refer to comments in [SComplex.jl](src/SComplex.jl) for more information.

Note: Some of Suiron's types have an 'S' appended to the name, to distinguish
them from Julia types with the same name.

The query mother(June, $Child) could be created in Julia as follows:

```
mother = Atom("mother")
June   = Atom("June")
child  = LogicVar("Child")
query  = make_goal(mother, June, child)
```

Please refer to [LogicVar.jl](src/LogicVar.jl) and [Goal.jl](src/Goal.jl) for more details.

Note: In the example above, the logic variable is defined as "Child", not "$Child".
The reason for this is because Julia interprets $Child as a string interpolation, when it
is between quotation marks. Therefore, when defining a logic variable with LogicVar(),
it is necessary to leave the dollar sign out. When the variable is printed, the dollar
sign will be shown.

In parse-functions, such as parse\_rule(), parse\_unification(), etc., the dollar sign
cannot simply be left out. A variable name without a dollar sign would be interpreted
as an atom.

Dollar signs must be escaped with a backslash. The following is wrong.

```
rule, err = parse_rule("test3($X) :- $X = add(7.922, 3).")
```

This is correct:

```
rule, err = parse_rule("test3(\$X) :- \$X = add(7.922, 3).")
```

Alternatively, a percent sign can be used:

```
rule, err = parse_rule("test3(%X) :- %X = add(7.922, 3).")
```

Of course, double quotes within double quotes must also be escaped, with a backslash.

```
c, _ = parse_complex("quote_mark(\", \")")
```

## Numbers

Suiron supports integers and floating point numbers. A number such as '4' will
be parsed as an integer, and '4.0' will be parsed as a floating point number.

Internally, Suiron lets Julia handle number conversions. When floats and ints
are mixed in arithmetic functions or comparisons, Julia will make the necessary
conversions.

Please refer to [SNumber.jl](src/SNumber.jl).

## Lists

Of course, Suiron supports linked lists, which work the same way as Prolog lists.
A linked list can be defined in a text file:

```
..., [a, b, c, d] = [$Head | $Tail], ...
```

or created within Julia:

```
X = parse_linked_list("[a, b, c, d]")
Y = make_linked_list(true, $Head, $Tail)
```

Please refer to [SLinkedList.jl](src/SLinkedList.jl).

## Requirements

Suiron was developed and tested with Julia version 1.7.3.

[https://julialang.org/](https://julialang.org/)

## Cloning

To clone the repository, run the following command in a terminal window:

```
git clone git@github.com:Indrikoterio/Suiron.jl.git
```

The repository has three folders:

```
suiron/src
suiron/test
suiron/demo
```

The code for the inference engine itself is in the subfolder /src.

The subfolder /test contains Julia programs which test the basic functionality of Suiron.

The subfolder /demo contains a simple demo program which parses English sentences.

## Usage

In the top folder is a program called [Query.jl](Query.jl), which loads facts and rules from a file, and allows the user to query the knowledgebase. Query can be run in a terminal window as follows:

```
julia Query.jl test/kings.txt
```

The user will be prompted for a query with this prompt: ?-

The query below will print out all father/child relationships.

```
?- father($F, $C).
```

After typing enter, the program will print out solutions, one after each press of Enter, until there are no more solutions, as indicated by 'No'.

```
go run query.jl test/kings.txt
?- father($F, $C).
$F = Godwin, $C = Harold II
$F = Godwin, $C = Tostig
$F = Godwin, $C = Edith
$F = Tostig, $C = Skule
$F = Harold II, $C = Harold
No
?-
```

To use Suiron in your own project, add the following line:

```
using Suiron
```

... at the top of your file.

It is useful to define the module name 'Suiron' to something shorter, such as 'sr'.

```
const sr = Suiron

pron = sr.Atom("pronoun")
verb = sr.Atom("verb")
```

The program [ParseDemo.jl](demo/ParseDemo.jl) demonstrates how to set up a knowledgebase and make queries. If you intend to incorporate Suiron into your own project, this is a good reference. There are detailed comments in the header.

To run ParseDemo, move to the demo folder and execute the batch file 'run'.

```
cd demo
./run
```

Suiron doesn't have a lot of built-in predicates, but it does have: [Append.jl](src/Append.jl), [Functor.jl](src/Functor.jl), [Print.jl](src/Print.jl), [NewLine.jl](src/NewLine.jl), [Include.jl](src/Include.jl), [Exclude.jl](src/Exclude.jl), [GreaterThan.jl](src/GreaterThan.jl) (etc.)


...and some arithmetic functions: [Add.jl](src/Add.jl), [Subtract.jl](src/Subtract.jl), [Multiply.jl](src/Multiply.jl), [Divide.jl](src/Divide.jl)

Please refer to the test programs for examples of how to use these.

To run the tests, open a terminal window, go to the test folder, and execute 'run'.

```
cd test
./run
```

Suiron allows you to write your own built-in predicates and functions. The files [BIPTemplate](src/BIPTemplate) and [BIFTemplate](src/BIFTemplate) can be used as templates. Please read the comments in the headers of these files.

The files [Hyphenate.jl](test/Hyphenate.jl) and [Capitalize.jl](test/Capitalize.jl) in the test directory can also be used for reference.

## Developer

Suiron was developed by Cleve (Klivo) Lendon.

## Contact

To contact the developer, send email to indriko@yahoo.com . Comments, suggestions and criticism are welcomed.

## History

First release, September 2022.

## Reference

The code structure of this inference engine is inspired by the Predicate Calculus Problem Solver presented in chapters 23 and 24 of 'AI Algorithms...' by Luger and Stubblefield. I highly recommend this book.

```
AI Algorithms, Data Structures, and Idioms in Prolog, Lisp, and Java
George F. Luger, William A. Stubblefield, ©2009 | Pearson Education, Inc. 
ISBN-13: 978-0-13-607047-4
ISBN-10: 0-13-607047-7
```

## License

The source code for Suiron is licensed under the MIT license, which you can find in [LICENSE](LICENSE).
