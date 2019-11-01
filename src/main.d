import risper;

import std.stdio;
import std.array:join;


int main(string[] args)
{
	if (args.length < 2)
	{
		writeln("Please pass expression as argument");
		return 1;
	}
	auto tree = parse(args[1]);
	
	writeln("------ AST --------------------");
	writeln(tree);
	
	Context c = new Context;
	writeln("------ result -----------------");
	eval(tree, c).writeln;
	writeln("------ context ----------------");
	c.writeln;
	
	return 0;
}