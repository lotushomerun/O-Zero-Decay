extends BehaviorNode
class_name BehaviorSubTree

@export var tree_resource: BehaviorTreeResource

func tick(owner, blackboard, delta) -> BehaviorStatus:
	if tree_resource == null || tree_resource.root == null:
		if children.size() > 0: return children[0].tick(owner, blackboard, delta)
		return BehaviorStatus.SUCCESS
		
	var result: BehaviorStatus = tree_resource.root.tick(owner, blackboard, delta)
	if children.size() > 0: return children[0].tick(owner, blackboard, delta)
	
	return result
