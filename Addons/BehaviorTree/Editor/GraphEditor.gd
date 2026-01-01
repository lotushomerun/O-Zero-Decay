@tool
extends Control

@onready var graph: GraphEdit = $GraphEdit
var current_tree: BehaviorTreeResource
var selected_nodes: Array[BehaviorNode] = []
var gnode_map: Dictionary = {} # Runtime map: BehaviorNode -> GraphNode
var parent_map: Dictionary = {} # key is child_node, value is parent_node

#region Colors
const Regular_Color: Color = Color(1.0, 1.0, 1.0, 1.0)
const Output_Color: Color = Color(0.8, 0.3, 0.3)
const Print_Color: Color = Color(0.6, 0.6, 0.6)
#endregion

#region Ready
func _ready() -> void:
	spawn_menu.id_pressed.connect(_on_spawn_menu_selected)
	graph.connect("connection_request", Callable(self, "_on_connection_request"))
	graph.connect("disconnection_request", Callable(self, "_on_disconnection_request"))
	graph.connect("gui_input", Callable(self, "_on_graph_gui_input"))
#endregion

#region Edit
func edit(tree: BehaviorTreeResource) -> void:
	selected_nodes = []
	current_tree = tree
	_clear_graph()
	
	if !tree: return
	if !tree.root: tree.root = BehaviorOutput.new()
	
	_restore_parents(tree.root) # Active connected nodes
	for inactive: BehaviorNode in current_tree.inactive_nodes: parent_map[inactive] = null # Base inactive nodes don't have parents
	for node: BehaviorNode in tree.inactive_nodes: _restore_parents(node) # Nested inactive nodes DO have parents
	
	_add_node_recursive(tree.root, Vector2(0, 0))
	for node: BehaviorNode in tree.inactive_nodes: _add_node_recursive(node, node.saved_position)
	
	_rebuild_connections(tree.root)
	for inactive: BehaviorNode in current_tree.inactive_nodes: _rebuild_connections(inactive)
	
#endregion

#region Input
func _on_graph_gui_input(event) -> void:
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_RIGHT && event.pressed:
		var global_mouse = event.global_position
		right_click_pos = event.position + graph.get_scroll_offset()
		spawn_menu.position = global_mouse + Spawn_Menu_Offset
		load_spawn_options()
		spawn_menu.popup()
		
func _can_drop_data(_pos: Vector2, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY: return false
	if data.has("files") and data["files"].size() > 0:
		var path = data["files"][0]
		return path.ends_with(".tres")
	return false
	
func _drop_data(_pos: Vector2, data) -> void:
	for node in graph.get_children():
		if node is GraphNode:
			var rect = node.get_global_rect()
			if rect.has_point(get_global_mouse_position()):
				var behavior: BehaviorNode = node.get_meta("resource")
				_drop_data_onto(behavior, node, data)
				break
				
func _drop_data_onto(behavior: BehaviorNode, gnode: GraphNode, data) -> void:
	if data.has("files") and data["files"].size() > 0:
		var path = data["files"][0]
		if !path.ends_with(".tres"): return
		
		var res = ResourceLoader.load(path)
		if res && res is BehaviorTreeResource && behavior is BehaviorSubTree:
			behavior.tree_resource = res
			var label: Label = gnode.get_node("HBox/Path")
			label.text = res.resource_path

func _on_node_selected(node: BehaviorNode) -> void: selected_nodes.append(node)
func _on_node_deselected(node: BehaviorNode) -> void: if selected_nodes.has(node): selected_nodes.erase(node)
func _on_node_position_changed() -> void:
	for node: BehaviorNode in selected_nodes:
		var gnode: GraphNode = gnode_map.get(node, null)
		if is_instance_valid(gnode): node.saved_position = gnode.position_offset
#endregion

#region Spawn Menu
@onready var spawn_menu: PopupMenu = $SpawnMenu
var right_click_pos: Vector2 = Vector2.ZERO
const Spawn_Menu_Offset: Vector2 = Vector2(0, -16)
const Spawnable_Nodes: Dictionary = {
	"BehaviorPrint": "res://Addons/BehaviorTree/Nodes/BehaviorPrint.gd",
	"BehaviorCondition": "res://Addons/BehaviorTree/Nodes/BehaviorCondition.gd",
	"BehaviorSequence": "res://Addons/BehaviorTree/Nodes/BehaviorSequence.gd",
	"BehaviorSelector": "res://Addons/BehaviorTree/Nodes/BehaviorSelector.gd",
	"BehaviorInvertor": "res://Addons/BehaviorTree/Nodes/BehaviorInvertor.gd",
	"BehaviorReturn": "res://Addons/BehaviorTree/Nodes/BehaviorReturn.gd",
	"BehaviorCall": "res://Addons/BehaviorTree/Nodes/BehaviorCall.gd",
	"BehaviorSubTree": "res://Addons/BehaviorTree/Nodes/BehaviorSubTree.gd",
}
const Node_Scenes: Dictionary = {
	"BehaviorOutput": "res://Addons/BehaviorTree/Editor/OutputNode.tscn",
	"BehaviorPrint": "res://Addons/BehaviorTree/Editor/PrintNode.tscn",
	"BehaviorCondition": "res://Addons/BehaviorTree/Editor/ConditionNode.tscn",
	"BehaviorSequence": "res://Addons/BehaviorTree/Editor/SequenceNode.tscn",
	"BehaviorSelector": "res://Addons/BehaviorTree/Editor/SelectorNode.tscn",
	"BehaviorInvertor": "res://Addons/BehaviorTree/Editor/InvertNode.tscn",
	"BehaviorReturn": "res://Addons/BehaviorTree/Editor/ReturnNode.tscn",
	"BehaviorCall": "res://Addons/BehaviorTree/Editor/CallNode.tscn",
	"BehaviorSubTree": "res://Addons/BehaviorTree/Editor/SubTreeNode.tscn",
}

func load_spawn_options() -> void:
	spawn_menu.clear()
	var i := 0
	
	if selected_nodes.size() > 0:
		for node: BehaviorNode in selected_nodes: if is_instance_valid(node) && node.get_script().get_global_name() == "BehaviorOutput": return
		spawn_menu.add_item("Delete", i)
		spawn_menu.add_item("Rename", i + 1)
		return
	
	for n: String in Spawnable_Nodes.keys():
		spawn_menu.add_item(n, i)
		i += 1

func _on_spawn_menu_selected(id: int) -> void:
	var type_name = spawn_menu.get_item_text(id)
	
	if type_name == "Delete":
		var to_delete := selected_nodes.duplicate()
		var parent_snapshot := parent_map.duplicate()
		for node in to_delete: if node != current_tree.root: _delete_node(node, to_delete, parent_snapshot)
		return
		
	if type_name == "Rename":
		_start_rename_selected_node()
		return
	
	var script_path = Spawnable_Nodes[type_name]
	var script = ResourceLoader.load(script_path)
	var new_node: BehaviorNode = script.new()
	
	call_deferred("_add_to_inactive", new_node)
	_add_node_recursive(new_node, right_click_pos)
#endregion

#region Node Management
func _add_node_recursive(node: BehaviorNode, pos: Vector2) -> GraphNode:
	var scene_path = Node_Scenes[node.get_script().get_global_name()]
	var gnode: GraphNode = load(scene_path).instantiate()
	graph.add_child(gnode)
	
	gnode.position_offset = pos
	node.saved_position = pos
	
	node.base_name = gnode.title
	_update_node_name(gnode, node)
	
	gnode.set_meta("resource", node)
	gnode.connect("node_selected", Callable(self, "_on_node_selected").bind(node))
	gnode.connect("node_deselected", Callable(self, "_on_node_deselected").bind(node))
	gnode.connect("position_offset_changed", Callable(self, "_on_node_position_changed"))
	_attach_unique_signals(gnode, node)
	
	gnode_map[node] = gnode
	
	# For visual coolness
	var hbox: HBoxContainer = gnode.get_titlebar_hbox()
	var label: Label = hbox.get_child(0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Add children
	for i in node.children.size():
		var child: BehaviorNode = node.children[i]
		_add_node_recursive(child, child.saved_position)
		
	return gnode
	
func _delete_node(node: BehaviorNode, to_delete: Array, parent_snapshot: Dictionary) -> void:
	if node == current_tree.root: return
	var parent: BehaviorNode = parent_snapshot.get(node, null)
	
	if parent is BehaviorCondition:
		if node == parent.true_node: parent.true_node = null
		elif node == parent.false_node: parent.false_node = null

	var children_copy := node.children.duplicate()
	for child in children_copy:
		if to_delete.has(child): continue
		_add_to_inactive(child)
		
	if parent && !to_delete.has(parent):
		call_deferred("_remove_from_children", node, parent)
		_rebuild_connections(parent)
	else: call_deferred("_remove_from_inactive", node)

	# graph node
	var gnode = gnode_map.get(node, null)
	if gnode:
		graph.remove_child(gnode)
		gnode.call_deferred("queue_free")
		gnode_map.erase(node)

	selected_nodes.erase(node)
	
func _restore_parents(node: BehaviorNode) -> void:
	for child in node.children:
		parent_map[child] = node
		_restore_parents(child)

func _clear_graph() -> void:
	for child in graph.get_children().duplicate():
		if child is GraphNode:
			graph.remove_child(child)
			child.call_deferred("queue_free")
	gnode_map.clear()

func _remove_from_inactive(node: BehaviorNode) -> void:
	var temp: Array[BehaviorNode] = current_tree.inactive_nodes.duplicate()
	temp.erase(node)
	current_tree.inactive_nodes = temp

func _add_to_inactive(node: BehaviorNode) -> void:
	var temp: Array[BehaviorNode] = current_tree.inactive_nodes.duplicate()
	temp.append(node)
	current_tree.inactive_nodes = temp
	
func _remove_from_children(node: BehaviorNode, parent: BehaviorNode) -> void:
	var temp_children = parent.children.duplicate()
	temp_children.erase(node)
	parent.children = temp_children
	parent_map[node] = null
	
func _add_to_children(node: BehaviorNode, parent: BehaviorNode, index: int = -1) -> void:
	var temp_children = parent.children.duplicate()
	
	if index >= 0:
		temp_children.erase(node)
		if index >= temp_children.size(): temp_children.append(node)
		else: temp_children.insert(index, node)
	else:
		if !temp_children.has(node): temp_children.append(node)
		
	parent.children = temp_children
	parent_map[node] = parent
	
func _start_rename_selected_node():
	if selected_nodes.is_empty(): return
	
	var node: BehaviorNode = selected_nodes[0]
	var gnode: GraphNode = gnode_map.get(node, null)
	if gnode == null: return
	
	var line_edit := LineEdit.new()
	graph.add_child(line_edit)
	
	line_edit.text = node.custom_name
	line_edit.expand_to_text_length = true
	line_edit.position = gnode.position + Vector2(0, -32)
	
	line_edit.grab_focus()
	line_edit.select_all()
	
	line_edit.connect("text_submitted", Callable(self, "_finish_rename").bind(node, gnode, line_edit))
	line_edit.connect("focus_exited", Callable(self, "_cancel_rename").bind(line_edit))
	
func _finish_rename(new_text: String, node: BehaviorNode, gnode: GraphNode, editor: LineEdit) -> void:
	node.custom_name = new_text.strip_edges()
	_update_node_name(gnode, node)
	editor.queue_free()
	
func _cancel_rename(editor: LineEdit) -> void: editor.queue_free()

func _update_node_name(gnode: GraphNode, behavior: BehaviorNode) -> void:
	gnode.title = behavior.base_name + (" [" + behavior.custom_name.strip_edges() + "]" if behavior.custom_name.length() > 0 else "")
#endregion

#region Connections
func _on_connection_request(from_name: StringName, from_port: int, to_name: StringName, to_port: int) -> void:
	for conn in graph.get_connection_list(): if conn["from_node"] == from_name && conn["from_port"] == from_port: return # Port is busy
			
	var from_gnode: GraphNode = graph.get_node(NodePath(from_name))
	var to_gnode: GraphNode = graph.get_node(NodePath(to_name))
	
	if from_gnode == null || to_gnode == null: return
	
	var parent_node: BehaviorNode = from_gnode.get_meta("resource")
	var child_node: BehaviorNode = to_gnode.get_meta("resource")
	
	if child_node in current_tree.inactive_nodes: call_deferred("_remove_from_inactive", child_node) # Remove from inactive
	
	var old_parent = parent_map.get(child_node, null)
	if old_parent != null: call_deferred("_remove_from_children", child_node, old_parent) # Remove from old parent
	
	if _is_ancestor(child_node, parent_node): return # Against cycles
	
	if parent_node is BehaviorSequence || parent_node is BehaviorSelector:
		call_deferred("_add_to_children", child_node, parent_node, from_port) # Add to new parent in index
		
	else: call_deferred("_add_to_children", child_node, parent_node) # Add to new parent
	
	if parent_node is BehaviorCondition:
		if from_port == BehaviorCondition.Condition_Right_True: parent_node.true_node = child_node
		elif from_port == BehaviorCondition.Condition_Right_False: parent_node.false_node = child_node
	
	graph.connect_node(from_name, from_port, to_name, to_port) # Visual connection

func _on_disconnection_request(from_name: StringName, from_port: int, to_name: StringName, to_port: int) -> void:
	var from_gnode: GraphNode = graph.get_node(NodePath(from_name))
	var to_gnode: GraphNode = graph.get_node(NodePath(to_name))
	if from_gnode == null || to_gnode == null: return
	
	var parent_node: BehaviorNode = from_gnode.get_meta("resource")
	var child_node: BehaviorNode = to_gnode.get_meta("resource")
	
	var old_parent = parent_map.get(child_node, null)
	if old_parent == parent_node: call_deferred("_remove_from_children", child_node, parent_node) # Remove parent
	if !current_tree.inactive_nodes.has(child_node): call_deferred("_add_to_inactive", child_node) # Add to inactive
	
	if parent_node is BehaviorCondition:
		if child_node == parent_node.true_node: parent_node.true_node = null
		elif child_node == parent_node.false_node: parent_node.false_node = null
	
	graph.disconnect_node(from_name, from_port, to_name, to_port) # Visual connection

func _rebuild_connections(node: BehaviorNode):
	var gnode = gnode_map.get(node, null)
	if !gnode: return

	if node is BehaviorCondition:
		if node.true_node != null:
			var child_gnode = gnode_map[node.true_node]
			graph.connect_node(gnode.name, BehaviorCondition.Condition_Right_True, child_gnode.name, 0)
			_rebuild_connections(node.true_node)
		if node.false_node != null:
			var child_gnode = gnode_map[node.false_node]
			graph.connect_node(gnode.name, BehaviorCondition.Condition_Right_False, child_gnode.name, 0)
			_rebuild_connections(node.false_node)
			
	elif node is BehaviorSequence || node is BehaviorSelector:
		for i in range(node.children.size()):
			var child = node.children[i]
			var child_gnode = gnode_map.get(child, null)
			if child_gnode:
				var port_index = i 
				graph.connect_node(gnode.name, port_index, child_gnode.name, 0)
				_rebuild_connections(child)
				
	else:
		for child in node.children:
			var child_gnode = gnode_map.get(child, null)
			if child_gnode:
				graph.connect_node(gnode.name, 0, child_gnode.name, 0)
				_rebuild_connections(child)
				
func _is_ancestor(parent: BehaviorNode, child: BehaviorNode) -> bool:
	if parent == child: return true
	for c in parent.children: if _is_ancestor(c, child): return true
	return false
#endregion

#region Node Scripts
func _attach_unique_signals(gnode: GraphNode, behavior: BehaviorNode) -> void:
	if behavior is BehaviorPrint:
		var line_edit: LineEdit = gnode.get_node("LineEdit")
		line_edit.text = behavior.message
		line_edit.connect("text_changed", Callable(self, "_on_print_text_changed").bind(behavior))
		
	elif behavior is BehaviorCondition || behavior is BehaviorCall:
		var line_edit: LineEdit = gnode.get_node("LineEdit")
		line_edit.text = behavior.expression_text
		if behavior is BehaviorCondition: line_edit.connect("text_changed", Callable(self, "_on_condition_text_changed").bind(behavior))
		else: line_edit.connect("text_changed", Callable(self, "_on_call_text_changed").bind(behavior))
		
	elif behavior is BehaviorReturn:
		var check_box: CheckBox = gnode.get_node("CheckBox")
		check_box.button_pressed = behavior.is_failure
		check_box.connect("toggled", Callable(self, "_on_return_failure_toggled").bind(behavior))
	
	elif behavior is BehaviorSequence || behavior is BehaviorSelector:
		var add_button: Button = gnode.get_node("Controls/Add")
		var sub_button: Button = gnode.get_node("Controls/Sub")
		for i in range(2, behavior.ports + 1): _node_add_port(gnode, i) # Add ports
		if behavior is BehaviorSequence:
			add_button.connect("pressed", Callable(self, "_on_sequence_add").bind(gnode, behavior))
			sub_button.connect("pressed", Callable(self, "_on_sequence_subtract").bind(gnode, behavior))
		else:
			add_button.connect("pressed", Callable(self, "_on_selector_add").bind(gnode, behavior))
			sub_button.connect("pressed", Callable(self, "_on_selector_subtract").bind(gnode, behavior))
	
	elif behavior is BehaviorSubTree:
		var label: Label = gnode.get_node("HBox/Path")
		var detach: Button = gnode.get_node("HBox/Detach")
		label.text = behavior.tree_resource.resource_path if behavior.tree_resource != null else ""
		detach.connect("pressed", Callable(self, "_on_subtree_detach").bind(label, behavior))
		
func _on_print_text_changed(new_text: String, behavior: BehaviorPrint) -> void: behavior.message = new_text
func _on_condition_text_changed(new_text: String, behavior: BehaviorCondition) -> void: behavior.expression_text = new_text
func _on_call_text_changed(new_text: String, behavior: BehaviorCall) -> void: behavior.expression_text = new_text
func _on_return_failure_toggled(toggled_on: bool, behavior: BehaviorReturn) -> void: behavior.is_failure = toggled_on
	
func _on_subtree_detach(label: Label, behavior: BehaviorSubTree) -> void:
	label.text = ""
	behavior.tree_resource = null
	
# Sequence ports
func _on_sequence_add(gnode: GraphNode, behavior: BehaviorSequence) -> void:
	behavior.ports = clamp(behavior.ports + 1, 1, INF)
	_node_add_port(gnode, behavior.ports)

func _on_sequence_subtract(gnode: GraphNode, behavior: BehaviorSequence) -> void:
	behavior.ports = clamp(behavior.ports - 1, 1, INF)
	_node_subtract_port(gnode, behavior.ports)

# Selector ports
func _on_selector_add(gnode: GraphNode, behavior: BehaviorSelector) -> void:
	behavior.ports = clamp(behavior.ports + 1, 1, INF)
	_node_add_port(gnode, behavior.ports)
	
func _on_selector_subtract(gnode: GraphNode, behavior: BehaviorSelector) -> void:
	behavior.ports = clamp(behavior.ports - 1, 1, INF)
	_node_subtract_port(gnode, behavior.ports)

# Adding and removing ports
func _node_add_port(gnode: GraphNode, slot_index: int) -> void:
	var old_port: Label = gnode.get_node("Port")
	var new_port: Label = old_port.duplicate() as Label
	var port_color: Color = old_port.get_theme_color("font_color") as Color
	new_port.text = "Port %d" % slot_index
	new_port.add_theme_color_override("font_color", port_color)
	gnode.add_child(new_port)
	gnode.set_slot(slot_index, false, 0, Color.WHITE, true, 0, port_color)
	
func _node_subtract_port(gnode: GraphNode, slot_n: int) -> void:
	var labels := []
	for child in gnode.get_children(): if child is Label: labels.append(child)
	
	for i in range(labels.size() - 1, -1, -1):
		var lbl: Label = labels[i]
		
		if lbl.name != "Port" and labels.size() > slot_n:
			var from_name = gnode.name
			var from_port = i 
			
			for conn in graph.get_connection_list():
				if conn["from_node"] == from_name and conn["from_port"] == from_port:
					var to_name = conn["to_node"]
					var to_port = conn["to_port"]
					_on_disconnection_request(from_name, from_port, to_name, to_port)
					
			lbl.queue_free()
			labels.remove_at(i)
#endregion
