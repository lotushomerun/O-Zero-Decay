extends Status
class_name BadPhysiqueStatus

func _init() -> void:
	title = "Bad Physique"
	description = "You struggle with running and all forms of physical activity"
	icon = load("res://UI/Status/Icons/BadPhysique.png")
	infinite = true
	color = Red_Color

func on_add_status() -> void:
	super.on_add_status()
	if human == Player.this.character:
		Chatbox.important_message("[color=warning][b][i]Your body got weaker. You now have a bad physique.[/i][/b][/color]", Chatbox.ColorLib["warning"])

func on_remove_status() -> void:
	super.on_remove_status()
	if human == Player.this.character:
		Chatbox.important_message("[color=good][b][i]Your muscles have strengthened. You are back in shape.[/i][/b][/color]", Chatbox.ColorLib["good"])

func _on_add_status() -> void:
	super._on_add_status()
	human.stamina.exercise_changed.connect(self._on_exercise_changed)
	human.stamina.fatigue_changed.connect(self._on_fatigue_changed)
	
func _on_remove_status() -> void:
	super._on_remove_status()
	human.stamina.exercise_changed.disconnect(self._on_exercise_changed)
	human.stamina.fatigue_changed.disconnect(self._on_fatigue_changed)

func _on_exercise_changed(new: float, old: float) -> void:
	if new > old: human.stamina.exercising += (new - old) / 2.0 # We get additional exercise points (and thus get tired faster)

func _on_fatigue_changed(new: float, old: float) -> void:
	if new > old: human.stamina.fatigue += (new - old) / 2.0 # We get additional fatigue points
