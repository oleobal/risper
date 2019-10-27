module risper.interpreter;


/++
 + expr the expression to evaluate
 + context the defined identifiers
 +/
Node eval(Node expr, Node[Ident] context=[])
{
	
	if (expr.isA!Literal)
		return expr;
	
	if (Call e = cast(Call) expr )
	{
		if (e.func.isA!Dot)
		{
			// TODO
			throw new EvalException("Dot calling is not implemented yet");
		}
		else
		{
			
			// TODO
		}
		
	}
	
	if (List e = cast(List) expr)
	{
		foreach(c;e.children)
		{
			Node result = eval(c, context);
			if (result.isA!Def)
			{
				auto a = new List(); a.children = result.children;
				context[result.func] = a;
			}
		}
	}
	
}

