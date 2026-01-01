extends MarginContainer
class_name Chatbox

static var vbox: VBoxContainer = null
static var message_scene: PackedScene = null
const Message_Label = preload("res://UI/Chatbox/Chatlog.tscn")
static var Max_Messages := 20
static var Min_Alpha := 0.2

func _ready() -> void:
	register_vbox($VBox)
	register_message_scene(Message_Label)

#region Registering
static func register_vbox(node: VBoxContainer) -> void: vbox = node
static func register_message_scene(scene: PackedScene) -> void: message_scene = scene
#endregion

#region Messages
static func send_message(text: String, underscore_show: bool = false, underscore_color: Color = Color.WHITE):
	if !vbox || !message_scene:
		push_warning("ChatBox: not initialized (vbox or scene missing)")
		return
	
	# Message limit
	if vbox.get_child_count() >= Max_Messages:
		var old = vbox.get_child(0)
		vbox.remove_child(old)
		old.queue_free()
		
	var msg = message_scene.instantiate() as Chatlog
	vbox.add_child(msg)
	text = replace_color_names(text)
	msg.init_chatlog(text, underscore_show, underscore_color)
	_update_alpha_fade()
	
static func _update_alpha_fade() -> void:
	var count := vbox.get_child_count()
	if count == 0: return
	
	for i in range(count):
		var child := vbox.get_child(i)
		
		var fake_index := float(i + (Max_Messages - count))
		fake_index = clamp(fake_index, 0, Max_Messages - 1)
		
		var alpha: float = lerp(Min_Alpha, 1.0, fake_index / float(Max_Messages - 1))
		var c: Color = child.modulate
		c.a = alpha
		child.modulate = c
		
static func regular_message(text: String) -> void: send_message(text)

static func system_message(text: String) -> void:
	var color_tag := _get_first_color_tag(text)
	if color_tag != "": send_message(color_tag + "•[/color] " + text)
	else: send_message("• " + text)
	
static func warning_message(text: String) -> void:
	SoundManager.play_sound_ui(SoundLib.ui_cancel_sound, -20.0)
	var color_tag := _get_first_color_tag(text)
	if color_tag != "": send_message(color_tag + "•[/color] " + text)
	else: send_message("• " + text)

static func important_message(text: String, color: Color = Color.WHITE) -> void:
	if !_previous_is_blank(): blank_message()
	send_message(text, true, color)
	blank_message()
	
static func header_message(text: String, color: Color = Color.WHITE) -> void:
	if !_previous_is_blank(): blank_message()
	send_message(text, true, color)
	
static func blank_message() -> void: send_message(" ")

static func _previous_is_blank() -> bool:
	var count := vbox.get_child_count()
	if count == 0: return true # Previous one doesn't exist so its blank
	var last_msg := vbox.get_child(count - 1)
	if last_msg is Chatlog: return last_msg.text.strip_edges() == ""
	return false
#endregion

#region Color Lib
static var ColorLib := {
	"danger": Color(0.84, 0.143, 0.224, 1.0),
	"warning": Color(0.88, 0.421, 0.114, 1.0),
	"romantic": Color(0.631, 0.248, 0.69, 1.0),
	"erotic": Color(0.91, 0.41, 0.618, 1.0),
	"lucky": Color(0.13, 0.638, 0.251, 1.0),
	"good": Color(0.168, 0.328, 0.7, 1.0),
	"finances": Color(0.82, 0.604, 0.008, 1.0),
	"creepy": Color(0.501, 0.386, 0.773, 1.0),
	"info": Color(0.405, 0.405, 0.405, 1.0),
}

static func replace_color_names(text: String) -> String:
	var re := RegEx.new()
	re.compile(r"\[color=['\"]?([a-zA-Z]+)['\"]?\]") # look for [color=name]
	var result := text
	for match in re.search_all(text):
		var n := match.get_string(1).to_lower()
		if ColorLib.has(n):
			var c := ColorLib[n] as Color
			var hex := "#" + c.to_html(false) # convert to hex
			result = result.replace(match.get_string(0), "[color=" + hex + "]")
	return result
	
static func _get_first_color_tag(text: String) -> String:
	var start := text.find("[color=")
	if start == -1: return ""
	var end := text.find("]", start)
	if end == -1: return ""
	return text.substr(start, end - start + 1)
#endregion
