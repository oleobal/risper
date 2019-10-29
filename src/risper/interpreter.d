import common;

class Context
{
	Context outer;
	
	Node[Ident] contents;
	
	Node opIndex(Ident i)
	{
		if (i in contents)
			return contents[i];
		else
		{
			if (outer)
				return outer[i];
			else
				throw new Exception("undefined in context: "~i.to!string);
		}
	}
	
	Node opIndexAssign(Node val, Ident key)
	{
		return contents[key] = val;
	}
	
	this() {}
	
	this(Context outer)
	{
		this.outer = outer;
	}
}



Node function(Node, ref Context)[string] specialFunctions()
{
	
	return [
		/// returns a Function node
		"function":
		function(Node n, ref Context c){
			if (!n.children[1].isA!List)
				goto badArgs;
			if (n.children[0].isA!Ident)
			{
				return new Function([cast(Ident) 
				n.children[0]], n.children[1].children);
			}
			else if (n.children[0].isA!List)
			{
				foreach(child;n.children[0].children)
					if (!child.isA!Ident)
						goto badArgs;
				return new Function(cast(Ident[]) n.children[0].children, n.children[1].children);
			}
			else
				badArgs:
				throw new Exception("first parameter of function must be list of ident or ident");
			
		} 
		
	];
}



/++
 + expr the expression to evaluate
 + context the defined identifiers
 +/
Node eval(Node expr, ref Context context)
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
		
		else if (e.func.value.get!string in specialFunctions)
		{
			
			return specialFunctions[e.func.value.get!string](e, context);
		}
		
		else
		{
			auto newContext = new Context(context);
			auto func = cast(Function) context[e.func];
			for(ulong i=0; i<e.children.length && i<func.args.length; i++)
				newContext[func.args[i]] = e.children[i];
			return eval(func.children, newContext);
		}
		
	}
	
	if (List e = cast(List) expr)
	{
		foreach(c;e.children)
		{
			Node result = eval(c, context);
		}
	}
	return new Empty();
}

Node eval(Node[] expr, ref Context context)
{
	auto l = new List();
	l.children = expr;
	return eval(l, context);
}