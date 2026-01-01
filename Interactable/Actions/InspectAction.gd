extends Action
class_name InspectAction

func _action_name() -> String: return "Inspect"

func _execute(params: Array[Variant]) -> void:
	if params.size() < 2:
		push_warning("InspectAction: params.size() < 2!")
		super._execute(params)
		return
		
	var _character: Char = params[0]
	var interactable: Interactable = params[1]
	
	Chatbox.header_message("[color=info]You take a closer look at %s...[/color]" % interactable.entity_name, Chatbox.ColorLib["info"])
	Chatbox.regular_message("[i][color=info]%s[/color][/i]" % interactable.entity_desc)
	super._execute(params)
