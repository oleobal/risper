import common;

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

alias parseWord = parseTo!(long,double,string);


Node[] parse(string s)
{
	ulong i;
	ulong depth=0;
	string currentExpr;
	Node[] exprs;
	for(i=0; i<s.length; i++)
	{
		currentExpr="";
		if (s[i] == '(')
		{
			depth++;
			for(;i<s.length && depth>0 ; i++)
			{
				if (s[i] == '(')
					depth++;
				else if (s[i] == ')')
					depth--;
				currentExpr~=s[i];
			}
			exprs~=parseExpr(currentExpr);
		}
	}
	
	return exprs;
}

Node parseExpr(string s)
{
	
}