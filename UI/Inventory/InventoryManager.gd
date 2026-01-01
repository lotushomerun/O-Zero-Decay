extends VBoxContainer
class_name InventoryManager

static var inventory_panel: PanelContainer
static var scroll_container: ScrollContainer
static var inventory_entries: VBoxContainer
static var space_label: Label
static var equip_separator: HSeparator
static var time_label: Label

static var inventory: Inventory
static var backpack: Inventory
static var storage: Inventory
static var open_inventory: Inventory
static var open_storage: ContainerObj

static var entry_scene: PackedScene
@export var entry_scene_export: PackedScene

static var entry_ghost: Label
static var dragged_entry: InventoryEntry

#region Registering
static func register_inventory_panel(node: PanelContainer) -> void: inventory_panel = node
static func register_scroll_container(node: ScrollContainer) -> void: scroll_container = node
static func register_inventory_entries(node: VBoxContainer) -> void: inventory_entries = node
static func register_space_label(node: Label) -> void: space_label = node
static func register_equip_separator(node: HSeparator) -> void: equip_separator = node
static func register_entry_scene(node: PackedScene) -> void: entry_scene = node
static func register_time_label(node: Label) -> void: time_label = node

static func register_entry_ghost(node: Label) -> void: entry_ghost = node
static func register_dragged_entry(node: InventoryEntry) -> void: dragged_entry = node

static func register_container(node: ContainerObj) -> void: open_storage = node

static func register_inventory(node: Inventory) -> void:
	inventory = node
	inventory.rename("inventory")
	inventory.resize(15)
static func register_backpack(node: Inventory) -> void:
	backpack = node
	backpack.rename("backpack")
	backpack.resize(10)
static func register_storage(node: Inventory) -> void:
	storage = node
	storage.rename("storage")
	storage.resize(20)
#endregion

#region Ready
func _ready() -> void:
	register_entry_scene(entry_scene_export)
	register_equip_separator($Inventory/Margin/Panel/Margin/ScrollContainer/VBox/HSeparator)
	register_space_label($Inventory/Margin/Panel/Margin/Space)
	register_inventory_panel($Inventory)
	register_scroll_container($Inventory/Margin/Panel/Margin/ScrollContainer)
	register_inventory_entries($Inventory/Margin/Panel/Margin/ScrollContainer/VBox)
	register_time_label($Panel/TimeMargin/Time)
	
	register_inventory($Panel/HBox/Inventory)
	register_backpack($Panel/HBox/Backpack)
	register_storage($Panel/HBox/Storage)
	
	hide_inventory(backpack)
	hide_inventory(storage)
#endregion

#region Process
func _process(_delta: float) -> void:
	if is_instance_valid(entry_ghost) && !is_instance_valid(dragged_entry): entry_ghost.queue_free()
#endregion

#region Managing
static func show_entries(node: Inventory) -> void:
	if is_instance_valid(open_inventory): open_inventory.add_theme_stylebox_override("normal", open_inventory.normal_style)
	node.add_theme_stylebox_override("normal", node.pressed_style)
	
	inventory_panel.show()
	open_inventory = node
	clear_entries()
	
	# Sorting
	var equipped: Array = []
	var unequipped: Array = []
	for it in node.items:
		if !is_instance_valid(it): continue
		if it.is_equipped: equipped.append(it)
		else: unequipped.append(it)
	
	space_label.text = "%d/%d" % [node.items.size(), node.max_size]
	
	# Creating entries
	var idx := 0
	for item in equipped:
		inventory_entries.add_child(create_entry(item, idx))
		idx += 1
	
	# Separator
	if equipped.size() > 0:
		equip_separator.show()
		inventory_entries.move_child(equip_separator, -1) # after equipped entries
	else: equip_separator.hide()
	
	# Unequipped entries
	for item in unequipped:
		inventory_entries.add_child(create_entry(item, idx))
		idx += 1
		
static func create_entry(item: Item, idx: int) -> InventoryEntry:
	var entry := entry_scene.instantiate() as InventoryEntry
	entry.item = item
	entry.text = "• %s" % item.entity_name
	entry.our_style = entry.style1 if idx % 2 == 0 else entry.style2
	entry.add_theme_stylebox_override("normal", entry.our_style)
	return entry

static func hide_entries() -> void:
	open_inventory.add_theme_stylebox_override("normal", open_inventory.normal_style)
	open_inventory = null
	inventory_panel.hide()
	
static func clear_entries() -> void:
	for node: Control in inventory_entries.get_children(): if node != equip_separator: node.queue_free()
	space_label.text = "0/0"

static func show_inventory(node: Inventory) -> void:
	node.show()
	
static func hide_inventory(node: Inventory) -> void:
	node.hide()
	if open_inventory == node: hide_entries()
	
static func resize_inventory(node: Inventory, n: int) -> void: node.resize(n)
#endregion
