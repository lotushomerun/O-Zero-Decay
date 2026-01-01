extends Area2D
class_name Projectile

signal hit_signal(target)

@export var velocity: Vector2
@export var drag: float = 2.5
@export var life_time: float = 5.0

func _ready():
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _process(delta):
	velocity.y += gravity * delta
	velocity = velocity.move_toward(Vector2.ZERO, drag * delta * velocity.length())
	global_position += velocity * delta
	if velocity.length() > 0.01: rotation = velocity.angle()
	life_time -= delta
	if life_time <= 0.0: queue_free()

func _on_area_entered(area: Area2D) -> void:
	emit_signal("hit_signal", area)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	emit_signal("hit_signal", body)
	queue_free()
