extends Camera2D
class_name Camera

static var this: Camera

# Shake
const Light_Shake: float = 5.0
const Medium_Shake: float = 10.0
const Strong_Shake: float = 20.0
var shake_noise := FastNoiseLite.new()
var shake_time: float = 0.0
var shake_duration: float = 0.0
var shake_strength: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO

# Offset
static var default_offset: Vector2 = Vector2(0.0, 0.0)
var designated_offset: Vector2 = default_offset
var smoothed_base_offset: Vector2
const Offset_Speed: float = 3.33
const Look_Offset: Vector2 = Vector2(16.0, 0.0)

# Zoom
static var default_zoom: Vector2 = Vector2(2.33, 2.33)
var designated_zoom: Vector2 = default_zoom
const Zoom_Speed: float = 5.0

# Heartbeat
static var heartbeat_zoom: Vector2 = Vector2(0.33, 0.33) # Addative
static var in_heartbeat: bool = false
const Heartbeat_Duration := 0.2
const Heartbeat_Return_Duration := 0.33

# Rain
@onready var rain: AudioStreamPlayer = $RainLoop

# Wind
@onready var wind_loop: AudioStreamPlayer = $WindLoop
@onready var wind: AudioStreamPlayer = $Wind

# Sky
@onready var sky: ColorRect = $CanvasBack/Sky
@onready var clouds: Parallax2D = $Clouds
@onready var rain_clouds: Parallax2D = $RainClouds

# Darkness
@onready var darkness: ColorRect = $CanvasBack/Darkness

static func register_instance(n: Camera) -> void: this = n

func _ready() -> void:
	register_instance(self)
	
	# Shake noise
	shake_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	shake_noise.frequency = 1.5

func _process(delta: float) -> void:
	# Zoom shit
	if !in_heartbeat: zoom = lerp(zoom, designated_zoom, Zoom_Speed * delta)
	
	# Shake logic
	if shake_time > 0.0:
		shake_time -= delta
		var t := shake_time / shake_duration
		var power := shake_strength * t  # fades out
		shake_offset.x = (shake_noise.get_noise_1d(Time.get_ticks_msec() * 0.01) * 2.0 - 1.0) * power
		shake_offset.y = (shake_noise.get_noise_1d(Time.get_ticks_msec() * 0.02 + 1000) * 2.0 - 1.0) * power
		offset = shake_offset + designated_offset
	else: shake_offset = Vector2.ZERO
	
	smoothed_base_offset = smoothed_base_offset.lerp(designated_offset, Offset_Speed * delta)
	offset = smoothed_base_offset + shake_offset

static func shake(strength: float, duration: float) -> void:
	if this == null: return
	this.shake_strength = strength
	this.shake_duration = duration
	this.shake_time = duration

static func _do_heartbeat() -> void:
	var tween := this.create_tween()
	var start_zoom := this.zoom
	var peak_zoom := start_zoom + heartbeat_zoom
	SoundManager.play_sound_ui(SoundLib.ui_heartbeat_sound, -15.0)
	tween.tween_property(this, "zoom", peak_zoom, Heartbeat_Duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(this, "zoom", start_zoom, Heartbeat_Return_Duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
