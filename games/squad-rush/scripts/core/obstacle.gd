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
	# Clear old mesh if rebuilding
	if mesh_root and is_instance_valid(mesh_root):
		mesh_root.queue_free()
	if collision_shape and is_instance_valid(collision_shape):
		collision_shape.queue_free()
	
	mesh_root = Node3D.new()
	add_child(mesh_root)
	
	collision_shape = CollisionShape3D.new()
	
	match obstacle_type:
		ObstacleType.TIRE_STACK:
			var shape = CylinderShape3D.new()
			shape.radius = 0.68
			shape.height = 1.3
			collision_shape.shape = shape
			collision_shape.position.y = 0.65
			
			var tire_mat = StandardMaterial3D.new()
			tire_mat.albedo_color = Color(0.18, 0.18, 0.20)
			tire_mat.roughness = 0.9
			
			var hub_mat = StandardMaterial3D.new()
			hub_mat.albedo_color = Color(0.35, 0.35, 0.38)
			hub_mat.metallic = 0.7
			
			for i in range(3):
				var tire = MeshInstance3D.new()
				var cyl = CylinderMesh.new()
				cyl.top_radius = 0.65
				cyl.bottom_radius = 0.65
				cyl.height = 0.38
				tire.mesh = cyl
				tire.position.y = 0.20 + (i * 0.40)
				tire.material_override = tire_mat
				mesh_root.add_child(tire)
				
				# Rim center
				var hub = MeshInstance3D.new()
				var h_cyl = CylinderMesh.new()
				h_cyl.top_radius = 0.32
				h_cyl.bottom_radius = 0.32
				h_cyl.height = 0.40
				hub.mesh = h_cyl
				hub.position.y = 0.20 + (i * 0.40)
				hub.material_override = hub_mat
				mesh_root.add_child(hub)
				
		ObstacleType.CRATE:
			var shape = BoxShape3D.new()
			shape.size = Vector3(1.3, 1.3, 1.3)
			collision_shape.shape = shape
			collision_shape.position.y = 0.65
			
			var crate = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(1.3, 1.3, 1.3)
			crate.mesh = box
			crate.position.y = 0.65
			
			var crate_mat = StandardMaterial3D.new()
			crate_mat.albedo_color = Color(0.68, 0.45, 0.22)
			crate_mat.roughness = 0.8
			crate.material_override = crate_mat
			mesh_root.add_child(crate)
			
			# Steel reinforcing straps
			var strap_mat = StandardMaterial3D.new()
			strap_mat.albedo_color = Color(0.25, 0.25, 0.28)
			strap_mat.metallic = 0.8
			
			for side in [-0.5, 0.5]:
				var strap = MeshInstance3D.new()
				var s_box = BoxMesh.new()
				s_box.size = Vector3(1.32, 0.12, 1.32)
				strap.mesh = s_box
				strap.position.y = 0.65 + side
				strap.material_override = strap_mat
				mesh_root.add_child(strap)
				
		ObstacleType.BARREL:
			var shape = CylinderShape3D.new()
			shape.radius = 0.52
			shape.height = 1.4
			collision_shape.shape = shape
			collision_shape.position.y = 0.70
			
			var barrel = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.50
			cyl.bottom_radius = 0.50
			cyl.height = 1.4
			barrel.mesh = cyl
			barrel.position.y = 0.70
			
			var b_mat = StandardMaterial3D.new()
			b_mat.albedo_color = Color(0.85, 0.18, 0.15) # Red hazard drum
			b_mat.metallic = 0.5
			b_mat.roughness = 0.35
			barrel.material_override = b_mat
			mesh_root.add_child(barrel)
			
			# Yellow hazard stripe in middle
			var stripe = MeshInstance3D.new()
			var s_cyl = CylinderMesh.new()
			s_cyl.top_radius = 0.51
			s_cyl.bottom_radius = 0.51
			s_cyl.height = 0.25
			stripe.mesh = s_cyl
			stripe.position.y = 0.70
			var s_mat = StandardMaterial3D.new()
			s_mat.albedo_color = Color(1.0, 0.85, 0.1)
			stripe.material_override = s_mat
			mesh_root.add_child(stripe)
				
		ObstacleType.CONCRETE_BLOCK:
			var shape = BoxShape3D.new()
			shape.size = Vector3(1.8, 1.3, 0.9)
			collision_shape.shape = shape
			collision_shape.position.y = 0.65
			
			var block = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(1.8, 1.3, 0.9)
			block.mesh = box
			block.position.y = 0.65
			
			var c_mat = StandardMaterial3D.new()
			c_mat.albedo_color = Color(0.55, 0.56, 0.58) # Road barrier concrete
			c_mat.roughness = 0.92
			block.material_override = c_mat
			mesh_root.add_child(block)
			
			# Hazard warning stripes on bottom
			var haz = MeshInstance3D.new()
			var h_box = BoxMesh.new()
			h_box.size = Vector3(1.82, 0.22, 0.92)
			haz.mesh = h_box
			haz.position.y = 0.20
			var h_mat = StandardMaterial3D.new()
			h_mat.albedo_color = Color(0.9, 0.6, 0.1)
			haz.material_override = h_mat
			mesh_root.add_child(haz)
	
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
