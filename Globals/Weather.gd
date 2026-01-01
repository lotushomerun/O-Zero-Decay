extends Node
class_name Weather

enum WeatherCondition { Clear, Rain }

static var condition := WeatherCondition.Clear
static var rain_intensity: float = 0.0
static var wind_velocity: float = 0.0

class WeatherEvent:
	var start_time: Dictionary # {year, month, day, hour, minute}
	var condition: WeatherCondition
	var rain_intensity: float # 0..1
	var wind_velocity: float # -1..1
	
	func _print_data() -> void:
		var condition_name: String = WeatherCondition.keys()[condition]
		var rain: String = str(snapped(rain_intensity, 0.1))
		var wind: String = str(snapped(wind_velocity, 0.1))
		print("%s, rain intensity - %s, wind velocity - %s, %s" % [condition_name, rain, wind, start_time])

static var rain_shader: ShaderMaterial
static var rain_splash_shader: ShaderMaterial
static var sky_shader: ShaderMaterial

const Rain_Container_Name: String = "RainEffects" # Yeah it's dumb...
const Rain_Node_Name: String = "Rain"
const Splashes_Node_Name: String = "Splashes"

const Rain_Volume_Min: float = -50.0
const Rain_Volume_Inside: float = -15.0
const Rain_Volume_Outside: float = -10.0
const Rain_No_Color: Color = Color("#5675b300")
const Rain_Full_Color: Color = Color("#5675b3aa")

const Clouds_Max_Speed: float = 15.0
const Clouds_Min_Speed: float = 3.0
const Clouds_Darkest_Color: Color = Color(0.337, 0.337, 0.337, 1.0)
const Clouds_Lightest_Color: Color = Color(1.0, 1.0, 1.0, 1.0)
const Rain_Clouds_Min_Alpha: float = 0.0
const Rain_Clouds_Max_Alpha: float = 1.0

# Sky
const Clear_Sky_Top_Color: Color = Color("#0b3db3")
const Clear_Sky_Bottom_Color: Color = Color("#4881b8")
const Clear_Sky_Vignette: float = .25

const Rain_Sky_Top_Color: Color = Color("#3d4c6e")
const Rain_Sky_Bottom_Color: Color = Color("#8499b5")
const Rain_Sky_Vignette: float = 1.33

const Sky_Gradient_Curve_Min: float = 0.2
const Sky_Gradient_Curve_Max: float = 1.5

const Sky_Morning_Tint: Color = Color("#cd5199")
const Sky_Day_Tint: Color = Color("ffffffff")
const Sky_Evening_Tint: Color = Color("#dc4028")
const Sky_Night_Tint: Color = Color("#18142b")

const Darkness_Max: Color = Color(0.0, 0.0, 0.0, 0.7)
const Darkness_Min: Color = Color(0.0, 0.0, 0.0, 0.0)

# Wind
const Wind_Loop_Outside: float = -15.0 # dB
const Wind_Loop_Inside: float = -27.0 # dB
const Wind_Loop_Min: float = -50.0 # dB
const Wind_Max: float = 0.0 # dB
const Wind_Min: float = -20.0 # dB
const Wind_Min_Delay: float = 10.0
const Wind_Max_Delay: float = 60.0 
static var wind_sound_delay: float = 0.0

#region Tick
static func _tick(delta: float):
	update_shaders(delta)
	ensure_forecast()
	progress_forecast()
#endregion

#region Human
static func _process_weather(character: Human, delta: float) -> void:
	var human_rig: HumanRig = character.rig as HumanRig
	human_rig.skin_wetness = clampf(human_rig.skin_wetness - delta * 0.05, 0.0, 1.0) # Drying
	
	var hit: Dictionary = Utils.raycast_2d(character.global_position, character.global_position + Vector2(0.0, -256.0), [], [2]) # Underneath something?
	
	# Wind
	if Player.this.character == character: # Wind sounds
		wind_sound_delay = clampf(wind_sound_delay - delta, 0.0, Wind_Max_Delay) # Cooldown
		if hit.is_empty(): # Smaller wind sounds only play outdoors with no cover
			if !Camera.this.wind.playing:
				if wind_sound_delay <= 0.0:
					wind_sound_delay = lerp(Wind_Max_Delay, Wind_Min_Delay, abs(wind_velocity)) + randf_range(-2.0, 2.0)
					Camera.this.wind.stream = SoundLib.wind_sounds.pick_random()
					Camera.this.wind.volume_db = lerp(Wind_Min, Wind_Max, abs(wind_velocity))
					Camera.this.wind.play()
					
		if abs(wind_velocity) >= 0.5:
			if !Camera.this.wind_loop.playing: Camera.this.wind_loop.play() # Start sound
			var target_volume: float = (Wind_Loop_Outside if hit.is_empty() else Wind_Loop_Inside) / abs(wind_velocity)
			Camera.this.wind_loop.volume_db = lerp(Camera.this.wind_loop.volume_db, target_volume, delta * 5.0)
		else:
			if Camera.this.wind_loop.playing:
				Camera.this.wind_loop.volume_db = lerp(Camera.this.wind_loop.volume_db, Wind_Loop_Min, delta * 5.0)
				if Camera.this.wind_loop.volume_db == Wind_Loop_Min: Camera.this.wind_loop.stop() # Stop sound
			
	# Rain
	match condition:
		WeatherCondition.Clear:
			if Camera.this.rain.playing:
				Camera.this.rain.volume_db = lerp(Camera.this.rain.volume_db, Rain_Volume_Min, delta * 5.0)
				if Camera.this.rain.volume_db == Rain_Volume_Min: Camera.this.rain.stop() # Stop sound
			
		WeatherCondition.Rain:
			if !Camera.this.rain.playing: Camera.this.rain.play() # Start sound
				
			if hit.is_empty(): # No roof
				human_rig.skin_wetness = clampf(human_rig.skin_wetness + delta * 0.1 * rain_intensity, 0.0, 1.0) # Getting wet!
				var datas: Array[ClothesData] = human_rig._get_all_clothes_data()
				for data in datas: if data != null: data.add_wetness(delta * 0.05 * rain_intensity)
			
			# Rain volume
				if Player.this.character == character:
					var target_volume: float = lerp(Rain_Volume_Min, Rain_Volume_Outside, rain_intensity)
					Camera.this.rain.volume_db = lerp(Camera.this.rain.volume_db, target_volume, delta * 5.0)
			else:
				if Player.this.character == character:
					var target_volume: float = lerp(Rain_Volume_Min, Rain_Volume_Inside, rain_intensity)
					Camera.this.rain.volume_db = lerp(Camera.this.rain.volume_db, target_volume, delta * 5.0)
#endregion

#region Effect
static func reload_weather() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var root_node: Node = tree.current_scene
	
	if is_instance_valid(Camera.this): sky_shader = Camera.this.sky.material as ShaderMaterial
	
	for node: Node in root_node.get_children():
		if node.name == Rain_Container_Name:
			var n_control: Control = node as Control
			n_control.z_as_relative = false
			n_control.z_index = Layering.Max_Char_Index + 1
			for control: Control in node.get_children(): # Getting shader refs (all rains and all splashes share shaders so we just need one)
				if control.name.contains(Rain_Node_Name): rain_shader = control.material as ShaderMaterial
				elif control.name.contains(Splashes_Node_Name): rain_splash_shader = control.material as ShaderMaterial
			break

static func update_shaders(delta: float):
	if is_instance_valid(current_forecast):
		condition = current_forecast.condition
		rain_intensity = lerp(rain_intensity, current_forecast.rain_intensity, delta)
		wind_velocity = lerp(wind_velocity, current_forecast.wind_velocity, delta)
	
	var rain_lerped_color: Color = Rain_No_Color.lerp(Rain_Full_Color, rain_intensity)
		
	if rain_shader:
		rain_shader.set_shader_parameter("rain_color", rain_lerped_color)
		rain_shader.set_shader_parameter("horizontal_shift", 3.33 * wind_velocity)

	if rain_splash_shader:
		rain_splash_shader.set_shader_parameter("rain_color", rain_lerped_color)
	
	# Clouds
	var clouds_lerped_color: Color = Clouds_Lightest_Color.lerp(Clouds_Darkest_Color, rain_intensity)
	Camera.this.clouds.modulate = clouds_lerped_color
	Camera.this.rain_clouds.modulate = Color(clouds_lerped_color.r, clouds_lerped_color.g, clouds_lerped_color.b, 
	lerp(Rain_Clouds_Min_Alpha, Rain_Clouds_Max_Alpha, rain_intensity))
	
	var cloud_clamped_speed = clamp(Clouds_Max_Speed * wind_velocity, -Clouds_Max_Speed, Clouds_Max_Speed)
	if abs(cloud_clamped_speed) < Clouds_Min_Speed: cloud_clamped_speed = sign(cloud_clamped_speed) * Clouds_Min_Speed
	Camera.this.clouds.autoscroll = Vector2(lerp(Camera.this.clouds.autoscroll.x, cloud_clamped_speed, delta), 0.0)
	Camera.this.rain_clouds.autoscroll = Vector2(lerp(Camera.this.rain_clouds.autoscroll.x, cloud_clamped_speed, delta), 0.0)
	
	# Sky shader, including time effect
	var sky_tint: Color = get_sky_tint(TimeManager.hour, TimeManager.minute)
	sky_shader.set_shader_parameter("top_color", Clear_Sky_Top_Color.lerp(Rain_Sky_Top_Color, rain_intensity))
	sky_shader.set_shader_parameter("bottom_color", Clear_Sky_Bottom_Color.lerp(Rain_Sky_Bottom_Color, rain_intensity))
	sky_shader.set_shader_parameter("vignette_strength", lerp(Clear_Sky_Vignette, Rain_Sky_Vignette, rain_intensity))
	sky_shader.set_shader_parameter("gradient_curve", lerp(Sky_Gradient_Curve_Min, Sky_Gradient_Curve_Max, abs(wind_velocity)))
	sky_shader.set_shader_parameter("time_tint", sky_tint)
	Camera.this.darkness.color = lerp(Darkness_Min, Darkness_Max, get_darkness(TimeManager.hour, TimeManager.minute))
	
static func get_sky_tint(hour: int, minute: int) -> Color:
	var t = hour + minute / 60.0 
	if t < 4.0: return Sky_Night_Tint # 00:00 - 04:00
	elif t < 6.0: return Sky_Night_Tint.lerp(Sky_Morning_Tint, (t - 4.0) / 2.0) # 04:00 - 06:00
	elif t < 12.0: return Sky_Morning_Tint.lerp(Sky_Day_Tint, (t - 6.0) / 6.0) # 06:00 - 12:00
	elif t < 15.0: return Sky_Day_Tint # 12:00 - 15:00
	elif t < 18.0: return Sky_Day_Tint.lerp(Sky_Evening_Tint, (t - 15.0) / 3.0) # 15:00 - 18:00
	elif t < 22.0: return Sky_Evening_Tint.lerp(Sky_Night_Tint, (t - 18.0) / 4.0) # 18:00 - 22:00
	else: return Sky_Night_Tint.lerp(Sky_Night_Tint, (t - 22.0) / 2.0) # 22:00 - 00:00
	
static func get_darkness(hour: int, minute: int) -> float:
	var t = hour + minute / 60.0
	if t < 4.0: return 1.0 # 00:00 - 04:00 = 1.0
	elif t < 9.0: return lerp(1.0, 0.0, (t - 4.0) / 5.0) # 04:00 - 09:00 = 1.0 -> 0.0
	elif t < 16.0: return 0.0 # 09:00 -> 16:00 = 0.0
	else: return lerp(0.0, 1.0, (t - 16.0) / 8.0) # 16:00 -> 24:00 = 0.0 -> 1.0
#endregion

#region Forecast
const Forecast_Hours_Ahead: int = 72
const Min_Weather_Change_Interval: int = 180 # Next weather change in not less than X minutes
const Max_Weather_Change_Interval: int = 720 # Max cap
static var forecast: Array[WeatherEvent] = []
static var current_forecast: WeatherEvent
	
static func progress_forecast() -> void:
	var now: Dictionary = TimeManager._now()
	
	if forecast.size() > 0:
		var next_event: WeatherEvent = forecast[0]
		if !TimeManager.is_date_before(now, next_event.start_time):
			current_forecast = next_event
			current_forecast._print_data()
			forecast.remove_at(0)

static func ensure_forecast() -> void:
	var now: Dictionary = TimeManager._now()
	var target_time: Dictionary = TimeManager._calculate_minute_addition(now, Forecast_Hours_Ahead * 60)
	var last_event_time: Dictionary
	
	if forecast.size() == 0:
		if is_instance_valid(current_forecast): last_event_time = current_forecast.start_time
		else:
			last_event_time = now
			var first_event = generate_single_forecast_event(last_event_time)
			forecast.append(first_event)
	else: last_event_time = forecast[forecast.size() - 1].start_time
	
	while TimeManager.is_date_before(last_event_time, target_time):
		last_event_time = TimeManager._calculate_minute_addition(last_event_time, randi_range(Min_Weather_Change_Interval, Max_Weather_Change_Interval))
		var ev = generate_single_forecast_event(last_event_time)
		forecast.append(ev)
		
static func generate_single_forecast_event(start_time: Dictionary) -> WeatherEvent:
	var e = WeatherEvent.new()
	e.start_time = start_time
	
	var conditions = [ WeatherCondition.Clear, WeatherCondition.Rain ]
	e.condition = conditions[randi() % conditions.size()]
	
	# Rain
	if e.condition == WeatherCondition.Rain: e.rain_intensity = randf_range(0.33, 1.0)
	else: e.rain_intensity = 0.0
	
	e.wind_velocity = randf_range(-1.0, 1.0) # Wind
	return e
#endregion
