public import std.variant;
public import std.conv;
import std.uni;

import std.traits:isSomeString;

dchar[] reservedSymbols =
[
	'.',
	',',
];

enum NodeType {
	list,
	endOfList, // used for context exploration, not in final tree
	ident, // must start with alpha or _, may then contain alpha, num
	symbol, // preliminary, expanded to ident
	
	call, // ident will be expanded to this, if followed by list
	
	number, // preliminary classification, should be expanded to Z or R
	numberZ,
	numberR,
	
	string,
	
	empty, // nothing (whitespace)
	comma, // ',' (forceful separator)
	endOfFile, 
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
		auto spaces = function(uint indent) { return ' '.repeat(indent*2).to!string; };
		
		string result=type.to!string.capitalizeFirst~"(";
		
		if (type == NodeType.call)
		{
			result~=value.to!string~"";
			if (children.length == 0)
				result~=")";
			else if (children.length == 1
			      && children[0].type != NodeType.list
				  && children[0].type != NodeType.call)
				result~=", "~children[0].to!string~")";
				
			else
			{
				result~="\n";
				
				foreach(c;children[0..$-1])
					result~=spaces(indent+1)~c.toString(indent+1)~",\n";
				result~=spaces(indent+1)~children[$-1].toString(indent+1);
				result~='\n'~spaces(indent)~")";
			}
		}
		
		else if (type == NodeType.list)
		{
			if (children.length == 0)
				result~=")";
			else if (children.length ==1)
				result~=children[0].to!string~")";
				
			else
			{
				result~="\n";
				
				foreach(c;children[0..$-1])
					result~=spaces(indent+1)~c.toString(indent+1)~",\n";
				result~=spaces(indent+1)~children[$-1].toString(indent+1);
				result~='\n'~spaces(indent)~")";
			}
		}
		else if (type == NodeType.empty || type == NodeType.endOfFile || type == NodeType.endOfList)
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