extends Node
class_name Movement

@export var character: CharacterBody2D

@export var speed: float = 200.0
@export var sprint_speed: float = 300.0
@export var acceleration: float = 1500.0
@export var deceleration: float = 1800.0
@export var gravity: float = 981.0

var direction: Vector2 = Vector2.ZERO
var external_force: Vector2 = Vector2.ZERO
@export var external_force_acceleration: float = 1500.0
@export var external_force_deceleration: float = 1800.0
var sprinting: bool = false

# Collision info
var obstacle_left: bool = false
var obstacle_right: bool = true

func _ready():
	if character == null: push_warning("Movement: 'character' is not assigned! Movement disabled.")

func _physics_process(delta: float) -> void:
	if character == null: return
	
	process_gravity(delta)
	
	if is_moved(): process_impulses(delta) # Influenced by external force
	else: # Not influenced so we do our stuff
		
		if character.mobility == Char.Mobility.Full: process_movement(delta) # Can actually move only on full mobility
		else:
			
			if is_moving(): # We're trying to move despite being immobile to a degree
				if character.mobility == Char.Mobility.Half: _try_half_mobile_move()
				else: _try_immobile_move()
				
			character.velocity.x = move_toward(character.velocity.x, 0.0, deceleration * delta) # Stop!
	
	character.move_and_slide() # Apply movement
	
	# Collisions
	var collision_count: int = character.get_slide_collision_count()
	if collision_count > 1: # 1 because we're always colliding with the floor
		for i in collision_count:
			var collision = character.get_slide_collision(i)
			var normal = collision.get_normal()
			if normal.x > 0.7: obstacle_left = true
			elif normal.x < -0.7: obstacle_right = true
	else:
		obstacle_left = false
		obstacle_right = false
			
func process_gravity(delta: float):
	var vel := character.velocity
	vel.y += gravity * delta # Apply gravity
	character.velocity = vel

func process_movement(delta: float):
	var vel := character.velocity
	
	var target_speed = direction.x * (speed if !is_sprinting() else sprint_speed)
	if is_moving_backwards(): target_speed *= 0.5
	
	if direction.x != 0:
		if sign(vel.x) != sign(direction.x) and vel.x != 0: vel.x = move_toward(vel.x, 0.0, deceleration * delta) # Use decel for faster turn-around when changing dirs
		else: vel.x = move_toward(vel.x, target_speed, acceleration * delta)
	else: vel.x = move_toward(vel.x, 0.0, deceleration * delta)
	
	character.velocity = vel
	
func process_impulses(delta: float):
	var vel := character.velocity
	vel = vel.move_toward(external_force, external_force_acceleration * delta)
	external_force = external_force.move_toward(Vector2.ZERO, external_force_deceleration * delta) # decay external force
	character.velocity = vel
	
func apply_impulse(force: Vector2) -> void: external_force += force
func stop_impulse() -> void: external_force = Vector2.ZERO

func play_footstep() -> void:
	var step_sounds: Array[AudioStream] = SoundLib.asphalt_footsteps
	SoundManager.play_sound_2d(step_sounds.pick_random(), character.global_position, -25.0)
	
func is_moved() -> bool: return (abs(external_force.length()) > 0.01)

func is_moving() -> bool: return abs(direction.x) > 0

func is_sprinting() -> bool: return (sprinting && is_moving() && !is_moving_backwards())

func is_moving_backwards() -> bool:
	if character == null: return false
	var moving_right = character.movement.direction.x > 0
	var moving_left  = character.movement.direction.x < 0
	if (character.rig.facing_right && moving_left) || (!character.rig.facing_right && moving_right): return true
	return false
	
func _try_half_mobile_move() -> void: if character.has_method("_try_half_mobile_move"): character.call("_try_half_mobile_move")
func _try_immobile_move() -> void: if character.has_method("_try_immobile_move"): character.call("_try_immobile_move")
