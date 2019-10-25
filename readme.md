## The Risper language

Risper is a language intended for scripting and interacting with D environments.

Characteristics:
 - interpreted
 - uses its own lists to represent its own code, making it fully reflexive
 
 - supports either prefix notation, or an infix notation rewritten to prefix:
    - arg1.f(arg2) is rewritten to (f arg1 arg2)
    - the . can be omitted if the function name is not alphabetic:
      arg1 + arg2 <=> (+ arg1 arg2)
      a=(5 6) <=> (= a (5 6))
 
 - identifiers are any set of alphanumeric characters starting with an
   alphabetic character
 - numerics

(Alphabetic and Alphanumeric as defined by Phobos' std.uni, which obey the
Unicode standard)


To risp: to rub together, to rasp or grate (Wiktionary)