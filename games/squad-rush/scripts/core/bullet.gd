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
static var spark_quad: QuadMesh = null
static var mat_spark_player: StandardMaterial3D = null
static var mat_spark_enemy: StandardMaterial3D = null
static var spark_pool: Array[MeshInstance3D] = []
const MAX_POOL_SIZE: int = 24

func _play_hit_sound() -> void:
	var cur_t = Time.get_ticks_msec() * 0.001
	if cur_t - last_hit_sound_time >= 0.06:
		last_hit_sound_time = cur_t
		SoundManager.play("hit", 0.08)

func _spawn_hit_spark(hit_pos: Vector3) -> void:
	if not is_inside_tree():
		return
	var parent_node = get_parent()
	if not parent_node:
		return

	if spark_quad == null:
		spark_quad = QuadMesh.new()
		spark_quad.size = Vector2(0.38, 0.38)

	if mat_spark_player == null:
		mat_spark_player = StandardMaterial3D.new()
		mat_spark_player.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		mat_spark_player.albedo_color = Color(1.0, 0.88, 0.30)
		mat_spark_player.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED

		mat_spark_enemy = StandardMaterial3D.new()
		mat_spark_enemy.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		mat_spark_enemy.albedo_color = Color(1.0, 0.32, 0.15)
		mat_spark_enemy.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED

	# Prune any freed or invalid sparks from previous runs/scenes
	var valid_sparks: Array[MeshInstance3D] = []
	var s: MeshInstance3D = null
	for item in spark_pool:
		if is_instance_valid(item):
			valid_sparks.append(item)
			if s == null and not item.visible:
				s = item
	spark_pool = valid_sparks

	if s == null:
		if spark_pool.size() < MAX_POOL_SIZE:
			s = MeshInstance3D.new()
			s.mesh = spark_quad
			parent_node.add_child(s)
			spark_pool.append(s)
		elif spark_pool.size() > 0:
			s = spark_pool[randi() % spark_pool.size()]

	if not is_instance_valid(s):
		return

	if s.get_parent() != parent_node:
		if s.get_parent():
			s.get_parent().remove_child(s)
		parent_node.add_child(s)

	s.material_override = mat_spark_player if is_player_bullet else mat_spark_enemy
	s.position = hit_pos
	s.scale = Vector3(0.4, 0.4, 0.4)
	s.visible = true

	var tw = s.create_tween()
	tw.tween_property(s, "scale", Vector3(1.6, 1.6, 1.6), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "scale", Vector3(0.01, 0.01, 0.01), 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func(): if is_instance_valid(s): s.visible = false)

func _physics_process(delta: float) -> void:
	if has_hit:
		return

	var move_dist = speed * delta
	var start_pos = global_position
	var end_pos = start_pos + direction * move_dist

	# Continuous raycast check ensures zero tunneling through thin targets (e.g. 0.4m gates) across all speeds & framerates
	if move_dist > 0.001:
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

	var hit_pos = global_position if is_inside_tree() else Vector3.ZERO
	if is_player_bullet:
		# Player bullet can hit shootable gates, enemies, boss, or obstacles
		if area.name == "GateShootableHitbox" or area.has_method("on_bullet_hit"):
			has_hit = true
			if area.has_method("on_bullet_hit"):
				area.on_bullet_hit(damage)
			elif area.get_parent() and area.get_parent().has_method("on_bullet_hit"):
				area.get_parent().on_bullet_hit(damage)
			_spawn_hit_spark(hit_pos)
			_play_hit_sound()
			queue_free()
		elif area.has_method("take_damage"):
			has_hit = true
			area.take_damage(damage)
			_spawn_hit_spark(hit_pos)
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
			_spawn_hit_spark(hit_pos)
			_play_hit_sound()
			queue_free()

func _on_body_entered(body: Node3D) -> void:
	if has_hit:
		return

	var hit_pos = global_position if is_inside_tree() else Vector3.ZERO
	if is_player_bullet:
		# Player bullet: NEVER hurt player squad
		if body is PlayerSquad:
			return
		if body is Obstacle or body.has_method("take_damage"):
			has_hit = true
			if body.has_method("take_damage"):
				body.take_damage(damage)
			_spawn_hit_spark(hit_pos)
			_play_hit_sound()
			queue_free()
	else:
		# Enemy bullet: NEVER hurt enemies or boss
		if body is EnemyUnit or body is BossUnit:
			return
		if body is PlayerSquad:
			has_hit = true
			body.take_damage(damage)
			_spawn_hit_spark(hit_pos)
			_play_hit_sound()
			queue_free()
		elif body.has_method("take_damage") and not (body is Obstacle):
			has_hit = true
			body.take_damage(damage)
			_spawn_hit_spark(hit_pos)
			_play_hit_sound()
			queue_free()
