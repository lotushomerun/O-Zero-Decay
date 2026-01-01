extends Node
class_name AI

@export var is_disabled: bool = false
@export var character: CharacterBody2D
var first_enable: bool = true # We might turn off AI at some point, and this is used to avoid calling _init_behavior_tree()

#region Ready
func _ready():
	if is_disabled: return
	if character == null: push_warning("AI: 'character' is not assigned! AI disabled.")
	if behavior_tree == null: push_warning("AI: 'behavior_tree' is not assigned! AI disabled.")
	elif behavior_tree.tree == null : push_warning("AI: 'behavior_tree' doesn't have a tree resource! AI disabled.")
	_init_behavior_tree()
	
func switch_AI(n: bool) -> void:
	is_disabled = n
	if !is_disabled && first_enable: _init_behavior_tree()
#endregion

#region Process
func _process(_delta: float) -> void:
	if is_disabled: return
	_update_behavior_tree()
#endregion

#region Behavior Tree
@export var behavior_tree: BehaviorTree

func _init_behavior_tree() -> void:
	if !character || !behavior_tree || !behavior_tree.tree: return
	
	first_enable = false
	behavior_tree.bb_clear()
	
	# Node refs
	behavior_tree.bb_set("character", character)
	behavior_tree.bb_set("movement", character.movement)
	behavior_tree.bb_set("rig", character.rig)
	behavior_tree.bb_set("ai", self)
	
	# Target
	behavior_tree.bb_set("target", null)
	behavior_tree.bb_set("target_dir", -1) # For walking in a certain direction instead of following a target
	
	# Movement vars
	behavior_tree.bb_set("move_distance_halt", 10.0)
	
func _update_behavior_tree() -> void:
	if !character || !behavior_tree || !behavior_tree.tree: return
#endregion
