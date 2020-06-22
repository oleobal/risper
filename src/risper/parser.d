public import common;

import std.uni;
import std.range;
import std.algorithm;

import std.traits:isSomeString;

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

/++
 + checks whether input is part of the reserved symbols
 +/
bool isValidSymbol(dchar c)
{
	if (!c.isSymbol && !c.isPunctuation)
		return false;
	if (reservedSymbols.canFind(c))
		return false;
	return true;
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
 +
 + this should be split into lexical (outputs a token stream) and
 + syntactical (outputs an AST) parts
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
	else if (s[i] == ':')
	{
		result = new Colon;
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
	else if (s[i].isValidSymbol)
		result = new Symbol;
	else
		throw new ParseException("invalid character: "~s[i].to!string);
	
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
					throw new ParseException("invalid number literal: "~result.value.get!string~s[i].to!string);
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
		
		
		if (i<s.length && (s[i] == '.' || s[i].isValidSymbol))
		{
			immutable auto oldi = i;
			
			if (s[i] == '.')
				i++;
			
			auto newResult = new Dot();
			newResult.children~=result;
			
			// is right-associative, should be left-associative..
			
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
						throw new ParseException("dot operator followed by "~buf.to!string);
				}
			}
			while (buf.isA!Ignorable);
		}
		
	}
	
	
	
	if (result.isA!List)
	{
		auto rAsList = cast(List) result;
		while (i<s.length)
		{
			if ((rAsList.delimiter == ListDelimiter.Parentheses    && s[i] == ')')
			 || (rAsList.delimiter == ListDelimiter.SquareBrackets && s[i] == ']'))
			{
				i++;
				break;
			}
			else if (s[i].isWhite || s[i] == ',')
				i++;
			else if (s[i] == ':')
			{
				i++;
				
				result = new Dict(result);
				if (result.children.length > 1)
					throw new ParseException("Invalid mixing of List and Dict syntax");
				if (result.children.length>0)
					(cast(Dict) result).members[result.children[0]] = null;
				result.children=[];
				break;
			}
			else
			{
				auto buf = parseExpr(p);
				if (!buf.isA!Comment)
					result.children~=buf;
			}
		}
		
		// was found to be a dict, let's try this again
		if (result.isA!Dict)
		{
			auto d = cast(Dict) result;
			
			bool beforeColon = false;
			
			Node currentKey = null;
			if (d.members.length > 0)
				currentKey = d.members.byKey.front;
			
			while (i<s.length)
			{
				if ((rAsList.delimiter == ListDelimiter.Parentheses    && s[i] == ')')
				 || (rAsList.delimiter == ListDelimiter.SquareBrackets && s[i] == ']'))
				{
					i++;
					break;
				}
				else if (s[i].isWhite || s[i] == ',')
				{
					beforeColon=true;
					i++;
				}
				else if (s[i] == ':')
				{
					beforeColon=false;
					i++;
				}
				else
				{
					auto buf = parseExpr(p);
					if (!buf.isA!Comment)
					{
						if (beforeColon)
							currentKey = buf;
						else
							d.members[currentKey] = buf;
					}
				}
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










/++
 + returns a token stream
 +/
Node[] tokenize(Range)(Range s)
{
	assert(isSomeString!Range);
	
	debug { import std.stdio:writeln; }
	Node[] result;
	
	while(!s.empty)
	{
	
		Node current;
		
		// first character
		// -----------------------------
		
		if (s.front.isWhite)
		{
			s.popFront;
			continue;
		}
		else if (s.front == '#')
		{
			current = new HashComment;
			s.popFront;
		}
		else if (s.front == ',')
		{
			current = new Comma;
			s.popFront;
		}
		else if (s.front == '.')
		{
			current = new FullStop;
			s.popFront;
		}
		else if (s.front == ':')
		{
			current = new Colon;
			s.popFront;
		}
		else if (s.front == ';')
		{
			current = new Semicolon;
			s.popFront;
		}
		else if (s.front == '[')
		{
			current = new StartOfList;
			s.popFront;
		}
		else if (s.front == ']')
		{
			current = new EndOfList;
			s.popFront;
		}
		else if (s.front == '(')
		{
			current = new StartOfParens;
			s.popFront;
		}
		else if (s.front == ')')
		{
			current = new EndOfParens;
			s.popFront;
		}
		else if (s.front == '"')
		{
			current = new String;
			s.popFront;
		}
		else if (s.front.isNumber)
			current = new NumberP;
		else if (s.front.isAlpha || s.front == '_' )
			current = new Ident;
		else if (s.front.isValidSymbol)
			current = new Symbol;
		else
			throw new ParseLexicException("invalid character: "~s.front.to!string);
		
		
		
		// keep munching if necessary
		
		if (current.isA!HashComment)
		{
			while(!s.empty && s.front != '\n')
			{
				s.popFront;
			}
			current = new HashComment;
		}
		
		if (current.isA!String)
		{
			current.value = "";
			while (!s.empty && s.front != '"')
			{
				current.value~=s.front.to!string; // remember it's a dchar
				s.popFront;
				// TODO handle escaping
			}
		}
		
		
		// if a number follows the dot then it's a number
		// a.5 is Ident(a) NumberR(0.5)
		if (current.isA!FullStop && s.front.isNumber)
		{
			current = new NumberR;
			current.value = ".";
		}
		
		if (current.isA!Number)
		{
			if (!current.value.hasValue)
				current.value = "";
			while(!s.empty)
			{
				if (s.front.isNumber)
					current.value~=s.front.to!string;
					
				else if (s.front == '.')
				{
					if (current.isA!NumberR)
						throw new ParseLexicException("invalid number literal: "~current.value.get!string~s.front.to!string);
					current = new NumberR(current);
					
					current.value~=s.front.to!string;
				}
				else if (s.front == '_') {}
				else
					break;
				s.popFront;
			}
			
			
			if (current.isA!NumberR)
				current.value = current.value.get!string.to!double;
			else
			{
				current = new NumberZ(current);
				current.value = current.value.get!string.to!long;
			}
			
		}
		
		if (current.isA!Symbol)
		{
			current.value = "";
			while(!s.empty)
			{
				if ((s.front.isSymbol || s.front.isPunctuation) && !reservedSymbols.canFind(s.front))
					current.value~=s.front.to!string;
				else
					break;
				s.popFront;
			}
			
		}
		else if (current.isA!Ident)
		{
			current.value = "";
			current.value~=s.front.to!string; s.popFront;
			
			while(!s.empty)
			{
				if (s.front == '_' || s.front.isAlphaNum)
					current.value~=s.front.to!string;
				else
					break;
				s.popFront;
			}
			current.value=current.value.get!string.toLower; //case insensitivity
			
		}
		
		
		result~=current;
	}
	
	result~=(new EndOfFile);
	
	return result;
}




Node treeze(T:List)(InputRange!Node n, Node stopAt=null)
{
	T result= new T;
	
	while(!n.empty)
	{
		if (stopAt && typeid(n.front) == typeid(stopAt))
			break;
			
			
		if (n.front.isA!Ignorable)
			n.popFront;
		else if (n.front.isA!Comma) // almost but not quite ignorable
			n.popFront;
		else if (n.front.isA!Literal)
		{
			result.children~=n.front;
			n.popFront;
		}
		else if (n.front.isA!StartOfList)
		{
			n.popFront;
			result.children~=treeze!List(n, stopAt=new List);
		}
		else if (n.front.isA!StartOfParens)
		{
			n.popFront;
			result.children~=treeze!Parens(n, stopAt=new Parens);
		}
		
		
		else if (n.front.isA!Ident)
		{
			Node buf = n.front;
			n.popFront;
			
			// look ahead for Dot
			while (!n.empty && ( n.front.isA!Ignorable || n.front.isA!FullStop || n.front.isA!Symbol) )
			{
				if (n.front.isA!Ignorable)
				{
					n.popFront;
					continue;
				}
				
				auto newBuf = new Dot;
				newBuf.children~=buf;
				if (n.front.isA!FullStop)
				{
					n.popFront;
					if (!n.front.isA!Ident)
						throw new ParseSyntaxException("Dot not followed by an Ident");
					
				}
				newBuf.children~=n.front;
				buf = newBuf;
				n.popFront;
			}
			
			
			
			// look ahead for Call
			
			while (!n.empty && n.front.isA!Ignorable)
				n.popFront;
			
			if (!n.empty && (n.front.isA!Primary || n.front.isA!StartOfList))
			{
				if (n.front.isA!Primary)
				{
					buf = new Call(cast(Ident) buf, n.front);
					n.popFront;
				}
				else if (n.front.isA!StartOfList)
				{
					n.popFront;
					auto newBuf = treeze!(typeof(correspondingList(cast(StartOfList) n.front)))
					                     (n, (cast(StartOfList) n.front).correspondingEnd);
					buf = new Call(cast(Ident) buf, newBuf);
				}
			}
			
			result.children~=buf;
		}
		
		
		else if (n.front.isA!Colon)
		{
			if (!result.isA!List)
				throw new ParseSyntaxException("Colon outside of List");
			
			auto newResult = new Dict;
			if (result.children.length==0) {}
			if (result.children.length==1)
				newResult.members[result.children[0]] == new Empty();
			else
				throw new ParseSyntaxException("mixing of List and Dict syntax");
			
			
			
		}
		
	}
	return result;
}

