extends Rig
class_name HumanRig

#region Refs
@export_group("Refs")
@export var movement_tree: AnimationTree
@export var wrestling_tree: AnimationTree
@export var doggy_sex_tree: AnimationTree
var current_animation_tree: AnimationTree

func select_animation_tree(new_tree: AnimationTree) -> void:
	if is_instance_valid(current_animation_tree): current_animation_tree.active = false
	new_tree.active = true
	current_animation_tree = new_tree
#endregion

#region Sex-Refs
@export_group("Sex-Refs")
@export var penis_tip_marker: Marker2D
@export var groin_area: Area2D
#endregion

#region Textures
@export_group("Textures")
@export var breasts_texture: Texture2D
@export var no_breasts_texture: Texture2D
#endregion

#region Nodes
@export_group("Nodes")
@export var eyes_node: Sprite2D
@export var hair_node: Sprite2D
@export var penis_node: Sprite2D

@export var head_node: Sprite2D
@export var chest_node: Sprite2D
@export var spine_node: Sprite2D

@export var front_upper_arm_node: Sprite2D
@export var front_lower_arm_node: Sprite2D
@export var front_hand_node: Sprite2D

@export var back_upper_arm_node: Sprite2D
@export var back_lower_arm_node: Sprite2D
@export var back_hand_node: Sprite2D

@export var front_upper_leg_node: Sprite2D
@export var front_lower_leg_node: Sprite2D
@export var front_foot_node: Sprite2D

@export var back_upper_leg_node: Sprite2D
@export var back_lower_leg_node: Sprite2D
@export var back_foot_node: Sprite2D

var body_nodes: Array[Sprite2D] = []
var has_breasts: bool = false
var has_penis: bool = false

var front_body_shader: ShaderMaterial
var back_body_shader: ShaderMaterial
var hair_shader: ShaderMaterial

@onready var water_droplets: GPUParticles2D = $WaterDroplets
#endregion

#region Bones
@export_group("Bones")
@export var head_bone: Bone2D
@export var front_upper_arm_bone: Bone2D
@export var back_upper_arm_bone: Bone2D
@export var front_upper_leg_bone: Bone2D
@export var back_upper_leg_bone: Bone2D
#endregion

#region Ready
func _ready() -> void:
	body_nodes = [head_node, chest_node, spine_node, front_upper_arm_node, front_lower_arm_node, front_hand_node,
	back_upper_arm_node, back_lower_arm_node, back_hand_node, front_upper_leg_node, front_lower_leg_node, front_foot_node,
	back_upper_leg_node, back_lower_leg_node, back_foot_node]
	
	shirt_nodes = [chest_shirt_node, spine_shirt_node, front_upper_arm_shirt_node, front_lower_arm_shirt_node,
	back_upper_arm_shirt_node, back_lower_arm_shirt_node]
	
	jacket_nodes = [chest_jacket_node, spine_jacket_node, front_upper_arm_jacket_node, front_lower_arm_jacket_node,
	back_upper_arm_jacket_node, back_lower_arm_jacket_node]
	
	pants_nodes = [spine_pants_node, front_upper_leg_pants_node, front_lower_leg_pants_node, back_upper_leg_pants_node, back_lower_leg_pants_node]
	
	socks_nodes = [front_upper_leg_sock_node, front_lower_leg_sock_node, front_sock_node, back_upper_leg_sock_node, back_lower_leg_sock_node, back_sock_node]
	shoes_nodes = [front_shoe_node, back_shoe_node]
	
	front_body_shader = front_upper_arm_node.material as ShaderMaterial
	back_body_shader = back_upper_arm_node.material as ShaderMaterial
	hair_shader = hair_node.material as ShaderMaterial
	
	movement_tree.active = false
	wrestling_tree.active = false
	select_animation_tree(movement_tree)
#endregion

#region Process
func _process(_delta: float) -> void:
	_process_all_clothes_data()
#endregion

#region Appearance
func load_appearance(char_data: CharData) -> void:
	eye_color = char_data.eye_color
	hair_color = char_data.hair_color
	skin_tone = char_data.skin_tone
	has_breasts = char_data.has_breasts
	has_penis = char_data.male_genitals
	body_weight = char_data.body_weight
	body_height = char_data.body_height
	hair_node.texture = char_data.haircut
	#skin_dirtiness = 0.7
	
	# Tits / no tits sprite
	for node: Sprite2D in body_nodes:
		if char_data.has_breasts: node.texture = load(breasts_texture.resource_path)
		else: node.texture = load(no_breasts_texture.resource_path)
	
	# Show / hide penix
	if char_data.male_genitals: penis_node.show()
	else: penis_node.hide()

var eye_color: Color = Color.CORNFLOWER_BLUE: # You guessed it
	set(value):
		eye_color = value
		
		if (eyes_node == null):
			push_warning("HumanRig: Eyes not found!")
			return
			
		var shadermat: ShaderMaterial = eyes_node.material
		shadermat.set_shader_parameter("target_color", value)
		
var hair_color: Color = Color.ALICE_BLUE:
	set(value):
		hair_color = value
		
		if (hair_node == null || hair_shader == null):
			push_warning("HumanRig: Hair node / shader not found!")
			return
			
		hair_shader.set_shader_parameter("target_color", value)
		
var body_weight: float = 0.5:
	set(value):
		body_weight = clampf(value, 0.0, 1.0)
		var max_delta: float = 0.1
		var delta: float = (body_weight - 0.5) * 2.0 * max_delta
		
		var nodes_to_scale: Array[Sprite2D] = [spine_node, chest_node, front_upper_arm_node, front_lower_arm_node,
		back_upper_arm_node, back_lower_arm_node, front_upper_leg_node, front_lower_leg_node, back_upper_leg_node,
		back_lower_leg_node,
		
		front_upper_leg_sock_node, front_lower_leg_sock_node, back_upper_leg_sock_node, back_lower_leg_sock_node,
		
		bra_node, panties_node]
		
		nodes_to_scale.append_array(shirt_nodes)
		nodes_to_scale.append_array(jacket_nodes)
		nodes_to_scale.append_array(pants_nodes)
		
		for node: Sprite2D in nodes_to_scale: node.scale.x = 1.0 + delta

var body_height: CharData.Height = CharData.Height.MEDIUM:
	set(value):
		body_height = value
		
		var body_height_float: float = 0.0
		var max_delta: float = 0.05
		if body_height != CharData.Height.MEDIUM: body_height_float = (max_delta if body_height == CharData.Height.TALL else -max_delta)
		
		skeleton.position.y = 0.0
		if body_height != CharData.Height.MEDIUM: skeleton.position.y = (2 if body_height_float == -max_delta else -2)
		skeleton.scale.y = 1.0 + body_height_float
		head_bone.scale.y = 1.0 - body_height_float # Avoid head squish

var skin_tone: float = 0.0:
	set(value):
		skin_tone = value
		front_body_shader.set_shader_parameter("skin_tone", skin_tone)
		back_body_shader.set_shader_parameter("skin_tone", skin_tone)
		
var skin_dirtiness: float = 0.0:
	set(value):
		skin_dirtiness = value
		front_body_shader.set_shader_parameter("dirt_amount", value)
		back_body_shader.set_shader_parameter("dirt_amount", value)
		hair_shader.set_shader_parameter("dirt_amount", value)
		
var skin_wetness: float = 0.0:
	set(value):
		skin_wetness = value
		if is_instance_valid(water_droplets):
			if skin_wetness >= 0.5: water_droplets.emitting = true
			else: water_droplets.emitting = false
			
func _copy_droplets_shape(col: CollisionShape2D) -> void:
	if !water_droplets || !col: return
	var rect := col.shape.get_rect()
	var mat: ParticleProcessMaterial = water_droplets.process_material as ParticleProcessMaterial
	mat.emission_box_extents = Vector3(rect.size.x + rect.position.x, (rect.size.y + rect.position.y) / 2.0, 1.0)
	water_droplets.position.y = col.position.y
#endregion

#region Clothes
@export_group("Clothes Nodes")
@export var hat_node: Sprite2D
@export var glasses_node: Sprite2D
@export var mask_node: Sprite2D

@export var chest_shirt_node: Sprite2D
@export var spine_shirt_node: Sprite2D
@export var front_upper_arm_shirt_node: Sprite2D
@export var front_lower_arm_shirt_node: Sprite2D
@export var back_upper_arm_shirt_node: Sprite2D
@export var back_lower_arm_shirt_node: Sprite2D
var shirt_nodes: Array[Sprite2D] = []

@export var chest_jacket_node: Sprite2D
@export var spine_jacket_node: Sprite2D
@export var front_upper_arm_jacket_node: Sprite2D
@export var front_lower_arm_jacket_node: Sprite2D
@export var back_upper_arm_jacket_node: Sprite2D
@export var back_lower_arm_jacket_node: Sprite2D
var jacket_nodes: Array[Sprite2D] = []

@export var spine_pants_node: Sprite2D
@export var front_upper_leg_pants_node: Sprite2D
@export var front_lower_leg_pants_node: Sprite2D
@export var back_upper_leg_pants_node: Sprite2D
@export var back_lower_leg_pants_node: Sprite2D
var pants_nodes: Array[Sprite2D] = []

@export var front_upper_leg_sock_node: Sprite2D
@export var front_lower_leg_sock_node: Sprite2D
@export var front_sock_node: Sprite2D
@export var back_upper_leg_sock_node: Sprite2D
@export var back_lower_leg_sock_node: Sprite2D
@export var back_sock_node: Sprite2D
var socks_nodes: Array[Sprite2D] = []

@export var front_shoe_node: Sprite2D
@export var back_shoe_node: Sprite2D
var shoes_nodes: Array[Sprite2D] = []

@export var bra_node: Sprite2D
@export var panties_node: Sprite2D
@export var backpack_node: Sprite2D

@export_group("Clothes")
@export var hat_data: ClothesData
@export var glasses_data: ClothesData
@export var mask_data: ClothesData
@export var shirt_data: ClothesData
@export var jacket_data: ClothesData
@export var pants_data: ClothesData
@export var socks_data: ClothesData
@export var shoes_data: ClothesData
@export var bra_data: ClothesData
@export var panties_data: ClothesData

func put_on_clothes(clothes: ClothesItem) -> void:
	_apply_clothes_data(clothes.clothes_data)
	clothes.remove_action("EquipClothesAction")
	clothes.actions.append(UnequipClothesAction.new())
	
func take_off_clothes(clothes: ClothesItem) -> void:
	clothes.is_equipped = false
	_remove_clothes_data(clothes.clothes_data)
	if is_instance_valid(InventoryManager.open_inventory) && InventoryManager.open_inventory == InventoryManager.inventory:
		InventoryManager.show_entries(InventoryManager.inventory)
		
	clothes.remove_action("UnequipClothesAction")
	clothes.actions.append(EquipClothesAction.new())
	
func _get_all_clothes_data() -> Array[ClothesData]: return [hat_data, glasses_data, mask_data, shirt_data, jacket_data, pants_data, socks_data, shoes_data, bra_data, panties_data]
	
func _process_all_clothes_data() -> void:
	if hat_data != null: _process_clothes_data([hat_node], hat_data)
	#if glasses_data != null: _process_clothes_data([glasses_data], glasses_data)
	if mask_data != null: _process_clothes_data([mask_node], mask_data)
	if shirt_data != null: _process_clothes_data(shirt_nodes, shirt_data)
	if jacket_data != null: _process_clothes_data(jacket_nodes, jacket_data)
	if pants_data != null: _process_clothes_data(pants_nodes, pants_data)
	if socks_data != null: _process_clothes_data(socks_nodes, socks_data)
	if shoes_data != null: _process_clothes_data(shoes_nodes, shoes_data)
	if bra_data != null: _process_clothes_data([bra_node], bra_data)
	if panties_data != null: _process_clothes_data([panties_node], panties_data)
	
func _process_clothes_data(nodes: Array[Sprite2D], data: ClothesData) -> void:
	if data == null || nodes.size() == 0: return
	for node: Sprite2D in nodes:
		if node.material == null: continue
		var shadermat: ShaderMaterial = node.material
		shadermat.set_shader_parameter("wetness", data.wetness)
		shadermat.set_shader_parameter("dirt_amount", data.dirtiness)

func _apply_all_clothes_data() -> void:
	_apply_clothes_data(hat_data)
	_apply_clothes_data(glasses_data)
	_apply_clothes_data(mask_data)
	_apply_clothes_data(shirt_data)
	_apply_clothes_data(jacket_data)
	_apply_clothes_data(pants_data)
	_apply_clothes_data(socks_data)
	_apply_clothes_data(shoes_data)
	_apply_clothes_data(bra_data)
	_apply_clothes_data(panties_data)

func _apply_clothes_data(data: ClothesData) -> void:
	if data == null: return
	match data.clothes_type:
		ClothesData.ClothesType.Hat:
			hat_data = data
			_apply_clothes_to_node(hat_node, data)
		ClothesData.ClothesType.Glasses:
			glasses_data = data
			_apply_clothes_to_node(glasses_node, data)
		ClothesData.ClothesType.Mask:
			mask_data = data
			_apply_clothes_to_node(mask_node, data)
		ClothesData.ClothesType.Shirt:
			shirt_data = data
			for node: Sprite2D in shirt_nodes: _apply_clothes_to_node(node, data)
		ClothesData.ClothesType.Jacket:
			jacket_data = data
			for node: Sprite2D in jacket_nodes: _apply_clothes_to_node(node, data)
		ClothesData.ClothesType.Pants:
			pants_data = data
			for node: Sprite2D in pants_nodes: _apply_clothes_to_node(node, data)
			penis_node.hide()
		ClothesData.ClothesType.Socks:
			socks_data = data
			for node: Sprite2D in socks_nodes: _apply_clothes_to_node(node, data)
		ClothesData.ClothesType.Shoes:
			shoes_data = data
			for node: Sprite2D in shoes_nodes: _apply_clothes_to_node(node, data)
		ClothesData.ClothesType.Bra:
			bra_data = data
			_apply_clothes_to_node(bra_node, data)
		ClothesData.ClothesType.Panties:
			panties_data = data
			_apply_clothes_to_node(panties_node, data)
			penis_node.hide()
			
func _apply_clothes_to_node(node: Sprite2D, data: ClothesData) -> void:
	var resource_path: String = data.boobs_icon.resource_path if has_breasts else data.no_boobs_icon.resource_path
	node.texture = load(resource_path)
	
	if data.clothes_type != ClothesData.ClothesType.Shoes:
		if node.material != null:
			var shadermat: ShaderMaterial = node.material
			var primary_color: Color = data.clothes_color_pool[data.primary_color]
			shadermat.set_shader_parameter("target_color", primary_color)
	else:
		var primary_color: Color = data.clothes_color_pool[data.primary_color]
		var secondary_color: Color = data.clothes_color_pool[data.secondary_color]
		var third_color: Color = data.clothes_color_pool[data.third_color]
		var shadermat: ShaderMaterial = node.material
		shadermat.set_shader_parameter("target_color1", primary_color)
		shadermat.set_shader_parameter("target_color2", secondary_color)
		shadermat.set_shader_parameter("target_color3", third_color)

func _remove_all_clothes_data() -> void:
	_remove_clothes_data(hat_data)
	_remove_clothes_data(glasses_data)
	_remove_clothes_data(mask_data)
	_remove_clothes_data(shirt_data)
	_remove_clothes_data(jacket_data)
	_remove_clothes_data(pants_data)
	_remove_clothes_data(socks_data)
	_remove_clothes_data(shoes_data)
	_remove_clothes_data(bra_data)
	_remove_clothes_data(panties_data)

func _remove_clothes_data(data: ClothesData) -> void:
	if data == null: return
	match data.clothes_type:
		ClothesData.ClothesType.Hat:
			hat_data = null
			_remove_clothes_from_node(hat_node)
		ClothesData.ClothesType.Glasses:
			glasses_data = null
			_remove_clothes_from_node(glasses_node)
		ClothesData.ClothesType.Mask:
			mask_data = null
			_remove_clothes_from_node(mask_node)
		ClothesData.ClothesType.Shirt:
			shirt_data = null
			for node: Sprite2D in shirt_nodes: _remove_clothes_from_node(node)
		ClothesData.ClothesType.Jacket:
			jacket_data = null
			for node: Sprite2D in jacket_nodes: _remove_clothes_from_node(node)
		ClothesData.ClothesType.Pants:
			pants_data = null
			for node: Sprite2D in pants_nodes: _remove_clothes_from_node(node)
			if has_penis && !panties_data: penis_node.show()
		ClothesData.ClothesType.Socks:
			socks_data = null
			for node: Sprite2D in socks_nodes: _remove_clothes_from_node(node)
		ClothesData.ClothesType.Shoes:
			shoes_data = null
			for node: Sprite2D in shoes_nodes: _remove_clothes_from_node(node)
		ClothesData.ClothesType.Bra:
			bra_data = null
			_remove_clothes_from_node(bra_node)
		ClothesData.ClothesType.Panties:
			panties_data = null
			_remove_clothes_from_node(panties_node)
			if has_penis && !pants_data: penis_node.show()
			
func _remove_clothes_from_node(node: Sprite2D) -> void: node.texture = null
		
func _is_already_wearing(clothes_type: ClothesData.ClothesType) -> bool:
	match clothes_type:
		ClothesData.ClothesType.Hat: return hat_data != null
		ClothesData.ClothesType.Glasses: return glasses_data != null
		ClothesData.ClothesType.Mask: return mask_data != null
		ClothesData.ClothesType.Shirt: return shirt_data != null
		ClothesData.ClothesType.Jacket: return jacket_data != null
		ClothesData.ClothesType.Pants: return pants_data != null
		ClothesData.ClothesType.Socks: return socks_data != null
		ClothesData.ClothesType.Shoes: return shoes_data != null
		ClothesData.ClothesType.Bra: return bra_data != null
		ClothesData.ClothesType.Panties: return panties_data != null
	return false

func _show_clothes(nodes: Array[Sprite2D]) -> void:
	for node: Sprite2D in nodes: node.show()
	if has_penis && (panties_node.visible || spine_pants_node.visible): penis_node.hide()

func _hide_clothes(nodes: Array[Sprite2D]) -> void:
	for node: Sprite2D in nodes: node.hide()
	if has_penis && !panties_node.visible && !spine_pants_node.visible: penis_node.show()
#endregion

#region Actions
func look_back() -> void: eyes_node.region_rect = Rect2(Vector2(16, 0), Vector2(16, 16))
func look_front() -> void: eyes_node.region_rect = Rect2(Vector2(0, 0), Vector2(16, 16))
func roll_eyes() -> void: eyes_node.region_rect = Rect2(Vector2(32, 0), Vector2(16, 16))
func look_up(percentage: float = 1.0) -> void: head_track_to(head_node.global_position + Vector2(128.0 if facing_right else -128.0, -100.0 * percentage))
func look_down(percentage: float = 1.0) -> void: head_track_to(head_node.global_position + Vector2(128.0 if facing_right else -128.0, 100.0 * percentage))
#endregion

#region Footsteps
func play_footstep(running: bool) -> void:
	if get_parent() is Char:
		var character: Char = get_parent()
		if running && character.movement.is_sprinting(): character.movement.play_footstep()
		elif !running && character.movement.is_moving() && !character.movement.is_sprinting(): character.movement.play_footstep()
#endregion
