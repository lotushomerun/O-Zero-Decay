extends Node

# level_states = {
#	"res://Levels/Level01/Level01.tscn": {
#		"items": [
#			{ ...state_dict... },
#			...
#		],
#	},
#}

var loading_level: bool = false # Are we currently loading a level???
var unloading_level: bool = false # Are we currently unloading a level?
var save_data: Dictionary = {
	"levels": {},
	"player": {},
	"world": {}
}

const RUNTIME_FILE: String = "user://runtime_state.json"
const SAVE_FILE_BASE: String = "user://save_"

func _ready() -> void:
	SexLib._init_sex_data()
	await get_tree().create_timer(0.1).timeout
	Player.this.random_loadout()
	#load_runtime()

#region Helpers
func _ensure_level_category(level_name: String, category: String) -> Array:
	if !save_data["levels"].has(level_name): save_data["levels"][level_name] = {}
	if !save_data["levels"][level_name].has(category): save_data["levels"][level_name][category] = []
	return save_data["levels"][level_name][category]
	
func remember_in_category(level_name: String, category: String, entity_id: String) -> void:
	var arr: Array = _ensure_level_category(level_name, category)
	if !arr.has(entity_id): arr.append(entity_id)
	save_data["levels"][level_name][category] = arr
	
func forget_in_category(level_name: String, category: String, entity_id: String) -> void:
	if !save_data["levels"].has(level_name): return
	if !save_data["levels"][level_name].has(category): return
	var arr: Array = save_data["levels"][level_name][category]
	if arr.has(entity_id): arr.erase(entity_id)
	save_data["levels"][level_name][category] = arr
	
func get_from_category(level_name: String, category: String) -> Array:
	if save_data["levels"].has(level_name) and save_data["levels"][level_name].has(category):
		return save_data["levels"][level_name][category]
	return []
#endregion

#region Entities
func remember_destroyed_entity(level_name: String, entity_id: String) -> void:
	remember_in_category(level_name, "destroyed_entities", entity_id)
	
func forget_destroyed_entity(level_name: String, entity_id: String) -> void:
	forget_in_category(level_name, "destroyed_entities", entity_id)
	
func get_destroyed_entities(level_name: String) -> Array:
	return get_from_category(level_name, "destroyed_entities")
#endregion

#region Items
func save_level_items(level_name: String, items_array: Array) -> void:
	if !save_data["levels"].has(level_name): save_data["levels"][level_name] = {}
	save_data["levels"][level_name]["items"] = items_array
	save_runtime()

func get_level_items(level_name: String) -> Array:
	if save_data["levels"].has(level_name) && save_data["levels"][level_name].has("items"): return save_data["levels"][level_name]["items"]
	return []
	
func save_inventory_items(items_array: Array) -> void:
	save_data["player"]["inventory"] = items_array
	save_runtime()
	
func get_inventory_items() -> Array:
	if save_data["player"].has("inventory"): return save_data["player"]["inventory"]
	return []
	
func remember_moved_item(level_name: String, entity_id: String) -> void:
	remember_in_category(level_name, "moved_items", entity_id)
	
func forget_moved_item(level_name: String, entity_id: String) -> void:
	forget_in_category(level_name, "moved_items", entity_id)
	
func get_moved_items(level_name: String) -> Array:
	return get_from_category(level_name, "moved_items")
#endregion

#region Player
func save_spawn_door(door_id: String) -> void:
	save_data["player"]["spawn_door_id"] = door_id
	save_runtime()
	
func get_spawn_door() -> String:
	if !save_data["player"].has("spawn_door_id"): return ""
	return save_data["player"]["spawn_door_id"]
#endregion

#region Followers
func _ensure_followers() -> void: if !save_data["player"].has("followers"): save_data["player"]["followers"] = []

func get_followers() -> Array:
	_ensure_followers()
	return save_data["player"]["followers"]
	
func add_follower(data: Dictionary) -> void:
	_ensure_followers()
	var follower: Dictionary = data
	
	if data.size() <= 0:
		push_warning("Empty follower data...")
		return
		
	save_data["player"]["followers"].append(follower)
	save_runtime()

func remove_follower(follower: Dictionary) -> void:
	_ensure_followers()
	var followers = save_data["player"]["followers"]
	if followers.has(follower): followers.erase(follower)
	save_data["player"]["followers"] = followers
	save_runtime()
	
func _update_followers(_prev_level: String, new_level: String) -> void: # Called when we travel levels, to update followers
	_ensure_followers()
	
	for f in save_data["player"]["followers"]: # Go through every follower
		if f["path"].has(new_level): # Already in the array? It means player is backtracking, remove extra paths
			var path: Array = f["path"]
			var index := path.find(new_level)
			var new_path := path.slice(0, index + 1)
			for key in f["timers"].keys(): if !new_path.has(key): f["timers"].erase(key)
			for key in f["doors"].keys(): if !new_path.has(key): f["doors"].erase(key)
			f["path"] = new_path
			continue
		
		if f["current_level"] == new_level: continue # Follower already there? (How did they get there first lol)
		
		f["path"].append(new_level)
		f["doors"][new_level] = save_data["player"]["spawn_door_id"]
		f["timers"][new_level] = _calculate_follower_travel_time(f["current_level"], new_level, f["speed"])
		
	save_runtime()

func _calculate_follower_travel_time(_from_level: String, _to_level: String, speed: float) -> float: return 10.0 / max(speed, 0.01)
#endregion

#region Runtime State
func save_runtime() -> void:
	#print("[SYSTEM]: Saving runtime state...")
	_save_to_file(RUNTIME_FILE)

func load_runtime() -> void:
	#print("[SYSTEM]: Loading runtime state...")
	_load_from_file(RUNTIME_FILE)
	
func clear_runtime_state() -> void:
	#print("[SYSTEM]: Clearing runtime state...")
	save_data = {
		"levels": {},
		"player": {},
		"world": {}
	}
	_save_to_file(RUNTIME_FILE)
#endregion

#region Game Saves
func save_game(slot: String) -> void:
	var path: String = SAVE_FILE_BASE + slot + ".json"
	_save_to_file(path)
	
func load_game(slot: String) -> void:
	var path: String = SAVE_FILE_BASE + slot + ".json"
	_load_from_file(path)
	
func delete_save(slot: String) -> void:
	var path := SAVE_FILE_BASE + slot + ".json"
	if !FileAccess.file_exists(path): return
	var dir := DirAccess.open("user://")
	if dir:
		var filename := "save_" + slot + ".json"
		var err := dir.remove(filename)
		if err != OK: push_error("Failed to delete save file: %s (error %s)" % [filename, err])
#endregion

#region File Management
func _save_to_file(path: String) -> void:
	var json_text := JSON.stringify(save_data, "\t")
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Couldn't open save file: %s" % path)
		return
		
	file.store_string(json_text)
	file.close()
	
func _load_from_file(path: String) -> void:
	if !FileAccess.file_exists(path): return
	
	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(content)
	if typeof(parsed) == TYPE_DICTIONARY: save_data = parsed
	else: push_warning("Save file corrupted (%s); keeping old save_data." % path)
#endregion
