extends ColorRect
class_name ArousalEffect

static var shader_material: ShaderMaterial
static func register_shader_material(mat: ShaderMaterial) -> void: shader_material = mat
static func set_arousal(n: float) -> void: shader_material.set_shader_parameter("effect_intensity", clampf(n, 0.0, 1.0))
func _ready() -> void: register_shader_material(material)
