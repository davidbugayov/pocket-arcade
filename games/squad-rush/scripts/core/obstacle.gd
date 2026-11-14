extends StaticBody3D

class_name Obstacle

enum ObstacleType {
	TIRE_STACK,
	CRATE,
	BARREL,
	CONCRETE_BLOCK,
}

@export var obstacle_type: ObstacleType = ObstacleType.TIRE_STACK
@export var max_hp: float = 20.0
@export var coin_reward: int = 5

var current_hp: float = 20.0
var hp_label: Label3D
var hp_bg: MeshInstance3D
var mesh_root: Node3D
var collision_shape: CollisionShape3D
var squad_detector: Area3D
var detector_shape: CollisionShape3D

var has_collided_with_squad: bool = false
var is_destroyed: bool = false

signal destroyed(pos: Vector3, reward: int)

static var model_scenes = {
	ObstacleType.TIRE_STACK: preload("res://assets/models/tyre_stack.glb"),
	ObstacleType.CRATE: preload("res://assets/models/ammunition_crate.glb"),
	ObstacleType.BARREL: preload("res://assets/models/barrel.glb"),
	ObstacleType.CONCRETE_BLOCK: preload("res://assets/models/jersey_barrier.glb")
}

func _ready() -> void:
	collision_layer = 2 # Obstacle layer
	collision_mask = 1 | 4 # Player (1) and player bullets (4)

	current_hp = max_hp
	_rebuild_visuals()
	_create_hp_label()
	_setup_squad_detector()

func setup(p_type: ObstacleType, p_hp: float, p_coins: int) -> void:
	obstacle_type = p_type
	max_hp = p_hp
	current_hp = max_hp
	coin_reward = p_coins

	if is_inside_tree():
		_rebuild_visuals()
		_update_hp_display()
		_update_detector_shape()

func _rebuild_visuals() -> void:
	if mesh_root and is_instance_valid(mesh_root):
		mesh_root.queue_free()
	if collision_shape and is_instance_valid(collision_shape):
		collision_shape.queue_free()

	mesh_root = Node3D.new()
	add_child(mesh_root)

	collision_shape = CollisionShape3D.new()

	var scene: PackedScene = model_scenes.get(obstacle_type, null)
	var model_inst: Node3D = scene.instantiate() if scene else null

	match obstacle_type:
		ObstacleType.TIRE_STACK:
			var shape = CylinderShape3D.new()
			shape.radius = 0.68
			shape.height = 1.3
			collision_shape.shape = shape
			collision_shape.position.y = 0.65

			if model_inst:
				model_inst.scale = Vector3(1.4, 1.4, 1.4)
				mesh_root.add_child(model_inst)

		ObstacleType.CRATE:
			var shape = BoxShape3D.new()
			shape.size = Vector3(1.3, 1.3, 1.3)
			collision_shape.shape = shape
			collision_shape.position.y = 0.65

			if model_inst:
				model_inst.scale = Vector3(1.3, 1.3, 1.3)
				model_inst.position.y = 0.05
				mesh_root.add_child(model_inst)

		ObstacleType.BARREL:
			var shape = CylinderShape3D.new()
			shape.radius = 0.52
			shape.height = 1.4
			collision_shape.shape = shape
			collision_shape.position.y = 0.70

			if model_inst:
				model_inst.scale = Vector3(1.35, 1.35, 1.35)
				mesh_root.add_child(model_inst)

		ObstacleType.CONCRETE_BLOCK:
			var shape = BoxShape3D.new()
			shape.size = Vector3(1.8, 1.3, 0.9)
			collision_shape.shape = shape
			collision_shape.position.y = 0.65

			if model_inst:
				model_inst.scale = Vector3(1.15, 1.35, 1.15)
				mesh_root.add_child(model_inst)

	add_child(collision_shape)

func _setup_squad_detector() -> void:
	if squad_detector and is_instance_valid(squad_detector):
		squad_detector.queue_free()

	squad_detector = Area3D.new()
	squad_detector.name = "SquadDetector"
	squad_detector.collision_layer = 0
	squad_detector.collision_mask = 1 # PlayerSquad layer
	squad_detector.monitoring = true
	squad_detector.monitorable = false

	detector_shape = CollisionShape3D.new()
	_update_detector_shape()
	squad_detector.add_child(detector_shape)
	add_child(squad_detector)

	squad_detector.body_entered.connect(_on_squad_detector_body_entered)

func _update_detector_shape() -> void:
	if not detector_shape:
		return

	match obstacle_type:
		ObstacleType.TIRE_STACK:
			var shape = CylinderShape3D.new()
			shape.radius = 0.72
			shape.height = 1.35
			detector_shape.shape = shape
			detector_shape.position.y = 0.65
		ObstacleType.CRATE:
			var shape = BoxShape3D.new()
			shape.size = Vector3(1.35, 1.35, 1.35)
			detector_shape.shape = shape
			detector_shape.position.y = 0.65
		ObstacleType.BARREL:
			var shape = CylinderShape3D.new()
			shape.radius = 0.56
			shape.height = 1.45
			detector_shape.shape = shape
			detector_shape.position.y = 0.70
		ObstacleType.CONCRETE_BLOCK:
			var shape = BoxShape3D.new()
			shape.size = Vector3(1.85, 1.35, 0.95)
			detector_shape.shape = shape
			detector_shape.position.y = 0.65

func _create_hp_label() -> void:
	if hp_label and is_instance_valid(hp_label):
		hp_label.queue_free()
	if hp_bg and is_instance_valid(hp_bg):
		hp_bg.queue_free()

	# Background Pill Mesh for high readability
	hp_bg = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(0.9, 0.45)
	hp_bg.mesh = quad
	hp_bg.position = Vector3(0, 1.75, 0)

	var mat_bg = StandardMaterial3D.new()
	mat_bg.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_bg.albedo_color = Color(0.08, 0.08, 0.10, 0.85)
	mat_bg.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_bg.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	hp_bg.material_override = mat_bg
	add_child(hp_bg)

	hp_label = Label3D.new()
	hp_label.pixel_size = 0.012
	hp_label.font_size = 56
	hp_label.outline_size = 16
	hp_label.outline_modulate = Color(0, 0, 0, 1)
	hp_label.modulate = Color(1.0, 0.92, 0.15) # Bold yellow
	hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_label.position = Vector3(0, 1.75, 0.02)
	add_child(hp_label)
	_update_hp_display()

func _update_hp_display() -> void:
	if is_instance_valid(hp_label):
		hp_label.text = str(maxi(0, int(ceil(current_hp))))

func take_damage(amount: float) -> void:
	if is_destroyed or current_hp <= 0:
		return

	current_hp -= amount
	_update_hp_display()
	_flash_mesh()

	if current_hp <= 0:
		_destroy_obstacle()

func _flash_mesh() -> void:
	if not is_instance_valid(mesh_root):
		return
	var tween = create_tween()
	mesh_root.scale = Vector3(1.10, 0.90, 1.10)
	tween.tween_property(mesh_root, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_SINE)

func _on_squad_detector_body_entered(body: Node3D) -> void:
	if is_destroyed or has_collided_with_squad:
		return
	if body is PlayerSquad:
		on_player_squad_collided(body as PlayerSquad)

func on_player_squad_collided(squad: PlayerSquad) -> void:
	if has_collided_with_squad or is_destroyed or current_hp <= 0:
		return
	has_collided_with_squad = true

	# Immediately disable squad detector to guarantee no multiple triggers per frame
	if is_instance_valid(squad_detector):
		squad_detector.set_deferred("monitoring", false)
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)

	# Squad loses members based on remaining HP of obstacle
	var squad_loss = maxi(1, int(ceil(current_hp / 12.0)))
	squad.remove_members(squad_loss)

	# Obstacle is smashed
	_destroy_obstacle()

func _destroy_obstacle() -> void:
	if is_destroyed:
		return
	is_destroyed = true

	if is_instance_valid(squad_detector):
		squad_detector.set_deferred("monitoring", false)
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)

	SoundManager.play("explosion")
	GameManager.add_coins(coin_reward)
	GameManager.run_kills += 1
	destroyed.emit(global_position, coin_reward)

	var tween = create_tween()
	if is_instance_valid(mesh_root):
		tween.tween_property(mesh_root, "scale", Vector3(0.05, 0.05, 0.05), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if is_instance_valid(hp_label):
		tween.parallel().tween_property(hp_label, "scale", Vector3(0.05, 0.05, 0.05), 0.15)
	if is_instance_valid(hp_bg):
		tween.parallel().tween_property(hp_bg, "scale", Vector3(0.05, 0.05, 0.05), 0.15)
	tween.finished.connect(func(): queue_free())
