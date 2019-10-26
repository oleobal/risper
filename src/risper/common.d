public import std.variant;
public import std.conv;
import std.uni;

import std.traits:isSomeString;

bool isA(T)(Object o)
{
	return (cast(T) o) ?true:false;
}


dchar[] reservedSymbols =
[
	'.',
	',',
];

enum NodeType {
	list,
	endOfList, 
	ident, 
	symbol, 
	
	call,
	
	number, // preliminary classification, should be expanded to Z or R
	numberZ,
	numberR,
	
	string,
	
	empty, // nothing (whitespace)
	comma, // ',' (forceful separator)
	endOfFile, 
}

mixin template CommonToNodes()
{
	this() {}
	this(Node n) { super(n); }
}

/// will be removed after initial rounds of parsing
interface Preliminary {}

/// must start with alpha or _, may then contain alpha, num, '_'
class Ident: Node { mixin CommonToNodes; }

class Symbol: Ident, Preliminary { mixin CommonToNodes; }



interface HasChildren {}
class List: Node, HasChildren { mixin CommonToNodes; }

/// ident will be expanded to this, if followed by list
class Call: Node, HasChildren { mixin CommonToNodes; }



interface Ignorable {}

/// whitespace 
class Empty : Node, Ignorable {}

/// ',' (forceful separator)
class Comma : Node, Ignorable {}

/// used for context exploration, not in final tree
class EndOfList : Node, Ignorable {}

class EndOfFile : Node, Ignorable {}


interface Literal {}

/// expanded to Z (integer) or R (real)
class Number : Node, Literal, Preliminary { mixin CommonToNodes; }
class NumberZ : Number, Literal { mixin CommonToNodes; }
class NumberR : Number, Literal { mixin CommonToNodes; }

class String : Node, Literal { mixin CommonToNodes; }



class Node
{
	Node[] children;
	
	Variant value;
	
	this() {}
	
	this(Node n)
	{
		this.value = n.value;
		this.children = n.children;
	}
	
	override string toString()
	{
		return this.toString(0);
	}
	
	
	string toString(uint indent)
	{
		import std.range:repeat;
		auto spaces = function(uint indent) { return ' '.repeat(indent*2).to!string; };
		
		string result=typeid(this).to!string.capitalizeFirst~"(";
		
		if (this.isA!Call)
		{
			result~=value.to!string~"";
			if (children.length == 0)
				result~=")";
			else if (children.length == 1 && !(this.isA!HasChildren))
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
		
		else if (this.isA!List)
		{
			if (children.length == 0)
				result~=")";
			else if (children.length == 1 && !(this.isA!HasChildren))
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
		else if (this.isA!Ignorable)
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