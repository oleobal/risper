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