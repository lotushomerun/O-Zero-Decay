extends MarginContainer
class_name StatusManager

@export var ui_status_scene: PackedScene
@onready var h_box: HBoxContainer = $HBox
var ui_statuses: Array[UIStatus] = []
var tracked_statuses: Array[Status] = []

func _process(_delta: float) -> void:
	var player_char: Human = Player.this.character as Human
	for status: Status in player_char.statuses: if !tracked_statuses.has(status): track_status(status)

func track_status(status: Status) -> void:
	tracked_statuses.append(status)
	var new_status: UIStatus = ui_status_scene.instantiate() as UIStatus
	h_box.add_child(new_status)
	new_status._setup(status, self)
	
func remove_status(status: UIStatus) -> void:
	tracked_statuses.erase(status.status_data)
	ui_statuses.erase(status)
	status.queue_free()
