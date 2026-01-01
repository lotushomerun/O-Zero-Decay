extends Node
class_name Layering

const Item_Index := 99
const Min_Char_Index := 101
const Max_Char_Index := 3995
const Char_Layer_Size := 6
const Player_Index := 27
const Min_Sex_Index := 0
const Max_Sex_Index := 2

static var occupied_indices: Dictionary = {}
static var changed_z_nodes: Dictionary = {} # Node2D : int (node and its old index before it was changed)

static func get_z_index(i: int) -> int: return Min_Char_Index + int(Char_Layer_Size / 2.0) + i * (Char_Layer_Size + 1)

static func add_to_background(character: Char) -> void:
	sanitize_indices()
	for i in range(Player_Index - 1, Max_Sex_Index, -1):
		if !occupied_indices.has(i):
			set_char_index(character, i)
			return
			
static func add_to_foreground(character: Char) -> void:
	sanitize_indices()
	for i in range(Player_Index + 1, 100):
		if !occupied_indices.has(i):
			set_char_index(character, i)
			return
			
static func set_char_index(character: Char, index: int) -> void:
	sanitize_indices()
	if occupied_indices.has(index) && index > Max_Sex_Index: return
	
	free_char_index(character)
	character.z_index = get_z_index(index)
	
	if index > Max_Sex_Index: occupied_indices[index] = character
	
static func free_char_index(character: Char) -> void:
	for i in occupied_indices.keys().duplicate():
		if occupied_indices[i] == character:
			occupied_indices.erase(i)
			return

static func set_node_z(node: Node2D, target_z: int) -> void:
	changed_z_nodes[node] = node.z_index
	node.z_index = target_z
	
static func reset_node_z(node: Node2D) -> void:
	if changed_z_nodes.has(node):
		node.z_index = changed_z_nodes[node]
		changed_z_nodes.erase(node)
	else: node.z_index = 0 # Fallback
			
static func sanitize_indices() -> void:
	for i in changed_z_nodes.keys().duplicate(): if !is_instance_valid(i): changed_z_nodes.erase(i)
	for i in occupied_indices.keys().duplicate(): if !is_instance_valid(occupied_indices[i]): occupied_indices.erase(i)
