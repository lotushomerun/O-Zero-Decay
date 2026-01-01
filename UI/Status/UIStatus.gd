extends TextureRect
class_name UIStatus

@onready var title: Label = $TitlePanel/Margin/Title
@onready var desc: Label = $DescPanel/Margin/Desc
@onready var title_panel: PanelContainer = $TitlePanel
@onready var desc_panel: PanelContainer = $DescPanel
const Fade_Time: float = .25
const Min_Fade: float = 0.33
var status_data: Status
var status_manager: StatusManager
var blink_tween: Tween

func _setup(data: Status, manager: StatusManager) -> void:
	if !data:
		push_warning("UIStatus: No status data passed!")
		return
	
	data.ui_status = self # Write us down
	status_manager = manager
	status_data = data
	title.text = data.title[data.stage]
	desc.text = data.description[data.stage]
	texture = data.icon
	title_panel.modulate = data.color
	desc_panel.modulate = data.color
	
func _process(_delta: float) -> void:
	if !status_data.infinite:
		if status_data.seconds <= 10 && blink_tween == null: _start_blinking()
		elif status_data.seconds > 10 && blink_tween != null: _stop_blinking()
	
func _update_timer() -> void:
	if !status_data.infinite: title.text = status_data.title[status_data.stage] + " (%ds)" % [status_data.seconds]
	title.text = status_data.title[status_data.stage]
	desc.text = status_data.description[status_data.stage]

#region Blinking
func _start_blinking():
	_stop_blinking() # Just in case blinking was already present
	
	blink_tween = get_tree().create_tween()
	blink_tween.set_trans(Tween.TRANS_SINE)
	blink_tween.set_ease(Tween.EASE_IN_OUT)
	blink_tween.bind_node(self)
	blink_tween.set_loops()  # Infinite cycle
	
	blink_tween.tween_property(self, "modulate:a", 1.0, 0.4)
	blink_tween.tween_property(self, "modulate:a", Min_Fade, 0.4)
	
func _stop_blinking():
	if blink_tween: blink_tween.kill()
	blink_tween = null
	modulate.a = Min_Fade  # Back to min fade
#endregion

#region Mouse
func _on_icon_mouse_entered() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 1.0, Fade_Time)
	title_panel.show()
	desc_panel.show()
	_update_timer()

func _on_icon_mouse_exited() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", Min_Fade, Fade_Time)
	title_panel.hide()
	desc_panel.hide()
#endregion
