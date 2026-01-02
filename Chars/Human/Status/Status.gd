extends Resource
class_name Status

const Green_Color: Color = Color("#59985e")
const Red_Color: Color = Color("#bd4949")

var title: Array[String] = ["Status"]
var description: Array[String] = ["Makes you think"]
var icon: Texture2D
var infinite: bool = false
var color: Color = Color.WHITE
var stage: int = 0

var ui_status: UIStatus
var human: Human
var seconds: int = 30

# Public (for showing messages and stuff, something that would happen if you got the status at spawn for example and not acquire it)
func on_add_status() -> void: pass
func on_stage_status(_int) -> void: pass
func on_remove_status() -> void: pass

# Private (technical part)
func _on_add_status() -> void: pass
func _on_stage_status(_int) -> void: pass
func _on_remove_status() -> void: pass

# Time related
func _tick(_delta: float) -> void: pass
func _second() -> void: # Always call super._second()
	if !infinite:
		seconds = clamp(seconds - 1, 0, INF)
		if is_instance_valid(ui_status) && ui_status.title_panel.visible: ui_status._update_timer()
		if seconds <= 0:
			if ui_status != null:
				ui_status._stop_blinking()
			human.remove_status(self)
