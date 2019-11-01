import risper;

import std.stdio;
import std.file;


int main(string[] args)
{
	if (args.length < 2)
	{
		writeln("Please pass file name as argument");
		return 1;
	}
	
	string expr;
	if(args[1] == "-c")
	{
		if (args.length < 3)
		{
			writeln("Please pass expression as argument to -c");
			return 1;
		}
		expr = args[2];
	}
	else
		expr = args[1].read.to!string;
	
	auto tree = parse(expr);
	
	writeln("------ AST --------------------");
	writeln(tree);
	
	Context c = new Context;
	writeln("------ result -----------------");
	eval(tree, c).writeln;
	writeln("------ context ----------------");
	c.writeln;
	
	return 0;
}