public import common;

import std.uni;
import std.range;
import std.algorithm;

Variant parseWordTo(T...)(string s)
{
	foreach(t; T)
	{
		try
			return Variant(to!t(s));
		catch (Exception e)
		{ }
	}
	assert(0);
}

alias parseWord = parseWordTo!(long,double,string);

class ParseInfo
{
	dstring s;
	ulong i;
	
	this(string s)
	{
		this(s.to!dstring);
	}
	this(dstring s)
	{
		this.s=s;
		i=0;
	}
}

/++
 + able to deal with implicit top-level list (serie of statements)
 + so '(f 5 2) (g 3 4)' is parsed as ((f 5 2) (g 3 4))
 +/
Node parse(string s)
{
	Node[] children;
	
	auto p = new ParseInfo(s);
	
	if (p.s.length > 0)
		while (p.i < p.s.length)
		{
			children~=parseExpr(p);
		}
	
	Node[] filteredChildren;
	for(ulong i =0;i<children.length;i++)
	{
		if (children[i].type != NodeType.empty
		 && children[i].type != NodeType.endOfFile)
			filteredChildren~=children[i];
	}
	if (filteredChildren.length == 0)
		return Node(NodeType.empty);
	else if (filteredChildren.length == 1)
		return filteredChildren[0];
	else 
	{
		auto n = Node(NodeType.list);
		n.children = filteredChildren;
		return n;
	}
}

Node parseExpr(string s)
{
	auto p = new ParseInfo(s);
	return parseExpr(p);
}


/++
 + the actual parser
 +/
Node parseExpr(ParseInfo p) { with (p)
{
	Node result;
	
	if (s.length == 0 || i >= s.length)
		result = Node(NodeType.endOfFile);
	else if (s[i].isWhite)
	{
		result = Node(NodeType.empty);
		i++;
	}
	else if (s[i] == ',')
	{
		result = Node(NodeType.comma);
		i++;
	}
	else if (s[i].isWhite)
	{
		result = Node(NodeType.comma);
		i++;
	}
	else if (s[i] == '(')
	{
		result = Node(NodeType.list);
		i++;
	}
	else if (s[i] == ')')
	{
		result = Node(NodeType.endOfList);
		i++;
	}
	else if (s[i] == '"')
	{
		result = Node(NodeType.string);
		i++;
	}
	else if (s[i].isNumber || s[i] == '.')
		result = Node(NodeType.number);
	else if (s[i].isAlpha || s[i] == '_' )
		result = Node(NodeType.ident);
	else if (s[i].isSymbol)
		result = Node(NodeType.symbol);
	
	
	if (result.type == NodeType.string)
	{
		result.value = "";
		for (;i<s.length;i++)
		{
			if (s[i] == '"')
			{
				i++;
				break;
			}
			result.value~=s[i].to!string; // remember it's a dchar
			// TODO handle escaping
		}
	}
	
	if (result.type == NodeType.number)
	{
		result.value = "";
		for (;i<s.length;i++)
		{
			if (s[i].isNumber)
			{
				if (result.type == NodeType.numberR &&
				result.value.get!string[$-1] == 'f')
					throw new ParsingException("Invalid number literal: "~result.value.get!string~s[i].to!string);
				result.value~=s[i].to!string;
			}
			else if (s[i] == '.' || s[i] == 'f')
			{
				if (result.type == NodeType.numberR)
					throw new ParsingException("Invalid number literal: "~result.value.get!string~s[i].to!string);
				result.type = NodeType.numberR;
				
				if (s[i] == '.')
					result.value~=s[i].to!string;
			}
			else
				break;
		}
		if (result.type == NodeType.numberR)
			result.value = result.value.get!string.to!double;
		else
		{
			result.type = NodeType.numberZ;
			result.value = result.value.get!string.to!long;
		}
		
	}
	
	if (result.type == NodeType.ident)
	{
		result.value = "";
		result.value~=s[i].to!string; i++;
		for (;i<s.length;i++)
		{
			if (s[i] == '_' || s[i].isAlphaNum)
				result.value~=s[i].to!string;
			else
				break;
		}
		result.value=result.value.get!string.toLower; //case insensitivity
	}
	if (result.type == NodeType.symbol)
	{
		if (s[i].isSymbol)
		{
			result.type = NodeType.ident;
			result.value=s[i].to!string;
			i++;
		}
	}
	
	if (result.type == NodeType.list)
	{
		while (i<s.length)
		{
			if (s[i] == ')')
			{
				i++;
				break;
			}
			else if (s[i].isWhite || s[i] == ',')
				i++;
			else
				result.children~=parseExpr(p);
		}
	}
	
	
	// Second pass
	// -----------------------------
	
	// attempt to convert an ident to call
	if (result.type == NodeType.ident)
	{
		auto oldi = i;
		
		auto buf = Node(NodeType.empty);
		do {
			buf = parseExpr(p);
			if (buf.type == NodeType.list)
			{
				result.type = NodeType.call;
				result.children = buf.children;
			}
			else if (buf.type != NodeType.empty)
			{
				i = oldi;
				break;
			}
		}
		while (buf.type == NodeType.empty);
	}
	
	
	
	
	
	return result;
}
}