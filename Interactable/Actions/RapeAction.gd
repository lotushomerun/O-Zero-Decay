extends Action
class_name RapeAction

func _action_name() -> String: return "Rape"

func _execute(params: Array[Variant]) -> void:
	if params.size() < 2:
		push_warning("RapeAction: params.size() < 2!")
		super._execute(params)
		return

	var _character: Char = params[0]
	var thing: Interactable = params[1]
	var victim: Char = thing.get_parent()
	if victim.stamina.stunned <= 0:
		push_warning("RapeAction: victim is not stunned!")
		Chatbox.warning_message("[color=warning]Cannot violate %s. %s not stunned[/color]" % [TextManager.parse("you",victim),TextManager.parse("You are",victim,1)])
		super._execute(params)
		return
	elif victim.get_status("FuckedStatus") != null:
		push_warning("RapeAction: victim still has cooldown!")
		Chatbox.warning_message("[color=warning]Cannot violate %s. Please wait until %s cooldown period is over[/color]" % [TextManager.parse("you",victim),TextManager.parse("your",victim,1)])
		super._execute(params)
		return
	elif _character.get_status("FuckedStatus") != null:
		push_warning("RapeAction: violator still has cooldown!")
		Chatbox.warning_message("[color=warning]Cannot violate %s. Please wait until %s cooldown period is over[/color]" % [TextManager.parse("you",victim),TextManager.parse("your",_character,1)])
		super._execute(params)
		return
	
	Chatbox.header_message("[color=info]%s the unspeakable to %s...[/color]" % [TextManager.parse("You do",_character),TextManager.parse("you",victim)], Chatbox.ColorLib["info"])
	_character.sex.start_sex_with(victim, _character.rig.doggy_sex_tree, victim.rig.doggy_sex_tree)
	super._execute(params)
