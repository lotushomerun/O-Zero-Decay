extends Action
class_name OpenContainerAction

func _action_name() -> String: return "Open"

func _execute(params: Array[Variant]) -> void:
	if params.size() < 2:
		push_warning("OpenContainerAction: params.size() < 2!")
		super._execute(params)
		return
		
	var _character: Char = params[0]
	var container: ContainerObj = params[1]
	
	Chatbox.system_message("[color=info]You take a look inside the %s.[/color]" % [container.entity_name])
	
	container.inventory_container._give_items(InventoryManager.storage)
	InventoryManager.register_container(container)
	InventoryManager.show_inventory(InventoryManager.storage)
	InventoryManager.show_entries(InventoryManager.storage)
	super._execute(params)
