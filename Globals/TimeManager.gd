extends Node
class_name TimeManager

static var year: int = 2008
static var month: int = 8
static var day: int = 24
static var hour: int = 8
static var minute: int = 0

const Seconds_Per_Minute: float = .33
static var _accumulated_real_time: float = 0.0

static var weekdays: Array[String] = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

static var days_in_month: Array[int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
static func is_leap_year(y: int) -> bool: return (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0)

static func _tick(delta: float) -> void:
	_accumulated_real_time += delta
	while _accumulated_real_time >= Seconds_Per_Minute:
		_accumulated_real_time -= Seconds_Per_Minute
		add_minutes(1)

static func add_minutes(minutes_to_add: int) -> void:
	var dict: Dictionary = _calculate_minute_addition(_now(), minutes_to_add)
	set_time(dict)

static func set_time(dict: Dictionary) -> void:
	year = dict["year"]
	month = dict["month"]
	day = dict["day"]
	hour = dict["hour"]
	minute = dict["minute"]
	InventoryManager.time_label.text = "%s, %s" % [get_time_string(), get_date_string()]

static func _calculate_minute_addition(dictionary: Dictionary, minutes_to_add: int) -> Dictionary:
	var dict: Dictionary = dictionary.duplicate()
	dict["minute"] += minutes_to_add
	
	# Minutes to hours
	while dict["minute"] >= 60:
		dict["minute"] -= 60
		dict["hour"] += 1
		
	# Hours to days
	while dict["hour"] >= 24:
		dict["hour"] -= 24
		dict["day"] += 1
		
	# Days to months
	var dim = days_in_month.duplicate()
	if is_leap_year(dict["year"]): dim[1] = 29  # February in leap year
	
	while dict["day"] > dim[dict["month"] - 1]:
		dict["day"] -= dim[dict["month"] - 1]
		dict["month"] += 1
		if dict["month"] > 12:
			dict["month"] = 1
			dict["year"] += 1
	
	return dict
			
static func get_weekday() -> String:
	# Calculate weekday (January 1st of year 1 is Monday)
	var total_days = 0
	for y in range(1, year): total_days += 366 if is_leap_year(y) else 365

	for m in range(1, month):
		var dim = days_in_month[m - 1]
		if m == 2 && is_leap_year(year): dim = 29
		total_days += dim

	total_days += day - 1  # Count current day
	return weekdays[total_days % 7]

static func get_time_string() -> String: return "%02d:%02d" % [hour, minute]
static func get_date_string() -> String: return "%s, %02d/%02d/%03d" % [get_weekday(), day, month, year]
static func _now() -> Dictionary: return { "year" = year, "month" = month, "day" = day, "hour" = hour, "minute" = minute }

static func is_date_before(a: Dictionary, b: Dictionary) -> bool:
	if a["year"] != b["year"]: return a["year"] < b["year"]
	if a["month"] != b["month"]: return a["month"] < b["month"]
	if a["day"] != b["day"]: return a["day"] < b["day"]
	if a["hour"] != b["hour"]: return a["hour"] < b["hour"]
	return a["minute"] < b["minute"]
