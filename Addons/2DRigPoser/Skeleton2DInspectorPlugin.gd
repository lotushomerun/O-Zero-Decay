@tool
extends EditorInspectorPlugin
class_name Skeleton2DInspectorPlugin

var editor_plugin: EditorPlugin
var buttons_data: Array = []

#region Base
func _init(editor_plugin_ref: EditorPlugin):
	print("Skeleton2DInspectorPlugin class initiated...")
	editor_plugin = editor_plugin_ref

func _can_handle(object): 
	return (object is Skeleton2D) or (object is AnimationPlayer)

func _parse_begin(object: Object) -> void:
	var vbox = VBoxContainer.new()
	
	# Skeleton2D
	if object is Skeleton2D:
		_add_category_title(vbox, "Skeleton2D Tools")
		
		var skeleton_buttons := [
			{ "text": "Flip Rig Pose", "callback": Callable(self, "_flip_rig_pose") },
			{ "text": "Copy Rig Pose", "callback": Callable(self, "_copy_rig_pose") },
			{ "text": "Paste Rig Pose", "callback": Callable(self, "_paste_rig_pose") },
			{ "text": "Select Rig Bones", "callback": Callable(self, "_select_rig_bones") },
			{ "text": "Show/Hide Rig Bones", "callback": Callable(self, "_hide_rig_bones") },
			{ "text": "Fix Animation Preview", "callback": Callable(self, "_fix_animation_preview") },
		]
		for button_data in skeleton_buttons:
			var btn = Button.new()
			btn.text = button_data["text"]
			btn.connect("pressed", Callable(button_data["callback"].bind(object)))
			vbox.add_child(btn)
			
	# AnimationPlayer
	elif object is AnimationPlayer:
		_add_category_title(vbox, "AnimationPlayer Tools")
		
		var buttons := [
			{ "text": "Delete Keys at Current Frame", "callback": Callable(self, "_delete_keys_current_frame") },
			{ "text": "Sanitize Animation", "callback": Callable(self, "_sanitize_animation_prompt") }
		]
		
		for b in buttons:
			var btn := Button.new()
			btn.text = b["text"]
			btn.pressed.connect(b["callback"].bind(object))
			vbox.add_child(btn)
		
	add_custom_control(vbox)
	
func _add_category_title(vbox: VBoxContainer, text: String) -> void:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.DODGER_BLUE)
	
	var font = vbox.get_theme_font("bold_font", "Editor")
	if font: label.add_theme_font_override("font", font)
	
	vbox.add_child(label)
	
	var sep = HSeparator.new()
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(sep)
#endregion

#region Bone Parse
func _get_bones_recursive(node: Node) -> Array:
	var bones = []
	for child in node.get_children():
		if child is Bone2D: bones.append(child)
		bones += _get_bones_recursive(child)
	return bones
#endregion

#region Fix Animation Preview
func _fix_animation_preview(skeleton: Skeleton2D):
	var selection = EditorInterface.get_selection()
	selection.clear()
	
	for node: Node in skeleton.get_parent().get_children():
		if node is AnimationTree or node is AnimationPlayer:
			EditorInterface.edit_node(node)
			selection.remove_node(node)
#endregion

#region Select Bones
func _select_rig_bones(skeleton: Skeleton2D):
	var selection = EditorInterface.get_selection()
	selection.clear()
	
	var bones: Array = _get_bones_recursive(skeleton)
	var markers: Node2D = skeleton.get_parent().get_node_or_null("Targets")
	
	if markers != null: bones.append_array(markers.get_children())
	for bone in bones: selection.add_node(bone)
#endregion

#region Show/Hide Bones
func _hide_rig_bones(skeleton: Skeleton2D):
	var bones: Array = _get_bones_recursive(skeleton)
	
	var all_visible: bool = true
	for bone: Bone2D in bones:
		if !bone.get("editor_settings/show_bone_gizmo"):
			all_visible = false
			break
	
	var new_state: bool = !all_visible
	for bone: Bone2D in bones: bone.set("editor_settings/show_bone_gizmo", new_state)
#endregion

#region Copy Pose
var copied_pose: Dictionary = {}

func _copy_rig_pose(skeleton: Skeleton2D):
	copied_pose.clear()
	
	var bones: Array = _get_bones_recursive(skeleton)
	var markers: Node2D = skeleton.get_parent().get_node_or_null("Targets")
	if markers != null: bones.append_array(markers.get_children())
	
	for node2D: Node2D in bones: copied_pose[node2D.get_class() + node2D.name] = { "position": node2D.position, "rotation": node2D.rotation }
	print("Pose copied:", copied_pose.keys())
#endregion

#region Paste Pose
func _paste_rig_pose(skeleton: Skeleton2D):
	if copied_pose.is_empty():
		print("No pose copied!")
		return
	
	var bones: Array = _get_bones_recursive(skeleton)
	var markers: Node2D = skeleton.get_parent().get_node_or_null("Targets")
	if markers != null: bones.append_array(markers.get_children())
	
	for node2D: Node2D in bones:
		if copied_pose.has(node2D.get_class() + node2D.name):
			print(node2D.name+" found!")
			var pose = copied_pose[node2D.get_class() + node2D.name]
			node2D.position = pose["position"]
			node2D.rotation = pose["rotation"]
	
	print("Pose pasted!")
#endregion

#region Flip Pose
func _flip_rig_pose(skeleton: Skeleton2D) -> void:
	var markers: Node2D = skeleton.get_parent().get_node_or_null("Targets")
	if markers == null:
		push_warning("Flip Pose: Cannot find 'Targets' node next to Skeleton2D.")
		return
		
	var children: Array = markers.get_children()
	if children.is_empty():
		push_warning("Flip Pose: 'Targets' has no children.")
		return
		
	var front_dict := {}  # base_name > node
	var back_dict := {}   # base_name > node
	
	# Parse nodes
	for node in children:
		if not (node is Node2D): continue
		
		var name: String = node.name
		
		if name.begins_with("Front"):
			var base := name.substr(5)  # after Front
			front_dict[base] = node
			
		elif name.begins_with("Back"):
			var base := name.substr(4)  # after Back
			back_dict[base] = node
			
	for base in front_dict.keys():
		if back_dict.has(base):
			var a: Node2D = front_dict[base]
			var b: Node2D = back_dict[base]
			
			# Flip states
			var temp_pos = a.position
			a.position = b.position
			b.position = temp_pos
			
			var temp_rot = a.rotation
			a.rotation = b.rotation
			b.rotation = temp_rot
			
			var temp_scale = a.scale
			a.scale = b.scale
			b.scale = temp_scale
#endregion

#region Delete Keys
func _delete_keys_current_frame(ap: AnimationPlayer):
	if ap == null:
		push_warning("AnimationPlayer is null")
		return
		
	var selection := EditorInterface.get_selection()
	var nodes := selection.get_selected_nodes()
	if nodes.size() != 1 or not (nodes[0] is AnimationPlayer):
		push_warning("Select exactly one AnimationPlayer in SceneTree.")
		return
	ap = nodes[0] as AnimationPlayer
	
	var dialog := AcceptDialog.new()
	dialog.title = "Enter Title"
	dialog.ok_button_text = "Cancel"
	
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog.add_child(vbox)
	
	var line_edit := LineEdit.new()
	line_edit.placeholder_text = "Animation name"
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(line_edit)
	
	var btn_delete := Button.new()
	btn_delete.text = "Delete"
	btn_delete.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(btn_delete)
	
	btn_delete.pressed.connect(Callable(self, "_on_anim_name_confirmed").bind(ap, dialog, line_edit))
	
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered()
	
func _on_anim_name_confirmed(ap: AnimationPlayer, dialog: AcceptDialog, line_edit: LineEdit):
	var anim_name := line_edit.text.strip_edges()
	dialog.queue_free()
	if anim_name == "":
		push_warning("Animation name empty")
		return
		
	var anim := ap.get_animation(anim_name)
	if anim == null:
		push_warning("Animation not found: " + anim_name)
		return
		
	var time := ap.current_animation_position
	print("Deleting keys in animation:", anim_name, " at time:", time)
	_delete_keys_at_time(anim, time)
	print("Done.")
	
func _delete_keys_at_time(anim: Animation, time: float):
	for track_index in range(anim.get_track_count()):
		var idx := anim.track_find_key(track_index, time)
		if idx != -1: anim.track_remove_key(track_index, idx)
#endregion

#region Sanitize Animation
func _sanitize_animation_prompt(ap: AnimationPlayer) -> void:
	if ap == null:
		push_warning("AnimationPlayer is null")
		return
		
	var dialog := AcceptDialog.new()
	dialog.title = "Sanitize Animation"
	dialog.ok_button_text = "Cancel"
	
	var vbox := VBoxContainer.new()
	dialog.add_child(vbox)
	
	var line_edit := LineEdit.new()
	line_edit.placeholder_text = "Animation name"
	vbox.add_child(line_edit)
	
	var btn := Button.new()
	btn.text = "Sanitize"
	vbox.add_child(btn)
	
	btn.pressed.connect(Callable(self, "_on_sanitize_animation_confirmed").bind(ap, dialog, line_edit))
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered()
	
func _on_sanitize_animation_confirmed(ap: AnimationPlayer, dialog: AcceptDialog, line_edit: LineEdit) -> void:
	var anim_name := line_edit.text.strip_edges()
	dialog.queue_free()
	
	if anim_name == "":
		push_warning("Animation name empty")
		return
		
	var anim := ap.get_animation(anim_name)
	if anim == null:
		push_warning("Animation not found: " + anim_name)
		return
		
	print("Sanitizing animation:", anim_name)
	_sanitize_animation(anim)
	print("Sanitize done.")
	
func _sanitize_animation(anim: Animation) -> void:
	var prefixes := ["Active/", "Passive/"]
	
	for i in range(anim.get_track_count()):
		var path: NodePath = anim.track_get_path(i)
		var path_str := String(path)
		
		for prefix in prefixes:
			if path_str.begins_with(prefix):
				path_str = path_str.substr(prefix.length())
				anim.track_set_path(i, NodePath(path_str))
				break
#endregion
