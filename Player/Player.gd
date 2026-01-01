extends Node2D
class_name Player

@export_group("Refs")
@export var character: Char
@onready var behavior_tree: BehaviorTree = $BehaviorTree

static var this: Player
static var interactable: Interactable # What's under mouse
static var dependencies: Array[Dependency] = []
static func register_instance(instance: Player) -> void: this = instance

#region Ready
func _ready() -> void:
	register_instance(self)
	
	if character.movement == null: push_error("Player: Movement not found!")
	if character == null: push_error("Player: Char not found!")
	
	# Spawn camera
	var new_camera: Camera = load("res://Player/Camera.tscn").instantiate()
	character.add_child(new_camera)
	
	await get_tree().create_timer(0.1).timeout
	
	# Get to spawn position if there's one
	var door_id: String = SaveState.get_spawn_door()
	if door_id.length() > 0: Door.position_at_door(character, door_id)
	
	about_player()
	#random_loadout()
	
	if !is_instance_valid(Dependency.get_dependency("FoodDependency")): Dependency.add_dependency(FoodDependency.new())
#endregion

#region Temp
func random_loadout() -> void:
	var shirt_instance: Area2D = ClothesLib.create_clothes_item(ClothesData.ClothesType.Shirt)
	var pants_instance: Area2D = ClothesLib.create_clothes_item(ClothesData.ClothesType.Pants)
	var socks_instance: Area2D = ClothesLib.create_clothes_item(ClothesData.ClothesType.Socks)
	var shoes_instance: Area2D = ClothesLib.create_clothes_item(ClothesData.ClothesType.Shoes)
	var bra_instance: Area2D = ClothesLib.create_clothes_item(ClothesData.ClothesType.Bra)
	var panties_instance: Area2D = ClothesLib.create_clothes_item(ClothesData.ClothesType.Panties)
	
	var cap_instance: Area2D = ClothesLib.create_clothes_item(ClothesData.ClothesType.Hat)
	
	var backpack_instance: Area2D = ClothesLib.generate_backpack_item()
	var backpack_item: BackpackItem = backpack_instance.get_node("BackpackItem") as BackpackItem
	backpack_item.inventory_container._force_add_item(cap_instance)
	force_equip_backpack(backpack_instance)
	
	var to_equip: Array[Area2D] = [bra_instance, panties_instance, shirt_instance, pants_instance, socks_instance, shoes_instance]
	for node: Area2D in to_equip: force_equip_clothes(node)

func about_player() -> void:
	var human: Human = character
	var data: CharData = human.char_data
	
	var gender_name: String = CharData.GenderIdentity.keys()[data.identity]
	var appearance_name: String = CharData.AppearanceType.keys()[data.appearance]
	var voice_name: String = CharData.VoiceType.keys()[data.voice]
	
	var penis_text: String = "You have a penis" if data.male_genitals else "You have a vagina"
	var breasts_text: String = "you have breasts" if data.has_breasts else "your chest is flat"
	
	var npc_perception: CharData.NPCPerception = data.npc_perceived_gender()
	var perceived_as: String
	
	match npc_perception:
		CharData.NPCPerception.MASCULINE: perceived_as = "You are generally seen as a male"
		CharData.NPCPerception.FEMININE: perceived_as = "You are generally seen as a female"
		CharData.NPCPerception.ANDROGYNOUS: perceived_as = "People are generally unsure of your gender"
	
	Chatbox.regular_message("[color=info]You're known as %s. You're %d years old. You consider yourself to be %s. You look %s, your voice sounds %s. %s and %s. %s.[/color]" % 
	[data.known_as, data.age, gender_name.to_lower(), appearance_name.to_lower(), voice_name.to_lower(), penis_text, breasts_text, perceived_as])
	
	var hair_color_text: String = "Your hair is [i][color=%s]%s[/color][/i]" % [data.hair_color.to_html(), data.get_hair_color_name().to_lower()]
	var eye_color_text: String = "your eyes are [i][color=%s]%s[/color][/i]" % [data.eye_color.to_html(), data.get_eye_color_name().to_lower()]
	Chatbox.regular_message("[color=info]%s, %s.[/color]" % [hair_color_text, eye_color_text])
#endregion

#region Process
func _process(delta: float) -> void:
	handle_input()
	handle_debug_input()
	_process_dependencies(delta)
	
func _process_dependencies(delta: float) -> void:
	for dependency in dependencies: dependency._tick(delta)
#endregion

#region Inputs
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT: left_click()
			elif event.button_index == MOUSE_BUTTON_RIGHT: right_click()
			elif event.button_index == MOUSE_BUTTON_MIDDLE: middle_click()
				
func left_click() -> void:
	if is_instance_valid(interactable):
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		if Context.this.visible:
			if !Context.this.get_rect().has_point(mouse_pos): Context.hide_context()
		else:
			if interactable.primary_action != null && interactable.primary_action._valid([character, interactable]):
				interactable.primary_action._execute([character, interactable]) # Primary action click
	
func right_click() -> void:
	if Context.this.visible: Context.hide_context()
	if interactable != null: Context.show_context(interactable, get_viewport().get_mouse_position() + Context.context_offset)
	
func middle_click() -> void:
	pass

func handle_input() -> void:
	if character.movement == null: return
	
	var x_input = (1 if Input.is_action_pressed("right") else 0) - (1 if Input.is_action_pressed("left") else 0);
	var dir := Vector2.ZERO
		
	dir.x = x_input
	
	if dir.x != 0: # We're trying to move the player
		if Context.this.visible: Context.hide_context()
		if InventoryManager.open_storage != null:
			InventoryManager.open_storage.inventory_container._get_items(InventoryManager.storage)
			InventoryManager.hide_inventory(InventoryManager.storage)
			InventoryManager.open_storage = null
	
	character.movement.direction = dir
	character.movement.sprinting = Input.is_action_pressed("sprint")
	
	var human: Human = character as Human
	var human_rig: HumanRig = human.rig as HumanRig
	
	if (character.mobility != Char.Mobility.None && human.use_body_lean):
		var global_mouse: Vector2 = get_global_mouse_position()
		var mouse_dir = global_mouse.x - character.global_position.x
		var need_to_turn: bool = (mouse_dir < 0 && character.rig.facing_right) || (mouse_dir > 0 && !character.rig.facing_right)
		
		# Combat!
		if (character.mobility == Char.Mobility.Full):
			var shove_input: bool = Input.is_action_just_pressed("shove")
			var lunge_input: bool = Input.is_action_just_pressed("lunge")
			var shove_or_lunge: bool = shove_input || lunge_input
			
			if shove_or_lunge && human.stamina.fatigue < Stamina.Exhausted_Threshold_Base:
				
				if need_to_turn: character.rig.flip_skeleton()
				human_rig.head_track_to(global_mouse)
				human_rig.look_front()
				
				if shove_input: human.combat.shove()
				else: human.combat.lunge()
				return
		
		if character.mobility == Char.Mobility.Full && need_to_turn && character.movement.is_moving_backwards(): character.rig.flip_skeleton()
		
		if !Context.this.visible:
			Camera.this.designated_offset = Vector2(Camera.Look_Offset.x if mouse_dir > 0 else -Camera.Look_Offset.x, 0.0)
			if !need_to_turn:
				human_rig.head_track_to(global_mouse)
				human_rig.look_front()
			else: # Bombastic side eye
				var mouse_y_delta: float = global_mouse.y - human_rig.head_node.global_position.y
				human_rig.head_track_to(human_rig.head_node.global_position + Vector2(128.0 if human_rig.facing_right else -128.0, -mouse_y_delta))
				human_rig.look_back()

func handle_debug_input() -> void:
	if character.movement == null: return
		
	if Input.is_action_just_pressed("debug1"):
		var human_char: Human = character as Human
		if is_instance_valid(human_char.sex.sex_partner): return
		
		var sex_partner_instance: Human = load("res://Chars/Human/Human.tscn").instantiate()
		get_tree().current_scene.add_child(sex_partner_instance)
		sex_partner_instance.global_position = character.global_position
		
		var human_rig: HumanRig = human_char.rig as HumanRig
		var partner_rig: HumanRig = sex_partner_instance.rig as HumanRig
		
		await get_tree().process_frame
		human_char.sex.start_sex_with(sex_partner_instance, human_rig.doggy_sex_tree, partner_rig.doggy_sex_tree)
		sex_partner_instance.sex.on_sex_end.connect(sex_partner_instance.queue_free)
		
	#if Input.is_action_just_pressed("debug1"): pass
		#for ev: Weather.WeatherEvent in Weather.forecast: ev._print_data()
		
	#if Input.is_action_just_pressed("debug1"):
		#var follower_instance: Node2D = load("res://Chars/AI/Dummy/Dummy.tscn").instantiate()
		#get_tree().current_scene.add_child(follower_instance)
		#follower_instance.global_position = character.global_position
		#
		#var char_ref: Char
		#for node: Node in follower_instance.get_children():
			#if node is Char:
				#char_ref = node
				#break
		#
		#char_ref.ai.behavior_tree.tree = load("res://Chars/AI/Trees/TargetNavigation.tres")
		#char_ref.ai.behavior_tree.bb_set("target", character)
		#SaveState.add_follower(char_ref._get_follower_data())
#endregion

#region Inventory
func force_give_item(item_instance: Area2D) -> void:
	var item: Item
	for node: Node in item_instance.get_children():
		if node is Item:
			item = node
			break
			
	if !InventoryManager.inventory.items.has(item): InventoryManager.inventory.add_item(item)
	
func force_equip_clothes(clothes_instance: Area2D) -> void:
	var clothes_item: ClothesItem = clothes_instance.get_node("ClothesItem") as ClothesItem
	if !InventoryManager.inventory.items.has(clothes_item): InventoryManager.inventory.add_item(clothes_item)
	clothes_item.is_equipped = true
	character.rig.put_on_clothes(clothes_item)
	
func force_equip_backpack(backpack_instance: Area2D) -> void:
	var backpack_item: BackpackItem = backpack_instance.get_node("BackpackItem") as BackpackItem
	if !InventoryManager.inventory.items.has(backpack_item): InventoryManager.inventory.add_item(backpack_item)
	backpack_item.is_equipped = true
	backpack_item._equip(character.rig as HumanRig)
	backpack_item.inventory_container._give_items(InventoryManager.backpack)
	InventoryManager.show_inventory(InventoryManager.backpack)
#endregion
