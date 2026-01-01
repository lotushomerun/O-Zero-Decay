extends Resource
class_name BehaviorTreeResource

@export var root: BehaviorOutput = BehaviorOutput.new()
@export var inactive_nodes: Array[BehaviorNode] = []
