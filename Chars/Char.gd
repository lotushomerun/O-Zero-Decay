extends CharacterBody2D
class_name Char

#region Refs
@export_group("Refs")
@export var rig: Rig
@export var movement: Movement
@export var ai: AI
@export var interactable: Interactable
#endregion

#region Follower
func _get_follower_data() -> Dictionary:
	if !is_instance_valid(ai) || !is_instance_valid(ai.behavior_tree) || !ai.behavior_tree.tree: return {}
	var data: Dictionary = {
		"parent_scene": get_parent().scene_file_path,
		"current_level": get_tree().current_scene.scene_file_path,
		"behavior_tree_res": ai.behavior_tree.tree.resource_path,
		"path": [],
		"doors": {}, # "level_path": "door_id"
		"timers": {}, # "level_path": time
		"speed": 5.0, # 5.0 is about 2 real seconds
	}
	return data
#endregion

#region Ready
func _ready() -> void:
	await get_tree().process_frame
	if Player.this.character == self: Layering.set_char_index(self, Layering.Player_Index)
	else: Layering.add_to_background(self)
#endregion

#region Process
func _process(delta: float) -> void:
	animate(delta)
	
func animate(_delta: float) -> void: pass
#endregion

#region Mobility
enum Mobility { Full, Half, None } # Full - can move freely, Half - can't move but can send inputs, None - immobile
var mobility: Mobility = Mobility.Full

func set_mobility(new_mobility: Mobility) -> void: mobility = new_mobility

func is_fully_mobile() -> bool: return mobility == Mobility.Full
func is_half_mobile() -> bool: return mobility == Mobility.Half
func is_immobile() -> bool: return mobility == Mobility.None
#endregion
