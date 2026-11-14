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
var body_mesh: MeshInstance3D
var muzzle_point: Node3D
var gun_mesh: MeshInstance3D
var muzzle_flash_mesh: MeshInstance3D

var is_dead: bool = false
var is_active: bool = true

# Shooting logic
var attack_timer: float = 1.0
var attack_interval: float = 1.8
var is_telegraphing: bool = false
var telegraph_timer: float = 0.0
const TELEGRAPH_DURATION: float = 0.25
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
	# Red Soldier Model
	body_mesh = MeshInstance3D.new()
	var cap = CapsuleMesh.new()
	cap.radius = 0.28
	cap.height = 0.85
	body_mesh.mesh = cap
	body_mesh.position.y = 0.45
	
	var mat_red = StandardMaterial3D.new()
	mat_red.albedo_color = Color(0.9, 0.15, 0.15)
	mat_red.roughness = 0.5
	body_mesh.material_override = mat_red
	add_child(body_mesh)
	
	# Head
	var head = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.20
	sphere.height = 0.40
	head.mesh = sphere
	head.position.y = 0.48
	
	var mat_helmet = StandardMaterial3D.new()
	mat_helmet.albedo_color = Color(0.5, 0.05, 0.05)
	head.material_override = mat_helmet
	body_mesh.add_child(head)
	
	# Gun
	gun_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.12, 0.12, 0.50)
	gun_mesh.mesh = box
	gun_mesh.position = Vector3(0.25, 0.35, 0.22) # Aiming towards player (+Z)
	var mat_gun = StandardMaterial3D.new()
	mat_gun.albedo_color = Color(0.15, 0.15, 0.18)
	gun_mesh.material_override = mat_gun
	add_child(gun_mesh)
	
	muzzle_point = Node3D.new()
	muzzle_point.position = Vector3(0.25, 0.35, 0.52)
	add_child(muzzle_point)
	
	# Telegraph muzzle indicator
	muzzle_flash_mesh = MeshInstance3D.new()
	var f_sph = SphereMesh.new()
	f_sph.radius = 0.10
	f_sph.height = 0.20
	muzzle_flash_mesh.mesh = f_sph
	muzzle_flash_mesh.position = Vector3(0.25, 0.35, 0.54)
	var mat_f = StandardMaterial3D.new()
	mat_f.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_f.albedo_color = Color(1.0, 0.2, 0.1)
	muzzle_flash_mesh.material_override = mat_f
	muzzle_flash_mesh.visible = false
	add_child(muzzle_flash_mesh)
	
	# Collision Shape
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
	mat_bg.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	hp_bg.material_override = mat_bg
	add_child(hp_bg)
	
	hp_label = Label3D.new()
	hp_label.pixel_size = 0.012
	hp_label.font_size = 52
	hp_label.outline_size = 14
	hp_label.outline_modulate = Color(0, 0, 0, 1)
	hp_label.modulate = Color(1.0, 0.35, 0.35)
	hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_label.position = Vector3(0, 1.50, 0.02)
	add_child(hp_label)
	_update_hp_display()

func _update_hp_display() -> void:
	if is_instance_valid(hp_label):
		hp_label.text = str(maxi(0, int(ceil(current_hp))))

func _physics_process(delta: float) -> void:
	if is_dead or not is_active:
		return
	
	if moves_forward:
		# Advance towards player (+Z)
		position.z += move_speed * delta
	
	_process_shooting(delta)

func _process_shooting(delta: float) -> void:
	# Find player squad to evaluate distance
	var p_nodes = get_tree().get_nodes_in_group("player")
	if p_nodes.size() == 0:
		return
	var player = p_nodes[0] as PlayerSquad
	if not is_instance_valid(player) or player.is_defeated:
		if muzzle_flash_mesh:
			muzzle_flash_mesh.visible = false
		return
	
	var z_dist = global_position.z - player.global_position.z
	# Player moves in -Z direction, so enemy at e.g. -140 is ahead of player at -100 (z_dist is -40, so dist is 40)
	var forward_dist = player.global_position.z - global_position.z
	
	# Only attack if player is in front and in engagement range
	if forward_dist >= MIN_ATTACK_Z and forward_dist <= ATTACK_RANGE_Z:
		if is_telegraphing:
			telegraph_timer -= delta
			if telegraph_timer <= 0.0:
				is_telegraphing = false
				muzzle_flash_mesh.visible = false
				_fire_shot(player)
		else:
			attack_timer -= delta
			if attack_timer <= TELEGRAPH_DURATION:
				# Show telegraph warning
				is_telegraphing = true
				telegraph_timer = TELEGRAPH_DURATION
				if muzzle_flash_mesh:
					muzzle_flash_mesh.visible = true
	else:
		if is_telegraphing:
			is_telegraphing = false
			if muzzle_flash_mesh:
				muzzle_flash_mesh.visible = false

func _fire_shot(player: PlayerSquad) -> void:
	if is_dead or not is_active:
		return
	
	attack_timer = attack_interval + randf_range(-0.2, 0.2)
	SoundManager.play("shoot_rifle", 0.15)
	
	var spawn_pos = muzzle_point.global_position if muzzle_point else global_position
	# Aim toward player's current X position, along +Z
	var target_pos = player.global_position + Vector3(0, 0.8, 0)
	var shoot_dir = (target_pos - spawn_pos).normalized()
	
	enemy_shot_fired.emit(spawn_pos, shoot_dir, 1.0)
	
	# Small recoil animation
	var tw = create_tween()
	gun_mesh.position.z = 0.12
	tw.tween_property(gun_mesh, "position:z", 0.22, 0.12)

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
	
	if muzzle_flash_mesh:
		muzzle_flash_mesh.visible = false
	
	SoundManager.play("explosion")
	GameManager.add_coins(coin_reward)
	GameManager.run_kills += 1
	enemy_defeated.emit(global_position, coin_reward)
	
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.15).set_trans(Tween.TRANS_BACK)
	tween.finished.connect(func(): queue_free())

func _on_body_entered(body: Node3D) -> void:
	if is_dead:
		return
	if body is PlayerSquad:
		(body as PlayerSquad).remove_members(damage_to_player)
		_die()
