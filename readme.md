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
 - symbols are single-character identifiers
 - case-insensitive
 - automatic typing with optional type declaration


To risp: to rub together, to rasp or grate (Wiktionary)

### AST Node types

**List** an ordered list, used to represent code as well as data

**Ident** an identifier (variable or function name). Must start with an
alphabetic character or `_`, and may only contain alphanumeric characters
or `_`. Case-insensitive (lowercased on parsing)

**Symbol** single-character identifier

**NumberZ** a positive integer

**NumberR** a positive real

**String** a string delimited with `"`

(Alphabetic and Alphanumeric as defined by Phobos' std.uni, which obey the
Unicode standard. Symbol is isSymbol + isPunctuation)