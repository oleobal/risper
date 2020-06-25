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
		
		"if":
		function(Node n, ref Context c){
			if (n.children.length < 2 || n.children.length > 3)
				badArgs:
				throw new Exception("parameters should be bool, code if, code else");
			
			auto condition = eval(n.children[0],c);
			
			Node result = new Empty;
			if (condition.value == true)
				result = eval(n.children[1],c);
			else
				if (n.children.length > 2)
					result = eval(n.children[2],c);
			
			return result;
		},
		
		// many questionable built-ins here but I'll get around to
		// formalizing all of that later
		
		"writeln":
		function(Node n, ref Context c){
			string result = "";
			
			foreach(child;n.children)
			{
				Node buf = eval(child, c);
				if (buf.isA!HasChildren)
					result~=buf.to!string;
				else
					result~=buf.value.to!string;
			}
			import std.stdio:writeln; writeln(result);
			
			return new Empty;
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
		
		"-":
		function(Node n, ref Context c){
			if (n.children.length != 2)
				badArgs:
				throw new Exception("parameters should be two Number");
			
			Number result ;
			if(n.children[0].isA!NumberR || n.children[1].isA!NumberR)
				result = new NumberR(Variant(0.0));
			else
				result = new NumberZ(Variant(0));
			
			result.value = eval(n.children[0], c).value - eval(n.children[1], c).value;
			return result;
		},
		
		"==":
		function(Node n, ref Context c){
			if (n.children.length < 2)
				badArgs:
				throw new Exception("parameters should be at least two Numbers "~n.children.to!string);
			
			Bool result = new Bool(Variant(true));
			with (n) for(uint i = 1; i < children.length ; i++)
			{
				if(eval(children[i-1],c).value != eval(children[i],c).value)
				{
					result.value = false;
					break;
				}
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
	{
		if (expr.isA!Dot)
			// getMember(expr.children[0], expr.children[1])
			/+
			if(expr.children[0].isA!Dict)
			{
				
			}
			+/
			throw new EvalException("Dicts not implemented");
		else
			return context[expr.value.coerce!string];
	}
	
	if (Call e = cast(Call) expr )
	{
		if (e.func.isA!Dot)
		{
			// as it's a Call it may be either an UFCS call or
			// an object member (which happens to be a function)
			
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
					newContext[func.args[i]] = eval(e.children[i], context);
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

/++
 + Params:
 +     expr = the list of expressions to evaluate
 +     context = the defined identifiers
 + Returns:
 +     If one of the expressions is a Return, then the children of that
 +     Else what the last expression evals to
 +/
Node eval(Node[] expr, ref Context context)
{
	Node result;
	foreach(c;expr)
	{
		result = eval(c, context);
		
		if (result.isA!Return)
			return result.children[0];
	}
	return result;
}