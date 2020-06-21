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
	'#',
	'.',',',':',
	'(',')',
	'[',']',
	'{','}',
];

enum ListDelimiter
{
	Parentheses,
	SquareBrackets,
	Accolades, // ie curly brackets
}


mixin template CommonToNodes()
{
	this() {}
	this(Variant v) {this.value = v;}
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
interface IsDelimited {
	ListDelimiter delimiter();
	ListDelimiter setDelimiter(ListDelimiter d);
}
mixin template DelimiterUtil(alias d)
{
	ListDelimiter internalDelimiter = d; 
	
	ListDelimiter delimiter()
	{
		return internalDelimiter;
	}
	
	ListDelimiter setDelimiter(ListDelimiter d)
	{
		return internalDelimiter = d;
	}
}
/// stupid, yeah
mixin template DelimiterUtilOverride(alias d)
{
	ListDelimiter internalDelimiter = d; 
	
	override ListDelimiter delimiter()
	{
		return internalDelimiter;
	}
	
	override ListDelimiter setDelimiter(ListDelimiter d)
	{
		return internalDelimiter = d;
	}
}



class List: Primary, HasChildren, IsDelimited {
	mixin CommonToNodes;
	mixin DelimiterUtil!(ListDelimiter.SquareBrackets);
}
class Parens: List {
	mixin CommonToNodes;
	mixin DelimiterUtilOverride!(ListDelimiter.Parentheses);
}

/// used for passing around results 
class Return: Node, HasChildren { mixin CommonToNodes; }

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
	
	/// if args is a Parens, it will be unpacked
	this(Ident func, Node args)
	{
		if (args.isA!Parens)
			children = args.children;
		else
			children ~= args;
		this(func);
	}
	
	override string toString(uint indent) const
	{
		import std.range:repeat;
		
		string result=typeid(this).to!string["common.".length..$].capitalizeFirst~"(";
		
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
		return result;
	}
}

/// a block of code that declares arguments
/// children -> the code to execute
class Function: Primary, HasChildren {
	Ident[] args;
	
	this(Ident[] args, Node[] code)
	{
		this.args = args,
		children = code;
	}
}




interface Ignorable {}

/// whitespace 
class Empty : Node, Ignorable {}

/// ',' (forceful separator)
class Comma : Node, Ignorable {}

/// ':'
class Colon : Node {}

/// used for context exploration, not in final tree
class EndOfList : Node, Ignorable {}
class EndOfParens : EndOfList {}

class EndOfFile : Node, Ignorable {}

interface Comment {}

class HashComment : Node, Preliminary, Comment, Ignorable {}

interface Literal {}

/// expanded to Z (integer) or R (real)
class Number  : Primary, Literal { mixin CommonToNodes; }
class NumberP : Number, Preliminary { mixin CommonToNodes; }
class NumberZ : Number { mixin CommonToNodes; }
class NumberR : Number { mixin CommonToNodes; }

class String  : Primary, Literal { mixin CommonToNodes; }

class Bool : Primary, Literal { mixin CommonToNodes; }

class Dict : Primary, IsDelimited {
	mixin CommonToNodes;
	mixin DelimiterUtil!(ListDelimiter.Parentheses); // will be overridden
	
	Node[Node] members;
	
	
	auto hasMember(Node key)
	{
		return cast(bool) (key in members);
	}
	
	Node getMember(Node key)
	{
		return members[key];
	}
	
	Node setMember(Node key, Node value)
	{
		return members[key] = value;
	}
	
}


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
	
	override string toString() const
	{
		return this.toString(0);
	}
	
	
	string toString(uint indent) const
	{
		string result=typeid(this).to!string["common.".length..$].capitalizeFirst~"(";
		
		if (this.isA!Dict)
		{
			auto members = (cast(Dict) this).members;
			if (members.length == 0)
				result~=")";
			else if (members.length == 1 && !(this.isA!HasChildren))
				result~=members.byKey.front.toString(indent+1)~": "~members[members.byKey.front].to!string~")";
				
			else
			{
				result~="\n";
				typeof(members.length) index=0;
				foreach(k;members.byKey)
				{
					result~=spaces(indent+1)~k.toString(indent+1)~": "~members[k].toString;
					index++;
					if (index < members.length)
						result~=",\n";
					
				}
				result~='\n'~spaces(indent)~")";
			}
		}
		else if (this.isA!HasChildren)
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
	
	string toDOTgraph()
	{
		string thisNode=this.toHash.to!string~" [label=\""~typeid(this).to!string["common.".length..$].capitalizeFirst;
		string strChildren="";
		
		if (this.isA!Dict)
		{
			auto members = (cast(Dict) this).members;
			foreach (k;members.byKey)
			{
				strChildren~=this.toHash.to!string~" -> "~k.toHash.to!string~" [arrowhead=none]\n";
				strChildren~=k.toHash.to!string~" -> "~members[k].toHash.to!string~" [arrowhead=vee]\n";
				strChildren~=k.toDOTgraph;
				strChildren~=members[k].toDOTgraph;
			}
		}
		else if (this.isA!HasChildren)
		{
			if(this.isA!Call)
			{
				strChildren~=this.toHash.to!string~" -> "~(cast(Call) this).func.toHash.to!string~" [arrowhead=box]\n";
				strChildren~=(cast(Call) this).func.toDOTgraph;
			}
			
			foreach(c;children)
			{
				strChildren~=this.toHash.to!string~" -> "~c.toHash.to!string~" [arrowhead=none]\n";
				strChildren~=c.toDOTgraph;
			}
		}
		else if (this.isA!Ignorable)
			{}
		else
			thisNode~= "("~(cast(Variant) value).coerce!string~")";
		
		thisNode~="\"]";
		
		return thisNode~"\n"~strChildren;
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

string spaces(uint indent)
{
	import std.range:repeat;
	return ' '.repeat(indent*2).to!string;
}