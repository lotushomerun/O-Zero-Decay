extends Node
class_name SoundManager

static func play_sound_2d(sound: AudioStream, position: Vector2, volume_db: float = 0.0) -> AudioStreamPlayer2D:
	var player := AudioStreamPlayer2D.new()
	
	var tree := Engine.get_main_loop() as SceneTree
	tree.current_scene.add_child(player)

	player.global_position = position
	player.volume_db = volume_db
	player.max_distance = 500.0

	var stream: AudioStream = sound
	if stream == null:
		player.queue_free()
		return null

	player.stream = stream
	player.play()

	player.finished.connect(Callable(func(): player.queue_free()))
	return player
	
static func play_sound_ui(sound: AudioStream, volume_db: float = 0.0) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	
	var tree := Engine.get_main_loop() as SceneTree
	tree.current_scene.add_child(player)

	player.volume_db = volume_db

	var stream: AudioStream = sound
	if stream == null:
		player.queue_free()
		return null

	player.stream = stream
	player.play()

	player.finished.connect(Callable(func(): player.queue_free()))
	return player
