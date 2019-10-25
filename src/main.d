import pegged.grammar;

import std.stdio;

mixin(grammar(`
Risper:
	Parens	< "(" Primary* ")"
	Primary	< Ident / Number / Parens
	Number	< ~([0-9]+)
	Ident	<- identifier
`));

void main()
{
	auto parseTree = Risper("(f 51 (1 2))");
	writeln(parseTree);
	
}