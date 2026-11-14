extends Area3D

class_name BossUnit

signal boss_hp_changed(current: float, max_h: float)
signal boss_defeated()
signal boss_shot_fired(pos: Vector3, dir: Vector3, dmg: float)

@export var boss_name: String = "Iron Sentinel"
@export var max_hp: float = 300.0
@export var coin_reward: int = 100

var current_hp: float = 300.0
var is_active: bool = false
var is_dead: bool = false

var move_direction: float = 1.0
var move_speed: float = 2.5
var bridge_limit_x: float = 3.2

var attack_timer: float = 1.0
var attack_interval: float = 1.8

var boss_mesh: Node3D
var left_cannon: Node3D
var right_cannon: Node3D
var left_cannon_mesh: MeshInstance3D
var right_cannon_mesh: MeshInstance3D

func _ready() -> void:
	collision_layer = 16
	collision_mask = 1 | 4
	
	current_hp = max_hp
	_build_visuals()

func setup(p_name: String, p_hp: float, p_coins: int) -> void:
	boss_name = p_name
	max_hp = p_hp
	current_hp = max_hp
	coin_reward = p_coins
	boss_hp_changed.emit(current_hp, max_hp)

func _build_visuals() -> void:
	boss_mesh = Node3D.new()
	add_child(boss_mesh)
	
	var hull = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(2.4, 2.2, 2.4)
	hull.mesh = box
	hull.position.y = 1.6
	
	var mat_hull = StandardMaterial3D.new()
	mat_hull.albedo_color = Color(0.85, 0.15, 0.15)
	mat_hull.metallic = 0.7
	mat_hull.roughness = 0.3
	hull.material_override = mat_hull
	boss_mesh.add_child(hull)
	
	var eye = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.45
	cyl.bottom_radius = 0.45
	cyl.height = 0.2
	eye.mesh = cyl
	eye.rotation_degrees.x = 90
	eye.position = Vector3(0, 1.8, 1.25)
	
	var mat_eye = StandardMaterial3D.new()
	mat_eye.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_eye.albedo_color = Color(1.0, 0.8, 0.1)
	eye.material_override = mat_eye
	boss_mesh.add_child(eye)
	
	for side in [-1, 1]:
		var cannon = MeshInstance3D.new()
		var c_mesh = BoxMesh.new()
		c_mesh.size = Vector3(0.4, 0.4, 1.8)
		cannon.mesh = c_mesh
		cannon.position = Vector3(side * 1.5, 1.4, 0.4)
		
		var mat_c = StandardMaterial3D.new()
		mat_c.albedo_color = Color(0.2, 0.2, 0.25)
		mat_c.metallic = 0.9
		cannon.material_override = mat_c
		boss_mesh.add_child(cannon)
		
		var muzzle = Node3D.new()
		muzzle.position = Vector3(side * 1.5, 1.4, 1.4)
		boss_mesh.add_child(muzzle)
		if side < 0:
			left_cannon = muzzle
			left_cannon_mesh = cannon
		else:
			right_cannon = muzzle
			right_cannon_mesh = cannon
	
	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(3.2, 2.5, 2.6)
	col.shape = box_shape
	col.position.y = 1.6
	add_child(col)

func activate() -> void:
	is_active = true
	boss_hp_changed.emit(current_hp, max_hp)

func stop_boss() -> void:
	is_active = false

func _physics_process(delta: float) -> void:
	if not is_active or is_dead:
		return
	
	position.x += move_direction * move_speed * delta
	if position.x > bridge_limit_x:
		position.x = bridge_limit_x
		move_direction = -1.0
	elif position.x < -bridge_limit_x:
		position.x = -bridge_limit_x
		move_direction = 1.0
	
	attack_timer -= delta
	if attack_timer <= 0.0:
		attack_timer = attack_interval
		_execute_attack()

func _execute_attack() -> void:
	if not is_active or is_dead:
		return
	
	SoundManager.play("shoot_shotgun", 0.05)
	var forward = global_transform.basis.z
	
	if left_cannon and right_cannon:
		boss_shot_fired.emit(left_cannon.global_position, (forward + Vector3(-0.08, 0, 0)).normalized(), 1.0)
		boss_shot_fired.emit(right_cannon.global_position, (forward + Vector3(0.08, 0, 0)).normalized(), 1.0)
		
		# Cannon recoil animation
		if left_cannon_mesh and right_cannon_mesh:
			var tw = create_tween()
			left_cannon_mesh.position.z = 0.2
			right_cannon_mesh.position.z = 0.2
			tw.tween_property(left_cannon_mesh, "position:z", 0.4, 0.15)
			tw.parallel().tween_property(right_cannon_mesh, "position:z", 0.4, 0.15)

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
	boss_mesh.scale = Vector3(1.08, 0.94, 1.08)
	tween.tween_property(boss_mesh, "scale", Vector3.ONE, 0.1)

func _defeat() -> void:
	if is_dead:
		return
	is_dead = true
	is_active = false
	SoundManager.play("explosion")
	GameManager.add_coins(coin_reward)
	boss_defeated.emit()
	
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	var tween = create_tween()
	tween.tween_property(boss_mesh, "rotation_degrees:x", -30.0, 0.4)
	tween.parallel().tween_property(boss_mesh, "position:y", -2.0, 0.5)
	tween.parallel().tween_property(boss_mesh, "scale", Vector3(0.05, 0.05, 0.05), 0.5)
	tween.finished.connect(func(): queue_free())
