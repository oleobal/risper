public import std.variant;
public import std.conv;

enum NodeType {
	list,
	functionCall,
	literal,
}

struct Node
{
	Node[] children;
	
	NodeType type;
	Variant value;
	
	
	string toString()
	{
		import std.string:capitalize;
		string result=type.to!string.capitalize~"(";
		if (type == NodeType.list)
		{
			foreach(c;children[0..$-1])
				result~=c.to!string~", ";
			result~=children[$-1].to!string;
		}
		else
			result~=value.to!string;
		return result~")";
	}
}