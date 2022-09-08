# Suiron.jl - An Inference Engine written in Julia.

Suiron is an inference engine written in Julia. The rule declaration syntax is very similar to Prolog, but there are some differences.

This brief README does not present a detailed explanation of how inference engines work, so a basic understanding of Prolog is required. Documentation will be expanded in time.

## Briefly

An inference engine analyzes facts and rules which are stored in a knowledge base. Suiron has a parser which loads these facts and rules from a text-format source file.

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

The [anonymous](src/Anonymous.jl) variable must also begin with a dollar sign: $\_ . A simple underscore '\_' is treated as an atom. Below is an example of a rule which contains an anonymous variable:

```
voter($P) :- $P = person($_, $Age), $Age >= 18.
```

<hr><br>

Facts and rules can also be created dynamically within a Julia program. The fact
mother(June, Theodore) could be created by calling the function parse_complex().

```
    fact = parse_complex("mother(June, Theodore).")
```

Please refer to [SComplex.jl](src/SComplex.jl).

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

Note: In the example above, the logic variable Child is defined without a dollar
sign. The reason for this is because, in a Julia source program, the compiler
interprets $Child within quotation marks as a string interpolation. Therefore,
when defining a logic variable with LogicVar(), it is necessary to leave the
dollar sign out.

In 'parse_' functions, however, the dollar sign cannot be left out. If the 
Suiron compiler sees 'X', without a dollar sign, it will treat this as an atom.
The following is wrong.

```
  rule, err = sr.parse_rule("test3($X) :- $X = add(7.922, 3).")
```

The dollar signs must be escaped with backslashes:

```
  rule, err = sr.parse_rule("test3(\$X) :- \$X = add(7.922, 3).")
```

Alternatively, a percent sign can be used:

```
  rule, err = sr.parse_rule("test3(%X) :- %X = add(7.922, 3).")
```

Of course, double quotes within double quotes must also be escaped, with a backslash.

```
  c, _ = sr.parse_complex("quote_mark(\", \")")
```

<hr><br>

Suiron supports integer and floating point numbers. A number such as '4' will
be parsed as an integer, and '4.0' will be parsed as a floating point number.

Internally, Suiron lets Julia handle number conversions. When floats and ints
are mixed in an arithmetic functions or comparisons, Julia will make the necessary
conversions.

Please refer to [SNumber.jl](src/SNumber.jl).

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

In the top folder is a program called [query.jl](query.jl), which loads facts and rules from a file, and allows the user to query the knowledge base. Query can be run in a terminal window as follows:

```
julia query.jl test/kings.txt
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

To use Suiron in your own project, copy the subfolder 'suiron' to your project folder. You will have to include:

```
using Suiron
```

... at the top of your file.

It's also helpful to define a prefix, such as 'sr'.

```
const sr = Suiron

a = sr.Atom("")
```

The program [ParseDemo.jl](demo/ParseDemo.jl) demonstrates how to set up a knowledge base and make queries. If you intend to incorporate Suiron into your own project, this is a good reference. There are detailed comments in the header.

To run ParseDemo, move to the demo folder and execute the batch file 'run'.

```
 cd demo
 ./run
```

Suiron doesn't have a lot of built-in predicates, but it does have: [Append.jl](src/Append.jl), [Functor.jl](src/Functor.jl), [Print.jl](src/Print.jl), [NewLine.jl](src/NewLine.jl), [Include.jl](src/Include.jl), [Exclude.jl](src/Exclude.jl), greater_than (etc.)


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
