extends Area3D

class_name BossUnit

signal boss_hp_changed(current: float, max_h: float)
signal boss_defeated()
signal boss_shot_fired(pos: Vector3, dir: Vector3, dmg: float)

enum BossType {
	HEAVY_ROBOT,
	TANK,
	DREAD_TITAN
}

@export var boss_name: String = "Iron Sentinel"
@export var boss_type: BossType = BossType.HEAVY_ROBOT
@export var max_hp: float = 950.0
@export var coin_reward: int = 120

var current_hp: float = 950.0
var is_active: bool = false
var is_dead: bool = false

var move_direction: float = 1.0
var move_speed: float = 2.0
var bridge_limit_x: float = 2.8

var attack_timer: float = 1.2
var attack_interval: float = 2.2
var is_telegraphing: bool = false
var telegraph_timer: float = 0.0
const TELEGRAPH_DURATION: float = 0.75

var boss_mesh_root: Node3D
var model_instance: Node3D
var collision_shape: CollisionShape3D

var left_cannon: Node3D
var right_cannon: Node3D
var main_cannon: Node3D
var tank_turret_node: Node3D
var tank_gun_node: Node3D

var telegraph_laser_left: MeshInstance3D
var telegraph_laser_right: MeshInstance3D
var telegraph_charge_left: MeshInstance3D
var telegraph_charge_right: MeshInstance3D

# Lane sweep indicators for Heavy Robot
var lane_telegraph_mesh: MeshInstance3D
var robot_target_lane_x: float = 0.0
var robot_attack_step: int = 0
const ROBOT_LANES: Array[float] = [-2.1, 2.1, 0.0, -2.1]

# Blast zone indicator for Tank
var tank_blast_marker: MeshInstance3D
var tank_target_x: float = 0.0

# Dread Titan attack alternation
var titan_attack_toggle: bool = false

static var _boss_models: Dictionary = {}
static func get_boss_model(b_type: BossType) -> PackedScene:
	if _boss_models.is_empty():
		_boss_models[BossType.HEAVY_ROBOT] = load("res://assets/models/service_robot.glb")
		_boss_models[BossType.TANK] = load("res://assets/models/medium_tank.glb")
		_boss_models[BossType.DREAD_TITAN] = load("res://assets/models/cargo_walker.glb")
	return _boss_models.get(b_type)

func _ready() -> void:
	collision_layer = 16
	collision_mask = 1 | 4
	monitoring = true
	monitorable = true

	current_hp = max_hp
	_rebuild_boss_visuals()

func setup(p_name: String, p_hp: float, p_coins: int, p_type: int = -1) -> void:
	boss_name = p_name
	max_hp = p_hp if p_hp > 0 else 950.0
	current_hp = max_hp
	coin_reward = p_coins

	if p_type >= 0:
		boss_type = p_type as BossType
	else:
		var n = p_name.to_lower()
		if "tank" in n:
			boss_type = BossType.TANK
		elif "titan" in n:
			boss_type = BossType.DREAD_TITAN
		else:
			boss_type = BossType.HEAVY_ROBOT

	if is_inside_tree():
		_rebuild_boss_visuals()

	boss_hp_changed.emit(current_hp, max_hp)

func _rebuild_boss_visuals() -> void:
	if boss_mesh_root and is_instance_valid(boss_mesh_root):
		boss_mesh_root.queue_free()
	if collision_shape and is_instance_valid(collision_shape):
		collision_shape.queue_free()

	boss_mesh_root = Node3D.new()
	add_child(boss_mesh_root)

	collision_shape = CollisionShape3D.new()

	var scene: PackedScene = get_boss_model(boss_type)
	model_instance = scene.instantiate() if scene else null
	if model_instance:
		boss_mesh_root.add_child(model_instance)

	# Laser / charge material
	var mat_laser = StandardMaterial3D.new()
	mat_laser.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_laser.albedo_color = Color(1.0, 0.15, 0.1, 0.85)
	mat_laser.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var mat_charge = StandardMaterial3D.new()
	mat_charge.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_charge.albedo_color = Color(1.0, 0.40, 0.05, 0.95)

	match boss_type:
		BossType.HEAVY_ROBOT:
			# Iron Sentinel: 3.8m tall heavy bipedal mech
			if model_instance:
				model_instance.scale = Vector3(2.2, 2.2, 2.2)
				model_instance.rotation_degrees = Vector3(0, 0, 0)

			var col_box = BoxShape3D.new()
			col_box.size = Vector3(3.4, 3.8, 2.0)
			collision_shape.shape = col_box
			collision_shape.position.y = 1.9

			# Shoulder Heavy Cannons
			for side in [-1, 1]:
				var cannon = MeshInstance3D.new()
				var c_box = BoxMesh.new()
				c_box.size = Vector3(0.35, 0.35, 1.6)
				cannon.mesh = c_box
				cannon.position = Vector3(side * 1.5, 2.8, 0.2)

				var c_mat = StandardMaterial3D.new()
				c_mat.albedo_color = Color(0.2, 0.2, 0.25)
				c_mat.metallic = 0.9
				c_mat.roughness = 0.3
				cannon.material_override = c_mat
				boss_mesh_root.add_child(cannon)

				var muzzle = Node3D.new()
				muzzle.position = Vector3(side * 1.5, 2.8, 1.2)
				boss_mesh_root.add_child(muzzle)

				# Telegraph Laser Beam
				var laser = MeshInstance3D.new()
				var cyl = CylinderMesh.new()
				cyl.top_radius = 0.04
				cyl.bottom_radius = 0.04
				cyl.height = 36.0
				laser.mesh = cyl
				laser.rotation_degrees.x = 90.0
				laser.position = Vector3(0, 0, 18.0)
				laser.material_override = mat_laser
				laser.visible = false
				muzzle.add_child(laser)

				# Muzzle charge indicator
				var charge = MeshInstance3D.new()
				var sph = SphereMesh.new()
				sph.radius = 0.22
				sph.height = 0.44
				charge.mesh = sph
				charge.material_override = mat_charge
				charge.visible = false
				muzzle.add_child(charge)

				if side < 0:
					left_cannon = muzzle
					telegraph_laser_left = laser
					telegraph_charge_left = charge
				else:
					right_cannon = muzzle
					telegraph_laser_right = laser
					telegraph_charge_right = charge

			# Red lane telegraph ground projector
			lane_telegraph_mesh = MeshInstance3D.new()
			var l_quad = QuadMesh.new()
			l_quad.size = Vector2(2.4, 38.0)
			lane_telegraph_mesh.mesh = l_quad
			lane_telegraph_mesh.rotation_degrees.x = -90.0
			lane_telegraph_mesh.position = Vector3(0, 0.04, 19.0)
			var lane_mat = StandardMaterial3D.new()
			lane_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
			lane_mat.albedo_color = Color(1.0, 0.12, 0.12, 0.42)
			lane_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			lane_telegraph_mesh.material_override = lane_mat
			lane_telegraph_mesh.visible = false
			add_child(lane_telegraph_mesh)

		BossType.TANK:
			# Heavy War Tank
			if model_instance:
				model_instance.scale = Vector3(1.05, 1.05, 1.05)
				model_instance.rotation_degrees = Vector3(0, 0, 0)
				tank_turret_node = model_instance.find_child("turret", true, false) as Node3D
				tank_gun_node = model_instance.find_child("gun", true, false) as Node3D

			var col_box = BoxShape3D.new()
			col_box.size = Vector3(3.2, 2.4, 5.8)
			collision_shape.shape = col_box
			collision_shape.position.y = 1.2

			# Main Cannon Muzzle Point
			main_cannon = Node3D.new()
			main_cannon.position = Vector3(0, 1.8, 3.4)
			boss_mesh_root.add_child(main_cannon)

			# Main Gun Telegraph Laser
			telegraph_laser_left = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.05
			cyl.bottom_radius = 0.05
			cyl.height = 36.0
			telegraph_laser_left.mesh = cyl
			telegraph_laser_left.rotation_degrees.x = 90.0
			telegraph_laser_left.position = Vector3(0, 0, 18.0)
			telegraph_laser_left.material_override = mat_laser
			telegraph_laser_left.visible = false
			main_cannon.add_child(telegraph_laser_left)

			telegraph_charge_left = MeshInstance3D.new()
			var sph = SphereMesh.new()
			sph.radius = 0.28
			sph.height = 0.56
			telegraph_charge_left.mesh = sph
			telegraph_charge_left.material_override = mat_charge
			telegraph_charge_left.visible = false
			main_cannon.add_child(telegraph_charge_left)

			left_cannon = main_cannon
			right_cannon = main_cannon

			# Blast zone disc marker on ground
			tank_blast_marker = MeshInstance3D.new()
			var disc = CylinderMesh.new()
			disc.top_radius = 2.2
			disc.bottom_radius = 2.2
			disc.height = 0.05
			tank_blast_marker.mesh = disc
			tank_blast_marker.position = Vector3(0, 0.05, 20.0)
			var blast_mat = StandardMaterial3D.new()
			blast_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
			blast_mat.albedo_color = Color(1.0, 0.22, 0.05, 0.55)
			blast_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			tank_blast_marker.material_override = blast_mat
			tank_blast_marker.visible = false
			add_child(tank_blast_marker)

		BossType.DREAD_TITAN:
			# Dread Titan: colossal multi-legged mechanical behemoth
			if model_instance:
				model_instance.scale = Vector3(0.52, 0.52, 0.52)
				model_instance.position.y = 2.05

			var col_box = BoxShape3D.new()
			col_box.size = Vector3(3.6, 7.0, 3.2)
			collision_shape.shape = col_box
			collision_shape.position.y = 3.6

			# Twin heavy underslung plasma batteries
			for side in [-1, 1]:
				var muzzle = Node3D.new()
				muzzle.position = Vector3(side * 1.3, 3.8, 1.2)
				boss_mesh_root.add_child(muzzle)

				var laser = MeshInstance3D.new()
				var cyl = CylinderMesh.new()
				cyl.top_radius = 0.05
				cyl.bottom_radius = 0.05
				cyl.height = 36.0
				laser.mesh = cyl
				laser.rotation_degrees.x = 90.0
				laser.position = Vector3(0, 0, 18.0)
				laser.material_override = mat_laser
				laser.visible = false
				muzzle.add_child(laser)

				var charge = MeshInstance3D.new()
				var sph = SphereMesh.new()
				sph.radius = 0.28
				sph.height = 0.56
				charge.mesh = sph
				charge.material_override = mat_charge
				charge.visible = false
				muzzle.add_child(charge)

				if side < 0:
					left_cannon = muzzle
					telegraph_laser_left = laser
					telegraph_charge_left = charge
				else:
					right_cannon = muzzle
					telegraph_laser_right = laser
					telegraph_charge_right = charge

	add_child(collision_shape)

func activate() -> void:
	is_active = true
	attack_timer = 1.0 # First attack gives player 1.0s to settle before telegraph
	boss_hp_changed.emit(current_hp, max_hp)

func stop_boss() -> void:
	is_active = false
	_hide_telegraph()

func _physics_process(delta: float) -> void:
	if not is_active or is_dead:
		return

	# Movement behavior
	match boss_type:
		BossType.HEAVY_ROBOT:
			# Heavy Robot slides to align with targeted lane
			position.x = lerpf(position.x, robot_target_lane_x, delta * 5.0)

		BossType.TANK:
			position.x += move_direction * move_speed * delta
			if position.x > bridge_limit_x:
				position.x = bridge_limit_x
				move_direction = -1.0
			elif position.x < -bridge_limit_x:
				position.x = -bridge_limit_x
				move_direction = 1.0

			if tank_turret_node:
				var p_nodes = get_tree().get_nodes_in_group("player")
				if p_nodes.size() > 0:
					var p_x = (p_nodes[0] as Node3D).global_position.x - global_position.x
					tank_turret_node.rotation_degrees.y = clampf(-p_x * 8.0, -22.0, 22.0)

		BossType.DREAD_TITAN:
			position.x += move_direction * (move_speed * 0.75) * delta
			if position.x > bridge_limit_x * 0.8:
				position.x = bridge_limit_x * 0.8
				move_direction = -1.0
			elif position.x < -bridge_limit_x * 0.8:
				position.x = -bridge_limit_x * 0.8
				move_direction = 1.0

	# Attack & Telegraph Cycle
	if is_telegraphing:
		telegraph_timer -= delta
		if telegraph_timer <= 0.0:
			is_telegraphing = false
			_hide_telegraph()
			_execute_attack()
	else:
		attack_timer -= delta
		if attack_timer <= TELEGRAPH_DURATION:
			is_telegraphing = true
			telegraph_timer = TELEGRAPH_DURATION
			_show_telegraph()

func _show_telegraph() -> void:
	match boss_type:
		BossType.HEAVY_ROBOT:
			# Select lane to sweep
			robot_target_lane_x = ROBOT_LANES[robot_attack_step % ROBOT_LANES.size()]
			if lane_telegraph_mesh:
				lane_telegraph_mesh.position.x = robot_target_lane_x - position.x
				lane_telegraph_mesh.visible = true
			if telegraph_laser_left:
				telegraph_laser_left.visible = true
			if telegraph_laser_right:
				telegraph_laser_right.visible = true
			if telegraph_charge_left:
				telegraph_charge_left.visible = true
			if telegraph_charge_right:
				telegraph_charge_right.visible = true

		BossType.TANK:
			var p_nodes = get_tree().get_nodes_in_group("player")
			if p_nodes.size() > 0:
				tank_target_x = (p_nodes[0] as Node3D).global_position.x
			if tank_blast_marker:
				tank_blast_marker.position.x = tank_target_x - position.x
				tank_blast_marker.visible = true
			if telegraph_laser_left:
				telegraph_laser_left.visible = true
			if telegraph_charge_left:
				telegraph_charge_left.visible = true

		BossType.DREAD_TITAN:
			if telegraph_laser_left:
				telegraph_laser_left.visible = true
			if telegraph_laser_right:
				telegraph_laser_right.visible = true
			if telegraph_charge_left:
				telegraph_charge_left.visible = true
			if telegraph_charge_right:
				telegraph_charge_right.visible = true

func _hide_telegraph() -> void:
	if lane_telegraph_mesh:
		lane_telegraph_mesh.visible = false
	if tank_blast_marker:
		tank_blast_marker.visible = false
	if telegraph_laser_left:
		telegraph_laser_left.visible = false
	if telegraph_laser_right:
		telegraph_laser_right.visible = false
	if telegraph_charge_left:
		telegraph_charge_left.visible = false
	if telegraph_charge_right:
		telegraph_charge_right.visible = false

func _execute_attack() -> void:
	if not is_active or is_dead:
		return

	attack_timer = attack_interval
	SoundManager.play("shoot_shotgun", 0.05)
	var forward = Vector3(0, 0, 1)

	match boss_type:
		BossType.HEAVY_ROBOT:
			# Lane Sweep: 3 heavy plasma bullets down the telegraphed lane!
			if left_cannon and right_cannon:
				boss_shot_fired.emit(left_cannon.global_position, forward, 1.5)
				boss_shot_fired.emit(right_cannon.global_position, forward, 1.5)
				boss_shot_fired.emit(global_position + Vector3(0, 2.2, 1.0), forward, 1.5)

				var tw = create_tween()
				tw.tween_property(boss_mesh_root, "position:z", -0.30, 0.08)
				tw.tween_property(boss_mesh_root, "position:z", 0.0, 0.16)

			robot_attack_step += 1

		BossType.TANK:
			# High Explosive Tank Shell aimed at marked blast zone
			if main_cannon:
				var dir = (Vector3(tank_target_x - global_position.x, 0, 22.0)).normalized()
				boss_shot_fired.emit(main_cannon.global_position, dir, 2.5)
				boss_shot_fired.emit(main_cannon.global_position, (dir + Vector3(-0.08, 0, 0)).normalized(), 1.0)
				boss_shot_fired.emit(main_cannon.global_position, (dir + Vector3(0.08, 0, 0)).normalized(), 1.0)

				if tank_gun_node:
					var tw = create_tween()
					tank_gun_node.position.z = -0.45
					tw.tween_property(tank_gun_node, "position:z", 0.0, 0.22)

		BossType.DREAD_TITAN:
			titan_attack_toggle = !titan_attack_toggle
			if titan_attack_toggle:
				# Attack A: 5-projectile spread volley across bridge with gaps to dodge!
				for a in [-0.22, -0.11, 0.0, 0.11, 0.22]:
					var s_dir = (forward + Vector3(a, 0, 0)).normalized()
					boss_shot_fired.emit(global_position + Vector3(0, 3.6, 1.2), s_dir, 1.5)
			else:
				# Attack B: Focused twin heavy plasma battery blast down center
				if left_cannon and right_cannon:
					boss_shot_fired.emit(left_cannon.global_position, forward, 2.0)
					boss_shot_fired.emit(right_cannon.global_position, forward, 2.0)

			var tw = create_tween()
			tw.tween_property(boss_mesh_root, "position:y", 0.25, 0.10)
			tw.tween_property(boss_mesh_root, "position:y", 0.0, 0.20)

func take_damage(amount: float) -> void:
	if is_dead or not is_active:
		return

	current_hp -= amount
	boss_hp_changed.emit(maxf(0.0, current_hp), max_hp)
	_flash()

	if current_hp <= 0:
		_defeat()

func _flash() -> void:
	var tween = create_tween()
	boss_mesh_root.scale = Vector3(1.06, 0.94, 1.06)
	tween.tween_property(boss_mesh_root, "scale", Vector3.ONE, 0.1)

func _defeat() -> void:
	if is_dead:
		return
	is_dead = true
	is_active = false
	_hide_telegraph()

	SoundManager.play("explosion")
	GameManager.add_coins(coin_reward)
	boss_defeated.emit()

	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	var tween = create_tween()
	tween.tween_property(boss_mesh_root, "rotation_degrees:x", -30.0, 0.4)
	tween.parallel().tween_property(boss_mesh_root, "position:y", -3.0, 0.6)
