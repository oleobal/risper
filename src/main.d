import risper;

import std.stdio;
import std.file;
import util;


int main(string[] args)
{
	auto usage="
	Risper interpreter. Usage:
	risper <filename> [--debug]
	risper -c <program> [--debug]
	".trimIndent;
	
	if (args.length < 2)
	{
		writeln(usage);
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
	
	auto debugMode=false;
	if (args[$-1] == "--debug")
		debugMode=true;
	
	auto tree = parse(expr);
	
	if (debugMode)
	{
		writeln("------ AST --------------------");
		writeln(tree);
	}
	
	Context c = new Context;
	if (debugMode)
		writeln("------ result -----------------");
	eval(tree, c).writeln;
	if (debugMode)
	{
		writeln("------ context ----------------");
		c.writeln;
	}
	return 0;
}