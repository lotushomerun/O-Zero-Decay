extends Node
class_name Actions

@export var character: Human
@export var movement: Movement
@export var human_rig: HumanRig

#region Fall
signal on_fall
func fall(backwards: bool = true) -> void:
	if backwards: movement.apply_impulse(Vector2(-500.0 if character.rig.facing_right else 500.0, 0.0))
	else: movement.apply_impulse(Vector2(500.0 if character.rig.facing_right else -500.0, 0.0))
	
	if Player.this.character == character:
		Camera.shake(Camera.Medium_Shake, .5)
		Camera.this.designated_zoom = Camera.default_zoom * 1.5
	
	emit_signal("on_fall")
	SoundManager.play_sound_2d(SoundLib.body_fall_sound, character.global_position, -10.0)
	character.set_mobility(Char.Mobility.None)
	character.use_body_lean = false
	
	var movement_tree: AnimationTree = human_rig.movement_tree
	
	character._reset_blends() # Reset these to avoid jerkiness when going back to mobility (animate() lerps your shit)
	
	if backwards:
		movement_tree.set("parameters/LayToButtTransition/transition_request", "laying")
		movement_tree.set("parameters/StandingTransition/transition_request", "falling_back")
		movement_tree.set("parameters/FallBackShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	else:
		movement_tree.set("parameters/LayToKneesTransition/transition_request", "laying")
		movement_tree.set("parameters/StandingTransition/transition_request", "falling_front")
		movement_tree.set("parameters/FallFrontShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	var anim: Animation = movement_tree.get_animation("fall_back") if backwards else movement_tree.get_animation("fall_front")
	await get_tree().create_timer(anim.length).timeout
	
	movement_tree.set("parameters/StandingTransition/transition_request", "on_ground")
	movement_tree.set("parameters/OnGroundDirection/transition_request", "back" if backwards else "front")
	
	character.set_mobility(Char.Mobility.Half)
	character.anim_action = Human.AnimActions.LayOnBack if backwards else Human.AnimActions.LayOnFront
	character.interactable._copy_collision_shape(character.laying_shape)
	human_rig._copy_droplets_shape(character.laying_shape)
#endregion

#region Stand Up
signal on_stand_up

func stand_from_butt() -> void:
	if character.anim_action == Human.AnimActions.StandFromButt: return
	
	if Player.this.character == character: Camera.this.designated_zoom = Camera.default_zoom
	var movement_tree: AnimationTree = human_rig.movement_tree
	
	character.anim_action = Human.AnimActions.StandFromButt
	movement_tree.set("parameters/FromButtShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	var anim: Animation = movement_tree.get_animation("stand_from_butt")
	await get_tree().create_timer(anim.length).timeout
	
	emit_signal("on_stand_up")
	movement_tree.set("parameters/StandingTransition/transition_request", "standing")
	character.anim_action = Human.AnimActions.None
	character.set_mobility(Char.Mobility.Full)
	character.interactable._copy_collision_shape(character.collision_shape_2d)
	human_rig._copy_droplets_shape(character.collision_shape_2d)
	
func stand_from_knees() -> void:
	if character.anim_action == Human.AnimActions.StandFromKnees: return
	
	if Player.this.character == character: Camera.this.designated_zoom = Camera.default_zoom
	var movement_tree: AnimationTree = human_rig.movement_tree
	
	character.anim_action = Human.AnimActions.StandFromKnees
	movement_tree.set("parameters/FromKneesShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	var anim: Animation = movement_tree.get_animation("stand_from_knees")
	await get_tree().create_timer(anim.length).timeout
	
	emit_signal("on_stand_up")
	movement_tree.set("parameters/StandingTransition/transition_request", "standing")
	character.anim_action = Human.AnimActions.None
	character.set_mobility(Char.Mobility.Full)
	character.interactable._copy_collision_shape(character.collision_shape_2d)
	human_rig._copy_droplets_shape(character.collision_shape_2d)
#endregion

#region Butt
func lay_to_butt() -> void:
	if character.anim_action == Human.AnimActions.LayToButt: return
	
	if Player.this.character == character: Camera.this.designated_zoom = Camera.default_zoom * 1.2
		
	var movement_tree: AnimationTree = human_rig.movement_tree
	
	character.use_body_lean = true
	character.anim_action = Human.AnimActions.LayToButt
	movement_tree.set("parameters/LayToButtShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	var anim: Animation = movement_tree.get_animation("to_butt")
	await get_tree().create_timer(anim.length).timeout
	
	movement_tree.set("parameters/LayToButtTransition/transition_request", "on_butt")
	character.anim_action = Human.AnimActions.OnButt
	character.interactable._copy_collision_shape(character.sitting_shape)
	human_rig._copy_droplets_shape(character.sitting_shape)
	
#func idle_to_butt() -> void:
	#if anim_action == AnimActions.IdleToButt: return
	#
	#var human_rig: HumanRig = rig
	#var movement_tree: AnimationTree = human_rig.movement_tree
	#
	#set_mobility(Char.Mobility.None)
	#_reset_blends() # Reset these to avoid jerkiness when going back to mobility (animate() lerps your shit)
	#
	#movement_tree.set("parameters/LayToButtTransition/transition_request", "on_butt")
	#movement_tree.set("parameters/StandingTransition/transition_request", "on_ground")
	#movement_tree.set("parameters/OnGroundDirection/transition_request", "back")
	#
	#anim_action = AnimActions.IdleToButt
	#movement_tree.set("parameters/FromButtTimeScale/scale", -1.0)
	#movement_tree.set("parameters/FromButtShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	#
	#var anim: Animation = movement_tree.get_animation("stand_from_butt")
	#await get_tree().create_timer(anim.length).timeout
	#
	##movement_tree.set("parameters/LayToButtTransition/transition_request", "on_butt")
	#movement_tree.set("parameters/FromButtTimeScale/scale", 1.0)
	#anim_action = AnimActions.OnButt
	#set_mobility(Char.Mobility.Half)
#endregion

#region Knees
func lay_to_knees() -> void:
	if character.anim_action == Human.AnimActions.LayToKnees: return
	
	if Player.this.character == character: Camera.this.designated_zoom = Camera.default_zoom * 1.2
	
	var movement_tree: AnimationTree = human_rig.movement_tree
	
	character.use_body_lean = true
	character.anim_action = Human.AnimActions.LayToButt
	movement_tree.set("parameters/LayToKneesShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	var anim: Animation = movement_tree.get_animation("to_knees")
	await get_tree().create_timer(anim.length).timeout
	
	movement_tree.set("parameters/LayToKneesTransition/transition_request", "on_knees")
	character.anim_action = Human.AnimActions.OnKnees
	character.interactable._copy_collision_shape(character.sitting_shape)
	human_rig._copy_droplets_shape(character.sitting_shape)
	
#func idle_to_knees() -> void:
	#if anim_action == AnimActions.IdleToKnees: return
	#
	#var human_rig: HumanRig = rig
	#var movement_tree: AnimationTree = human_rig.movement_tree
	#
	#set_mobility(Char.Mobility.None)
	#anim_action = AnimActions.IdleToKnees
	#movement_tree.set("parameters/FromKneesTimeScale/scale", -1.0)
	#movement_tree.set("parameters/LayToKneesShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	#
	#var anim: Animation = movement_tree.get_animation("to_knees")
	#await get_tree().create_timer(anim.length).timeout
	#
	#movement_tree.set("parameters/LayToKneesTransition/transition_request", "on_knees")
	#movement_tree.set("parameters/FromKneesTimeScale/scale", 1.0)
	#anim_action = AnimActions.OnKnees
	#set_mobility(Char.Mobility.Half)
#endregion
