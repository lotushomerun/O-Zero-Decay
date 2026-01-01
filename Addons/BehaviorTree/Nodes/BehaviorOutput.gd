extends BehaviorNode
class_name BehaviorOutput

func tick(owner, blackboard, delta) -> BehaviorStatus:
	if children.size() == 0: return BehaviorStatus.SUCCESS
	return children[0].tick(owner, blackboard, delta)
