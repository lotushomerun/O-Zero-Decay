extends AI
class_name HumanAI

#region Actions
func look_random_direction() -> void:
	var horizontal_dir: int = [-1, 1].pick_random()
	var vertical_dir: int = [-1, 1].pick_random()
	var human: Human = character as Human
	var rig: HumanRig = human.rig as HumanRig
	
	match horizontal_dir:
		1: rig.look_front()
		-1: rig.look_back()
		
	match vertical_dir:
		1: rig.look_up(randf_range(.1, .66))
		-1: rig.look_down(randf_range(.1, .66))
#endregion
