extends BehaviorNode
class_name BehaviorCondition

@export var expression_text: String = ""
@export var true_node: BehaviorNode
@export var false_node: BehaviorNode
const Condition_Right_True: int = 0
const Condition_Right_False: int = 1

var expr_vars: Dictionary = {}
var CALL_REGEX := RegEx.new()
func _init(): CALL_REGEX.compile(r"\{([A-Za-z0-9_]+)\}\.([A-Za-z_][A-Za-z0-9_]*)\((.*)\)")

func tick(owner, blackboard: Dictionary, delta) -> BehaviorStatus:
	var text := expression_text.strip_edges()
	expr_vars.clear()
	
	text = _process_calls(text, blackboard)
	if text == "": return BehaviorStatus.RUNNING
	
	text = _process_vars(text, blackboard)
	var expr = Expression.new()
	var err = expr.parse(text, expr_vars.keys())
	if err != OK:
		push_error(expr.get_error_text())
		return BehaviorStatus.FAILURE
		
	var result = expr.execute(expr_vars.values())
	var res_bool = bool(result)
	
	if res_bool: return true_node.tick(owner, blackboard, delta) if true_node else BehaviorStatus.SUCCESS
	else: return false_node.tick(owner, blackboard, delta) if false_node else BehaviorStatus.SUCCESS
	
func _process_calls(text: String, blackboard: Dictionary) -> String:
	var matches = CALL_REGEX.search_all(text)
	
	for m in matches:
		var key = m.get_string(1)
		var method = m.get_string(2)
		var args_raw = m.get_string(3).strip_edges()
		
		if !blackboard.has(key): return ""
		var obj = blackboard[key]
		if obj == null: return ""
			
		var args = _parse_args(args_raw, blackboard)
		if args == null: return ""
			
		if !obj.has_method(method):
			push_error("BehaviorCondition: object '%s' has no method '%s'" % [key, method])
			return ""
			
		var result = obj.callv(method, args)
		var lit = _result_to_literal(result)
		text = text.replace(m.get_string(0), lit)
		
	return text
	
func _process_vars(text: String, blackboard: Dictionary) -> String:
	var regex = RegEx.new()
	regex.compile(r"\{([A-Za-z0-9_]+)\}")
	
	for m in regex.search_all(text):
		var key = m.get_string(1)
		if !blackboard.has(key): return ""
		var value = blackboard[key]
		expr_vars[key] = value
		text = text.replace("{%s}" % key, key)
		
	return text
	
func _parse_args(args_str: String, blackboard: Dictionary) -> Array:
	if args_str == "": return []
	var args: Array = []
	
	for part in args_str.split(",", false):
		var a = part.strip_edges()
		var regex = RegEx.new()
		regex.compile(r"\{([A-Za-z0-9_]+)\}")
		
		for m in regex.search_all(a):
			var key = m.get_string(1)
			if !blackboard.has(key): return []
				
			var value = blackboard[key]
			
			if typeof(value) == TYPE_OBJECT:
				expr_vars[key] = value
				a = a.replace("{%s}" % key, key)
			else: a = a.replace("{%s}" % key, _result_to_literal(value))
			
		var expr = Expression.new()
		if expr.parse(a, expr_vars.keys()) != OK:
			push_error("BehaviorCondition: invalid argument expression '%s'" % a)
			return [null]
			
		var _value = expr.execute(expr_vars.values())
		args.append(_value)
		
	return args
	
func _result_to_literal(value) -> String:
	match typeof(value):
		TYPE_BOOL: return "true" if value else "false"
		TYPE_INT, TYPE_FLOAT: return str(value)
		TYPE_STRING: return '"%s"' % value
		TYPE_NIL: return "null"
		_:
			var name := "_ret_" + str(expr_vars.size())
			expr_vars[name] = value
			return name
