extends Node3D

class_name SquadMember

var target_offset: Vector3 = Vector3.ZERO
var fire_timer: float = 0.0
var walk_anim_time: float = 0.0
var is_active: bool = true

var body_mesh: MeshInstance3D
var gun_mesh: MeshInstance3D
var muzzle_point: Node3D

signal shot_fired(spawn_pos: Vector3, direction: Vector3)

func _ready() -> void:
	_build_mesh()
	walk_anim_time = randf() * PI * 2.0
	fire_timer = randf() * 0.15

func _build_mesh() -> void:
	body_mesh = MeshInstance3D.new()
	var cap = CapsuleMesh.new()
	cap.radius = 0.22
	cap.height = 0.75
	body_mesh.mesh = cap
	body_mesh.position.y = 0.45
	
	var mat_blue = StandardMaterial3D.new()
	mat_blue.albedo_color = Color(0.12, 0.45, 0.95)
	mat_blue.roughness = 0.4
	body_mesh.material_override = mat_blue
	add_child(body_mesh)
	
	var head = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36
	head.mesh = sphere
	head.position.y = 0.42
	
	var mat_helmet = StandardMaterial3D.new()
	mat_helmet.albedo_color = Color(0.18, 0.75, 1.0)
	head.material_override = mat_helmet
	body_mesh.add_child(head)
	
	gun_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.1, 0.12, 0.45)
	gun_mesh.mesh = box
	gun_mesh.position = Vector3(0.22, 0.35, -0.22)
	
	var mat_gun = StandardMaterial3D.new()
	mat_gun.albedo_color = Color(0.15, 0.15, 0.18)
	mat_gun.metallic = 0.6
	gun_mesh.material_override = mat_gun
	add_child(gun_mesh)
	
	muzzle_point = Node3D.new()
	muzzle_point.position = Vector3(0.22, 0.35, -0.45)
	add_child(muzzle_point)

func set_target_offset(offset: Vector3) -> void:
	target_offset = offset

func update_member(delta: float, can_shoot: bool, weapon_data: Dictionary, dmg_mult: float, fire_mult: float) -> void:
	if not is_active:
		return
	
	position = position.lerp(target_offset, delta * 12.0)
	
	walk_anim_time += delta * 16.0
	body_mesh.position.y = 0.45 + abs(sin(walk_anim_time)) * 0.08
	body_mesh.rotation_degrees.z = sin(walk_anim_time * 0.5) * 4.0
	
	if can_shoot:
		fire_timer -= delta
		var base_delay: float = weapon_data.get("fire_delay", 0.22)
		var actual_delay = maxf(0.05, base_delay / fire_mult)
		
		if fire_timer <= 0.0:
			fire_timer = actual_delay
			_fire(weapon_data, dmg_mult)

func _fire(weapon_data: Dictionary, dmg_mult: float) -> void:
	var base_dmg: float = weapon_data.get("damage", 10.0)
	var final_dmg: float = base_dmg * dmg_mult
	var b_speed: float = weapon_data.get("bullet_speed", 40.0)
	var spread_count: int = weapon_data.get("spread_count", 1)
	var b_color: Color = weapon_data.get("color", Color(0.2, 0.8, 1.0))
	var wid: int = weapon_data.get("id", 0)
	
	match wid:
		0: SoundManager.play("shoot_rifle", 0.08)
		1: SoundManager.play("shoot_shotgun", 0.06)
		2: SoundManager.play("shoot_minigun", 0.1)
	
	var forward = -global_transform.basis.z
	var right = global_transform.basis.x
	
	if spread_count <= 1:
		shot_fired.emit(muzzle_point.global_position, forward, final_dmg, b_speed, b_color)
	else:
		var spread_angle_step = 0.08
		var start_angle = -spread_angle_step * (spread_count - 1) * 0.5
		for i in range(spread_count):
			var angle = start_angle + i * spread_angle_step
			var dir = (forward + right * tan(angle)).normalized()
			shot_fired.emit(muzzle_point.global_position, dir, final_dmg, b_speed, b_color)

func play_spawn_anim() -> void:
	scale = Vector3(0.05, 0.05, 0.05)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func play_death_anim(on_complete: Callable) -> void:
	is_active = false
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(on_complete)
