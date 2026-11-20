extends Area3D

class_name EnemyUnit

enum EnemyType {
	RUNNER,
	SHOOTER,
	SHIELDER
}

@export var enemy_type: EnemyType = EnemyType.SHOOTER
@export var max_hp: float = 25.0
@export var damage_to_player: int = 1
@export var coin_reward: int = 8
@export var moves_forward: bool = false
@export var move_speed: float = 2.0

var current_hp: float = 25.0
var hp_label: Label3D
var hp_bg: MeshInstance3D
var soldier_model: StylizedSoldier
var body_mesh: MeshInstance3D
var muzzle_point: Node3D
var gun_mesh: Node3D
var muzzle_flash_mesh: MeshInstance3D
var telegraph_laser: MeshInstance3D
var shield_mesh: MeshInstance3D

var is_dead: bool = false
var is_active: bool = true

# Shooting logic (SHOOTER type only)
var attack_timer: float = 1.0
var attack_interval: float = 1.8
var is_telegraphing: bool = false
var telegraph_timer: float = 0.0
const TELEGRAPH_DURATION: float = 0.45
const ATTACK_RANGE_Z: float = 42.0
const MIN_ATTACK_Z: float = 6.0

signal enemy_defeated(pos: Vector3, coins: int)
signal enemy_shot_fired(pos: Vector3, dir: Vector3, dmg: float)

func _ready() -> void:
	collision_layer = 16 # Enemy layer
	collision_mask = 1 | 4 # Player (1) and player bullets (4)

	current_hp = max_hp
	attack_timer = randf_range(0.6, 1.4)

	_build_visuals()
	_create_hp_label()

	body_entered.connect(_on_body_entered)

func setup(p_hp: float, p_coins: int, p_moves: bool = false, p_type: int = 1) -> void:
	enemy_type = p_type as EnemyType
	max_hp = p_hp
	current_hp = max_hp
	coin_reward = p_coins
	moves_forward = p_moves

	match enemy_type:
		EnemyType.RUNNER:
			moves_forward = true
			move_speed = 5.8
			damage_to_player = 2
			max_hp = p_hp if p_hp > 0 else 12.0
			current_hp = max_hp
			coin_reward = p_coins if p_coins > 0 else 6
		EnemyType.SHOOTER:
			damage_to_player = 1
			max_hp = p_hp if p_hp > 0 else 20.0
			current_hp = max_hp
			coin_reward = p_coins if p_coins > 0 else 8
		EnemyType.SHIELDER:
			damage_to_player = 3
			max_hp = p_hp if p_hp > 0 else 55.0
			current_hp = max_hp
			coin_reward = p_coins if p_coins > 0 else 16

	if is_inside_tree():
		_rebuild_type_visuals()
	_update_hp_display()

func _build_visuals() -> void:
	_rebuild_type_visuals()

func _rebuild_type_visuals() -> void:
	for c in get_children():
		if c != hp_label and c != hp_bg:
			remove_child(c)
			c.queue_free()

	telegraph_laser = null
	shield_mesh = null

	soldier_model = StylizedSoldier.new()
	add_child(soldier_model)
	soldier_model.setup_team(true) # Enemy Team (Crimson armor, amber visor)

	var var_id = 0
	match enemy_type:
		EnemyType.RUNNER:
			var_id = 0 # Sleek scout runner with fins & thrusters
			soldier_model.build_soldier(true, var_id)
			soldier_model.equip_weapon(0)
			soldier_model.rotation_degrees.x = 10.0 # Forward aggressive sprint tilt
			if soldier_model.weapon_mount:
				soldier_model.weapon_mount.visible = false # Melee rusher: no gun

			# Dual forearm hydraulic ram spikes
			for side in [-1, 1]:
				var spike = MeshInstance3D.new()
				var sp_mesh = BoxMesh.new()
				sp_mesh.size = Vector3(0.06, 0.06, 0.32)
				spike.mesh = sp_mesh
				spike.position = Vector3(side * 0.22, 0.35, 0.16)
				var sp_mat = StandardMaterial3D.new()
				sp_mat.albedo_color = Color(0.85, 0.20, 0.10)
				sp_mat.metallic = 0.80
				spike.material_override = sp_mat
				add_child(spike)

		EnemyType.SHOOTER:
			var_id = 1 # Combat android with targeting optic & antenna
			soldier_model.build_soldier(true, var_id)
			soldier_model.equip_weapon(0)

		EnemyType.SHIELDER:
			var_id = 2 # Heavy fortified trooper with shield
			soldier_model.build_soldier(true, var_id)
			soldier_model.equip_weapon(0)
			if soldier_model.weapon_mount:
				soldier_model.weapon_mount.visible = false # Two-handed shield stance

	muzzle_point = soldier_model.muzzle_point
	gun_mesh = soldier_model.weapon_mount
	muzzle_flash_mesh = soldier_model.muzzle_flash

	var t_m = soldier_model.torso_node.get_node_or_null("TorsoMesh")
	if t_m is MeshInstance3D:
		body_mesh = t_m

	if enemy_type == EnemyType.SHOOTER:
		# Aiming Telegraph Laser (Bright red aiming laser matching bullet trajectory)
		telegraph_laser = MeshInstance3D.new()
		var l_mesh = CylinderMesh.new()
		l_mesh.top_radius = 0.02
		l_mesh.bottom_radius = 0.02
		l_mesh.height = 18.0
		telegraph_laser.mesh = l_mesh
		telegraph_laser.rotation_degrees.x = 90.0
		telegraph_laser.position = Vector3(0, 0.45, 9.0)

		var l_mat = StandardMaterial3D.new()
		l_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		l_mat.albedo_color = Color(1.0, 0.15, 0.1, 0.75)
		l_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		telegraph_laser.material_override = l_mat
		telegraph_laser.visible = false
		add_child(telegraph_laser)

	elif enemy_type == EnemyType.SHIELDER:
		# Heavy Ballistic Riot Shield in front of soldier
		shield_mesh = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(1.10, 1.30, 0.12)
		shield_mesh.mesh = s_box
		shield_mesh.position = Vector3(0, 0.65, 0.35)

		var s_mat = StandardMaterial3D.new()
		s_mat.albedo_color = Color(0.20, 0.12, 0.12) # Heavy dark composite plate
		s_mat.metallic = 0.70
		s_mat.roughness = 0.40
		shield_mesh.material_override = s_mat
		add_child(shield_mesh)

		# Shield viewport slit
		var slit = MeshInstance3D.new()
		var slit_box = BoxMesh.new()
		slit_box.size = Vector3(0.50, 0.08, 0.14)
		slit.mesh = slit_box
		slit.position = Vector3(0, 0.95, 0.36)
		var slit_mat = StandardMaterial3D.new()
		slit_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		slit_mat.albedo_color = Color(1.0, 0.45, 0.0) # Amber sensor visor
		slit.material_override = slit_mat
		add_child(slit)

	# Collision Shape
	var col = CollisionShape3D.new()
	if enemy_type == EnemyType.SHIELDER:
		var b_shape = BoxShape3D.new()
		b_shape.size = Vector3(1.15, 1.40, 0.8)
		col.shape = b_shape
		col.position.y = 0.70
	else:
		var shape = CapsuleShape3D.new()
		shape.radius = 0.38
		shape.height = 1.10
		col.shape = shape
		col.position.y = 0.55
	add_child(col)

func _create_hp_label() -> void:
	hp_bg = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(0.85, 0.42)
	hp_bg.mesh = quad
	hp_bg.position = Vector3(0, 1.55, 0)

	var mat_bg = StandardMaterial3D.new()
	mat_bg.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_bg.albedo_color = Color(0.1, 0.05, 0.05, 0.85)
	mat_bg.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hp_bg.material_override = mat_bg
	hp_bg.visibility_range_end = 34.0
	hp_bg.visibility_range_end_margin = 6.0
	hp_bg.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(hp_bg)

	hp_label = Label3D.new()
	hp_label.position = Vector3(0, 1.55, 0.02)
	hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_label.modulate = Color(1.0, 0.35, 0.35)
	hp_label.outline_modulate = Color(0, 0, 0, 1)
	hp_label.font_size = 38
	hp_label.text = str(int(current_hp))
	hp_label.visibility_range_end = 34.0
	hp_label.visibility_range_end_margin = 6.0
	hp_label.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(hp_label)

	_update_hp_display()

func _update_hp_display() -> void:
	if is_instance_valid(hp_label):
		hp_label.text = str(int(current_hp))

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Distance culling for enemy HP label: avoids cluttering distant horizon
	var p_nodes = get_tree().get_nodes_in_group("player")
	if p_nodes.size() > 0 and is_instance_valid(p_nodes[0]):
		var pz = p_nodes[0].global_position.z
		var dist = abs(global_position.z - pz)
		var show_hp = (dist <= 34.0)
		if is_instance_valid(hp_label) and hp_label.visible != show_hp:
			hp_label.visible = show_hp
		if is_instance_valid(hp_bg) and hp_bg.visible != show_hp:
			hp_bg.visible = show_hp

	if moves_forward and is_active:
		position.z += move_speed * delta
		if soldier_model:
			var anim_spd = 1.6 if enemy_type == EnemyType.RUNNER else 0.75
			soldier_model.animate_motion(delta, anim_spd)

	if enemy_type == EnemyType.SHOOTER:
		_process_shooting(delta)

func _process_shooting(delta: float) -> void:
	var p_nodes = get_tree().get_nodes_in_group("player")
	if p_nodes.size() == 0:
		return
	var player = p_nodes[0] as PlayerSquad
	if not is_instance_valid(player) or player.is_defeated:
		if telegraph_laser:
			telegraph_laser.visible = false
		if muzzle_flash_mesh:
			muzzle_flash_mesh.visible = false
		return

	var forward_dist = player.global_position.z - global_position.z

	if forward_dist >= MIN_ATTACK_Z and forward_dist <= ATTACK_RANGE_Z:
		if is_telegraphing:
			telegraph_timer -= delta
			if telegraph_timer <= 0.0:
				is_telegraphing = false
				if telegraph_laser:
					telegraph_laser.visible = false
				if muzzle_flash_mesh:
					muzzle_flash_mesh.visible = false
				_fire_shot(player)
		else:
			attack_timer -= delta
			if attack_timer <= TELEGRAPH_DURATION:
				is_telegraphing = true
				telegraph_timer = TELEGRAPH_DURATION
				if telegraph_laser:
					telegraph_laser.visible = true
				if muzzle_flash_mesh:
					muzzle_flash_mesh.visible = true
	else:
		if is_telegraphing:
			is_telegraphing = false
			if telegraph_laser:
				telegraph_laser.visible = false
			if muzzle_flash_mesh:
				muzzle_flash_mesh.visible = false

func _fire_shot(player: PlayerSquad) -> void:
	if is_dead or not is_active:
		return

	attack_timer = attack_interval + randf_range(-0.2, 0.2)
	SoundManager.play("shoot_rifle", 0.15)

	if soldier_model:
		soldier_model.trigger_recoil()

	var spawn_pos = soldier_model.get_muzzle_global_position() if soldier_model else global_position
	# Shoot straight down the lane along the laser
	var shoot_dir = Vector3(0, 0, 1)
	if is_instance_valid(player):
		var target_pos = player.global_position + Vector3(0, 0.8, 0)
		shoot_dir = (target_pos - spawn_pos).normalized()

	enemy_shot_fired.emit(spawn_pos, shoot_dir, 1.0)

func take_damage(amount: float) -> void:
	if is_dead:
		return

	current_hp -= amount
	_update_hp_display()
	_flash()

	if current_hp <= 0:
		_die()

func _flash() -> void:
	var tween = create_tween()
	scale = Vector3(1.18, 0.88, 1.18)
	tween.tween_property(self, "scale", Vector3.ONE, 0.1)

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	is_active = false

	if telegraph_laser:
		telegraph_laser.visible = false
	if muzzle_flash_mesh:
		muzzle_flash_mesh.visible = false

	SoundManager.play("explosion")
	GameManager.add_coins(coin_reward)
	GameManager.run_kills += 1
	enemy_defeated.emit(global_position, coin_reward)

	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	if soldier_model:
		soldier_model.play_defeat(func(): queue_free())
	else:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.15).set_trans(Tween.TRANS_BACK)
		tween.finished.connect(func(): queue_free())

func _on_body_entered(body: Node3D) -> void:
	if is_dead:
		return
	if body is PlayerSquad:
		(body as PlayerSquad).remove_members(damage_to_player)
		_die()
