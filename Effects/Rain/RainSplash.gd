@tool
extends TextureRect

@export var frames: Array[Texture2D] = []
@export var frame_delay: float = 0.1

var _current_frame: int = 0
var _timer: float = 0.0

func _process(delta: float) -> void:
	if frames.is_empty(): return
	_timer += delta
	if _timer >= frame_delay:
		_timer = 0.0
		_current_frame = (_current_frame + 1) % frames.size()
		texture = frames[_current_frame]
