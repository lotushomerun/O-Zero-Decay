extends ColorRect
class_name LevelTransitionEffect
static var this: LevelTransitionEffect

func _ready() -> void:
	this = self
	fade(true, .33)

static func fade(out: bool, time: float) -> bool: ## 'out' = true to remove the effect, false to show black screen
	var tree := Engine.get_main_loop() as SceneTree
	await tree.create_timer(.1).timeout # Wait just a tit bit before transition effect
	var tween: Tween = tree.create_tween()
	tween.tween_property(this, "color:a", 1.0 if !out else 0.0, time)
	await tween.finished
	return true
