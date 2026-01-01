extends BehaviorNode
class_name BehaviorCall

@export var expression_text: String = ""

var CALL_REGEX := RegEx.new()
func _init(): CALL_REGEX.compile(r"""^\{([a-zA-Z0-9_]+)\}\.([a-zA-Z_][a-zA-Z0-9_]*)\((.*)\)$""")

func tick(owner, blackboard: Dictionary, delta) -> BehaviorStatus:
	var expr_text := expression_text.strip_edges()
	var _match := CALL_REGEX.search(expr_text)
	if _match == null:
		push_error("BehaviorCall: invalid call expression '%s'" % expr_text)
		return BehaviorStatus.FAILURE
		
	var key := _match.get_string(1)
	var method := _match.get_string(2)
	var args_str := _match.get_string(3).strip_edges()
	
	if !blackboard.has(key): return BehaviorStatus.RUNNING
	var target = blackboard[key]
	if target == null: return BehaviorStatus.RUNNING
		
	var args := _parse_args(args_str, blackboard)
		
	if !target.has_method(method):
		push_error("BehaviorCall: object '%s' has no method '%s'" % [key, method])
		return BehaviorStatus.FAILURE
	
	var _result = target.callv(method, args)
	
	if children.is_empty(): return BehaviorStatus.SUCCESS
	else:
		var child: BehaviorNode = children[0]
		return child.tick(owner, blackboard, delta)
	
func _parse_args(args_str: String, blackboard: Dictionary) -> Array:
	var args: Array = []
	if args_str == "": return args
	
	for part in args_str.split(",", false):
		var a = part.strip_edges()
		var expr_vars: Dictionary = {}
		
		var regex = RegEx.new()
		regex.compile(r"\{([A-Za-z0-9_]+)\}")
		for m in regex.search_all(a):
			var var_key = m.get_string(1)
			if !blackboard.has(var_key): return []
			expr_vars[var_key] = blackboard[var_key]
			a = a.replace("{%s}" % var_key, var_key)
			
		var expr = Expression.new()
		if expr.parse(a, expr_vars.keys()) != OK:
			push_error("BehaviorCall: invalid expression argument '%s'" % a)
			return []
			
		var value = expr.execute(expr_vars.values())
		args.append(value)
		
	return args
