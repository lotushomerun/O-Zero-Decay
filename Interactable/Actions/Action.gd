extends Resource
class_name Action

func _action_name() -> String: return "Action"

func _execute(_params: Array[Variant]) -> void:	 Context.hide_context()
	
func _valid(_params: Array[Variant]) -> bool: return true
