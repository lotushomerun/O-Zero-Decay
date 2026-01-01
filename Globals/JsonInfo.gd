extends Node

#region Ready
func _ready(): load_names()
#endregion

#region Names
var Names: Dictionary = {}

func load_names():
	var path := "res://Data/Names.json"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var data := file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(data)
			if parsed is Dictionary: Names = parsed
			else: push_error("Failed to parse JSON: " + str(parsed))
		else: push_error("Cannot open %s" % path)
	else: push_error("%s not found!" % path)
	
func get_random_name(gender: String) -> String:
	if Names.has(gender):
		var arr = Names[gender]
		if arr.size() > 0: return arr[randi() % arr.size()]
	return "Unknown"
#endregion
