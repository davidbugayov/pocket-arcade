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
@export var is_left_gate: bool = true
@export var partner_gate: MathGate = null

var applied: bool = false
var area: Area3D
var label: Label3D
var text_bg: MeshInstance3D
var barrier_mesh: MeshInstance3D
var frame_top: MeshInstance3D
var frame_left: MeshInstance3D
var frame_right: MeshInstance3D

var tracked_squad: PlayerSquad = null

func _ready() -> void:
	_build_visuals()
	_setup_trigger()

func setup(op: OperationType, val: int, left_side: bool) -> void:
	operation = op
	value = val
	is_left_gate = left_side
	_update_display()

func _build_visuals() -> void:
	var gate_width = 3.9
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
	add_child(text_bg)
	
	# Large Bold Label
	label = Label3D.new()
	label.pixel_size = 0.018
	label.font_size = 80
	label.outline_size = 22
	label.outline_modulate = Color(0, 0, 0, 1)
	label.position = Vector3(0, gate_height * 0.52, 0.08)
	label.double_sided = true
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
	box.size = Vector3(3.9, 3.5, 2.0)
	col.shape = box
	col.position.y = 1.75
	area.add_child(col)
	add_child(area)
	
	area.body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	if applied:
		return
	
	# Find player squad if not tracked
	if not is_instance_valid(tracked_squad):
		var p_nodes = get_tree().get_nodes_in_group("player")
		if p_nodes.size() > 0:
			tracked_squad = p_nodes[0] as PlayerSquad
	
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
	
	# Deactivate and fade partner gate
	if is_instance_valid(partner_gate) and not partner_gate.applied:
		partner_gate.applied = true
		partner_gate._fade_and_remove()
	
	match operation:
		OperationType.ADD:
			squad.add_members(value)
		OperationType.MULTIPLY:
			squad.multiply_members(value)
		OperationType.SUBTRACT:
			squad.remove_members(value)
		OperationType.DIVIDE:
			squad.divide_members(value)
	
	_fade_and_remove()

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
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.15, 0.05, 1.15), 0.2).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "position:y", position.y - 0.8, 0.2)
	tween.finished.connect(func(): queue_free())
