extends PanelContainer
class_name Context

static var this: Context
static var panel: PanelContainer
static var vbox: VBoxContainer
static var header: Label
static var separator: HSeparator
static var button_scene: PackedScene
static var context_offset: Vector2 = Vector2(8, 8)

@export var button_scene_export: PackedScene

func _ready() -> void:
	this = self
	register_button_scene(button_scene_export)
	register_vbox($Margin/Panel/Margin/VBox)
	register_header($Margin/Panel/Margin/VBox/Header)
	register_separator($Margin/Panel/Margin/VBox/HSeparator)
	register_panel($Margin/Panel)

#region Registering
static func register_vbox(node: VBoxContainer) -> void: vbox = node
static func register_header(node: Label) -> void: header = node
static func register_separator(node: HSeparator) -> void: separator = node
static func register_button_scene(scene: PackedScene) -> void: button_scene = scene
static func register_panel(node: PanelContainer) -> void: panel = node
#endregion

#region Context
static func show_context(interactable: Interactable, pos: Vector2) -> void:
	if interactable.actions.size() <= 0: return
	
	SoundManager.play_sound_ui(SoundLib.ui_click_sound, -10.0)
	clear_context()
	header.text = interactable.entity_name.capitalize()
	
	for action: Action in interactable.actions:
		var btn = button_scene.instantiate() as ContextButton
		btn.text = action._action_name()
		btn.action = action
		btn.interactor = Player.this.character
		btn.interactable = interactable
		if !action._valid([btn.interactor, btn.interactable]): btn.disabled = true
		vbox.add_child(btn)
		
	this.position = pos
	
	var tree := Engine.get_main_loop() as SceneTree
	await tree.process_frame
	await tree.process_frame
	
	this.size = Vector2.ZERO
	var final_pos := clamp_to_screen(pos)
	this.position = final_pos
	apply_position_style(pos, final_pos)
	this.show()
	
static func hide_context() -> void:
	if is_instance_valid(Player.interactable):
		Player.interactable.hovered = false
		Player.interactable = null
		
	if is_instance_valid(InventoryManager.open_inventory): # Gotta redraw it if it's open to fix styles
		InventoryManager.show_entries(InventoryManager.open_inventory)
		
	this.hide()
	
static func clear_context() -> void:
	for node: Control in vbox.get_children(): if node != header && node != separator: node.queue_free()
#endregion

#region Position
static func clamp_to_screen(pos: Vector2) -> Vector2:
	var tree := Engine.get_main_loop() as SceneTree
	var viewport := tree.root
	var screen_size: Vector2 = viewport.size
	var panel_size: Vector2 = this.size
	
	pos.x = clamp(pos.x, 0, screen_size.x - panel_size.x)
	pos.y = clamp(pos.y, 0, screen_size.y - panel_size.y)
	
	return pos
	
static func apply_position_style(original_pos: Vector2, final_pos: Vector2) -> void:
	var style: StyleBoxFlat = this.get_theme_stylebox("panel", "PanelContainer").duplicate()
	var style2: StyleBoxFlat = panel.get_theme_stylebox("panel", "PanelContainer").duplicate()
	
	# If panel went higher than we anticipated
	if final_pos.y < original_pos.y:
		style.corner_radius_top_left = 12
		style.corner_radius_bottom_left = 2
		style2.corner_radius_top_left = 12
		style2.corner_radius_bottom_left = 2

	else: # Reset style to default
		style.corner_radius_top_left = 2
		style.corner_radius_bottom_left = 12
		style2.corner_radius_top_left = 2
		style2.corner_radius_bottom_left = 12
		
	this.add_theme_stylebox_override("panel", style)
	panel.add_theme_stylebox_override("panel", style2)
#endregion
