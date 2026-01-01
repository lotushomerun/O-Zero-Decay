extends Action
class_name UnequipClothesAction

func _action_name() -> String: return "Take Off"

func _execute(params: Array[Variant]) -> void:
	if params.size() < 2:
		push_warning("UnequipClothesAction: params.size() < 2!")
		super._execute(params)
		return
		
	var character: Char = params[0]
	var item: Item = params[1]
	
	Chatbox.system_message("[color=info]You take off %s.[/color]" % [item.entity_name])
	SoundManager.play_sound_2d(SoundLib.clothes_sounds.pick_random(), character.global_position, -20.0)
	var rig: HumanRig = character.rig as HumanRig
	var clothes_item: ClothesItem = item as ClothesItem
	
	# Apply shit
	rig.take_off_clothes(clothes_item)
	super._execute(params)
