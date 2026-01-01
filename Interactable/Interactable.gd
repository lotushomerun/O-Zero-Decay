extends Area2D
class_name Interactable

@export_group("Info")
@export var entity_id: String
@export var entity_name: String = "entity"
@export_multiline var entity_desc: String = "Something!"

@export_group("Refs")
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var arrow: Sprite2D = $Arrow
@export var collision_shape_copy: CollisionShape2D

@export_group("Hover")
@export var hover_speed: float = 20.0
const Arrow_Vertical_Offset: float = -8.0
var hovered: bool = false

var actions: Array[Action] = []
var primary_action: Action

func _ready() -> void:
	if entity_desc.length() > 0: actions.append(InspectAction.new())
	if !collision_shape || !collision_shape_copy: return
	_copy_collision_shape(collision_shape_copy)
	
func _process(delta: float) -> void:
	if hovered:
		if arrow.modulate.a != 1.0: arrow.modulate.a = lerpf(arrow.modulate.a, 1.0, delta * hover_speed)
	else: 
		if arrow.modulate.a != 0.0: arrow.modulate.a = lerpf(arrow.modulate.a, 0.0, delta * hover_speed)

func _on_mouse_entered() -> void:
	if Player.interactable != null && Player.interactable != self: Player.interactable._on_mouse_exited()
	if !Context.this.visible:
		hovered = true
		Player.interactable = self
	
func _on_mouse_exited() -> void:
	if !Context.this.visible:
		hovered = false
		if Player.interactable == self: Player.interactable = null

func _copy_collision_shape(col: CollisionShape2D) -> void:
	if !collision_shape || !col: return
	
	collision_shape.set_deferred("shape", col.shape)
	collision_shape.position = col.position - position
	
	await get_tree().process_frame
	var rect := collision_shape.shape.get_rect()
	var top_y := collision_shape.position.y + rect.position.y
	arrow.position.y = top_y + Arrow_Vertical_Offset

func _inspect() -> String:
	var inspect_text: String = entity_desc
	return inspect_text
	
func _on_item_interaction(_character: Char, _item: Item) -> void: print("Interacted!")
