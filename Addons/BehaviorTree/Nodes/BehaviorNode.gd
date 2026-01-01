extends Resource
class_name BehaviorNode

enum BehaviorStatus { SUCCESS, FAILURE, RUNNING }
@export var children: Array[BehaviorNode] = []
@export var saved_position: Vector2 = Vector2.ZERO
@export var custom_name: String = ""
@export var base_name: String = ""

func initialize(_owner, _blackboard) -> void: pass
func tick(_owner, _blackboard, _delta) -> BehaviorStatus: return BehaviorStatus.SUCCESS
