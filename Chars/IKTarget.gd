@tool
extends Node2D
class_name IKTarget

#region Exports
@export var switch_all: bool:
	get: return false
	set(value):
		enabled = !enabled
		for node in get_parent().get_children(): if node is IKTarget: node.enabled = enabled

@export var select_nodes: bool:
	get: return false
	set(value):
		if Engine.is_editor_hint() && value: _select_target_nodes()

@export var enabled: bool:
	get: return _enabled
	set(value):
		_enabled = value
		if bone1_end_path != null && bone1_end != null:
			global_position = bone1_end.global_position
			global_rotation = bone1_end.global_rotation

@export var joint_flip := false

@export var skeleton_path: NodePath:
	get: return _skeleton_path
	set(value):
		_skeleton_path = value
		skeleton = get_node_or_null(value)

@export var bone0_path: NodePath:
	get:
		return _bone0_path
	set(value):
		_bone0_path = value
		bone0 = get_node_or_null(value)

@export var bone1_path: NodePath:
	get:
		return _bone1_path
	set(value):
		_bone1_path = value
		bone1 = get_node_or_null(value)

@export var bone1_end_path: NodePath:
	get:
		return _bone1_end_path
	set(value):
		_bone1_end_path = value
		bone1_end = get_node_or_null(value)
#endregion

#region Vars
var _enabled: bool = false

var _skeleton_path: NodePath
var _bone0_path: NodePath
var _bone1_path: NodePath
var _bone1_end_path: NodePath

var skeleton: Node2D
var bone0: Bone2D
var bone1: Bone2D
var bone1_end: Node2D

var length1: float = 0.0
var length2: float = 0.0
#endregion

#region Ready
func _ready():
	skeleton = get_node_or_null(_skeleton_path)
	bone0 = get_node_or_null(_bone0_path)
	bone1 = get_node_or_null(_bone1_path)
	bone1_end = get_node_or_null(_bone1_end_path)
	
	if bone0 && bone1 && bone1_end:
		length1 = (bone0.global_position - bone1.global_position).length()
		length2 = (bone1.global_position - bone1_end.global_position).length()
#endregion

#region Helpers
func _select_target_nodes():
	var editor_sel = EditorInterface.get_selection()
	editor_sel.clear()
	
	var n1 = get_node_or_null(bone0_path)
	if n1: editor_sel.add_node(n1)
	
	var n2 = get_node_or_null(bone1_path)
	if n2: editor_sel.add_node(n2)
	
	var n3 = get_node_or_null(bone1_end_path)
	if n3: editor_sel.add_node(n3)

func _get_offset(start: Node2D, end: Node2D) -> float:
	var dir_next = (end.global_position - start.global_position).normalized()
	var y_vec = Vector2(0, 1).rotated(start.global_rotation).normalized()
	return y_vec.angle_to(dir_next)
	
func _normalize_angle(angle: float) -> float:
	angle = fmod(angle, TAU)
	if angle > PI: angle -= TAU
	if angle < -PI: angle += TAU
	return angle
#endregion

#region IK
func _process(_delta: float) -> void:
	if !Engine.is_editor_hint(): return
	if !bone0 || !bone1 || !bone1_end: return
	if !_enabled: return
	
	var root = bone0.global_position
	var target = global_position
	var mirror_sign := 1.0 if bone0.global_scale.y > 0.0 else -1.0
	
	var distance: float = root.distance_to(target)
	if distance > length1 + length2:
		var dir = (target - root).normalized()
		target = root + dir * (length1 + length2 - 0.01)
		
	var a: float = length1
	var b: float = length2
	var c: float = root.distance_to(target)
	
	var cos_angle: float = (a * a + c * c - b * b) / (2.0 * a * c)
	var angle: float = acos(clamp(cos_angle, -1.0, 1.0))
	
	var dir_to_target = (target - root).normalized()
	var flip_sign: float = (-1.0 if joint_flip == true else 1.0) * mirror_sign
	
	var bone1_dir: Vector2 = dir_to_target.rotated(angle * flip_sign)
	var bone1_pos: Vector2 = root + bone1_dir * length1
	var dir_to_bone1 = (bone1_pos - root).normalized()
	
	bone0.global_rotation = dir_to_bone1.angle() - PI * 0.5 - _get_offset(bone0, bone1)
	
	var raw_rot: float = (
		(target - bone1_pos).angle() * mirror_sign
		- (bone0.global_rotation * mirror_sign)
		- PI * 0.5
		- (_get_offset(bone1, bone1_end) * mirror_sign)
	)
	
	if mirror_sign < 0: raw_rot += deg_to_rad(180)
	
	var normalized: float = _normalize_angle(raw_rot)
	bone1.rotation = normalized
	
	bone1_end.global_rotation = global_rotation * mirror_sign
#endregion
