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
	
	writeln(tree);
	
	return 0;
}