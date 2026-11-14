extends CharacterBody3D

class_name PlayerSquad

signal squad_count_changed(count: int)
signal squad_defeated()
signal squad_damaged(loss: int)
signal camera_shake_requested(intensity: float)
signal bullet_spawn_requested(pos: Vector3, dir: Vector3, dmg: float, spd: float, col: Color)

@export var forward_speed: float = 9.0
@export var horizontal_speed: float = 16.0
@export var bridge_limit_x: float = 3.6

var squad_count: int = 1
var members: Array[SquadMember] = []

var target_x: float = 0.0
var is_dragging: bool = false
var drag_touch_id: int = -1
var last_touch_x: float = 0.0

var can_move: bool = true
var can_shoot: bool = true
var is_stopped_at_boss: bool = false
var boss_stop_z: float = -9999.0
var is_defeated: bool = false

const SPACING = 0.62

var badge_root: Node3D
var count_label: Label3D
var badge_bg: MeshInstance3D
var squad_col_shape: CollisionShape3D
var squad_cylinder: CylinderShape3D

func _ready() -> void:
	# Layer 1 = Player
	# Mask 2 (Obstacles) | 16 (Enemies/Boss) | 8 (Enemy Bullets)
	collision_layer = 1
	collision_mask = 2 | 16 | 8

	squad_col_shape = CollisionShape3D.new()
	squad_cylinder = CylinderShape3D.new()
	squad_cylinder.radius = 0.9
	squad_cylinder.height = 1.6
	squad_col_shape.shape = squad_cylinder
	squad_col_shape.position.y = 0.8
	add_child(squad_col_shape)

	target_x = position.x
	_create_count_badge()

	var start_size = GameManager.get_starting_squad_size()
	set_squad_size(start_size)

func _create_count_badge() -> void:
	badge_root = Node3D.new()
	badge_root.position = Vector3(0, 2.4, 0)
	add_child(badge_root)

	# Background Pill Mesh
	badge_bg = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(1.5, 0.65)
	badge_bg.mesh = quad

	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.06, 0.32, 0.88, 0.92)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	badge_bg.material_override = mat
	badge_root.add_child(badge_bg)

	count_label = Label3D.new()
	count_label.text = "1"
	count_label.pixel_size = 0.009
	count_label.font_size = 56
	count_label.modulate = Color(1, 1, 1)
	count_label.outline_modulate = Color(0, 0, 0)
	count_label.outline_size = 14
	count_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	count_label.position.z = 0.05
	badge_root.add_child(count_label)

func _unhandled_input(event: InputEvent) -> void:
	if not can_move or is_defeated:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			is_dragging = true
			drag_touch_id = event.index
			last_touch_x = event.position.x
		elif event.index == drag_touch_id:
			is_dragging = false
			drag_touch_id = -1

	elif event is InputEventScreenDrag and is_dragging:
		if event.index == drag_touch_id:
			var dx = event.relative.x
			var world_dx = (dx / 720.0) * (bridge_limit_x * 2.8)
			target_x = clampf(target_x + world_dx, -bridge_limit_x, bridge_limit_x)

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			last_touch_x = event.position.x
	elif event is InputEventMouseMotion and is_dragging:
		var dx = event.relative.x
		var world_dx = (dx / 720.0) * (bridge_limit_x * 2.8)
		target_x = clampf(target_x + world_dx, -bridge_limit_x, bridge_limit_x)

func _physics_process(delta: float) -> void:
	if is_defeated:
		return

	# Horizontal steer
	if can_move:
		position.x = lerpf(position.x, target_x, delta * horizontal_speed)

	# Forward movement
	if can_move and not is_stopped_at_boss:
		position.z -= forward_speed * delta
		if position.z <= boss_stop_z:
			position.z = boss_stop_z
			is_stopped_at_boss = true

	# Update all members
	var wdata = GameManager.get_weapon_data()
	var dmg_m = GameManager.get_damage_multiplier()
	var fire_m = GameManager.get_fire_rate_multiplier()

	for m in members:
		if is_instance_valid(m):
			m.update_member(delta, can_shoot and not is_defeated, wdata, dmg_m, fire_m)

func set_squad_size(new_count: int) -> void:
	if is_defeated:
		return

	new_count = maxi(0, new_count)
	squad_count = new_count

	if squad_count <= 0:
		_trigger_defeat()
		return

	if is_instance_valid(count_label):
		count_label.text = str(squad_count)
	squad_count_changed.emit(squad_count)
	_update_collision_size()
	_rebuild_formation()

func _update_collision_size() -> void:
	if is_instance_valid(squad_cylinder):
		# Dynamically scale collision radius with squad size
		squad_cylinder.radius = clampf(0.85 + sqrt(float(squad_count)) * 0.28, 0.85, 3.2)

func take_damage(amount: float) -> void:
	if is_defeated or squad_count <= 0:
		return

	var loss = maxi(1, int(round(amount)))
	remove_members(loss)
	squad_damaged.emit(loss)
	camera_shake_requested.emit(0.25)

func add_members(amount: int) -> void:
	if is_defeated or amount <= 0:
		return
	set_squad_size(squad_count + amount)
	SoundManager.play("gate_positive")
	_pulse_badge(Color(0.2, 1.0, 0.3))

func multiply_members(factor: int) -> void:
	if is_defeated or factor <= 1:
		return
	set_squad_size(squad_count * factor)
	SoundManager.play("gate_positive")
	_pulse_badge(Color(0.1, 0.9, 1.0))

func remove_members(amount: int) -> void:
	if is_defeated or amount <= 0:
		return
	var next_count = maxi(0, squad_count - amount)
	set_squad_size(next_count)
	SoundManager.play("gate_negative")
	_pulse_badge(Color(1.0, 0.2, 0.2))
	_flash_members_red()

func divide_members(divisor: int) -> void:
	if is_defeated or divisor <= 1:
		return
	var next_count = maxi(0, int(ceil(float(squad_count) / float(divisor))))
	set_squad_size(next_count)
	SoundManager.play("gate_negative")
	_pulse_badge(Color(1.0, 0.2, 0.2))
	_flash_members_red()

func _pulse_badge(flash_color: Color) -> void:
	if not is_instance_valid(count_label):
		return
	var tween = create_tween()
	count_label.modulate = flash_color
	if is_instance_valid(badge_bg) and badge_bg.material_override:
		(badge_bg.material_override as StandardMaterial3D).albedo_color = Color(flash_color.r * 0.8, flash_color.g * 0.8, flash_color.b * 0.8, 0.95)

	badge_root.scale = Vector3(1.35, 1.35, 1.35)
	tween.tween_property(badge_root, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(count_label, "modulate", Color(1, 1, 1), 0.25)
	if is_instance_valid(badge_bg) and badge_bg.material_override:
		tween.parallel().tween_property(badge_bg.material_override, "albedo_color", Color(0.06, 0.32, 0.88, 0.92), 0.25)

func _flash_members_red() -> void:
	for m in members:
		if is_instance_valid(m) and is_instance_valid(m.body_mesh) and m.body_mesh.material_override:
			var mat = m.body_mesh.material_override as StandardMaterial3D
			mat.albedo_color = Color(1.0, 0.3, 0.3)
			var tw = create_tween()
			tw.tween_property(mat, "albedo_color", Color(0.12, 0.45, 0.95), 0.2)

func _rebuild_formation() -> void:
	var positions = _calculate_formation_offsets(squad_count)

	while members.size() < squad_count:
		var m = SquadMember.new()
		add_child(m)
		m.shot_fired.connect(_on_member_shot_fired)
		m.position = Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
		m.play_spawn_anim()
		members.append(m)

	while members.size() > squad_count:
		var excess: SquadMember = members.pop_back()
		if is_instance_valid(excess):
			excess.play_death_anim(func(): if is_instance_valid(excess): excess.queue_free())

	for i in range(members.size()):
		if i < positions.size() and is_instance_valid(members[i]):
			members[i].set_target_offset(positions[i])

func _calculate_formation_offsets(count: int) -> Array[Vector3]:
	var offsets: Array[Vector3] = []
	if count <= 0:
		return offsets

	offsets.append(Vector3.ZERO)
	if count == 1:
		return offsets

	var golden_angle = 2.39996323
	for i in range(1, count):
		var r = sqrt(float(i)) * SPACING * 0.72
		var theta = float(i) * golden_angle
		var x = r * cos(theta)
		var z = r * sin(theta) * 0.85
		offsets.append(Vector3(x, 0, z))

	return offsets

func _on_member_shot_fired(pos: Vector3, dir: Vector3, dmg: float, spd: float, col: Color) -> void:
	if not is_defeated and can_shoot:
		bullet_spawn_requested.emit(pos, dir, dmg, spd, col)

func stop_at_boss(boss_z: float) -> void:
	boss_stop_z = boss_z + 16.0 # Stop 16 meters in front of boss to duel!

func _trigger_defeat() -> void:
	if is_defeated:
		return
	is_defeated = true
	can_move = false
	can_shoot = false
	if is_instance_valid(badge_root):
		badge_root.visible = false
	squad_defeated.emit()
	SoundManager.play("defeat")

func stop_squad() -> void:
	can_move = false
	can_shoot = false
