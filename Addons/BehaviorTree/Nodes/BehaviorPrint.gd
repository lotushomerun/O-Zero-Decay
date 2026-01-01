extends BehaviorNode
class_name BehaviorPrint

@export var message: String = "Hello from BehaviorPrint!"

func tick(owner, blackboard, delta) -> BehaviorStatus:
	var msg = message
	for key in blackboard.keys(): msg = msg.replace("{" + str(key) + "}", str(blackboard[key]))
	print(msg)
	
	if children.is_empty(): return BehaviorStatus.SUCCESS
	else:
		var child: BehaviorNode = children[0]
		var status: BehaviorStatus = child.tick(owner, blackboard, delta)
		return status
		
