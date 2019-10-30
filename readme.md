## The Risper language

Risper is a language intended for scripting and interacting with D environments.

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
 - symbols are single-character identifiers
 - case-insensitive
 - automatic typing with optional type declaration


To risp: to rub together, to rasp or grate (Wiktionary)


### Grammar

TODO: write out a full specification when I pin down a nice design.

Lists are delimited with `[]`. List elements are separated with whitespace, or
with `,` (forced separation).

An alternative type of list is `()`, used for priority, which "disappears" at
runtime when the expression within results in a single element.

Function calls are an identifier followed by a primary. To store function
pointers without calling them, one can use the `,` operator for forced
separation.

To accept multiple arguments, we overload Parens `()`: so the code `f(1 2)`
passes `1` and `2`, but `f[1 2]` passes `[1 2]`. Originally, Lists were always
expanded, but that results in confusing syntax when we want to pass a single
list as argument (eg `f[[1 2]]`, that's just ugly).

### built-in functions

`store(identifier expression)` binds the result of the expression to the
identifier

`function([args] code)` returns a function, ie callable code

#### might be, one day

`def(identifier expression)` either:
 - defines identifier to be the type of expression, and stores it
 - defines identifier to be the type returned by the expression, if it is a
   TypeInfo
   
`closure([args] code)` defines a closure, which is like a function, but that
has access to the context of where it was defined

Some way to call D functions -- that's the dream