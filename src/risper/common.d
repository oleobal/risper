public import std.variant;
public import std.conv;
import std.uni;

import std.traits:isSomeString;

bool isA(T)(const Object o)
{
	return (cast(T) o) ?true:false;
}


dchar[] reservedSymbols =
[
	'.',
	',',
];

mixin template CommonToNodes()
{
	this() {}
	this(Node n) { super(n); }
	
}



/// will be removed after initial rounds of parsing
interface Preliminary {}

class Primary: Node { mixin CommonToNodes; }

/// must start with alpha or _, may then contain alpha, num, '_'
class Ident: Primary { mixin CommonToNodes; }

class Symbol: Ident, Preliminary { mixin CommonToNodes; }

/// the . (membership) operator, has 2 children
class Dot: Ident, HasChildren { mixin CommonToNodes; }


interface HasChildren {}
class List: Primary, HasChildren { mixin CommonToNodes; }


/// ident will be expanded to this, if followed by list
class Call: Primary, HasChildren
{
	Ident func;
	
	this() {}
	
	/// assuming it is passed an ident..
	this(Ident func)
	{
		this.func = func;
	}
	
	/// args is assumed to be either a single node, or a List,
	/// which will be depacked
	this(Ident func, Node args)
	{
		if (args.isA!List)
			children = args.children;
		else
			children ~= args;
		this(func);
	}
	
	override string toString(uint indent) const
	{
		import std.range:repeat;
		
		string result=typeid(this).to!string["common.".length..$].capitalizeFirst~"(";
		
		if (this.isA!Call)
		{
			if (this.func.isA!Dot)
				result~="\n"~spaces(indent+1)~this.func.toString(indent+1)~",";
			else
				result~=(cast(Variant) this.func.value).to!string;
			
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
		return result;
	}
}


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
class Number  : Primary, Literal { mixin CommonToNodes; }
class NumberP : Number, Preliminary { mixin CommonToNodes; }
class NumberZ : Number { mixin CommonToNodes; }
class NumberR : Number { mixin CommonToNodes; }

class String  : Primary, Literal { mixin CommonToNodes; }

/// bind an expression to an identifier
class Store: Node { mixin CommonToNodes; }
/// declare an identifier to be a given type (takes either type or expr)
class Def: Node { mixin CommonToNodes; }

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
	
	
	string spaces(uint indent) const
	{
		import std.range:repeat;
		return ' '.repeat(indent*2).to!string;
	}
	
	override string toString() const
	{
		return this.toString(0);
	}
	
	
	string toString(uint indent) const
	{
		string result=typeid(this).to!string["common.".length..$].capitalizeFirst~"(";
		
		if (this.isA!HasChildren)
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
			result=result[0..$-1];
		else
			result~= (cast(Variant) value).coerce!string~")";
			
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

class EvalException:Exception
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