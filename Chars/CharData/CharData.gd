extends Resource
class_name CharData

#region Personality
@export var known_as: String = "Unknown"
@export_range(18, 999) var age: int = 18

enum GenderIdentity { MALE, FEMALE, NONBINARY }
@export var identity: GenderIdentity = GenderIdentity.NONBINARY
#endregion

#region Icons
@export_group("Icons")
@export var haircut: Texture2D
#endregion

#region Colors
@export_group("Colors")
@export var eye_color: Color = Color.CORNFLOWER_BLUE
@export var hair_color: Color = Color.SADDLE_BROWN
@export_range(0.0, 100.0, 0.1) var skin_tone: float = 0.0

static var eye_colors_pool := {
	"Blue": Color(0.149, 0.411, 0.71, 1.0),
	"Green": Color(0.324, 0.47, 0.211, 1.0),
	"Brown": Color(0.375, 0.186, 0.094, 1.0),
	"Hazel": Color(0.64, 0.431, 0.204, 1.0),
	"Black": Color(0.066, 0.054, 0.043, 1.0),
}

static var hair_colors_pool := {
	"Light Brown": Color(0.375, 0.186, 0.094, 1.0),
	"Dark Brown": Color(0.22, 0.091, 0.062, 1.0),
	"Blonde": Color(0.771, 0.543, 0.194, 1.0),
	"Light Blonde": Color(0.97, 0.724, 0.48, 1.0),
	"Black": Color(0.062, 0.068, 0.09, 1.0),
	"Ginger": Color(0.76, 0.34, 0.114, 1.0),
}

func get_eye_color_name() -> String:
	for key in eye_colors_pool.keys(): if eye_colors_pool[key] == eye_color: return key
	return "Unknown"
	
func get_hair_color_name() -> String:
	for key in hair_colors_pool.keys(): if hair_colors_pool[key] == hair_color: return key
	return "Unknown"
#endregion

#region Gender
@export_group("Gender")
enum Height { SHORT, MEDIUM, TALL }
@export_range(0.0, 1.0, 0.01) var body_weight: float = 0.5
@export_range(0.0, 1.0, 0.01) var body_height: Height = Height.MEDIUM

enum AppearanceType { MASCULINE, FEMININE, ANDROGYNOUS }
@export var appearance: AppearanceType = AppearanceType.ANDROGYNOUS # How you are generally percieved from your looks

enum VoiceType { MASCULINE, FEMININE, ANDROGYNOUS }
@export var voice: VoiceType = VoiceType.ANDROGYNOUS

@export var male_genitals: bool = true
@export var has_breasts: bool = false
#endregion

#region Perception
enum NPCPerception { MASCULINE, FEMININE, ANDROGYNOUS }

func npc_perceived_gender() -> NPCPerception:
	var score = 0
	
	# Base appearance
	match appearance:
		AppearanceType.MASCULINE: score += 1
		AppearanceType.ANDROGYNOUS: score += 0
		AppearanceType.FEMININE: score -= 1
	
	# Voice
	match voice:
		VoiceType.MASCULINE: score += 1
		VoiceType.ANDROGYNOUS: score += 0
		VoiceType.FEMININE: score -= 1
	
	# Tits are feminine bro
	if has_breasts: score -= 1
	
	if score >= 2: return NPCPerception.MASCULINE
	elif score <= -2: return NPCPerception.FEMININE
	else: return NPCPerception.ANDROGYNOUS
#endregion

#region Randomizer
enum Archetype { MALE, FEMALE, FEMBOY, TOMBOY }

func randomize_me(archetype: Archetype):
	age = randi_range(18, 21)
	
	match archetype:
		
		Archetype.MALE:
			identity = GenderIdentity.MALE
			appearance = AppearanceType.MASCULINE
			voice = VoiceType.MASCULINE
			male_genitals = true
			has_breasts = false
			
		Archetype.FEMALE:
			identity = GenderIdentity.FEMALE
			appearance = AppearanceType.FEMININE
			voice = VoiceType.FEMININE
			male_genitals = false
			has_breasts = true
			
		Archetype.FEMBOY:
			identity = GenderIdentity.MALE
			appearance = AppearanceType.FEMININE
			voice = VoiceType.ANDROGYNOUS
			male_genitals = true
			has_breasts = false
			
		Archetype.TOMBOY:
			identity = GenderIdentity.FEMALE
			appearance = AppearanceType.ANDROGYNOUS
			voice = VoiceType.ANDROGYNOUS
			male_genitals = false
			has_breasts = false
	
	known_as = JsonInfo.get_random_name(GenderIdentity.keys()[identity])
	haircut = HairLib.haircuts.pick_random()
	
	# Colors
	var eye_keys = eye_colors_pool.keys()
	var hair_keys = hair_colors_pool.keys()
	
	#skin_tone = randf_range(0.0, 100.0)
	#skin_tone = randf_range(0.0, 35.0)
	body_height = Height.values().pick_random()
	body_weight = randf_range(0.0, 1.0)
	eye_color = eye_colors_pool[eye_keys[randi() % eye_keys.size()]]
	hair_color = hair_colors_pool[hair_keys[randi() % hair_keys.size()]]
#endregion
