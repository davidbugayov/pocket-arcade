extends Area3D

class_name Bullet

var speed: float = 42.0
var direction: Vector3 = Vector3(0, 0, -1)
var damage: float = 10.0
var max_distance: float = 36.0
var distance_traveled: float = 0.0
var is_player_bullet: bool = true

var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var has_hit: bool = false

func _ready() -> void:
	_apply_collision_settings()
	monitoring = true
	monitorable = true

	_create_visuals()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _apply_collision_settings() -> void:
	if is_player_bullet:
		# Layer 4 = Player Bullet
		# Hits Layer 2 (Obstacles) and Layer 16 (Enemies & Boss)
		collision_layer = 4
		collision_mask = 2 | 16
	else:
		# Layer 8 = Enemy Bullet
		# Hits Layer 1 (Player Squad only). Does NOT hit obstacles or fellow enemies!
		collision_layer = 8
		collision_mask = 1

func setup(p_damage: float, p_speed: float, p_dir: Vector3, p_color: Color, p_is_player: bool = true) -> void:
	damage = p_damage
	speed = p_speed
	direction = p_dir.normalized()
	is_player_bullet = p_is_player

	_apply_collision_settings()

	if mesh_instance and mesh_instance.material_override:
		var mat = mesh_instance.material_override as StandardMaterial3D
		mat.albedo_color = p_color
		mat.emission = p_color
		mat.emission_energy_multiplier = 1.6

func _create_visuals() -> void:
	if mesh_instance == null:
		mesh_instance = MeshInstance3D.new()
		var cap = CapsuleMesh.new()
		cap.radius = 0.10 if not is_player_bullet else 0.08
		cap.height = 0.45 if not is_player_bullet else 0.4
		mesh_instance.mesh = cap
		mesh_instance.rotation_degrees.x = 90

		var mat = StandardMaterial3D.new()
		mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		var init_col = Color(0.2, 0.9, 1.0) if is_player_bullet else Color(1.0, 0.3, 0.1)
		mat.albedo_color = init_col
		mesh_instance.material_override = mat
		add_child(mesh_instance)

	if collision_shape == null:
		collision_shape = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 0.28 if not is_player_bullet else 0.22
		collision_shape.shape = shape
		add_child(collision_shape)

static var last_hit_sound_time: float = -1.0

func _play_hit_sound() -> void:
	var cur_t = Time.get_ticks_msec() * 0.001
	if cur_t - last_hit_sound_time >= 0.06:
		last_hit_sound_time = cur_t
		SoundManager.play("hit", 0.08)

func _physics_process(delta: float) -> void:
	if has_hit:
		return

	var move_dist = speed * delta
	var start_pos = global_position
	var end_pos = start_pos + direction * move_dist

	# Continuous raycast check on large steps ensures zero tunneling
	if move_dist > 0.8:
		var world = get_world_3d()
		if world:
			var space_state = world.direct_space_state
			if space_state:
				var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos, collision_mask)
				query.collide_with_areas = true
				query.collide_with_bodies = true
				var hit = space_state.intersect_ray(query)
				if hit and hit.collider:
					if hit.collider is Area3D:
						_on_area_entered(hit.collider as Area3D)
					elif hit.collider is Node3D:
						_on_body_entered(hit.collider as Node3D)
					if has_hit:
						global_position = hit.position
						return

	global_position = end_pos
	distance_traveled += move_dist
	if distance_traveled >= max_distance:
		queue_free()

func _on_area_entered(area: Area3D) -> void:
	if has_hit:
		return

	if is_player_bullet:
		# Player bullet can hit shootable gates, enemies, boss, or obstacles
		if area.name == "GateShootableHitbox" or area.has_method("on_bullet_hit"):
			has_hit = true
			if area.has_method("on_bullet_hit"):
				area.on_bullet_hit(damage)
			elif area.get_parent() and area.get_parent().has_method("on_bullet_hit"):
				area.get_parent().on_bullet_hit(damage)
			SoundManager.play("hit", 0.08)
			queue_free()
		elif area.has_method("take_damage"):
			has_hit = true
			area.take_damage(damage)
			_play_hit_sound()
			queue_free()
	else:
		# Enemy bullet: NEVER hit other enemies or boss
		if area is EnemyUnit or area is BossUnit or area.name == "BossUnit":
			return
		# If it hits player area or has take_damage
		if area.has_method("take_damage") and not (area is EnemyUnit or area is BossUnit):
			has_hit = true
			area.take_damage(damage)
			_play_hit_sound()
			queue_free()

func _on_body_entered(body: Node3D) -> void:
	if has_hit:
		return

	if is_player_bullet:
		# Player bullet: NEVER hurt player squad
		if body is PlayerSquad:
			return
		if body is Obstacle or body.has_method("take_damage"):
			has_hit = true
			if body.has_method("take_damage"):
				body.take_damage(damage)
			_play_hit_sound()
			queue_free()
	else:
		# Enemy bullet: NEVER hurt enemies or boss
		if body is EnemyUnit or body is BossUnit:
			return
		if body is PlayerSquad:
			has_hit = true
			body.take_damage(damage)
			_play_hit_sound()
			queue_free()
		elif body.has_method("take_damage") and not (body is Obstacle):
			has_hit = true
			body.take_damage(damage)
			_play_hit_sound()
			queue_free()
