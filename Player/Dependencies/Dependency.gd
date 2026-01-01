extends Resource
class_name Dependency

var description: String = "You have no special dependency."

var timer_seconds: float = 0.0
var thresholds: Array[float] = []

var full_satisfy_on_use: bool = false
var allow_negative_timer: bool = false

var _thresholds_reached: Dictionary = {} # key is threshold in seconds, value is bool (reached or nah)

#region Static
static func get_dependency(dependency_class: String) -> Dependency:
	for i in range(Player.dependencies.size()):
		var d: Dependency = Player.dependencies[i]
		if d && str(d.get_script().get_global_name()) == dependency_class: return d
	return null
	
static func add_dependency(dependency: Dependency) -> void:
	dependency.on_add_dependency()
	_add_dependency(dependency)
	
static func remove_dependency(dependency: Dependency) -> void:
	dependency.on_remove_dependency()
	_remove_dependency(dependency)
	
static func _add_dependency(dependency: Dependency) -> void:
	if dependency in Player.dependencies: return
	dependency._on_add_dependency()
	Player.dependencies.append(dependency)
	
static func _remove_dependency(dependency: Dependency) -> void:
	dependency._on_remove_dependency()
	Player.dependencies.erase(dependency)
#endregion

func _init() -> void: for t: float in thresholds: _thresholds_reached[t] = false

func satisfy(amount: float) -> void:
	if full_satisfy_on_use: timer_seconds = 0.0
	else:
		timer_seconds -= amount
		if !allow_negative_timer && timer_seconds < 0.0: timer_seconds = 0.0
	_check_thresholds()
	
# Public (for showing messages and stuff, something that would happen if you got the dependency at spawn for example and not acquire it)
func on_add_dependency() -> void: pass
func on_remove_dependency() -> void: pass

# Private (technical part)
func _on_add_dependency() -> void: pass
func _on_remove_dependency() -> void: pass
	
func _tick(delta: float) -> void:
	timer_seconds += delta
	_check_thresholds()
	
func _check_thresholds() -> void:
	for t: float in thresholds:
		var reached: bool = _thresholds_reached.get(t, false)
		
		if timer_seconds >= t and !reached:
			_thresholds_reached[t] = true
			_on_threshold_reached(t)
	
	# When leaving thresholds - going from the end of the array
	for i in range(thresholds.size() - 1, -1, -1):
		var t: float = thresholds[i]
		var reached: bool = _thresholds_reached.get(t, false)
		
		if timer_seconds < t and reached:
			_thresholds_reached[t] = false
			_on_threshold_left(t)
			
func _on_threshold_reached(_threshold: float) -> void: pass
func _on_threshold_left(_threshold: float) -> void: pass
