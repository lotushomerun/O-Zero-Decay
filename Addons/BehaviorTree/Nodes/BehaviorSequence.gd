extends BehaviorNode
class_name BehaviorSequence

@export var ports: int = 1

func tick(owner, blackboard, delta) -> BehaviorStatus:
	if children.is_empty(): return BehaviorStatus.SUCCESS
		
	for child: BehaviorNode in children:
		if child == null: continue
		var status: BehaviorStatus = child.tick(owner, blackboard, delta)
		if status == BehaviorStatus.RUNNING: return BehaviorStatus.RUNNING
		if status == BehaviorStatus.FAILURE: return BehaviorStatus.FAILURE
		
	return BehaviorStatus.SUCCESS
