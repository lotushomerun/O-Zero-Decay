extends BehaviorNode
class_name BehaviorReturn

@export var is_failure: bool = false

func tick(_owner, _blackboard, _delta) -> BehaviorStatus:
	if is_failure: return BehaviorStatus.FAILURE
	else: return BehaviorStatus.SUCCESS
