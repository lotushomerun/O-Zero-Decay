@tool
extends Node2D
class_name Level

#region Save & Load
static func _load_items() -> void:
	#print("[SYSTEM]: Loading level items...")
	var tree := Engine.get_main_loop() as SceneTree
	var scene_path: String = tree.current_scene.scene_file_path
		
	# Get entity ids
	var level_items: Array = SaveState.get_level_items(scene_path)
	var destroyed_entities: Array = SaveState.get_destroyed_entities(scene_path)
	var moved_items: Array = SaveState.get_moved_items(scene_path)
	var inventory_entities: Array[String] = []
	var saved_entities: Array[String] = []
	var known_entities: Array[String] = []
	
	for data: Dictionary in level_items: if data["entity_id"] != null: saved_entities.append(data["entity_id"])
	for data: Dictionary in SaveState.get_inventory_items(): inventory_entities.append(data["entity_id"])
	
	known_entities.append_array(destroyed_entities)
	known_entities.append_array(moved_items)
	known_entities.append_array(inventory_entities)
	known_entities.append_array(saved_entities)
	
	# Delete all existing items outside of inventory
	for item in tree.get_nodes_in_group("SaveableItems"):
		if item is Item:
			if known_entities.has(item.entity_id): # Delete entities that we know of
				if !item.in_inventory: item.get_parent().queue_free()
	
	# Spawn items from saved data
	for data: Dictionary in level_items:
		var parent_scene_path: String = data["parent_scene"]
		var parent_instance: Node = load(parent_scene_path).instantiate()
		tree.current_scene.add_child(parent_instance)
		
		var item_ref: Item
		for node: Node in parent_instance.get_children():
			if node is Item:
				item_ref = node
				break
				
		item_ref.load_save_data(data)
	
static func _save_items() -> void:
	#print("[SYSTEM]: Saving level items...")
	var tree := Engine.get_main_loop() as SceneTree
	var items_array: Array = []
	
	for item in tree.get_nodes_in_group("SaveableItems"):
		if item is Item:
			if !item.in_inventory:
				items_array.append(item.get_save_data())
	
	SaveState.save_level_items(tree.current_scene.scene_file_path, items_array)
	
static func _load_player_inventory() -> void:
	#print("[SYSTEM]: Loading player inventory...")
	var tree := Engine.get_main_loop() as SceneTree
	var inventory_items: Array = SaveState.get_inventory_items()
	if inventory_items.size() > 0:
		
		# Spawn items from saved inventory data
		for data: Dictionary in inventory_items:
			var parent_scene_path: String = data["parent_scene"]
			var parent_instance: Node = load(parent_scene_path).instantiate()
			tree.current_scene.add_child(parent_instance)
			
			var item_ref: Item
			for node: Node in parent_instance.get_children():
				if node is Item:
					item_ref = node
					break
					
			item_ref.load_save_data(data)
			if !item_ref.is_equipped: Player.this.force_give_item(parent_instance) # Not equipped? Just take to inventory
			else:
				if item_ref is ClothesItem: Player.this.force_equip_clothes(parent_instance) # Put on clothes
				elif item_ref is BackpackItem: Player.this.force_equip_backpack(parent_instance) # Put on backpack
			
static func _save_player_inventory() -> void:
	#print("[SYSTEM]: Saving player inventory...")
	var items_array: Array = []
	for item in InventoryManager.inventory.items: items_array.append(item.get_save_data())
	SaveState.save_inventory_items(items_array)
	
static func _load_level() -> void:
	print("[SYSTEM]: Loading level...")
	var tree := Engine.get_main_loop() as SceneTree
	SaveState.unloading_level = false
	SaveState.loading_level = true
	_load_items()
	_load_player_inventory()
	await tree.process_frame # Wait a bit, otherwise loading_level resets for some reason... hhhnghh...
	SaveState._update_followers("", tree.current_scene.scene_file_path)
	SaveState.loading_level = false

static func _save_level() -> void:
	print("[SYSTEM]: Saving level...")
	_save_items()
	_save_player_inventory()
#endregion

#region Enter/Exit
func _ready() -> void:
	if Engine.is_editor_hint(): return # Stop code below from running in editor
	
	_bake_entity_ids() # Remember static ids
	SaveState.load_runtime()
	_load_level()
	TimeManager.add_minutes(0) # Init and show current time
	Weather.reload_weather() # Weather

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("[SYSTEM]: Closing the game...")
		SaveState.unloading_level = true
		SaveState.clear_runtime_state()
		#_save_level()
#endregion

#region Process
func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return # Stop code below from running in editor
	
	process_followers(delta)
	TimeManager._tick(delta)
	Weather._tick(delta)
#endregion

#region Transitions
static func change_level(level_path: String) -> void:
	await LevelTransitionEffect.fade(false, .33)
	_change_level(level_path)

static func _change_level(level_path: String) -> void:
	_save_level()
	SaveState.save_runtime()
	print("[SYSTEM]: Changing level...")
	SaveState.unloading_level = true
	var tree := Engine.get_main_loop() as SceneTree
	print("--------------------")
	tree.change_scene_to_file(level_path)
#endregion

#region Followers
func process_followers(delta: float) -> void:
	var followers = SaveState.get_followers()
	
	for f: Dictionary in followers:
		if f["path"].is_empty(): continue # No path? We're on the same level then, no need to process
		
		var next_level: String = f["path"][0]
		f["timers"][next_level] -= delta
		
		if f["timers"][next_level] <= 0: # We can go to the next level
			if next_level == scene_file_path: spawn_follower(f)
			f["current_level"] = next_level
			f["path"].pop_front()
			f["doors"].erase(next_level)
			f["timers"].erase(next_level)
				
	SaveState.save_data["player"]["followers"] = followers
	
func spawn_follower(data: Dictionary) -> void:
	var parent_scene_path: String = data["parent_scene"]
	var parent_instance: Node = load(parent_scene_path).instantiate()
	add_child(parent_instance)
	
	var char_ref: Char
	for node: Node in parent_instance.get_children():
		if node is Char:
			char_ref = node
			break
	
	char_ref.ai.behavior_tree.tree = load(data["behavior_tree_res"])
	char_ref.ai.behavior_tree.bb_set("target", Player.this.character)
	Door.position_at_door(char_ref, data["doors"][scene_file_path])
#endregion

#region EntityID
# You need to make the item have "Editable Children" checkmark in the scene file if you want it to get an ID, otherwise it won't save
@export_tool_button("Generate IDs") var generate_ids_button = _generate_ids_for_scene
var static_entity_ids: Array[String] = []

func _bake_entity_ids() -> void: # To know what items we spawn with via scene hierarchy tree (basically items that are static)
	for node: Node in Utils.get_all_children(self):
		if node is Item:
			if node.entity_id.length() > 0 && node.entity_id != "no_id":
				static_entity_ids.append(node.entity_id)

func _generate_ids_for_scene() -> void:
	if !Engine.is_editor_hint(): return
	
	var root = get_tree().edited_scene_root
	print("Generating IDs for scene: ", root.name)
	
	var all_nodes = Utils.get_all_children(root)
	for node in all_nodes:
		if node is Interactable && !node.entity_id:
			var unique_id: String = _generate_unique_id()
			node.entity_id = unique_id
			print("Generated ID (%s) for %s" % [unique_id, node.name])
			notify_property_list_changed()

func _generate_unique_id() -> String: return "%08x%08x" % [randi(), randi()]
#endregion
