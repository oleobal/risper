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
	
	
	override string toString() const
	{
		dstring result = s~"\n";
		for (ulong z=0; z<i; z++)
			result~=" ";
		result~="^"~i.to!dstring;
		return result.to!string;
	}
}

/++
 + able to deal with implicit top-level list (serie of statements)
 + so 'f(5 2) g(3 4)' is parsed as (f(5 2) g(3 4))
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
		auto n = new Parens;
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
	
	// first character
	// -----------------------------
	
	if (s.length == 0 || i >= s.length)
		result = new EndOfFile;
	else if (s[i].isWhite)
	{
		result = new Empty;
		i++;
	}
	else if (s[i] == '#')
	{
		result = new HashComment;
		i++;
	}
	else if (s[i] == ',')
	{
		result = new Comma;
		i++;
	}
	else if (s[i] == '[')
	{
		result = new List;
		i++;
	}
	else if (s[i] == ']')
	{
		result = new EndOfList;
		i++;
	}
	else if (s[i] == '(')
	{
		result = new Parens;
		i++;
	}
	else if (s[i] == ')')
	{
		result = new EndOfParens;
		i++;
	}
	else if (s[i] == '"')
	{
		result = new String;
		i++;
	}
	else if (s[i].isNumber || s[i] == '.')
		result = new NumberP;
	else if (s[i].isAlpha || s[i] == '_' )
		result = new Ident;
	else if (s[i].isSymbol || s[i].isPunctuation)
		result = new Symbol;
	else
		throw new ParsingException("invalid character: "~s[i].to!string);
	
	// first pass
	// -----------------------------
	
	if (result.isA!HashComment)
	{
		for (;i<s.length;i++)
		{
			if (s[i] == '\n')
			{
				i++;
				break;
			}
		}
		result = new HashComment;
	}
	
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
	
	if (result.isA!NumberP)
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
			else if (s[i] == '_') {}
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
	
	if (result.isA!Symbol)
	{
		result.value = "";
		for (;i<s.length;i++)
		{
			if ((s[i].isSymbol || s[i].isPunctuation) && !reservedSymbols.canFind(s[i]))
				result.value~=s[i].to!string;
			else
				break;
		}
		
	}
	else if (result.isA!Ident)
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
		
		
		if (i<s.length && s[i] == '.')
		{
			immutable auto oldi = i;
			
			i++;
			auto newResult = new Dot();
			newResult.children~=result;
			
			//writeln(p.to!string);
			// looking ahead
			Node buf = new Empty();
			do {
				buf = parseExpr(p);
				if (buf.isA!Ident)
				{
					newResult.children~=buf;
					result = newResult;
				}
				else if (buf.isA!Call)
				{
					Call cbuf = cast(Call) buf;
					newResult.children~=cbuf.func;
					cbuf.func = newResult;
					result = cbuf;
				}
				else if (!buf.isA!Empty)
				{
					if (buf.isA!Number)
					{
						i = oldi;
						break;
					}
					else
						throw new ParsingException("dot operator followed by "~buf.to!string);
				}
			}
			while (buf.isA!Ignorable);
		}
		
	}
	
	
	
	if (result.isA!List)
	{
		while (i<s.length)
		{
			if ((result.isA!Parens && s[i] == ')')
			 || (result.isA!List   && s[i] == ']'))
			{
				i++;
				break;
			}
			else if (s[i].isWhite || s[i] == ',')
				i++;
			else
			{
				auto buf = parseExpr(p);
				if (!buf.isA!Comment)
					result.children~=buf;
			}
		}
	}
	
	
	// Second pass
	// -----------------------------
	
	// attempt to convert an ident to a reserved keyword
	if (result.isA!Ident)
	{
		if (result.value == "true")
			result = new Bool(Variant(true));
		else if (result.value == "false")
			result = new Bool(Variant(false));
	}
	
	// attempt to convert an ident to call
	if (result.isA!Ident)
	{
		immutable auto oldi = i;
		
		// looking ahead
		Node buf = new Empty();
		do {
			buf = parseExpr(p);
			if (buf.isA!Primary)
				result = new Call(cast(Ident) result, buf);
			else if (!buf.isA!Empty) // so end of file/list ..
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