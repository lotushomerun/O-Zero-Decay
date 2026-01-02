extends Node
class_name Sex

@export var character: Human
@export var movement: Movement
@export var stamina: Stamina

var resistance: float = 0.0
var sex_partner: Human
var is_bottom: bool = false

#region Ready
func _ready() -> void:
	await get_tree().process_frame
	if !character: push_warning("Sex: No character ref!")
	if !movement: push_warning("Sex: No movement ref!")
	if !stamina: push_warning("Sex: No stamina ref!")
#endregion

#region Arousal
const Ejaculation_Delay_Base: float = 1.0 # In seconds
const Ejaculation_Stop_Value: float = 0.1 # At which arousal we stop ejaculating?
const Ejaculation_Arousal_Deplete_Multiplier: float = 0.25 # How fast we lose arousal when ejaculating
var arousal: float = 0.0 # From 0 to 1
var ejaculation_delay: float = 0.0
var ejaculating: bool = false

func _process_arousal(delta: float) -> void:
	if Player.this.character == character:
		#if !ejaculating: arousal = clampf(arousal + delta * 0.1, 0.0, 1.0)
		ArousalEffect.set_arousal(clampf(arousal, 0.0, 1.0))
		
	if ejaculating:
		arousal = clampf(arousal - delta * Ejaculation_Arousal_Deplete_Multiplier, Ejaculation_Stop_Value, 1.0)
		
		if arousal > Ejaculation_Stop_Value:
			ejaculation_delay -= delta
			if ejaculation_delay <= 0.0: ejaculate()
			
		else: # Finished ejaculating
			ejaculated = true
			ejaculating = false
			ejaculation_delay = 0.0
			
			if is_instance_valid(sex_partner): # If we finished ejaculating in a sex scene
				var human_rig: HumanRig = character.rig as HumanRig
				var sex_data: Dictionary = _get_sex_data(human_rig.current_animation_tree)
				
				if is_bottom: # Turn off additive orgasm animation if we're a bottom in a sex scene
					var tween: Tween = get_tree().create_tween()
					tween.tween_property(human_rig.current_animation_tree, sex_data["bottom_orgasm_add_path"], 0.0, .33)
				else:
					human_rig.current_animation_tree.set(sex_data["top_orgasm_transition_path"], "AfterOrgasm")
					sex_partner.sex._sex_ended()
					_sex_ended()
	else:
		if arousal >= 1.0: ejaculate() # First cummies
#endregion

#region Prompt
static var sex_top_bar: ProgressBar
static var sex_bottom_bar: ProgressBar
static var sex_resistance_bar: ProgressBar
static var sex_prompt
static var Sex_Prompt_Scene: PackedScene = load("res://UI/ScreenText/SexPrompt.tscn")

static func show_sex_prompt(resisting: bool = false) -> void:
	if is_instance_valid(sex_prompt): sex_prompt.queue_free()
	
	sex_prompt = Sex_Prompt_Scene.instantiate()
	sex_top_bar = sex_prompt.get_node("VBox/TopBar")
	sex_bottom_bar = sex_prompt.get_node("VBox/BottomBar")
	sex_resistance_bar = sex_prompt.get_node("VBox/ResistanceBar")
	var label: Label = sex_prompt.get_node("VBox/HBox/Label")
	label.text = "SMASH to %s!" % ("resist" if resisting else "thrust")
	
	ScreenText.show_middle_text([sex_prompt], BoxContainer.AlignmentMode.ALIGNMENT_CENTER, VerticalAlignment.VERTICAL_ALIGNMENT_TOP)

func _process_prompt() -> void:
	var top_arousal: float = arousal if !is_bottom else sex_partner.sex.arousal
	var bottom_arousal: float = arousal if is_bottom else sex_partner.sex.arousal
	var resistance_value: float = resistance if is_bottom else sex_partner.sex.resistance
	sex_top_bar.value = top_arousal * 100.0
	sex_bottom_bar.value = bottom_arousal * 100.0
	sex_resistance_bar.value = resistance_value * 100.0
#endregion

#region Start/End
signal on_sex_start
signal on_sex_end

func start_sex_with(bottom: Human, top_anim_tree: AnimationTree, bottom_anim_tree: AnimationTree) -> void:
	emit_signal("on_sex_start")
	bottom.global_position = character.global_position
	_init_sex_data(bottom, top_anim_tree)
	_init_as_top(bottom, top_anim_tree)
	bottom.sex._init_as_bottom(character, bottom_anim_tree)
	
	if bottom == Player.this.character || character == Player.this.character:
		Camera.this.designated_offset = Vector2.ZERO
		Camera.shake(Camera.Strong_Shake, .5)
		Camera.this.designated_zoom = Camera.default_zoom * 1.5
		show_sex_prompt(bottom == Player.this.character)
	
func _init_sex_data(bottom: Human, top_anim_tree: AnimationTree) -> void:
	var sex_data: Dictionary = _get_sex_data(top_anim_tree)
	var top_rig: HumanRig = character.rig as HumanRig
	var bottom_rig: HumanRig = bottom.rig as HumanRig
	
	if sex_data.has("top_collision_shape"):
		var shape: CollisionShape2D = character.get(sex_data["top_collision_shape"])
		if is_instance_valid(shape):
			character.interactable._copy_collision_shape(shape)
			top_rig._copy_droplets_shape(shape)
	
	if sex_data.has("bottom_collision_shape"):
		var shape: CollisionShape2D = bottom.get(sex_data["top_collision_shape"])
		if is_instance_valid(shape):
			bottom.interactable._copy_collision_shape(shape)
			bottom_rig._copy_droplets_shape(shape)
	
	if !sex_data.has("same_facing"): push_warning("Sex scene from %s lacks 'same_facing' key in SexLib config!" % top_anim_tree.name)
	else:
		if sex_data["same_facing"] == true && bottom.rig.facing_right != character.rig.facing_right: bottom.rig.flip_skeleton()
		elif sex_data["same_facing"] == false && bottom.rig.facing_right == character.rig.facing_right: bottom.rig.flip_skeleton()
	
	if !sex_data.has("top_above"): push_warning("Sex scene from %s lacks 'top_above' key in SexLib config!" % top_anim_tree.name)
	else:
		Layering.set_char_index(bottom, Layering.Min_Sex_Index if (sex_data["top_above"] == true) else Layering.Max_Sex_Index)
		Layering.set_char_index(character, Layering.Max_Sex_Index if (sex_data["top_above"] == true) else Layering.Min_Sex_Index)
		
	# Top layering:
	if sex_data.has("top_front_leg_z_offset"): Layering.set_node_z(top_rig.front_upper_leg_bone, sex_data["top_front_leg_z_offset"])
	if sex_data.has("top_back_leg_z_offset"): Layering.set_node_z(top_rig.back_upper_leg_bone, sex_data["top_back_leg_z_offset"])
	if sex_data.has("top_front_arm_z_offset"): Layering.set_node_z(top_rig.front_upper_arm_bone, sex_data["top_front_arm_z_offset"])
	if sex_data.has("top_back_arm_z_offset"): Layering.set_node_z(top_rig.back_upper_arm_bone, sex_data["top_back_arm_z_offset"])
	if sex_data.has("top_penis_z_offset"): Layering.set_node_z(top_rig.penis_node, sex_data["top_penis_z_offset"])
	
	# Bottom layering:
	if sex_data.has("bottom_front_leg_z_offset"): Layering.set_node_z(bottom_rig.front_upper_leg_bone, sex_data["bottom_front_leg_z_offset"])
	if sex_data.has("bottom_back_leg_z_offset"): Layering.set_node_z(bottom_rig.back_upper_leg_bone, sex_data["bottom_back_leg_z_offset"])
	if sex_data.has("bottom_front_arm_z_offset"): Layering.set_node_z(bottom_rig.front_upper_arm_bone, sex_data["bottom_front_arm_z_offset"])
	if sex_data.has("bottom_back_arm_z_offset"): Layering.set_node_z(bottom_rig.back_upper_arm_bone, sex_data["bottom_back_arm_z_offset"])
	if sex_data.has("bottom_penis_z_offset"): Layering.set_node_z(bottom_rig.penis_node, sex_data["bottom_penis_z_offset"])
		
func _get_sex_data(anim_tree: AnimationTree) -> Dictionary:
	var anim_player: AnimationPlayer = anim_tree.get_node(anim_tree.anim_player)
	var sex_data: Dictionary = SexLib.sex_data[anim_player.name]
	return sex_data
	
func _init_in_sex(anim_tree: AnimationTree) -> void: # Shared init
	var human_rig: HumanRig = character.rig as HumanRig
	human_rig.select_animation_tree(anim_tree)
	movement.stop_impulse() # Stop if we're sliding or something
	character.set_mobility(Char.Mobility.None)
	character.use_body_lean = false
	character._reset_blends() # Reset these to avoid jerkiness when going back to mobility (animate() lerps your shit)
	character.anim_action = Human.AnimActions.Wrestling
	
	thrust_dmg = _calculate_thrust_damage()
	
	var clothes_to_hide: Array[Sprite2D] = [human_rig.panties_node]
	clothes_to_hide.append_array(human_rig.pants_nodes)
	human_rig._hide_clothes(clothes_to_hide)
	
func _init_as_top(bottom: Human, anim_tree: AnimationTree) -> void: # Considers as a top
	_init_in_sex(anim_tree)
	sex_partner = bottom
	is_bottom = false
	
	var human_rig: HumanRig = character.rig as HumanRig
	penis_tip_marker = human_rig.penis_tip_marker
	
	var sex_data: Dictionary = _get_sex_data(anim_tree)
	anim_tree.set(sex_data["role_path"], "top")
	
func _init_as_bottom(top: Human, anim_tree: AnimationTree) -> void: # Considers us a bottom
	_init_in_sex(anim_tree)
	sex_partner = top
	is_bottom = true
	
	var human_rig: HumanRig = character.rig as HumanRig
	top.sex.groin_area = human_rig.groin_area # So our top knows where our ass is
	penis_tip_marker = human_rig.penis_tip_marker
	
	var sex_data: Dictionary = _get_sex_data(anim_tree)
	anim_tree.set(sex_data["role_path"], "bottom")
	
func _sex_ended() -> void:
	await get_tree().create_timer(1.0).timeout # Temporary here for debug purposes to auto-end sex
	
	var is_top: bool = !is_bottom
	var human_rig: HumanRig = character.rig as HumanRig
	var sex_data: Dictionary = _get_sex_data(human_rig.current_animation_tree)
	
	human_rig.current_animation_tree.set(sex_data["top_orgasm_transition_path"], "BeforeOrgasm") # Revert it!
	ejaculated = false
	ejaculating = false
	groin_area = null
	penis_tip_marker = null
	is_bottom = false
	sex_partner = null
	
	character.interactable._copy_collision_shape(character.collision_shape_2d)
	human_rig._copy_droplets_shape(character.collision_shape_2d)
	
	character.set_mobility(Char.Mobility.Full)
	character.use_body_lean = true
	character.anim_action = Human.AnimActions.None
	
	if human_rig.panties_data || human_rig.pants_data:
		var clothes_to_show: Array[Sprite2D] = [human_rig.panties_node if human_rig.panties_data != null else null]
		if human_rig.pants_data != null: clothes_to_show.append_array(human_rig.pants_nodes)
		human_rig._show_clothes(clothes_to_show)
	
	human_rig.select_animation_tree(human_rig.movement_tree)
	
	if character == Player.this.character:
		Layering.set_char_index(character, Layering.Player_Index)
		sex_prompt.queue_free()
		Camera.shake(Camera.Strong_Shake, .33)
		Camera.this.designated_zoom = Camera.default_zoom
		
	else: Layering.add_to_background(character)
	
	if is_top:
		if sex_data.has("top_front_leg_z_offset"): Layering.reset_node_z(human_rig.front_upper_leg_bone)
		if sex_data.has("top_back_leg_z_offset"): Layering.reset_node_z(human_rig.back_upper_leg_bone)
		if sex_data.has("top_front_arm_z_offset"): Layering.reset_node_z(human_rig.front_upper_arm_bone)
		if sex_data.has("top_back_arm_z_offset"): Layering.reset_node_z(human_rig.back_upper_arm_bone)
		if sex_data.has("top_penis_z_offset"): Layering.reset_node_z(human_rig.penis_node)
	
	else:
		if sex_data.has("bottom_front_leg_z_offset"): Layering.reset_node_z(human_rig.front_upper_leg_bone)
		if sex_data.has("bottom_back_leg_z_offset"): Layering.reset_node_z(human_rig.back_upper_leg_bone)
		if sex_data.has("bottom_front_arm_z_offset"): Layering.reset_node_z(human_rig.front_upper_arm_bone)
		if sex_data.has("bottom_back_arm_z_offset"): Layering.reset_node_z(human_rig.back_upper_arm_bone)
		if sex_data.has("bottom_penis_z_offset"): Layering.reset_node_z(human_rig.penis_node)
	
	if !is_top:
		character.set_mobility(Char.Mobility.Half)
		character.anim_action = character.AnimActions.LayOnFront
		character.stamina.add_stunned(5.0)
		#character.movement._try_half_mobile_move()
	character.add_status(FuckedStatus.new())
	emit_signal("on_sex_end")
#endregion

#region Process
func _process(delta: float) -> void:
	_process_arousal(delta)
	
	if character.anim_action != Human.AnimActions.Wrestling || !is_instance_valid(sex_partner): return
	
	thrust_delay = clampf(thrust_delay - delta, 0.0, Thrust_Delay)
	
	if Player.this.character == character && is_instance_valid(sex_prompt):
		_process_prompt()
		_process_inputs()
				
func _process_inputs() -> void:
	if struggle_delay <= 0.0:
		if Input.is_action_just_pressed("lunge"):
			if stamina.fatigue >= Stamina.Exhausted_Threshold_Base: # Too tired!
				SoundManager.play_sound_ui(SoundLib.ui_cancel_sound, -5.0)
				return
				
			if is_bottom: struggle()
			else: thrust()
#endregion

#region Penetration
var penetrating: bool = false
var penis_tip_marker: Marker2D
var groin_area: Area2D
	
func _is_penetrating() -> bool: return Utils.is_point_inside_area(groin_area, penis_tip_marker.global_position)

func play_penetration_sound() -> void:
	if !is_instance_valid(sex_partner): return
	var human_rig: HumanRig = character.rig as HumanRig
	var sex_data: Dictionary = _get_sex_data(human_rig.current_animation_tree)
	var penetration_sounds: Array[AudioStream] = sex_data["penetration_sounds"]
	SoundManager.play_sound_2d(penetration_sounds.pick_random(), character.global_position)
#endregion

#region Thrust
var thrust_self_dmg: float = 0.05
var thrust_dmg: float = 0.1
var thrust_delay: float = 0.0
const Thrust_Delay: float = 0.4

signal on_thrust

func thrust() -> void:
	if ejaculating || ejaculated || thrust_delay > 0.0: return # Can't thrust while ejaculating or after ejaculated
	emit_signal("on_thrust")
	
	thrust_delay = Thrust_Delay
	stamina.add_exercise(1.0) # Get tired!!!
	if stamina.exercising >= Stamina.Sweating_Threshold_Base: stamina.add_fatigue(1.0) # Get tired!!!
	
	arousal += thrust_self_dmg
	sex_partner.sex.arousal += thrust_dmg
	
	var human_rig: HumanRig = character.rig as HumanRig
	var partner_rig: HumanRig = sex_partner.rig as HumanRig
	var sex_data: Dictionary = _get_sex_data(human_rig.current_animation_tree)
	
	play_penetration_sound()
	human_rig.current_animation_tree.set(sex_data["top_thrust_path"], AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	partner_rig.current_animation_tree.set(sex_data["bottom_thrust_path"], AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
func _calculate_thrust_damage() -> float:
	if !is_instance_valid(sex_partner): return 0.1
	
	var _human_rig: HumanRig = character.rig as HumanRig
	var _partner_rig: HumanRig = sex_partner.rig as HumanRig
	var dmg: float = 0.1
	
	if character.has_status("BigPenisStatus"): dmg += 0.033
	elif character.has_status("SmallPenisStatus"): dmg -= 0.033
	
	return clampf(dmg, 0.01, INF)
#endregion

#region Struggle
var struggle_dmg: float = 0.1
var struggle_delay: float = 0.0
const Struggle_Delay: float = 0.33

signal on_struggle

func struggle() -> void:
	emit_signal("on_struggle")
	
	stamina.add_exercise(2.0) # Get tired!!!
	if stamina.exercising >= Stamina.Sweating_Threshold_Base: stamina.add_fatigue(2.0) # Get super tired!!!
	
	resistance += struggle_dmg
	struggle_delay = Struggle_Delay
	
	SoundManager.play_sound_2d(SoundLib.resist_sounds.pick_random(), character.global_position, -10.0)
	Camera.shake(Camera.Light_Shake, .33)
	
func _calculate_struggle_damage() -> float:
	if !is_instance_valid(sex_partner): return 0.1
	
	var human_rig: HumanRig = character.rig as HumanRig
	var partner_rig: HumanRig = sex_partner.rig as HumanRig
	var dmg: float = 0.1
	
	if partner_rig.body_height < human_rig.body_height: dmg += 0.033 * abs((human_rig.body_height - partner_rig.body_height))
	elif partner_rig.body_height > human_rig.body_height: dmg -= 0.033 * abs((human_rig.body_height - partner_rig.body_height))
	
	if partner_rig.body_weight < human_rig.body_weight: dmg += 0.033 * (human_rig.body_weight - partner_rig.body_weight)
	elif partner_rig.body_weight > human_rig.body_weight: dmg -= 0.033 * (partner_rig.body_weight - human_rig.body_weight)
	
	return clampf(dmg, 0.01, INF)
#endregion

#region Cum
const Bottom_Orgasm_Additive: float = .33 # Never set it to 1.0 because it's fucked up
static var Cum_Projectile_Scene: PackedScene = load("res://Effects/Cum/CumProjectile.tscn")
var ejaculated: bool = false

signal on_ejaculation

func ejaculate() -> void:
	emit_signal("on_ejaculation")
	ejaculating = true
	ejaculation_delay = Ejaculation_Delay_Base + randf_range(0.0, .66)
	
	var human_rig: HumanRig = character.rig as HumanRig
	human_rig.roll_eyes()
	
	if is_instance_valid(sex_partner): # We're in a sex scene!
		var sex_data: Dictionary = _get_sex_data(human_rig.current_animation_tree)
		
		if !is_bottom:
			var partner_rig: HumanRig = sex_partner.rig as HumanRig
			human_rig.current_animation_tree.set(sex_data["top_orgasm_shot_path"], AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			partner_rig.current_animation_tree.set(sex_data["bottom_thrust_path"], AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		else:
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(human_rig.current_animation_tree, sex_data["bottom_orgasm_add_path"], Bottom_Orgasm_Additive, .33)
	
	if character.char_data.male_genitals: # Penis?!
		if !is_instance_valid(sex_partner) || is_bottom || !_is_penetrating(): # Bottoms always cum outside
			eject_seed()
		else:
			play_penetration_sound()
			SoundManager.play_sound_2d(SoundLib.cum_inside_sounds.pick_random(), character.global_position, -15.0)
		
func eject_seed() -> void:
	SoundManager.play_sound_2d(SoundLib.cum_sound, character.global_position, -15.0)
	await get_tree().create_timer(.33).timeout # Wait a bit for the sound to play out
	var human_rig: HumanRig = character.rig as HumanRig
	var p := Cum_Projectile_Scene.instantiate()
	var dir: Vector2 = human_rig.penis_tip_marker.global_position - human_rig.penis_node.global_position
	p.global_position = human_rig.penis_tip_marker.global_position
	p.velocity = dir * 50.0
	get_tree().current_scene.add_child(p)
#endregion
