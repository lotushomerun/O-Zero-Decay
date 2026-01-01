extends BehaviorNode
class_name BehaviorSelector

@export var ports: int = 1

func tick(owner, blackboard, delta) -> BehaviorStatus:
	if children.is_empty(): return BehaviorStatus.SUCCESS
		
	for child: BehaviorNode in children:
		if child == null: continue
		var status: BehaviorStatus = child.tick(owner, blackboard, delta)
		if status == BehaviorStatus.RUNNING: return BehaviorStatus.RUNNING
		if status == BehaviorStatus.SUCCESS: return BehaviorStatus.SUCCESS
		if status == BehaviorStatus.FAILURE: continue
		
	return BehaviorStatus.FAILURE
