extends Node
class_name SoundLib

#region UI
static var ui_click_sound: AudioStream = load("res://Sounds/UI/UIClick.ogg")
static var ui_cancel_sound: AudioStream = load("res://Sounds/UI/UICancel.ogg")
static var ui_hover_sound: AudioStream = load("res://Sounds/UI/UIHover.ogg")
static var ui_heartbeat_sound: AudioStream = load("res://Sounds/UI/Heartbeat.ogg")
#endregion

#region Inventory
static var pick_sound: AudioStream = load("res://Sounds/Effects/PickUp.ogg")
static var drop_sound: AudioStream = load("res://Sounds/Effects/Drop.ogg")
static var inventory_sounds: Array[AudioStream] = [load("res://Sounds/Effects/Inventory1.ogg"),
													load("res://Sounds/Effects/Inventory2.ogg"),
													load("res://Sounds/Effects/Inventory3.ogg"),
													load("res://Sounds/Effects/Inventory4.ogg")]
static var equip_sounds: Array[AudioStream] = [load("res://Sounds/Effects/Equip1.ogg"),
												load("res://Sounds/Effects/Equip2.ogg")]
static var clothes_sounds: Array[AudioStream] = [load("res://Sounds/Effects/Clothes1.ogg"),
												load("res://Sounds/Effects/Clothes2.ogg"),
												load("res://Sounds/Effects/Clothes3.ogg")]
#endregion

#region Human
static var resist_sounds: Array[AudioStream] = [load("res://Sounds/Effects/Resist1.ogg"),
												load("res://Sounds/Effects/Resist2.ogg"),
												load("res://Sounds/Effects/Resist3.ogg")]
static var grab_sound: AudioStream = load("res://Sounds/Effects/Grab.ogg")
static var push_sound: AudioStream = load("res://Sounds/Effects/Push.ogg")
static var lunge_sound: AudioStream = load("res://Sounds/Effects/Lunge.ogg")
static var body_fall_sound: AudioStream = load("res://Sounds/Effects/BodyFall.ogg")
static var trip_sound: AudioStream = load("res://Sounds/Effects/Trip.ogg")
static var inhale_sounds: Array[AudioStream] = [load("res://Sounds/Effects/Inhale1.ogg"), load("res://Sounds/Effects/Inhale2.ogg")]
static var exhale_sounds: Array[AudioStream] = [load("res://Sounds/Effects/Exhale1.ogg"),
												load("res://Sounds/Effects/Exhale2.ogg"),
												load("res://Sounds/Effects/Exhale3.ogg")]
static var eat_sound: AudioStream = load("res://Sounds/Effects/Eat.ogg")
static var drink_sound: AudioStream = load("res://Sounds/Effects/Drink.ogg")
#endregion

#region Sex
static var sex_clap_sounds: Array[AudioStream] = [load("res://Sounds/Sex/Clap1.ogg"), 
												load("res://Sounds/Sex/Clap2.ogg"),
												load("res://Sounds/Sex/Clap3.ogg"),
												load("res://Sounds/Sex/Clap4.ogg"),
												load("res://Sounds/Sex/Clap5.ogg"),
												load("res://Sounds/Sex/Clap6.ogg"),
												load("res://Sounds/Sex/Clap7.ogg"),
												load("res://Sounds/Sex/Clap8.ogg")]
static var cum_inside_sounds: Array[AudioStream] = [load("res://Sounds/Sex/CumInside1.ogg"),
													load("res://Sounds/Sex/CumInside2.ogg"),
													load("res://Sounds/Sex/CumInside3.ogg")]
static var cum_sound: AudioStream = load("res://Sounds/Sex/Cum.ogg")
static var cum_collide_sound: AudioStream = load("res://Sounds/Sex/CumCollide.ogg")
#endregion

#region Footsteps
static var asphalt_footsteps: Array[AudioStream] = [load("res://Sounds/Steps/Asphalt1.ogg"),
													load("res://Sounds/Steps/Asphalt2.ogg"),
													load("res://Sounds/Steps/Asphalt3.ogg")]
#endregion

#region Ambience
static var wind_sounds: Array[AudioStream] = [load("res://Sounds/Ambient/Wind1.ogg"),
											load("res://Sounds/Ambient/Wind2.ogg"), 
											load("res://Sounds/Ambient/Wind3.ogg")]
#endregion
