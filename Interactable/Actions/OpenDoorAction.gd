extends Action
class_name OpenDoorAction

func _action_name() -> String: return "Go Through"

func _execute(params: Array[Variant]) -> void:
	if params.size() < 2:
		push_warning("OpenDoorAction: params.size() < 2!")
		super._execute(params)
		return
		
	var _character: Char = params[0]
	var door: Door = params[1]
	
	SaveState.save_spawn_door(door.door_target_id)
	
	if door.door_open_sounds.size() > 0: SoundManager.play_sound_2d(door.door_open_sounds.pick_random(), door.global_position)
	Level.change_level(door.level_to_load)
	
	#if door.door_open_sounds.size() > 0:
		#super._execute(params) # To close the context menu
		#var audio: AudioStreamPlayer2D = SoundManager.play_sound_2d(door.door_open_sounds.pick_random(), door.global_position)
		#audio.finished.connect(func(): Level.change_level(door.level_to_load))
	#else: Level.change_level(door.level_to_load)
