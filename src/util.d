module util;

import std.traits;
import std.uni:isWhite;
import std.array;
import std.conv;
import std.algorithm.iteration;


/++
 + A copy of Kotlin's trimIndent
 + Checks indent on the first line and eliminates that off each line
 + (empty leading and trailing lines are ignored)
 +/
T trimIndent(T)(T s)
{
	assert(isSomeString!T);
		
	auto source = s.to!dstring.split("\n");
	
	while(source.front == "") source.popFront();
	while(source.back == "") source.popBack();
	
	dstring leading="";
	for (auto i=0;i<source[0].length;i++)
	{
		if (source[0][i].isWhite)
			leading~=source[0][i];
		else
			break;
	}
	auto trimmedSource = source.map!(it=>it[leading.length..$]);
	
	while(trimmedSource.front == "") trimmedSource.popFront();
	while(trimmedSource.back == "") trimmedSource.popBack();
	
	return trimmedSource.join("\n").to!T;
}




/++
 + line wrapper that:
 +  - does not put line feeds inside [], <>, or ()
 +  - preserves existing line feeds
 +/
string wrapWithRespect (
  string s,
  in size_t columns = 80,
  string firstindent = null,
  string indent = null,
)
{
	// build an array of string in sentences before wrapping it.
	string[] sentences;
	string buf; ulong i=0;
	
	string[] readInbetween(char start, char end)
	{
		string[] result; uint depth = 0;
		while (i < s.length)
		{
			if (s[i] == '\n')
			{
				if (buf != "")
				{
					result~=buf;
					buf = "";
				}
				result~="\n";
			}
			else
			{
				
				buf ~= s[i];
				if (s[i] == start)
				{
					depth++;
				}
				if (s[i] == end)
				{
					if (depth == 1)
						break;
					else
						depth--;
				}
			}
			i++;
		}
		result~=buf; buf = "";
		return result;
	}
	
	for (i=0; i<s.length; i++)
	{
		if (s[i] == ' ')
		{
			if (buf != "")
			{
				sentences~=buf;
				buf = "";
			}
		}
		else if (s[i] == '\n')
		{
			if (buf != "")
			{
				sentences~=buf;
				buf = "";
			}
			sentences~="\n";
		}
		else
		{
			switch (s[i])
			{
				case '[':
					sentences ~= readInbetween('[', ']');
					break;
				case '<':
					sentences ~= readInbetween('<','>');
					break;
				case '(':
					sentences ~= readInbetween('(',')');
					break;
				default:
					buf ~= s[i];
			}
		}
	}
	if (buf != "")
		sentences ~= buf;
	
	
	if (firstindent == null)
		firstindent = "";
	if (indent == null)
		indent = "";
	string[] result = [firstindent]; ulong currentLength = firstindent.length;
	bool firstWordOfTheLine=true;
	
	void newLine()
	{
		result~=to!string(indent);
		currentLength = indent.length;
		firstWordOfTheLine=true;
	}
	foreach(w;sentences)
	{
		if (w == "\n")
		{
			newLine();
			continue;
		}
		
		if (w.length + currentLength > columns)
			newLine();
		
		if (firstWordOfTheLine)
			firstWordOfTheLine^=true;
		else
			result[$-1] ~= " ";
		result[$-1] ~= w;
		currentLength += w.length;
	}
	return result.join("\n");
}
