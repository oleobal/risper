Right now I'm getting basic systems working, but here are some thoughts for
later.

Two kinds of lists, `()` and `[]`.

Two kinds of separators, `,` and `;`.

Right now `()` is a specialized case of `[]` but there's virtually no need for
`[]` because there's no drawback to `()`. I spend my time writing function calls
by accident because anything that follows an ident triggers a function call.
Why not redefine `[]` to be instead lists where function calls can only be
triggered with `()`, or not at all ? (first option preferred but might
complicate things)

I envisioned `,` as a separator for lists and `;` as a way to write instructions
without so many parentheses: instead of `(do thing) (do other thing)`,
you'd have b`do thing; do other thing` which I find more readable. But I don't
think there is an actual difference between `,` and `;`.
The obious conclusion is to remove one or the other, or to make them synonymous.


----

In D thanks to UFCS `a.d` can be a member or a method call.

However in Risper the semantics change between the two. This is because
functions require arguments. `a.d` on its own is a function pointer (an Ident
really) and will only become a Call if it is followed by an argument.

It means that the UFCS equivalent of `d(a)` is `a.d()`, which is.. meh. It also
means that function calls "grab" what follows them which is definitely annoying.
`,` can be used but that looks downright weird.

I therefore propose to introduce a "pointer" sigil, `&`, which prefixes a Call.
AST-wise it's very simple, just Pointer->Call. We also need suffix `*` for
dereferencing I suppose.

Although I'd prefer if both used function syntax. Easier to implement, really.

----

There needs to be some kind of separation between _methods_ and "functions that
just happen to be in a Dict", if I want to merge Dicts and Objects the way JS
does. In JS you have the `this` pointer which is overridden in member functions,
but the way the `this` pointer works in JS is _not_ something to be copied.

Maybe there could be two definitions, `function()` and `method()`, which would
change context ?

----

Fundamental problem in evaluating lists.

Evaluating a primary should give you that primary. Lists, as data, are
primaries.

But "executing code" gives you a result. In Parens that's the last statement. In
regular `[]` Lists that's Empty.

But there's no distinction between executing and evaluating, and there's no
distinction between lists and blocks of code. So... as of now, I can't
manipulate lists, because they get replaced with the result of their computation
as they are evaluated on assignment.

I don't have a specific "execute this" keyword or sigil, and in fact I wanted
not to have one. So how can I manipulate lists ?

Would that mean setting up a difference between "evaluating" and "executing" ?
(I should learn some better vocabulary..)