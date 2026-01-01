extends Label
func _process(_delta: float) -> void:
	var fps: int = round(Engine.get_frames_per_second())
	set_text("FPS: " + str(fps))
