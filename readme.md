## The Risper language

Risper is a language in which I experiment with features that seem interesting
to me. Perhaps I wish they were more common in the languages I use.

It is a Lisp, influenced by languages sich as D, Groovy, Python, and Javascript.



Characteristics:
 - interpreted, with late binding of all things
 - uses its own lists to represent its own code, making it fully reflexive
 - supports either prefix notation, or infix notation:
    - `arg1.f(arg2)` is rewritten to `f(arg1 arg2)`
    - the `.` can be omitted if the function name is not alphabetic:
      `arg1 + arg2` is equivalent to `+ (arg1 arg2)`,
      `a=[5 6]` is equivalent to `=(a [5 6])`
 
 - identifiers are any set of Unicode alphanumeric characters starting with an
   alphabetic character
 - _symbols_ are identifiers made of non-alphanumeric identifiers
 - case-insensitive
 - automatic typing with optional type declaration


To risp: to rub together, to rasp or grate (Wiktionary)