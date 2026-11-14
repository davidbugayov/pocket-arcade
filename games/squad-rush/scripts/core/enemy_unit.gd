extends Area3D

class_name EnemyUnit

@export var max_hp: float = 25.0
@export var damage_to_player: int = 1
@export var coin_reward: int = 8
@export var moves_forward: bool = false
@export var move_speed: float = 2.0

var current_hp: float = 25.0
var hp_label: Label3D
var body_mesh: MeshInstance3D
var is_dead: bool = false

signal enemy_defeated(pos: Vector3, coins: int)

func _ready() -> void:
	collision_layer = 16 # Enemy layer
	collision_mask = 1 | 4 # Player (1) and player bullets (4)
	
	current_hp = max_hp
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
	sphere.radius = 0.2
	sphere.height = 0.4
	head.mesh = sphere
	head.position.y = 0.48
	
	var mat_helmet = StandardMaterial3D.new()
	mat_helmet.albedo_color = Color(0.5, 0.05, 0.05)
	head.material_override = mat_helmet
	body_mesh.add_child(head)
	
	# Gun
	var gun = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.12, 0.12, 0.45)
	gun.mesh = box
	gun.position = Vector3(0.25, 0.35, 0.2) # Aiming towards player (+Z)
	var mat_gun = StandardMaterial3D.new()
	mat_gun.albedo_color = Color(0.1, 0.1, 0.1)
	gun.material_override = mat_gun
	add_child(gun)
	
	# Collision Shape
	var col = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.0
	col.shape = shape
	col.position.y = 0.5
	add_child(col)

func _create_hp_label() -> void:
	hp_label = Label3D.new()
	hp_label.pixel_size = 0.012
	hp_label.font_size = 48
	hp_label.outline_size = 12
	hp_label.outline_modulate = Color(0, 0, 0, 1)
	hp_label.modulate = Color(1.0, 0.3, 0.3)
	hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_label.position = Vector3(0, 1.45, 0)
	add_child(hp_label)
	_update_hp_display()

func _update_hp_display() -> void:
	if hp_label:
		hp_label.text = str(maxi(0, int(ceil(current_hp))))

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if moves_forward:
		# Advance towards player (+Z)
		position.z += move_speed * delta

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
	scale = Vector3(1.15, 0.9, 1.15)
	tween.tween_property(self, "scale", Vector3.ONE, 0.1)

func _die() -> void:
	is_dead = true
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

