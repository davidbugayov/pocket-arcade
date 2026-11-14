extends Node3D

class_name StylizedSoldier

enum Team { ALLY, ENEMY }

@export var team: Team = Team.ALLY
@export var is_enemy: bool = false

var torso_node: Node3D
var head_node: Node3D
var helmet_mesh: MeshInstance3D
var visor_mesh: MeshInstance3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var weapon_mount: Node3D
var weapon_instance: Node3D
var muzzle_point: Node3D
var muzzle_flash: MeshInstance3D
var rotary_cluster: Node3D

var walk_time: float = 0.0
var recoil_offset: float = 0.0
var flash_timer: float = 0.0
var current_weapon_id: int = -1

# Shared materials for batching / high performance
static var mat_ally_body: StandardMaterial3D
static var mat_ally_armor: StandardMaterial3D
static var mat_ally_visor: StandardMaterial3D

static var mat_enemy_body: StandardMaterial3D
static var mat_enemy_armor: StandardMaterial3D
static var mat_enemy_visor: StandardMaterial3D

static var mat_dark_metal: StandardMaterial3D
static var mat_skin: StandardMaterial3D
static var mat_flash: StandardMaterial3D

# Preloaded Polyfork weapon scenes
static var weapon_scenes = {
	0: load("res://assets/models/rifle.glb"),
	1: load("res://assets/models/scattergun.glb"),
	2: load("res://assets/models/rotary_cannon.glb")
}

func _init() -> void:
	_init_materials()
	_build_character_hierarchy()

static func _init_materials() -> void:
	if mat_ally_body != null:
		return

	# Ally Palette (High-readability tactical navy / vibrant royal blue & cyan)
	mat_ally_body = StandardMaterial3D.new()
	mat_ally_body.albedo_color = Color(0.12, 0.28, 0.65) # Navy uniform
	mat_ally_body.roughness = 0.65

	mat_ally_armor = StandardMaterial3D.new()
	mat_ally_armor.albedo_color = Color(0.18, 0.52, 0.98) # Bold cobalt armor & helmet
	mat_ally_armor.roughness = 0.35
	mat_ally_armor.metallic = 0.15

	mat_ally_visor = StandardMaterial3D.new()
	mat_ally_visor.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_ally_visor.albedo_color = Color(0.25, 0.95, 1.0) # Glowing cyan visor

	# Enemy Palette (Aggressive crimson / charcoal & amber)
	mat_enemy_body = StandardMaterial3D.new()
	mat_enemy_body.albedo_color = Color(0.24, 0.18, 0.20) # Charcoal battle uniform
	mat_enemy_body.roughness = 0.70

	mat_enemy_armor = StandardMaterial3D.new()
	mat_enemy_armor.albedo_color = Color(0.88, 0.14, 0.14) # Crimson armor & helmet
	mat_enemy_armor.roughness = 0.35
	mat_enemy_armor.metallic = 0.20

	mat_enemy_visor = StandardMaterial3D.new()
	mat_enemy_visor.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_enemy_visor.albedo_color = Color(1.0, 0.32, 0.10) # Glowing amber-orange visor

	# General Details
	mat_dark_metal = StandardMaterial3D.new()
	mat_dark_metal.albedo_color = Color(0.18, 0.18, 0.22)
	mat_dark_metal.metallic = 0.8
	mat_dark_metal.roughness = 0.35

	mat_skin = StandardMaterial3D.new()
	mat_skin.albedo_color = Color(0.82, 0.64, 0.52)
	mat_skin.roughness = 0.8

	mat_flash = StandardMaterial3D.new()
	mat_flash.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_flash.albedo_color = Color(1.0, 0.95, 0.5)

func _ready() -> void:
	if torso_node == null:
		_build_character_hierarchy()
	if weapon_instance == null:
		equip_weapon(0)

func setup_team(p_is_enemy: bool) -> void:
	is_enemy = p_is_enemy
	team = Team.ENEMY if is_enemy else Team.ALLY
	_apply_team_materials()

	# Enemies face towards player (+Z), Allies face -Z
	if is_enemy:
		rotation_degrees.y = 0.0
	else:
		rotation_degrees.y = 180.0

func _build_character_hierarchy() -> void:
	if torso_node != null:
		return
	# Root offset so character feet stand at y = 0
	torso_node = Node3D.new()
	torso_node.position.y = 0.42
	add_child(torso_node)

	# 1. Torso & Armor
	var torso_mesh = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.34, 0.38, 0.22)
	torso_mesh.mesh = t_box
	torso_mesh.name = "TorsoMesh"
	torso_node.add_child(torso_mesh)

	# Chest armor plate
	var chest_plate = MeshInstance3D.new()
	var cp_box = BoxMesh.new()
	cp_box.size = Vector3(0.30, 0.26, 0.08)
	chest_plate.mesh = cp_box
	chest_plate.position = Vector3(0, 0.04, 0.10)
	chest_plate.name = "ChestPlate"
	torso_node.add_child(chest_plate)

	# Belt & buckle
	var belt = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.36, 0.08, 0.24)
	belt.mesh = b_box
	belt.position.y = -0.16
	belt.material_override = mat_dark_metal
	torso_node.add_child(belt)

	# 2. Head & Helmet
	head_node = Node3D.new()
	head_node.position.y = 0.28
	torso_node.add_child(head_node)

	# Head base
	var head_mesh = MeshInstance3D.new()
	var h_sph = SphereMesh.new()
	h_sph.radius = 0.14
	h_sph.height = 0.28
	head_mesh.mesh = h_sph
	head_mesh.material_override = mat_skin
	head_node.add_child(head_mesh)

	# Helmet Dome (Tactical low-poly helmet covering top & sides)
	helmet_mesh = MeshInstance3D.new()
	var helm_sph = SphereMesh.new()
	helm_sph.radius = 0.17
	helm_sph.height = 0.26
	helmet_mesh.mesh = helm_sph
	helmet_mesh.position.y = 0.04
	head_node.add_child(helmet_mesh)

	# Visor (Glowing tactical eye-band)
	visor_mesh = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(0.24, 0.06, 0.06)
	visor_mesh.mesh = v_box
	visor_mesh.position = Vector3(0, 0.02, 0.13)
	head_node.add_child(visor_mesh)

	# 3. Shoulder Pads & Arms
	for side in [-1, 1]:
		# Shoulder Pad
		var pad = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(0.12, 0.10, 0.18)
		pad.mesh = p_box
		pad.position = Vector3(side * 0.22, 0.15, 0)
		pad.name = "ShoulderPad_" + ("L" if side < 0 else "R")
		torso_node.add_child(pad)

	left_arm = Node3D.new()
	left_arm.position = Vector3(-0.20, 0.12, 0.0)
	torso_node.add_child(left_arm)

	var l_arm_mesh = MeshInstance3D.new()
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 0.06
	l_cyl.bottom_radius = 0.05
	l_cyl.height = 0.28
	l_arm_mesh.mesh = l_cyl
	l_arm_mesh.rotation_degrees.x = -45.0
	l_arm_mesh.rotation_degrees.y = 20.0
	l_arm_mesh.position = Vector3(0.04, -0.06, 0.12)
	l_arm_mesh.name = "LeftArmMesh"
	left_arm.add_child(l_arm_mesh)

	right_arm = Node3D.new()
	right_arm.position = Vector3(0.20, 0.12, 0.0)
	torso_node.add_child(right_arm)

	var r_arm_mesh = MeshInstance3D.new()
	var r_cyl = CylinderMesh.new()
	r_cyl.top_radius = 0.06
	r_cyl.bottom_radius = 0.05
	r_cyl.height = 0.28
	r_arm_mesh.mesh = r_cyl
	r_arm_mesh.rotation_degrees.x = -60.0
	r_arm_mesh.rotation_degrees.y = -15.0
	r_arm_mesh.position = Vector3(-0.04, -0.04, 0.10)
	r_arm_mesh.name = "RightArmMesh"
	right_arm.add_child(r_arm_mesh)

	# 4. Weapon Mount (Pivots at chest level aiming forward)
	weapon_mount = Node3D.new()
	weapon_mount.position = Vector3(0.10, 0.04, 0.22)
	torso_node.add_child(weapon_mount)

	muzzle_point = Node3D.new()
	muzzle_point.position = Vector3(0, 0.05, 0.45)
	weapon_mount.add_child(muzzle_point)

	# Muzzle Flash Mesh
	muzzle_flash = MeshInstance3D.new()
	var mf_mesh = SphereMesh.new()
	mf_mesh.radius = 0.12
	mf_mesh.height = 0.24
	muzzle_flash.mesh = mf_mesh
	muzzle_flash.material_override = mat_flash
	muzzle_flash.visible = false
	muzzle_point.add_child(muzzle_flash)

	# 5. Articulated Legs
	left_leg = Node3D.new()
	left_leg.position = Vector3(-0.10, 0.24, 0.0)
	add_child(left_leg)

	var l_leg_mesh = MeshInstance3D.new()
	var ll_box = BoxMesh.new()
	ll_box.size = Vector3(0.12, 0.26, 0.13)
	l_leg_mesh.mesh = ll_box
	l_leg_mesh.position.y = -0.13
	l_leg_mesh.name = "LeftLegMesh"
	left_leg.add_child(l_leg_mesh)

	var l_boot = MeshInstance3D.new()
	var lb_box = BoxMesh.new()
	lb_box.size = Vector3(0.13, 0.10, 0.18)
	l_boot.mesh = lb_box
	l_boot.position = Vector3(0, -0.22, 0.03)
	l_boot.material_override = mat_dark_metal
	left_leg.add_child(l_boot)

	right_leg = Node3D.new()
	right_leg.position = Vector3(0.10, 0.24, 0.0)
	add_child(right_leg)

	var r_leg_mesh = MeshInstance3D.new()
	var rl_box = BoxMesh.new()
	rl_box.size = Vector3(0.12, 0.26, 0.13)
	r_leg_mesh.mesh = rl_box
	r_leg_mesh.position.y = -0.13
	r_leg_mesh.name = "RightLegMesh"
	right_leg.add_child(r_leg_mesh)

	var r_boot = MeshInstance3D.new()
	var rb_box = BoxMesh.new()
	rb_box.size = Vector3(0.13, 0.10, 0.18)
	r_boot.mesh = rb_box
	r_boot.position = Vector3(0, -0.22, 0.03)
	r_boot.material_override = mat_dark_metal
	right_leg.add_child(r_boot)

	_apply_team_materials()

func _apply_team_materials() -> void:
	var b_mat = mat_enemy_body if is_enemy else mat_ally_body
	var a_mat = mat_enemy_armor if is_enemy else mat_ally_armor
	var v_mat = mat_enemy_visor if is_enemy else mat_ally_visor

	if helmet_mesh:
		helmet_mesh.material_override = a_mat
	if visor_mesh:
		visor_mesh.material_override = v_mat

	var torso_m = torso_node.get_node_or_null("TorsoMesh") as MeshInstance3D
	if torso_m:
		torso_m.material_override = b_mat

	var chest_p = torso_node.get_node_or_null("ChestPlate") as MeshInstance3D
	if chest_p:
		chest_p.material_override = a_mat

	var sp_l = torso_node.get_node_or_null("ShoulderPad_L") as MeshInstance3D
	if sp_l:
		sp_l.material_override = a_mat
	var sp_r = torso_node.get_node_or_null("ShoulderPad_R") as MeshInstance3D
	if sp_r:
		sp_r.material_override = a_mat

	var la_m = left_arm.get_node_or_null("LeftArmMesh") as MeshInstance3D
	if la_m:
		la_m.material_override = b_mat
	var ra_m = right_arm.get_node_or_null("RightArmMesh") as MeshInstance3D
	if ra_m:
		ra_m.material_override = b_mat

	var ll_m = left_leg.get_node_or_null("LeftLegMesh") as MeshInstance3D
	if ll_m:
		ll_m.material_override = b_mat
	var rl_m = right_leg.get_node_or_null("RightLegMesh") as MeshInstance3D
	if rl_m:
		rl_m.material_override = b_mat

func equip_weapon(weapon_id: int) -> void:
	if current_weapon_id == weapon_id and weapon_instance != null:
		return

	current_weapon_id = weapon_id
	rotary_cluster = null

	# Remove old weapon
	if is_instance_valid(weapon_instance):
		weapon_instance.queue_free()
		weapon_instance = null

	var scene: PackedScene = weapon_scenes.get(weapon_id, weapon_scenes[0])
	if scene:
		weapon_instance = scene.instantiate()
		weapon_mount.add_child(weapon_instance)

		match weapon_id:
			0: # Assault Rifle
				weapon_instance.scale = Vector3(0.48, 0.48, 0.48)
				weapon_instance.rotation_degrees = Vector3(0, 0, 0)
				weapon_instance.position = Vector3(0, 0, 0.05)
				muzzle_point.position = Vector3(0, 0.06, 0.46)
			1: # Combat Shotgun
				weapon_instance.scale = Vector3(0.52, 0.52, 0.52)
				weapon_instance.rotation_degrees = Vector3(0, 0, 0)
				weapon_instance.position = Vector3(0, -0.02, 0.04)
				muzzle_point.position = Vector3(0, 0.05, 0.42)
			2: # Plasma Minigun
				weapon_instance.scale = Vector3(0.38, 0.38, 0.38)
				weapon_instance.rotation_degrees = Vector3(0, 0, 0)
				weapon_instance.position = Vector3(0, -0.05, -0.05)
				muzzle_point.position = Vector3(0, 0.06, 0.58)
				rotary_cluster = weapon_instance.find_child("cluster", true, false) as Node3D

func animate_motion(delta: float, speed_factor: float = 1.0, full_articulation: bool = true) -> void:
	walk_time += delta * 14.0 * speed_factor

	# Runner bounce
	torso_node.position.y = 0.42 + abs(sin(walk_time)) * 0.05

	if full_articulation:
		# Leg stride rotation
		var stride_angle = sin(walk_time) * 34.0
		left_leg.rotation_degrees.x = stride_angle
		right_leg.rotation_degrees.x = -stride_angle

		torso_node.rotation_degrees.z = sin(walk_time * 0.5) * 2.5
		head_node.rotation_degrees.x = sin(walk_time) * 3.0

		# Arm counter-sway
		left_arm.rotation_degrees.x = -stride_angle * 0.35
		right_arm.rotation_degrees.x = stride_angle * 0.25

	# Recover recoil
	if recoil_offset > 0.0:
		recoil_offset = maxf(0.0, recoil_offset - delta * 1.8)
		weapon_mount.position.z = 0.22 - recoil_offset

	# Muzzle flash timer
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			muzzle_flash.visible = false

	# Rotary barrel spin
	if rotary_cluster and speed_factor > 0.1:
		rotary_cluster.rotation_degrees.z += 900.0 * delta

func trigger_recoil() -> void:
	recoil_offset = 0.12
	weapon_mount.position.z = 0.22 - recoil_offset

	# Muzzle flash
	muzzle_flash.visible = true
	flash_timer = 0.06
	muzzle_flash.scale = Vector3(randf_range(0.8, 1.3), randf_range(0.8, 1.3), randf_range(1.0, 1.6))

func get_muzzle_global_position() -> Vector3:
	if is_inside_tree() and muzzle_point:
		return muzzle_point.global_position
	if is_inside_tree():
		return global_position + Vector3(0, 0.45, -0.45)
	return Vector3(0, 0.45, -0.45)

func play_spawn() -> void:
	scale = Vector3.ZERO
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector3.ONE, 0.28)

func play_defeat(on_complete: Callable = Callable()) -> void:
	var tw = create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Tumble backward and squash
	tw.tween_property(self, "position:y", position.y + 0.5, 0.25)
	tw.tween_property(self, "rotation_degrees:x", rotation_degrees.x + 75.0, 0.35)
	tw.tween_property(self, "rotation_degrees:z", randf_range(-40.0, 40.0), 0.35)
	tw.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.35)
	if on_complete.is_valid():
		tw.chain().tween_callback(on_complete)
