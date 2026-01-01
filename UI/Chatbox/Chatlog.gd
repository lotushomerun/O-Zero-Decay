extends RichTextLabel
class_name Chatlog

@export var underscore: TextureRect
const Max_Length := 80

func init_chatlog(txt: String, underscore_show: bool = false, underscore_color: Color = Color.WHITE) -> void:
	var max_len := Max_Length
	
	var visible_count := 0
	var index := 0
	var last_space_index := -1
	var open_tags := []
	var cut_index := 0
	
	while index < txt.length():
		if txt[index] == "[":
			var close_bracket := txt.find("]", index)
			if close_bracket == -1: break
			var tag := txt.substr(index, close_bracket - index + 1)
			if tag.begins_with("[/"):
				if open_tags.size() > 0 and open_tags[-1] == tag.replace("/", ""): open_tags.pop_back()
			else: open_tags.append(tag)
			index = close_bracket + 1
		else:
			if txt[index] == " ": last_space_index = index
			index += 1
			visible_count += 1
			
		if visible_count >= max_len: break
		
	cut_index = index
	
	if cut_index < txt.length():
		if last_space_index != -1: cut_index = last_space_index + 1
		else: cut_index = index
	
		var head := txt.substr(0, cut_index).strip_edges()
		text = head
		
		var tail := txt.substr(cut_index, txt.length() - cut_index).lstrip(" ")
		var prefix := ""
		for tag in open_tags: prefix += tag
		tail = prefix + tail
		
		Chatbox.send_message(tail, underscore_show, underscore_color)
	else: text = txt.strip_edges()

	# Underscore
	underscore.visible = underscore_show
	underscore.modulate = underscore_color
