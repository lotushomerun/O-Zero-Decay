extends Button
class_name ContextButton

var action: Action
var interactable: Interactable
var interactor: Char

func _on_pressed() -> void:
	SoundManager.play_sound_ui(SoundLib.ui_click_sound, -20.0)
	action._execute([interactor, interactable])

func _on_mouse_entered() -> void:
	if !disabled: SoundManager.play_sound_ui(SoundLib.ui_hover_sound, -10.0)
