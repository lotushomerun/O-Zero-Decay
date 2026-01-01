extends Bone2D
class_name HeadTracker

@export var rig: Rig
@export var max_up_degrees: float = -33.0
@export var max_down_degrees: float = 33.0
@export var turn_speed: float = 8.0
var target: Vector2 = Vector2.ZERO
var default_degrees: float

func _ready() -> void: default_degrees = rotation_degrees

func get_look_at_degrees(from: Vector2, to: Vector2) -> float: return (to - from).angle() * 180.0 / PI

func _process(delta: float) -> void:
	if rig == null: return
	
	var target_degrees: float = get_look_at_degrees(global_position, target)
	if !rig.facing_right: target_degrees = -get_look_at_degrees(target, global_position)
	if target == Vector2.ZERO: target_degrees = default_degrees
	
	var clamped_degrees = clampf(target_degrees, max_up_degrees, max_down_degrees)
	var lerped_degrees = lerp(rotation_degrees, clamped_degrees, delta * turn_speed)
	rotation_degrees = lerped_degrees
