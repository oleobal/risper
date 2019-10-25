public import std.variant;
public import std.conv;
import std.uni;

import std.traits:isSomeString;

dchar[] reservedSymbols =
[
	'.',
	':',
	',',
];

enum NodeType {
	list,
	ident, // must start with alpha or _, may then contain alpha, num
	call, // either a single symbol, or an ident starting with :
	
	number, // preliminary classification, should be expanded to Z or R
	numberZ,
	numberR,
	
	string,
	empty
}


struct Node
{
	Node[] children;
	
	NodeType type;
	Variant value;
	
	this(NodeType type)
	{
		this.type=type;
	}
	
	string toString()
	{
		return this.toString(0);
	}
	
	string toString(uint indent)
	{
		import std.range:repeat;
		string result=type.to!string.capitalizeFirst~"(";
		
		if (type == NodeType.list)
		{
			if (children.length == 0)
				result~=")";
			else if (children.length ==1)
				result~=children[0].to!string~")";
				
			else
			{
				auto spaces = function(uint indent) { return ' '.repeat(indent*2).to!string; };
				result~="\n";
				
				
				foreach(c;children[0..$-1])
					result~=spaces(indent+1)~c.toString(indent+1)~",\n";
				result~=spaces(indent+1)~children[$-1].toString(indent+1);
				result~='\n'~spaces(indent)~")";
			}
		}
		else if (type == NodeType.empty)
			result~=")";
		else
			result~=value.to!string~")";
			
		return result;
	}
}


class ParsingException:Exception
{
	this(string msg, string file = __FILE__, size_t line = __LINE__)
	{
		super(msg, file, line);
	}
}

pure T capitalizeFirst(T)(T s) if (isSomeString!T)
{
	if (s.length == 0)
		return s;
	auto a = s.to!dstring;
	if (s.length == 1)
		return a[0].toUpper.to!T;
	return a[0].toUpper.to!T ~ a[1..$].to!T;
}