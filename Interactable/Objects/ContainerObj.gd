extends Interactable
class_name ContainerObj

@export_group("Nodes")
@export var inventory_container: InventoryContainer

func _ready() -> void:
	super._ready()
	actions.append(OpenContainerAction.new())
