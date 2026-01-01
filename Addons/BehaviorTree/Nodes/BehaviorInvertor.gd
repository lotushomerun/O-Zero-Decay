extends BehaviorNode
class_name BehaviorInvertor

func tick(owner, blackboard, delta) -> BehaviorStatus:
	if children[0] == null: return BehaviorStatus.FAILURE
	
	var child: BehaviorNode = children[0]
	var status: BehaviorStatus = child.tick(owner, blackboard, delta)
	
	match status:
		BehaviorStatus.SUCCESS: return BehaviorStatus.FAILURE
		BehaviorStatus.FAILURE: return BehaviorStatus.SUCCESS
		BehaviorStatus.RUNNING: return BehaviorStatus.RUNNING
	
	return BehaviorStatus.FAILURE
