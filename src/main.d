import risper;

import std.stdio;
import std.file;
import std.algorithm;
import std.range.interfaces;
import core.stdc.stdlib;

import util;

void crash(string s, int returnValue=1)
{
	writeln(s);
	exit(returnValue);
}


int main(string[] args)
{
	auto usage="
	Risper interpreter.
	Usage: risper <filename>, or risper -c <program> 
	Options:
	  --debug            print debug info
	  --ast <filename>   print a DOT graph of the AST right after parsing
	                     ( - for stdout)
	".trimIndent;
	
	if (args.length < 2 || args.canFind("-h") || args.canFind("--help"))
		crash(usage);
	
	bool exprSet = false;
	string expr;
	auto debugMode=false;
	string astFilename="";
	
	args = args[1..$];
	auto index=0;
	for(auto i=0;i<args.length;i++)
	{
		auto a = args[i];
		if (a == "--command" || a == "-c")
		{
			if (i==args.length-1)
				crash("Pass expression as argument to -c");
				
			if (exprSet)
				crash("Pass either filename or -c, and only once");
			expr = args[++i];
			exprSet=true;
		}
		else if (a == "--debug")
			debugMode=true;
			
		else if (a == "--ast")
		{
			if (i==args.length-1)
				crash("Pass filename or '-' as argument to --ast");
			astFilename=args[++i];
		}
		
		else // positional
		{
			if (exprSet)
				crash("Pass either filename or -c, and only once");
				
			expr = a.read.to!string;
			exprSet=true;
		}
		
	}
	
	auto tokenList = tokenize(expr);
	writeln(tokenList);
	auto tree = treeze!Parens(inputRangeObject(tokenList));
	
	//auto tree = parse(expr);
	
	if (debugMode)
	{
		writeln("------ AST --------------------");
		writeln(tree);
	}
	
	if (astFilename != "")
	{
		if (astFilename == "-")
			write("digraph AST\n{\n"~tree.toDOTgraph~"\n}\n");
		else
			toFile("digraph "~astFilename~"\n{\n"~tree.toDOTgraph~"}\n", astFilename);
	}
	
	Context c = new Context;
	if (debugMode)
		writeln("------ result -----------------");
		
	try
	{
		eval(tree, c).writeln;
	}
	catch(Exception e)
	{
		if(debugMode)
			throw e;
		crash(e.msg);
	}
	if (debugMode)
	{
		writeln("------ context ----------------");
		c.writeln;
	}
	return 0;
}