extends Node2D
class_name Rig

@export_group("Refs")
@export var skeleton: Skeleton2D
@export var head_tracker: HeadTracker
var head_tracker_default: Vector2

var facing_right: bool = true

func head_track_to(pos: Vector2) -> void:
	if (head_tracker == null):
		push_warning("Rig (Head Tracking): HeadTracker not found!")
		return
		
	head_tracker.target = pos

func flip_skeleton() -> void:
	if (skeleton == null):
		push_warning("Rig (Flip Skeleton): Skeleton2D not found!")
		return
		
	facing_right = !facing_right
	skeleton.scale = Vector2(skeleton.scale.x * -1, skeleton.scale.y)
