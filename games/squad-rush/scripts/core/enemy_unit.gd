extends Area3D

class_name EnemyUnit

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

var is_dead: bool = false
var is_active: bool = true

# Shooting logic
var attack_timer: float = 1.0
var attack_interval: float = 1.8
var is_telegraphing: bool = false
var telegraph_timer: float = 0.0
const TELEGRAPH_DURATION: float = 0.28
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

func setup(p_hp: float, p_coins: int, p_moves: bool = false) -> void:
	max_hp = p_hp
	current_hp = max_hp
	coin_reward = p_coins
	moves_forward = p_moves
	_update_hp_display()

func _build_visuals() -> void:
	# Stylized Red Enemy Soldier
	soldier_model = StylizedSoldier.new()
	add_child(soldier_model)
	soldier_model.setup_team(true) # Enemy Team (Crimson armor, amber visor)
	soldier_model.equip_weapon(0) # Standard rifle

	muzzle_point = soldier_model.muzzle_point
	gun_mesh = soldier_model.weapon_mount
	muzzle_flash_mesh = soldier_model.muzzle_flash

	var t_m = soldier_model.torso_node.get_node_or_null("TorsoMesh")
	if t_m is MeshInstance3D:
		body_mesh = t_m

	# Aiming Telegraph Indicator (Bright red aiming laser)
	telegraph_laser = MeshInstance3D.new()
	var l_mesh = CylinderMesh.new()
	l_mesh.top_radius = 0.02
	l_mesh.bottom_radius = 0.02
	l_mesh.height = 14.0
	telegraph_laser.mesh = l_mesh
	telegraph_laser.rotation_degrees.x = 90.0
	telegraph_laser.position = Vector3(0, 0.45, 7.0)

	var l_mat = StandardMaterial3D.new()
	l_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	l_mat.albedo_color = Color(1.0, 0.15, 0.1, 0.65)
	l_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	telegraph_laser.material_override = l_mat
	telegraph_laser.visible = false
	add_child(telegraph_laser)

	# Collision Shape matching soldier height
	var col = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.10
	col.shape = shape
	col.position.y = 0.55
	add_child(col)

func _create_hp_label() -> void:
	# Background Pill Mesh for contrast
	hp_bg = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(0.85, 0.42)
	hp_bg.mesh = quad
	hp_bg.position = Vector3(0, 1.50, 0)

	var mat_bg = StandardMaterial3D.new()
	mat_bg.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_bg.albedo_color = Color(0.1, 0.05, 0.05, 0.85)
	mat_bg.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hp_bg.material_override = mat_bg
	add_child(hp_bg)

	hp_label = Label3D.new()
	hp_label.position = Vector3(0, 1.50, 0.02)
	hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_label.modulate = Color(1.0, 0.35, 0.35)
	hp_label.outline_modulate = Color(0, 0, 0, 1)
	hp_label.font_size = 38
	hp_label.text = str(int(current_hp))
	add_child(hp_label)

	_update_hp_display()

func _update_hp_display() -> void:
	if is_instance_valid(hp_label):
		hp_label.text = str(int(current_hp))

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if moves_forward and is_active:
		position.z += move_speed * delta
		if soldier_model:
			soldier_model.animate_motion(delta, 0.75)

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
	var target_pos = player.global_position + Vector3(0, 0.8, 0)
	var shoot_dir = (target_pos - spawn_pos).normalized()

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
