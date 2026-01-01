extends Char
class_name Human

#region Refs
@export_group("Refs")
@export var char_data: CharData
@export var stamina: Stamina
@export var combat: Combat
@export var actions: Actions
@export var sex: Sex

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sitting_shape: CollisionShape2D = $SittingShape
@onready var laying_shape: CollisionShape2D = $LayingShape
@onready var attack_area: Area2D = $HumanRig/Skeleton2D/AttackArea
#endregion

#region Statuses
var statuses: Array[Status] = []
var _status_second_timer := 0.0

func add_status(status: Status) -> void:
	status.on_add_status()
	_add_status(status)
	
func remove_status(status: Status) -> void:
	status.on_remove_status()
	_remove_status(status)
	
func has_status(status_class: String) -> bool:
	for i in range(statuses.size()):
		var a = statuses[i]
		if a && str(a.get_script().get_global_name()) == status_class: return true
	return false
	
func _add_status(status: Status) -> void:
	if status in statuses: return
	status.human = self
	status._on_add_status()
	statuses.append(status)
	
func _remove_status(status: Status) -> void:
	status._on_remove_status()
	statuses.erase(status)
	if is_instance_valid(status.ui_status): status.ui_status.status_manager.remove_status(status.ui_status) # Delete UI icon
	
func _process_statuses(delta: float) -> void:
	for status in statuses: status._tick(delta)
	
	_status_second_timer += delta
	if _status_second_timer >= 1.0:
		_status_second_timer = 0.0
		for status in statuses: status._second()
#endregion

#region Ready
func _ready() -> void:
	super._ready()
	var human_rig: HumanRig = rig
	
	if char_data == null:
		var random_data = CharData.new()
		var archetypes = CharData.Archetype.values()
		var archetype: CharData.Archetype = archetypes[randi() % archetypes.size()]
		
		#var archetype_name = CharData.Archetype.keys()[archetype]
		#print(archetype_name)
		
		random_data.randomize_me(archetype)
		char_data = random_data
	
	human_rig.load_appearance(char_data)
	
	# Statuses
	if char_data.body_height != CharData.Height.MEDIUM:
		if char_data.body_height == CharData.Height.SHORT: _add_status(ShortStatus.new())
		else: _add_status(TallStatus.new())
		
	if char_data.body_weight >= 0.85: _add_status(HeavyStatus.new())
	elif char_data.body_weight <= 0.25: _add_status(SkinnyStatus.new())
	
	if char_data.male_genitals:
		if randf() <= .5:
			if randf() <= .5: _add_status(BigPenisStatus.new())
			else: _add_status(SmallPenisStatus.new())
	
	#_add_status(BadPhysiqueStatus.new())
	
	human_rig._copy_droplets_shape(collision_shape_2d)
	interactable._copy_collision_shape(collision_shape_2d)
#endregion

#region Process
func _process(delta: float) -> void:
	super._process(delta)
	_process_statuses(delta)
	Weather._process_weather(self, delta)
#endregion

#region Animations
const MoveIdleTransitionSpeed: float = 6.66
const MoveBackwardsTransitionSpeed: float = 10.0

var use_body_lean: bool = true
enum AnimActions { None, LayOnBack, LayToButt, OnButt, StandFromButt,
					LayOnFront, LayToKnees, OnKnees, StandFromKnees,
					IdleToKnees, IdleToButt, Lunge, Shove, Wrestling, }
					
var anim_action: AnimActions = AnimActions.None

func animate(delta: float) -> void:
	super.animate(delta)
	
	var human_rig: HumanRig = rig
	var movement_tree: AnimationTree = human_rig.movement_tree
	
	# Movement
	var move_blend: float = movement_tree.get("parameters/MoveBlend/blend_amount")
	var move_time_scale: float = movement_tree.get("parameters/MoveTimeScale/scale")
	
	var idle_float: float = -1.0
	var walk_float: float = 0.0
	var run_float: float = 1.0
	
	if (mobility == Char.Mobility.Full): # We're able to move freely so animate us
		if (movement.is_moving()):
			if (movement.is_sprinting()): movement_tree.set("parameters/MoveBlend/blend_amount", lerpf(move_blend, run_float, delta * MoveIdleTransitionSpeed))
			else: movement_tree.set("parameters/MoveBlend/blend_amount", lerpf(move_blend, walk_float, delta * MoveIdleTransitionSpeed))
			
			# Walking backwards or forward
			var target_move_time_scale: float = (-.66 if movement.is_moving_backwards() else 1.0)
			movement_tree.set("parameters/MoveTimeScale/scale", lerpf(move_time_scale, target_move_time_scale, delta * 10))
			
		else:
			movement_tree.set("parameters/MoveTimeScale/scale", lerpf(move_time_scale, 1.0, delta * 10))
			movement_tree.set("parameters/MoveBlend/blend_amount", lerpf(move_blend, idle_float, delta * MoveIdleTransitionSpeed))
	
	# Look lean
	if use_body_lean:
		var head_tracker: HeadTracker = human_rig.head_tracker
		var rotation_normalized: float = (head_tracker.rotation_degrees - head_tracker.max_up_degrees) / (head_tracker.max_down_degrees - head_tracker.max_up_degrees) * 2.0 - 1.0
		rotation_normalized = clamp(rotation_normalized, -1, 1)
		movement_tree.set("parameters/LeanBlend/add_amount", rotation_normalized)
		
func _reset_blends() -> void:
	var human_rig: HumanRig = rig
	var movement_tree: AnimationTree = human_rig.movement_tree
	
	# Reset these to avoid jerkiness when going back to mobility (animate() lerps your shit)
	movement_tree.set("parameters/MoveBlend/blend_amount", -1.0)
	movement_tree.set("parameters/MoveTimeScale/scale", 1.0)
	movement_tree.set("parameters/LeanBlend/add_amount", 0.0)
#endregion

#region Mobility
func _try_half_mobile_move() -> void:
	if stamina.stunned > 0.0: return # We're stunned!
	if stamina.fatigue >= Stamina.Exhausted_Threshold_Base: return # Can't do shit, too exhausted
	if anim_action == AnimActions.LayOnBack: actions.lay_to_butt()
	elif anim_action == AnimActions.OnButt: actions.stand_from_butt()
	elif anim_action == AnimActions.LayOnFront: actions.lay_to_knees()
	elif anim_action == AnimActions.OnKnees: actions.stand_from_knees()
#endregion
