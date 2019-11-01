import common;

class Context
{
	Context outer;
	
	Node[string] contents;
	
	Node opIndex(Ident i)
	{ return opIndex(i.value.coerce!string);}
	
	Node opIndex(string i)
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
	
	Node opIndexAssign(Node val, string key)
	{
		return contents[key] = val;
	}
	Node opIndexAssign(Node val, Ident key)
	{
		return opIndexAssign(val, key.value.coerce!string);
	}
	
	/++
	 + will go up to the outer context to change the key at the source
	 +/
	Node overwrite(string key, Node val)
	{
		if (key in contents)
			return contents[key] = val;
		else
		{
			if (outer)
				return outer.overwrite(key, val);
			else
				throw new Exception("undefined in context: "~key.to!string);
		}
	}
	Node overwrite(Ident key, Node val)
	{
		return overwrite(key.value.coerce!string, val);
	}
	
	
	this() {}
	
	this(Context outer)
	{
		this.outer = outer;
	}
	
	
	override string toString() const
	{
		return toString(0);
	}
	
	string toString(uint indent) const
	{
		string result = spaces(indent)~"Context(";
		foreach(k,v;contents)
			result~="\n"~spaces(indent+1) ~ k ~ " : " ~ v.toString(indent+1);
		if (outer)
			result~="\n"~outer.toString(indent+1);
		if (result != spaces(indent)~"Context(")
			result~="\n";
		result~=")";
		return result;
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
			
		},
		/// store is special because it works on the current context
		"store":
		function(Node n, ref Context c){
			if (n.children.length != 2)
				goto badArgs;
			if (auto i = cast(Ident) n.children[0])
				return c[i] = eval(n.children[1], c);
			else
				badArgs:	
				throw new Exception("parameters should be ident and expression");
		},
		"+":
		function(Node n, ref Context c){
			if (n.children.length == 0)
				badArgs:
				throw new Exception("parameters should be Number");
			
			Number result = new Number(); result.value = 0;
			foreach(child;n.children)
			{
				Node buf = eval(child, c);
				if (!buf.isA!Number)
					goto badArgs;
				result.value+=buf.value;
			}
			return result;
			
		},
	];
}



/++
 + Params:
 +     expr = the expression to evaluate
 +     context = the defined identifiers
 + Returns:
 +     the result, or Empty if none
 +/
Node eval(Node expr, ref Context context)
{
	
	if (expr.isA!Literal || expr.isA!Return)
		return expr;
	
	if (expr.isA!Ident)
		return context[cast(Ident) expr];
	
	if (Call e = cast(Call) expr )
	{
		if (e.func.isA!Dot)
		{
			// TODO
			throw new EvalException("Dot calling is not implemented yet");
		}
		
		else if (e.func.value.get!string == "return")
		{
			if (e.children.length != 1)
				throw new EvalException("Return takes only one argument");
			
			Return r = new Return();
			r.children~= eval(e.children[0], context);
			return r;
		}
		
		else if (e.func.value.get!string in specialFunctions)
		{
			
			return specialFunctions[e.func.value.get!string](e, context);
		}
		
		else
		{
			auto newContext = new Context(context);
			if (auto func = cast(Function) context[e.func])
			{
				for(ulong i=0; i<e.children.length && i<func.args.length; i++)
					newContext[func.args[i]] = e.children[i];
				return eval(func.children, newContext);
			}
			else
				throw new EvalException("can't Call, as it isn't a function: "~e.func.value.coerce!string);
		}
	}
	
	if (List e = cast(List) expr)
	{
		if (e.isA!Parens)
		{
			if (e.children.length == 1)
				return eval(e.children[0], context);
			else
				return eval(e.children, context);
		}
		else
		{
			Context newContext = new Context(context);
			return eval(e.children, newContext);
		}
	}
	
	return new Empty();
}

/++ ditto +/
Node eval(Node[] expr, ref Context context)
{
	foreach(c;expr)
	{
		Node result = eval(c, context);
		
		if (result.isA!Return)
			return result.children[0];
	}
	return new Empty();
}