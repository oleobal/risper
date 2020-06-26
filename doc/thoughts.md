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

