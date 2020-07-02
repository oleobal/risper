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
alias parseWord = parseWordTo!(long,double,string);

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


/++
 + parse a string into an AST
 +/
Node parse(Range)(Range s)
{
	assert(isSomeString!Range);
	return treeze(inputRangeObject(tokenize(s)));
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
		Node[] before;
		Node current;
		Node[] after;
		
		
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
			if (s.empty)
				throw new ParseLexicException("Unterminated string");
			s.popFront;
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
					s.popFront;
					
					if (s.front.isNumber)
					{
					
						if (current.isA!NumberR)
							throw new ParseLexicException("invalid number literal: "~current.value.get!string~s.front.to!string);
						current = new NumberR(current);
						current.value~=".";
					}
					else
					{
						after ~= new FullStop;
						break;
					}
					
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
		
		
		result~= before.reverse ~ current ~ after;
	}
	
	return result;
}




/++
 + assumes it is getting a list of instructions
 +/
Node treeze(InputRange!Node n)
{
	return new Parens(parseList(n, null));
	
}

/++
 + assumes it is only reading one instruction.
 + stopAt is used for delimiting
 +/
Node parseInstruction(InputRange!Node n, Node stopAt=null)
{
	void lookAheadForDot(ref Node current, InputRange!Node n)
	{
		while (!n.empty && ( n.front.isA!Ignorable || n.front.isA!FullStop || n.front.isA!Symbol) )
		{
			if (n.front.isA!Ignorable)
			{
				n.popFront;
				continue;
			}
			
			auto newBuf = new Dot;
			newBuf.children~=current;
			if (n.front.isA!FullStop)
			{
				n.popFront;
				if (!n.front.isA!Ident)
					throw new ParseSyntaxException("Dot not followed by an Ident");
				
			}
			newBuf.children~=n.front;
			current = newBuf;
			n.popFront;
		}
		
		// look ahead for Call
		
		while (!n.empty && n.front.isA!Ignorable)
			n.popFront;
		
		if (!n.empty && (n.front.isA!Primary || n.front.isA!StartOfList))
		{
			if (n.front.isA!Primary)
			{
				current = new Call(cast(Ident) current, n.front);
				n.popFront;
			}
			else if (n.front.isA!StartOfList)
			{
				auto endMarker = (cast(StartOfList) n.front).correspondingEnd;
				n.popFront;
				auto newBuf = parseList(n, endMarker);
				
				current = new Call(cast(Ident) current, newBuf);
			}
		}
	}
	
	if (n.empty)
		return new Empty;
	
	if (n.front.isA!Ignorable)
	{
		n.popFront;
		return new Empty;
	}
	else if (n.front.isA!Comma) // almost but not quite ignorable
	{
		n.popFront;
		return new Empty;
	}
	else if (n.front.isA!Literal)
	{
		auto buf = n.front;
		n.popFront;
		lookAheadForDot(buf, n);
		return buf;
	}
	else if (n.front.isA!StartOfParens)
	{
		n.popFront;
		return parseList(n, new EndOfParens);
	}
	else if (n.front.isA!StartOfList)
	{
		n.popFront;
		return parseList(n, new EndOfList);
	}
	
	else if (n.front.isA!Ident)
	{
		Node buf = n.front;
		n.popFront;
		
		lookAheadForDot(buf, n);
		
		return buf;
	}
	
	
	throw new ParseSyntaxException("parseInstruction doesn't know what to do with "~n.front.to!string);
}

Node parseList(InputRange!Node n, Node stopAt)
{
	Node result = new List;
	if (stopAt.isA!Semicolon || stopAt.isA!EndOfParens)
		result = new Parens;
	
	while(!n.empty)
	{
		if (stopAt && typeid(n.front) == typeid(stopAt))
		{
			n.popFront;
			break;
		}
		
		
		
		if (n.front.isA!Colon)
		{
			n.popFront;
			if (!result.isA!List)
				throw new ParseSyntaxException("Colon outside of List");
			
			Node[Node] members;
			if (result.children.length==1)
			{
				if (result.children[0].isA!Ident)
					members[new String(result.children[0])] = new Empty();
				else
					members[result.children[0]] = new Empty();
			}
			else if (result.children.length>0)
				throw new ParseSyntaxException("mixing of List and Dict syntax");
			return parseDict(n, stopAt, members);
		}
		
		auto buf = parseInstruction(n);
		if (!buf.isA!Ignorable)
			result.children~=buf;
			
		
	}
	
	return result;
}

Node parseDict(InputRange!Node n, Node stopAt, Node[Node] startingPoint)
{
	Dict result = new Dict;
	result.members = startingPoint;
	
	bool beforeColon=true;
	Node lastKey;
	if(startingPoint.length==1)
	{
		beforeColon=false;
		lastKey=startingPoint.keys[0];
	}
	else if (startingPoint.length != 0)
		throw new ParseSyntaxException("parseDict called with more than one element in the starting point");
	
	
	
	while(!n.empty)
	{
		if (stopAt && typeid(n.front) == typeid(stopAt))
		{
			n.popFront;
			break;
		}
		
		if (n.front.isA!Colon)
		{
			n.popFront;
			if(beforeColon)
				beforeColon=false;
			else
				throw new ParseSyntaxException("two Colons in a row in dict");
			continue;
		}
		
		if (n.front.isA!Comma)
		{
			n.popFront;
			if(!beforeColon)
				beforeColon=true;
			// else whatever, who cares
			continue;
		}
		
		
		
		Node buf = parseInstruction(n);
		if (beforeColon)
		{
			if (buf.isA!Ident)
				buf = new String(buf);
			result.members[buf]=new Empty;
			lastKey=buf;
		}
		else
		{
			result.members[lastKey]=buf;
			lastKey = null;
		}
	}
	
	return result;
}