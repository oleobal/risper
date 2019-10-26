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
			children~=parseExpr(p);
	
	Node[] filteredChildren;
	for(ulong i =0;i<children.length;i++)
		if (!(children[i].isA!Ignorable))
			filteredChildren~=children[i];
	
	if (filteredChildren.length == 0)
		return new Empty;
	else if (filteredChildren.length == 1)
		return filteredChildren[0];
	else 
	{
		auto n = new List;
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
	debug { import std.stdio:writeln; }
	
	Node result;
	
	if (s.length == 0 || i >= s.length)
		result = new EndOfFile;
	else if (s[i].isWhite)
	{
		result = new Empty;
		i++;
	}
	else if (s[i] == ',')
	{
		result = new Comma;
		i++;
	}
	else if (s[i] == '(')
	{
		result = new List;
		i++;
	}
	else if (s[i] == ')')
	{
		result = new EndOfList;
		i++;
	}
	else if (s[i] == '"')
	{
		result = new String;
		i++;
	}
	else if (s[i].isNumber || s[i] == '.')
		result = new Number;
	else if (s[i].isAlpha || s[i] == '_' )
		result = new Ident;
	else if (s[i].isSymbol || s[i].isPunctuation)
		result = new Symbol;
	else
		throw new ParsingException("invalid character: "~s[i].to!string);
	
	if (result.isA!String)
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
	
	if (result.isA!Number)
	{
		result.value = "";
		for (;i<s.length;i++)
		{
			if (s[i].isNumber)
				result.value~=s[i].to!string;
				
			else if (s[i] == '.')
			{
				if (result.isA!NumberR)
					throw new ParsingException("invalid number literal: "~result.value.get!string~s[i].to!string);
				result = new NumberR(result);
				
				result.value~=s[i].to!string;
			}
			else
				break;
		}
		if (result.isA!NumberR)
			result.value = result.value.get!string.to!double;
		else
		{
			result = new NumberZ(result);
			result.value = result.value.get!string.to!long;
		}
		
	}
	
	if (result.isA!Ident)
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
	if (result.isA!Symbol)
	{
		result.value=s[i].to!string;
		i++;
	}
	
	if (result.isA!List)
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
	if (result.isA!Ident)
	{
		immutable auto oldi = i;
		
		Node buf = new Empty();
		do {
			buf = parseExpr(p);
			if (!buf.isA!Ignorable)
			{
				result = new Call(result);
				
				if (buf.isA!List)
					result.children~= buf.children;
				else
					result.children~= buf;
			}
			else if (!buf.isA!Empty)
			{
				i = oldi;
				break;
			}
		}
		while (buf.isA!Ignorable);
	}
	
	
	
	
	return result;
}
}