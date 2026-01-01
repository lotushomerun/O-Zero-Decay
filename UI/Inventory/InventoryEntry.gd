extends RichTextLabel
class_name InventoryEntry

@export var style1: StyleBoxFlat
@export var style2: StyleBoxFlat
@export var style_hovered: StyleBoxFlat
var our_style: StyleBoxFlat
var item: Item

# Drag & drop
@export var drag_preview_scene: PackedScene
var dragging := false
var drag_preview: Label = null

#region Hover
func _on_mouse_entered() -> void:
	if !is_instance_valid(Player.interactable):
		SoundManager.play_sound_ui(SoundLib.ui_hover_sound, -10.0)
		add_theme_stylebox_override("normal", style_hovered)

func _on_mouse_exited() -> void:
	if !is_instance_valid(Player.interactable):
		add_theme_stylebox_override("normal", our_style)
#endregion

#region Drag
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
			
		if event.button_index == MouseButton.MOUSE_BUTTON_RIGHT && event.pressed:
			if !get_global_rect().has_point(mouse_pos): return
			
			if is_instance_valid(drag_preview): _end_drag()
			if Context.this.visible: Context.hide_context()
			Player.interactable = item
			Context.show_context(item, mouse_pos + Context.context_offset)
			
		elif event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			if !Context.this.visible: # Can't drag shit if context menu is open
				if event.pressed:
					if !get_global_rect().has_point(mouse_pos): return
					_start_drag()
				else:
					_end_drag()
				
func _start_drag() -> void:
	if !drag_preview_scene: return
	
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()

	drag_preview = drag_preview_scene.instantiate() as Label
	drag_preview.text = item.entity_name
	dragging = true
	
	InventoryManager.register_dragged_entry(self)
	InventoryManager.register_entry_ghost(drag_preview)

	Context.this.get_parent().add_child(drag_preview)
	drag_preview.global_position = mouse_pos - drag_preview.size / 2.0

func _end_drag() -> void:
	if dragging:
		dragging = false
		if is_instance_valid(drag_preview):
			
			InventoryManager.entry_ghost = null
			InventoryManager.dragged_entry = null
			
			drag_preview.queue_free()
			drag_preview = null
			
			var mouse_pos: Vector2 = get_viewport().get_mouse_position()
			
			# Drop it in the world
			if is_instance_valid(Player.interactable):
				Player.interactable._on_item_interaction(Player.this.character, item)
				return
			
			# Try dropping it on item entries in inventory
			for control: Control in InventoryManager.inventory_entries.get_children():
				if !(control is InventoryEntry): continue
				var entry: InventoryEntry = control as InventoryEntry
				if entry.get_global_rect().has_point(mouse_pos):
					var target_item := entry.item
					target_item._on_item_interaction(Player.this.character, item)
					return
			
			# Try dropping it on inventories
			var inventories: Array[Inventory] = [InventoryManager.inventory, InventoryManager.backpack, InventoryManager.storage]
			for i: Inventory in inventories:
				if i.get_global_rect().has_point(mouse_pos):
					InventoryManager.open_inventory.transfer_item(item, i)
					return

func _process(_delta: float) -> void:
	if dragging && is_instance_valid(drag_preview):
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		drag_preview.global_position = mouse_pos - drag_preview.size / 2.0
	elif !dragging && is_instance_valid(drag_preview): drag_preview.queue_free()
#endregion
