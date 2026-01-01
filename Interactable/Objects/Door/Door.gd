extends Interactable
class_name Door

@export var door_id: String
@export var door_target_id: String
@export_file("*.tscn") var level_to_load: String # Godot freaked out when I tried doing regular export packed scenes for some reason
@export var facing_right: bool = false
@export var door_open_sounds: Array[AudioStream] = []
@export var door_close_sounds: Array[AudioStream] = []

func _ready() -> void:
	super._ready()
	add_to_group("Doors") # I don't like doing it via inspector because I might forget checking this for some instances...
	
	var open_door_action := OpenDoorAction.new()
	primary_action = open_door_action
	actions.append(open_door_action)

static func position_at_door(character: Char, s: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var doors: Array[Node] = tree.get_nodes_in_group("Doors")
	
	for n: Node in doors:
		if n is Door:
			if n.door_id == s:
				character.global_position = n.global_position + Vector2(32.0 * (1 if n.facing_right else -1), 0.0)
				if !n.facing_right: character.rig.flip_skeleton()
				if n.door_close_sounds.size() > 0: SoundManager.play_sound_2d(n.door_close_sounds.pick_random(), n.global_position, -10.0)
				break
