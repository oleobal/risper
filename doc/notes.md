
### Grammar

TODO: write out a full specification when I pin down a nice design.

Lists are delimited with `[]`. List elements are separated with whitespace, or
with `,` (forced separation).

Evaluating a list (ie, executing a block of code) evaluates all its elements and
returns what the last one evaluates to. Values can also be retrieved with the
`return` pseudo-function.

Parens `()`, unlike regular lists, are evaluated within the parent context.

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
with a `:` colon. Can be addressed with the `.` Dot syntax. Dicts can use
anything as key, but `dict.a` will query the dict with the string "a". Yet
another use for Parens here: `dict.(a)` will instead query the dict with
whatever `a` evaluates with. Alternatively, we could just do with a
`get(dict key)` function.

### Built-in functions

These aren't necessarily actual functions (they break function rules), but they
are called using the same syntax.

`store(identifier expression)` binds the result of the expression to the
identifier **in the current context**

`return(expression)` terminates the current block of code, and returns the
value of the passed expression.

`function([args] code)` returns a function, ie callable code

`if(expr(bool) expr [expr else])` returns the result of the expression evaluated
as a result of the evaluation

#### Might be, one day

`def(identifier expression)` either:
 - defines identifier to be the type of expression, and stores it
 - defines identifier to be the type returned by the expression, if it is a
   TypeInfo
   
`closure([args] code)` defines a closure, which is like a function, but that
has access to the context of where it was defined

Some way to call D functions -- that's the dream