extends Node
class_name BehaviorTree

@export var tree: BehaviorTreeResource

var _initialized := false
var _blackboard := {}

#region Ready
func _ready() -> void:
	init_built_in_values()
#endregion

#region Process
func _process(delta: float) -> void:
	if !tree || !tree.root: return
	
	if !_initialized:
		tree.root.initialize(self, _blackboard)
		_initialized = true
	
	process_built_in_values(delta)
	tree.root.tick(self, _blackboard, delta)
#endregion

#region Built-In
func init_built_in_values() -> void:
	# Main
	bb_set("tree", self)
	bb_set("timer", 0.0)
	
	# Vectors
	bb_set("v2_zero", Vector2.ZERO)
	bb_set("v2_left", Vector2(-1, 0))
	bb_set("v2_right", Vector2(1, 0))
	
func process_built_in_values(delta: float) -> void:
	# System related
	bb_set("delta", delta)
	bb_set("timer", bb_get("timer") + delta)
	
	# Character related
	var character: Char = bb_get("character")
	var ai: AI = bb_get("ai")
	if is_instance_valid(character) && is_instance_valid(ai): ai._update_behavior_tree()
#endregion

#region Blackboard
func bb_set(key: String, value: Variant) -> void: _blackboard[key] = value

func bb_get(key: String, default_value: Variant = null) -> Variant: ## Returns default value if value wasn't found
	if _blackboard.has(key): return _blackboard[key]
	return default_value

func bb_remove(key: String) -> void: _blackboard.erase(key)
func bb_has(key: String) -> bool: return _blackboard.has(key)
func bb_clear() -> void: _blackboard.clear()
func bb_keys() -> Array: return _blackboard.keys()
func bb_get_all() -> Dictionary: return _blackboard.duplicate()
#endregion
