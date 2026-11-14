extends Area3D

class_name Bullet

var speed: float = 42.0
var direction: Vector3 = Vector3(0, 0, -1)
var damage: float = 10.0
var max_distance: float = 65.0
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

func _physics_process(delta: float) -> void:
	var move_dist = speed * delta
	global_position += direction * move_dist
	distance_traveled += move_dist
	if distance_traveled >= max_distance:
		queue_free()

func _on_area_entered(area: Area3D) -> void:
	if has_hit:
		return
	
	if is_player_bullet:
		# Player bullet can only hit enemies/boss or obstacles
		if area is EnemyUnit or area is BossUnit or area is Obstacle:
			has_hit = true
			if area.has_method("take_damage"):
				area.take_damage(damage)
			SoundManager.play("hit", 0.1)
			queue_free()
	else:
		# Enemy bullet: NEVER hit other enemies or boss
		if area is EnemyUnit or area is BossUnit:
			return
		# If it hits player squad or player area
		if area.has_method("take_damage"):
			has_hit = true
			area.take_damage(damage)
			SoundManager.play("hit", 0.1)
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
			SoundManager.play("hit", 0.1)
			queue_free()
	else:
		# Enemy bullet: NEVER hurt enemies or boss
		if body is EnemyUnit or body is BossUnit:
			return
		if body is PlayerSquad:
			has_hit = true
			body.take_damage(damage)
			SoundManager.play("hit", 0.1)
			queue_free()
		elif body.has_method("take_damage") and not (body is Obstacle):
			has_hit = true
			body.take_damage(damage)
			SoundManager.play("hit", 0.1)
			queue_free()
