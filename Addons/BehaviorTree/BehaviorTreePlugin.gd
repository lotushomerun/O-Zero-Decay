@tool
extends EditorPlugin

var _dock

var behavior_tree_icon: Texture2D = preload("res://Addons/BehaviorTree/Nodes/BehaviorTree.svg")

func _enter_tree() -> void:
	add_custom_type("BehaviorTree", "Node", preload("res://Addons/BehaviorTree/Nodes/BehaviorTree.gd"), behavior_tree_icon)
	add_custom_type("BehaviorTreeResource", "Resource", preload("res://Addons/BehaviorTree/Nodes/BehaviorTreeResource.gd"), behavior_tree_icon)
	add_custom_type("BehaviorNode", "Resource", preload("res://Addons/BehaviorTree/Nodes/BehaviorNode.gd"), behavior_tree_icon)
	add_custom_type("BehaviorOutput", "Resource", preload("res://Addons/BehaviorTree/Nodes/BehaviorOutput.gd"), behavior_tree_icon)
	add_custom_type("BehaviorPrint", "Resource", preload("res://Addons/BehaviorTree/Nodes/BehaviorPrint.gd"), behavior_tree_icon)
	
	_dock = preload("res://Addons/BehaviorTree/Editor/Editor.tscn").instantiate()
	add_control_to_bottom_panel(_dock, "Behavior Tree")
	_dock.visible = false
	
func _exit_tree() -> void:
	remove_custom_type("BehaviorTree")
	remove_custom_type("BehaviorTreeResource")
	remove_custom_type("BehaviorNode")
	remove_custom_type("BehaviorOutput")
	remove_custom_type("BehaviorPrint")
	
	remove_control_from_bottom_panel(_dock)

func _edit(res): if res is BehaviorTreeResource: _dock.edit(res)
func _handles(obj): return (obj is BehaviorTreeResource)
