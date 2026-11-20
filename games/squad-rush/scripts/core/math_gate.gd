extends Node3D

class_name MathGate

enum OperationType {
	ADD,
	MULTIPLY,
	SUBTRACT,
	DIVIDE,
}

@export var operation: OperationType = OperationType.ADD
@export var value: int = 5
@export var initial_value: int = 5
@export var is_left_gate: bool = true
@export var partner_gate: MathGate = null

var applied: bool = false
var area: Area3D
var shootable_hitbox: Area3D
var label: Label3D
var text_bg: MeshInstance3D
var barrier_mesh: MeshInstance3D
var frame_top: MeshInstance3D
var frame_left: MeshInstance3D
var frame_right: MeshInstance3D

var tracked_squad: PlayerSquad = null
var punch_tween: Tween
var multiplier_bullet_hits: int = 0
var last_bullet_hit_time: float = -1.0

const MAX_LABEL_DIST: float = 85.0 # Increased for early route and gate preview
const MIN_HIT_INTERVAL: float = 0.22 # Controlled token rate prevents effortless over-upgrades
const MAX_GATE_VALUE_ADD: int = 20
const MAX_GATE_VALUE_MULT: int = 3
var subtract_bullet_hits: int = 0
var add_bullet_hits: int = 0

func _ready() -> void:
	_build_visuals()
	_setup_trigger()

func setup(op: OperationType, val: int, left_side: bool) -> void:
	operation = op
	value = val
	initial_value = val
	is_left_gate = left_side
	_update_display()

func _build_visuals() -> void:
	var gate_width = 3.2
	var gate_height = 3.2

	# Translucent Energy Barrier
	barrier_mesh = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(gate_width, gate_height)
	barrier_mesh.mesh = quad
	barrier_mesh.position.y = gate_height * 0.5

	var mat_barrier = StandardMaterial3D.new()
	mat_barrier.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_barrier.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	barrier_mesh.material_override = mat_barrier
	add_child(barrier_mesh)

	# Solid Outer Frame
	frame_top = MeshInstance3D.new()
	var box_top = BoxMesh.new()
	box_top.size = Vector3(gate_width, 0.24, 0.24)
	frame_top.mesh = box_top
	frame_top.position.y = gate_height

	var frame_mat = StandardMaterial3D.new()
	frame_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	frame_top.material_override = frame_mat
	add_child(frame_top)

	frame_left = MeshInstance3D.new()
	var box_p = BoxMesh.new()
	box_p.size = Vector3(0.22, gate_height, 0.22)
	frame_left.mesh = box_p
	frame_left.position = Vector3(-gate_width * 0.5, gate_height * 0.5, 0)
	frame_left.material_override = frame_mat
	add_child(frame_left)

	frame_right = MeshInstance3D.new()
	frame_right.mesh = box_p
	frame_right.position = Vector3(gate_width * 0.5, gate_height * 0.5, 0)
	frame_right.material_override = frame_mat
	add_child(frame_right)

	# High-contrast background badge for text readability
	text_bg = MeshInstance3D.new()
	var bg_quad = QuadMesh.new()
	bg_quad.size = Vector2(2.2, 1.2)
	text_bg.mesh = bg_quad
	text_bg.position = Vector3(0, gate_height * 0.52, 0.04)
	var mat_tbg = StandardMaterial3D.new()
	mat_tbg.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_tbg.albedo_color = Color(0.04, 0.04, 0.06, 0.85)
	mat_tbg.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	text_bg.material_override = mat_tbg
	text_bg.visibility_range_end = MAX_LABEL_DIST
	text_bg.visibility_range_end_margin = 8.0
	text_bg.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(text_bg)

	# Large Bold Label
	label = Label3D.new()
	label.pixel_size = 0.018
	label.font_size = 80
	label.outline_size = 22
	label.outline_modulate = Color(0, 0, 0, 1)
	label.position = Vector3(0, gate_height * 0.52, 0.08)
	label.double_sided = true
	label.visibility_range_end = MAX_LABEL_DIST
	label.visibility_range_end_margin = 8.0
	label.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(label)

	_update_display()

func _update_display() -> void:
	if not label:
		return

	var op_text = ""
	var main_color: Color = Color(0.1, 0.7, 1.0)

	match operation:
		OperationType.ADD:
			op_text = "+" + str(value)
			main_color = Color(0.15, 0.75, 1.0) # Bright Blue
		OperationType.MULTIPLY:
			op_text = "×" + str(value)
			main_color = Color(0.1, 0.95, 0.4) # Emerald Green
		OperationType.SUBTRACT:
			op_text = "−" + str(value)
			main_color = Color(1.0, 0.25, 0.25) # Crimson Red
		OperationType.DIVIDE:
			op_text = "÷" + str(value)
			main_color = Color(1.0, 0.55, 0.1) # Amber Orange

	label.text = op_text
	label.modulate = main_color

	if barrier_mesh and barrier_mesh.material_override:
		var b_mat: StandardMaterial3D = barrier_mesh.material_override
		b_mat.albedo_color = Color(main_color.r, main_color.g, main_color.b, 0.38)

	if frame_top and frame_top.material_override:
		var f_mat: StandardMaterial3D = frame_top.material_override
		f_mat.albedo_color = main_color

func _setup_trigger() -> void:
	area = Area3D.new()
	area.name = "GateTrigger"
	area.collision_layer = 0
	area.collision_mask = 1 # PlayerSquad layer
	area.monitoring = true
	area.monitorable = false

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(3.2, 3.5, 2.0)
	col.shape = box
	col.position.y = 1.75
	area.add_child(col)
	add_child(area)

	area.body_entered.connect(_on_body_entered)

	# Shootable hitbox for player bullets (increases gate value on hit, Real War mechanic)
	shootable_hitbox = Area3D.new()
	shootable_hitbox.name = "GateShootableHitbox"
	shootable_hitbox.collision_layer = 2 # Matches player bullet mask (layer 2)
	shootable_hitbox.collision_mask = 0
	shootable_hitbox.monitoring = false
	shootable_hitbox.monitorable = true

	var s_col = CollisionShape3D.new()
	var s_box = BoxShape3D.new()
	s_box.size = Vector3(3.2, 3.2, 0.4)
	s_col.shape = s_box
	s_col.position.y = 1.6
	shootable_hitbox.add_child(s_col)
	add_child(shootable_hitbox)

func take_damage(amount: float) -> void:
	on_bullet_hit(amount)

func on_bullet_hit(_damage: float = 1.0, ignore_rate_limit: bool = false) -> void:
	if applied:
		return

	# Rate limit gate hits (Real War token bucket prevents large squads from overflowing gate)
	if not ignore_rate_limit:
		var cur_time = Time.get_ticks_msec() * 0.001
		if cur_time - last_bullet_hit_time < MIN_HIT_INTERVAL:
			return
		last_bullet_hit_time = cur_time

	# Deliberate gate tuning: upgrades require intentional focus, negative gates don't become free exploits
	# Maximum delta from shooting is +2 (ensures safe lane never outscales or trivializes risky lane)
	match operation:
		OperationType.ADD:
			add_bullet_hits += 1
			var hits_needed = 1 if ignore_rate_limit else 2
			if add_bullet_hits >= hits_needed:
				add_bullet_hits = 0
				if value < initial_value + 2 and value < MAX_GATE_VALUE_ADD:
					value += 1
		OperationType.SUBTRACT:
			subtract_bullet_hits += 1
			var hits_needed = 1 if ignore_rate_limit else 2
			if subtract_bullet_hits >= hits_needed:
				subtract_bullet_hits = 0
				# Soften penalty down to -1, but prevent automatic conversion to positive exploit
				if value > 1:
					value -= 1
		OperationType.MULTIPLY:
			multiplier_bullet_hits += 1
			var hits_needed = 2 if ignore_rate_limit else 6
			if multiplier_bullet_hits >= hits_needed:
				multiplier_bullet_hits = 0
				if value < initial_value + 1 and value < MAX_GATE_VALUE_MULT:
					value += 1
		OperationType.DIVIDE:
			multiplier_bullet_hits += 1
			var hits_needed = 2 if ignore_rate_limit else 6
			if multiplier_bullet_hits >= hits_needed:
				multiplier_bullet_hits = 0
				if value > 2:
					value -= 1

	_update_display()
	_punch_text()

func _punch_text() -> void:
	if not is_instance_valid(label):
		return
	if punch_tween and punch_tween.is_valid():
		punch_tween.kill()

	label.scale = Vector3(1.24, 1.24, 1.24)
	punch_tween = create_tween()
	punch_tween.tween_property(label, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if is_instance_valid(barrier_mesh) and barrier_mesh.material_override:
		var b_mat: StandardMaterial3D = barrier_mesh.material_override
		var prev_albedo = b_mat.albedo_color
		b_mat.albedo_color = Color(prev_albedo.r + 0.3, prev_albedo.g + 0.3, prev_albedo.b + 0.3, 0.7)
		punch_tween.parallel().tween_property(b_mat, "albedo_color", prev_albedo, 0.15)

func _physics_process(_delta: float) -> void:
	if applied:
		return

	# Find player squad if not tracked
	if not is_instance_valid(tracked_squad):
		var p_nodes = get_tree().get_nodes_in_group("player")
		if p_nodes.size() > 0:
			tracked_squad = p_nodes[0] as PlayerSquad

	# Distance culling for gate text & badge: eliminates distant horizon overlap
	if is_instance_valid(tracked_squad):
		var dist = abs(global_position.z - tracked_squad.global_position.z)
		var in_range = (dist <= MAX_LABEL_DIST)
		if is_instance_valid(label) and label.visible != in_range:
			label.visible = in_range
		if is_instance_valid(text_bg) and text_bg.visible != in_range:
			text_bg.visible = in_range

	# Secondary proximity check to ensure crossing is never missed at high speeds
	if is_instance_valid(tracked_squad) and not applied:
		if tracked_squad.is_defeated:
			return
		var sz = tracked_squad.global_position.z
		var gz = global_position.z
		# Crossing plane check
		if sz <= gz and sz >= gz - 2.8:
			var sx = tracked_squad.global_position.x
			var is_squad_on_left = (sx <= 0.0)
			if (is_left_gate and is_squad_on_left) or (not is_left_gate and not is_squad_on_left):
				apply_to_squad(tracked_squad)

func _on_body_entered(body: Node3D) -> void:
	if applied:
		return
	if body is PlayerSquad:
		apply_to_squad(body as PlayerSquad)

func apply_to_squad(squad: PlayerSquad) -> void:
	if applied:
		return
	if not is_instance_valid(squad) or squad.is_defeated:
		return

	# Check if level is still active
	var parent_lvl = _get_level_parent()
	if parent_lvl and not parent_lvl.is_game_active:
		return

	applied = true
	if is_instance_valid(area):
		area.set_deferred("monitoring", false)
	if is_instance_valid(shootable_hitbox):
		shootable_hitbox.set_deferred("monitorable", false)

	# Deactivate and fade partner gate
	if is_instance_valid(partner_gate) and not partner_gate.applied:
		partner_gate.applied = true
		partner_gate._fade_and_remove()

	match operation:
		OperationType.ADD:
			squad.add_members(value)
			_spawn_celebration_ring(global_position, Color(0.2, 0.85, 1.0))
			squad.camera_shake_requested.emit(0.12)
		OperationType.MULTIPLY:
			squad.multiply_members(value)
			_spawn_celebration_ring(global_position, Color(0.2, 1.0, 0.4))
			squad.camera_shake_requested.emit(0.15)
		OperationType.SUBTRACT:
			squad.remove_members(value)
		OperationType.DIVIDE:
			squad.divide_members(value)

	var lvl = _get_level_parent()
	if is_instance_valid(lvl) and is_instance_valid(lvl.hud):
		if operation == OperationType.ADD:
			lvl.hud.show_toast("+%d SQUAD!" % value)
		elif operation == OperationType.MULTIPLY:
			lvl.hud.show_toast("×%d MULTIPLY!" % value)

	_fade_and_remove()

func _spawn_celebration_ring(pos: Vector3, col: Color) -> void:
	var ring = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.9
	cyl.bottom_radius = 0.9
	cyl.height = 0.08
	cyl.radial_segments = 16
	ring.mesh = cyl
	ring.position = Vector3(pos.x, 0.35, pos.z)

	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(col.r, col.g, col.b, 0.95)
	ring.material_override = mat

	var parent = get_parent()
	if parent:
		parent.add_child(ring)
		var tw = ring.create_tween().set_parallel(true)
		tw.tween_property(ring, "scale", Vector3(3.8, 1.0, 3.8), 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.28)
		tw.chain().tween_callback(func(): ring.queue_free())

func _get_level_parent() -> LevelBase:
	var cur: Node = get_parent()
	while cur:
		if cur is LevelBase:
			return cur as LevelBase
		cur = cur.get_parent()
	return null

func _fade_and_remove() -> void:
	if is_instance_valid(area):
		area.set_deferred("monitoring", false)
	if is_instance_valid(shootable_hitbox):
		shootable_hitbox.set_deferred("monitorable", false)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.15, 0.05, 1.15), 0.2).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "position:y", position.y - 0.8, 0.2)
	tween.finished.connect(func(): queue_free())
