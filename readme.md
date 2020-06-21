## The Risper language

Risper is a language in which I experiment with features that seem interesting
to me. Perhaps I wish they were more common in the languages I use.

It is a Lisp, influenced by languages sich as D, Groovy, Python, and Javascript.



Characteristics:
 - interpreted
 - uses its own lists to represent its own code, making it fully reflexive
 
 - supports either prefix notation, or an infix notation rewritten to prefix:
    - arg1.f(arg2) is rewritten to f (arg1 arg2)
    - the . can be omitted if the function name is not alphabetic:
      arg1 + arg2 <=> + (arg1 arg2)
      a=[5 6] <=> =(a [5 6])
 
 - identifiers are any set of Unicode alphanumeric characters starting with an
   alphabetic character
 - symbols are single-character non-alphanumeric identifiers
 - case-insensitive
 - automatic typing with optional type declaration


To risp: to rub together, to rasp or grate (Wiktionary)


### Grammar

TODO: write out a full specification when I pin down a nice design.

Lists are delimited with `[]`. List elements are separated with whitespace, or
with `,` (forced separation).

Evaluating a list (ie, executing a block of code) evaluates all its elements but
returns nothing (`Empty`). There are two ways to retrieve values: the first is
to use the `return` function, and the other is to use the alternative type of
list `()`, used for priority.

Parens have two special rules: 
 - if a Parens contains a single element, then it is replaced at runtime with
   the evaluation of this element
 - Parens, unlike regular lists, are evaluated within the parent context.

For instance, `if(true (store(a, 5)) )` results in `a=5` in the outer context,
but `if( true [store(a, 5)] )` doesn't touch it.



Function calls are an identifier followed by a primary. To store function
pointers without calling them, one can use the `,` operator for forced
separation.

To accept multiple arguments, we overload Parens `()`: so the code `f(1 2)`
passes `1` and `2`, but `f[1 2]` passes `[1 2]`. Originally, Lists were always
expanded, but that results in confusing syntax when we want to pass a single
list as argument (eg `f[[1 2]]`, that's just ugly).

Dicts (AKA associative arrays, maps, objects) use the same syntax as lists but
with a `:` colon. Can be addressed with the `.` Dot syntax.

### built-in functions

These aren't necessarily actual functions (they break function rules), but they
are called using the same syntax.

`store(identifier expression)` binds the result of the expression to the
identifier **in the current context**

`return(expression)` terminates the current block of code, and returns the
value of the passed expression.

`function([args] code)` returns a function, ie callable code

`if(expr(bool) expr [expr else])` returns the result of the expression evaluated
as a result of the evaluation

#### might be, one day

`def(identifier expression)` either:
 - defines identifier to be the type of expression, and stores it
 - defines identifier to be the type returned by the expression, if it is a
   TypeInfo
   
`closure([args] code)` defines a closure, which is like a function, but that
has access to the context of where it was defined

Some way to call D functions -- that's the dream