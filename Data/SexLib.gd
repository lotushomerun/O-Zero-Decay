extends Node
class_name SexLib

# Keys:

# same_facing : bool (Should both chars face the same direction?)
# top_above : bool (Is the top char getting drawn on top of the bottom one layering-wise?)
# role_path : String (AnimationTree param path to a transition that decides char's role in sex)
# top_collision_shape : String (Name of the collision shape var top char needs to assume)
# bottom_collision_shape : String (Same as above but for the bottom char)

# top_thrust_path : String (param path to a top one shot thrust)
# bottom_thrust_path : String (same as above but for bottom)

# top_orgasm_shot_path : String (OneShot for when top char ejaculates, MUST HAVE 'BeforeOrgasm' and 'AfterOrgasm' states!!!)
# bottom_orgasm_add_path : String (Add path for when bottom char orgasms, it's never a OneShot!)

# top_orgasm_transition_path : String (Transition before/after orgasm)
# bottom_orgasm_transition_path : String (Same as above, you can leave this empty if it's not present in your animation tree)

# penetration_sounds : Array (A random sound from this array will get picked, sounds should be loaded)

# (Affects bones (in some cases sprites), you can leave these empty if you don't have any offsets):
# top_front_leg_z_offset : int
# top_back_leg_z_offset : int
# top_front_arm_z_offset : int
# top_back_arm_z_offset : int
# top_penis_z_offset : int
# ----------
# bottom_front_leg_z_offset : int
# bottom_back_leg_z_offset : int
# bottom_front_arm_z_offset : int
# bottom_back_arm_z_offset : int
# bottom_penis_z_offset : int

static var sex_data: Dictionary

# Populate this function with your datas, it's getting called in SaveState on _ready
static func _init_sex_data() -> void:
	sex_data["DoggySex"] = doggy_data

static var doggy_data: Dictionary = {
	"same_facing" : true,
	"top_above" : true,
	"top_collision_shape" : "laying_shape",
	"bottom_collision_shape" : "laying_shape",
	
	"role_path" : "parameters/Role/transition_request",
	"top_thrust_path" : "parameters/TopThrustShot/request",
	"bottom_thrust_path" : "parameters/BottomThrustShot/request",
	"top_orgasm_shot_path" : "parameters/TopOrgasmShot/request",
	"bottom_orgasm_add_path" : "parameters/BottomOrgasmAdd/add_amount",
	"top_orgasm_transition_path" : "parameters/OrgasmState/transition_request",
	
	"penetration_sounds" : SoundLib.sex_clap_sounds,
	"top_back_arm_z_offset" : -15,
	"top_back_leg_z_offset" : -15,
	"top_penis_z_offset" : -15,
}
