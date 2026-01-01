extends ColorRect
class_name FatigueEffect

# Why is it here? Because I fuckin' want to, that's why. Also it's FUCKIN 2 AM
static var steam_particles: PackedScene
@export var steam_particles_scene: PackedScene
static func register_steam_particles(n: PackedScene) -> void: steam_particles = n

static var shader_material: ShaderMaterial
static func register_shader_material(mat: ShaderMaterial) -> void: shader_material = mat
static func set_fatigue(n: float) -> void: shader_material.set_shader_parameter("effect_intensity", clampf(n, 0.0, 1.0))

func _ready() -> void:
	register_shader_material(material)
	register_steam_particles(steam_particles_scene)
