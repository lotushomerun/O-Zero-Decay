extends TextureRect
class_name KeyIcon

var blinking: bool = true
@export var blinking_speed: float = 0.5
var blink_timer: float = 0.0
@export var key_string: String = "E"

static var Scene: PackedScene = load("res://UI/Keyboard/KeyIcon.tscn")
@onready var label: Label = $Label
@onready var key_icon: Texture2D = load("res://UI/Keyboard/KeyEmpty.png")
@onready var key_pressed_icon: Texture2D = load("res://UI/Keyboard/KeyPressed.png")

func _process(delta: float) -> void:
	if !blinking || !label: return
	label.text = key_string
	blink_timer = clampf(blink_timer - delta, 0.0, blinking_speed)
	if blink_timer <= 0.0:
		if texture == key_icon:
			texture = key_pressed_icon
			label.position.y = 4
		else:
			texture = key_icon
			label.position.y = 0
		blink_timer = blinking_speed
