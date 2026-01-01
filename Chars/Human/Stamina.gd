extends Node
class_name Stamina

@export var character: Human
@export var movement: Movement

#region Process
func _process(delta: float) -> void:
	_process_exercise(delta)
	_process_breathing(delta)
	if Player.this.character == character: _process_heartbeat(delta)
#endregion

#region Stamina
const Sweating_Threshold_Base: float = 5.0 # After x exercise we start sweating
const Fatigue_Threshold_Base: float = 10.0 # After x exercise we start getting fatigue
const Exhausted_Threshold_Base: float = 10.0 # After x fatigue we can stand up again
const Faint_Threshold_Base: float = 20.0 # After x fatigue we fall over
const Sweating_Max: float = 60.0 # Just a max number to clamp
const Stunned_Max: float = 10.0 # In seconds

var fatigue: float = 0.0 # Robs us of running at some point
var sweating: float = 0.0 # We're sweating if it's greater than 0
var exercising: float = 0.0 # Our physical activity at the moment
var stunned: float = 0.0 # How stunned we are

signal fatigue_changed(new_value, old_value)
signal sweating_changed(new_value, old_value)
signal exercise_changed(new_value, old_value)
signal stunned_changed(new_value, old_value)

func add_stunned(n: float) -> void:
	var old: float = stunned
	stunned = clampf(stunned + n, 0.0, Stunned_Max)
	if stunned != old: emit_signal("stunned_changed", stunned, old)

func add_fatigue(n: float) -> void:
	var old: float = fatigue
	fatigue = clampf(fatigue + n, 0.0, Faint_Threshold_Base)
	if fatigue != old: emit_signal("fatigue_changed", fatigue, old)
	
func add_sweating(n: float) -> void:
	var old: float = sweating
	sweating = clampf(sweating + n, 0.0, Sweating_Max)
	if sweating != old: emit_signal("sweating_changed", sweating, old)
	
func add_exercise(n: float) -> void:
	var old: float = exercising
	exercising = clampf(exercising + n, 0.0, Fatigue_Threshold_Base)
	if exercising != old: emit_signal("exercise_changed", exercising, old)
	
func _process_exercise(delta: float) -> void:
	add_exercise(-delta)
	add_sweating(-delta)
	add_fatigue(-delta)
	add_stunned(-delta)
	
	if Player.this.character == character: FatigueEffect.set_fatigue(clampf(inverse_lerp(0.0, Faint_Threshold_Base, fatigue), 0.0, 1.0))
	
	if movement.is_sprinting(): add_exercise(delta * 2.0)
	if exercising >= Sweating_Threshold_Base: add_sweating(delta * 2.0)
	if exercising >= Fatigue_Threshold_Base: add_fatigue(delta * 2.0)
	
	if fatigue >= Faint_Threshold_Base && character.mobility == Char.Mobility.Full: # Go down, too tired
		if Player.this.character == character:
			Chatbox.important_message("[color=danger][b][i]Your legs give out, you can no longer move![/i][/b][/color]", Chatbox.ColorLib["danger"])
		character.actions.fall(false)
	
	if sweating > 0.0: # Sweat in our clothes
		var human_rig: HumanRig = character.rig as HumanRig
		human_rig.skin_dirtiness += delta * 0.001
		
		var datas: Array[ClothesData] = [human_rig.shirt_data, human_rig.socks_data]
		for data in datas:
			if data != null:
				data.add_dirtiness(delta * 0.002)
				data.add_wetness(delta * 0.02)
#endregion

#region Breathing
var breath_timer: float = 0.0
var breath_interval: float = 1.0
var breath_inhale_next: bool = true
var breathing_active: bool = false

func _process_breathing(delta: float) -> void:
	var tired := exercising >= Fatigue_Threshold_Base || fatigue > 0.0
	if tired && !breathing_active: breathing_active = true # START breathing if we crossed tired threshold
	
	if !breathing_active: return
	
	# STOP breathing only after finishing cycle (must exhale)
	if !tired:
		if breath_inhale_next:
			breathing_active = false
			return

	# Breathing still active here — update rate
	var t = inverse_lerp(Fatigue_Threshold_Base, Faint_Threshold_Base, fatigue)
	t = clamp(t, 0.0, 1.0)
	breath_interval = lerp(1.0, 0.66, t)

	# Tick timer
	breath_timer -= delta
	if breath_timer <= 0.0:
		if breath_inhale_next: _inhale()
		else: _exhale()
		breath_inhale_next = !breath_inhale_next
		breath_timer = breath_interval
		
func _inhale() -> void:
	SoundManager.play_sound_2d(SoundLib.inhale_sounds.pick_random(), character.global_position, -5.0)
	
func _exhale() -> void:
	SoundManager.play_sound_2d(SoundLib.exhale_sounds.pick_random(), character.global_position, -5.0)
	var human_rig: HumanRig = character.rig as HumanRig
	var steam: GPUParticles2D = FatigueEffect.steam_particles.instantiate() as GPUParticles2D
	human_rig.head_node.add_child(steam)
	steam.position = Vector2.ZERO
	steam.emitting = true
#endregion

#region Heartbeat
var heartbeat_timer: float = 0.0
var heartbeat_interval: float = 1.2
var heartbeat_active: bool = false
var heartbeat_phase: int = 0 # 0 beat, 1 pause

func _process_heartbeat(delta: float) -> void:
	var tired := fatigue >= Exhausted_Threshold_Base
	var aroused := character.sex.arousal >= .5
	var need_to_beat := tired || aroused
	
	if need_to_beat && !heartbeat_active:
		heartbeat_active = true
		heartbeat_phase = 0
		heartbeat_timer = 0.0
		
	if !need_to_beat && heartbeat_active:
		if heartbeat_phase == 1:
			heartbeat_active = false
			return
			
	if !heartbeat_active: return
	
	var t := inverse_lerp(Fatigue_Threshold_Base, Faint_Threshold_Base, fatigue)
	t = clamp(t, 0.0, 1.0)
	heartbeat_interval = lerp(0.77, 0.2, t)
	
	heartbeat_timer -= delta
	if heartbeat_timer <= 0.0:
		if heartbeat_phase == 0: Camera._do_heartbeat()
		heartbeat_phase = (heartbeat_phase + 1) % 2
		heartbeat_timer = heartbeat_interval
#endregion
