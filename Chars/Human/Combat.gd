extends Node
class_name Combat

@export var character: Human
@export var movement: Movement
@export var stamina: Stamina

#region Ready
func _ready() -> void:
	await get_tree().process_frame
	if !character: push_warning("Combat: No character ref!")
	if !movement: push_warning("Combat: No movement ref!")
	if !stamina: push_warning("Combat: No stamina ref!")
	character.attack_area.body_entered.connect(Callable(self, "_on_attack_area_body_entered"))
#endregion

#region Process
func _process(delta: float) -> void:
	if character.anim_action != Human.AnimActions.Wrestling || !is_instance_valid(wrestling_opponent): return
	
	var player_in_fight: bool = (Player.this.character == character || Player.this.character == wrestling_opponent)
	struggle_delay = clampf(struggle_delay - delta, 0.0, Struggle_Delay)
	if !player_in_fight && struggle_delay <= 0.0 && !is_wrestling_victim: # Playing resist sounds on attacker if it's an npc struggle
		struggle_delay = Struggle_Delay + randf_range(-.2, .2) # Slight rando
		SoundManager.play_sound_2d(SoundLib.resist_sounds.pick_random(), character.global_position, -10.0)
	
	if Player.this.character == character && is_instance_valid(wrestling_prompt):
		wrestling_you_bar.value = wrestling_progress * 100.0
		wrestling_enemy_bar.value = wrestling_opponent.combat.wrestling_progress * 100.0
		
		if struggle_delay <= 0.0:
			if Input.is_action_just_pressed("lunge"):
				if stamina.fatigue >= Stamina.Exhausted_Threshold_Base: # Too tired!
					SoundManager.play_sound_ui(SoundLib.ui_cancel_sound, -5.0)
					return
					
				struggle()
	else: # We're not player? Slowly raise our wrestling progress then!
		wrestling_progress += delta * struggle_dmg
		
	# Check who won
	if wrestling_opponent.combat.wrestling_progress >= 1.0:
		wrestling_opponent.combat._grab_win()
		_grab_lose()
	elif wrestling_progress >= 1.0:
		wrestling_opponent.combat._grab_lose()
		_grab_win()
#endregion

#region Shove & Grab
signal on_got_shoved(attacker: Human)
signal on_shoved(victim: Human)

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body != character && body is Human && !is_instance_valid(wrestling_opponent):
		var human_victim: Human = body as Human
		var target_rig: HumanRig = human_victim.rig as HumanRig
		if human_victim.anim_action != Human.AnimActions.None: return
		
		movement.stop_impulse()
		human_victim.movement.stop_impulse()
		character.velocity = Vector2.ZERO
		human_victim.velocity = Vector2.ZERO
		
		if Player.this.character == human_victim || Player.this.character == character:
			Camera.shake(Camera.Light_Shake if Player.this.character == character else Camera.Strong_Shake, .5)
		
		if character.anim_action == Human.AnimActions.Shove:
			emit_signal("on_shoved", human_victim) # We just shoved someone!
			human_victim.combat._get_shoved(character)
		else:
			#var human_rig: HumanRig = character.rig as HumanRig
			#character.sex.start_sex_with(human_victim, human_rig.doggy_sex_tree, target_rig.doggy_sex_tree)
			
			if human_victim == Player.this.character || character == Player.this.character:
				Camera.this.designated_offset = Vector2.ZERO
				Camera.shake(Camera.Strong_Shake, .5)
				Camera.this.designated_zoom = Camera.default_zoom * 1.5
				show_wrestling_prompt(human_victim == Player.this.character)
				
			_grab(human_victim)
			human_victim.combat._get_grabbed(character)
			human_victim.global_position = character.global_position
			if target_rig.facing_right == character.rig.facing_right: target_rig.flip_skeleton()
			SoundManager.play_sound_2d(SoundLib.grab_sound, human_victim.global_position)

func shove() -> void:
	if stamina.fatigue >= Stamina.Exhausted_Threshold_Base: return # Too tired!
	character.anim_action = Human.AnimActions.Shove
	_lunge_animation()

func lunge() -> void:
	if stamina.fatigue >= Stamina.Exhausted_Threshold_Base: return # Too tired!
	character.anim_action = Human.AnimActions.Lunge
	_lunge_animation()
	
func _lunge_animation() -> void:
	character.set_mobility(Char.Mobility.None)
	character.use_body_lean = false
	
	var human_rig: HumanRig = character.rig as HumanRig
	var movement_tree: AnimationTree = human_rig.movement_tree
	var anim: Animation = movement_tree.get_animation("lunge")
	
	character._reset_blends() # Reset these to avoid jerkiness when going back to mobility (animate() lerps your shit)
	movement_tree.set("parameters/LungeShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	await get_tree().create_timer(0.2).timeout # Wait a bit for the prep of anim
	movement.apply_impulse(Vector2(500.0 if character.rig.facing_right else -500.0, 0.0))
	SoundManager.play_sound_2d(SoundLib.lunge_sound, character.global_position)
	
	stamina.add_exercise(1.33) # Get tired!!!
	if stamina.exercising >= Stamina.Sweating_Threshold_Base: stamina.add_fatigue(1.33) # Get super tired!!!
	
	await get_tree().create_timer(0.1).timeout # Wait A BIT MORE
	character.attack_area.monitoring = true
	
	await get_tree().create_timer(0.1).timeout # Wait a bit
	character.attack_area.monitoring = false
	
	var lunge_anim_states: Array[Human.AnimActions] = [Human.AnimActions.Lunge, Human.AnimActions.Shove]
	if !lunge_anim_states.has(character.anim_action): return
	movement.play_footstep()
	movement.stop_impulse()
	
	await get_tree().create_timer(anim.length - 0.5).timeout
	if !lunge_anim_states.has(character.anim_action): return
	character.set_mobility(Char.Mobility.Full)
	character.anim_action = Human.AnimActions.None
	character.use_body_lean = true
	
func _get_shoved(attacker: Human) -> void:
	emit_signal("on_got_shoved", attacker) # Someone just shoved us...
	var attacker_rig: HumanRig = attacker.rig as HumanRig
	character.actions.fall(true if character.rig.facing_right != attacker_rig.facing_right else false)
	SoundManager.play_sound_2d(SoundLib.push_sound, character.global_position)
	stamina.add_stunned(2.0)
#endregion

#region Wrestling
var wrestling_opponent: Human
var wrestling_progress: float = 0.0 # From 0 to 1
var is_wrestling_victim: bool = false

static var wrestling_you_bar: ProgressBar
static var wrestling_enemy_bar: ProgressBar
static var wrestling_prompt
static var Wrestling_Prompt_Scene: PackedScene = load("res://UI/ScreenText/WrestlingPrompt.tscn")

var struggle_dmg: float = 0.1
var struggle_delay: float = 0.0
const Struggle_Delay: float = 0.33

signal on_got_grabbed(attacker: Human)
signal on_grabbed(victim: Human)
signal on_grab_end
signal on_grab_win
signal on_grab_lose
signal on_struggle

func _grab(victim: Human) -> void:
	emit_signal("on_grabbed", victim) # We just grabbed someone!
	
	wrestling_progress = 0.0
	wrestling_opponent = victim
	is_wrestling_victim = false
	
	struggle_dmg = _calculate_struggle_damage()
	character.set_mobility(Char.Mobility.None)
	character.use_body_lean = false
	character.anim_action = Human.AnimActions.Wrestling
	
	var human_rig: HumanRig = character.rig as HumanRig
	var wrestling_tree: AnimationTree = human_rig.wrestling_tree
	human_rig.movement_tree.set("parameters/LungeShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT) # Abort this anim
	
	human_rig.select_animation_tree(human_rig.wrestling_tree)
	wrestling_tree.set("parameters/Role/transition_request", "attacker")
	
	var opponent_rig: HumanRig = wrestling_opponent.rig as HumanRig
	if opponent_rig.body_height < human_rig.body_height: wrestling_tree.set("parameters/Height/transition_request", "short")
	elif opponent_rig.body_height > human_rig.body_height: wrestling_tree.set("parameters/Height/transition_request", "tall")
	else: wrestling_tree.set("parameters/Height/transition_request", "medium")

func _get_grabbed(attacker: Human) -> void:
	emit_signal("on_got_grabbed", attacker) # Someone just grabbed us...
	
	wrestling_progress = 0.0
	wrestling_opponent = attacker
	is_wrestling_victim = true
	
	struggle_dmg = _calculate_struggle_damage()
	character.set_mobility(Char.Mobility.None)
	character.use_body_lean = false
	character.anim_action = Human.AnimActions.Wrestling
	
	var human_rig: HumanRig = character.rig as HumanRig
	var wrestling_tree: AnimationTree = human_rig.wrestling_tree
	human_rig.movement_tree.set("parameters/LungeShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT) # Abort this anim
	
	human_rig.select_animation_tree(human_rig.wrestling_tree)
	wrestling_tree.set("parameters/Role/transition_request", "victim")

func _end_grab() -> void:
	emit_signal("on_grab_end")
	var human_rig: HumanRig = character.rig as HumanRig
	character.global_position.x = human_rig.spine_node.global_position.x # Move them slightly to their actual position
	
	wrestling_opponent = null
	character.set_mobility(Char.Mobility.Full)
	character.use_body_lean = true
	character.anim_action = Human.AnimActions.None
	human_rig.select_animation_tree(human_rig.movement_tree)
	
	if Player.this.character == character:
		wrestling_prompt.queue_free()
		Camera.shake(Camera.Strong_Shake, .33)
		Camera.this.designated_zoom = Camera.default_zoom
	
func _grab_win() -> void:
	emit_signal("on_grab_win")
	_end_grab()
	
	# Force shove (preemptively remove exercise and fatigue addition that is going to happen)
	stamina.add_exercise(-3.0)
	stamina.add_fatigue(-3.0)
	
	character.anim_action = Human.AnimActions.Shove
	_lunge_animation()
	
func _grab_lose() -> void:
	emit_signal("on_grab_lose")
	_end_grab()
	movement.apply_impulse(Vector2(-250.0 if character.rig.facing_right else 250.0, 0.0)) # Move slightly backwards

func struggle() -> void:
	emit_signal("on_struggle")
	
	stamina.add_exercise(2.0) # Get tired!!!
	if stamina.exercising >= Stamina.Sweating_Threshold_Base: stamina.add_fatigue(2.0) # Get super tired!!!
	
	wrestling_progress += struggle_dmg
	struggle_delay = Struggle_Delay
	
	SoundManager.play_sound_2d(SoundLib.resist_sounds.pick_random(), character.global_position, -10.0)
	Camera.shake(Camera.Light_Shake, .33)
	
func _calculate_struggle_damage() -> float:
	if !is_instance_valid(wrestling_opponent): return 0.1
	
	var human_rig: HumanRig = character.rig as HumanRig
	var opponent_rig: HumanRig = wrestling_opponent.rig as HumanRig
	var dmg: float = 0.1
	
	if opponent_rig.body_height < human_rig.body_height: dmg += 0.033 * abs((human_rig.body_height - opponent_rig.body_height))
	elif opponent_rig.body_height > human_rig.body_height: dmg -= 0.033 * abs((human_rig.body_height - opponent_rig.body_height))
	
	if opponent_rig.body_weight < human_rig.body_weight: dmg += 0.033 * (human_rig.body_weight - opponent_rig.body_weight)
	elif opponent_rig.body_weight > human_rig.body_weight: dmg -= 0.033 * (opponent_rig.body_weight - human_rig.body_weight)
	
	return clampf(dmg, 0.01, INF)

static func show_wrestling_prompt(resisting: bool = false) -> void:
	if is_instance_valid(wrestling_prompt): wrestling_prompt.queue_free()
	
	wrestling_prompt = Wrestling_Prompt_Scene.instantiate()
	wrestling_you_bar = wrestling_prompt.get_node("VBox/YouBar")
	wrestling_enemy_bar = wrestling_prompt.get_node("VBox/EnemyBar")
	var label: Label = wrestling_prompt.get_node("VBox/HBox/Label")
	label.text = "SMASH to %s!" % ("resist" if resisting else "subdue")
	
	ScreenText.show_middle_text([wrestling_prompt], BoxContainer.AlignmentMode.ALIGNMENT_CENTER, VerticalAlignment.VERTICAL_ALIGNMENT_TOP)
#endregion
