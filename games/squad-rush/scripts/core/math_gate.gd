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
var barrier_mesh: MeshInstance3D

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
	
	var top_bar = MeshInstance3D.new()
	var box_top = BoxMesh.new()
	box_top.size = Vector3(gate_width, 0.22, 0.22)
	top_bar.mesh = box_top
	top_bar.position.y = gate_height
	
	var frame_mat = StandardMaterial3D.new()
	frame_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	top_bar.material_override = frame_mat
	add_child(top_bar)
	
	for side in [-1, 1]:
		var pillar = MeshInstance3D.new()
		var box_p = BoxMesh.new()
		box_p.size = Vector3(0.2, gate_height, 0.2)
		pillar.mesh = box_p
		pillar.position = Vector3(side * (gate_width * 0.5), gate_height * 0.5, 0)
		pillar.material_override = frame_mat
		add_child(pillar)
	
	label = Label3D.new()
	label.pixel_size = 0.016
	label.font_size = 72
	label.outline_size = 20
	label.outline_modulate = Color(0, 0, 0, 1)
	label.position = Vector3(0, gate_height * 0.52, 0.08)
	label.double_sided = true
	add_child(label)
	
	_update_display()

func _update_display() -> void:
	if not label:
		return
	
	var op_text = ""
	var is_positive = false
	
	match operation:
		OperationType.ADD:
			op_text = "+" + str(value)
			is_positive = true
		OperationType.MULTIPLY:
			op_text = "×" + str(value)
			is_positive = true
		OperationType.SUBTRACT:
			op_text = "−" + str(value)
			is_positive = false
		OperationType.DIVIDE:
			op_text = "÷" + str(value)
			is_positive = false
	
	label.text = op_text
	
	var color = Color(0.1, 0.65, 1.0) if is_positive else Color(1.0, 0.2, 0.2)
	if operation == OperationType.MULTIPLY:
		color = Color(0.1, 0.95, 0.4)
	
	label.modulate = Color.WHITE
	
	if barrier_mesh and barrier_mesh.material_override:
		var b_mat: StandardMaterial3D = barrier_mesh.material_override
		b_mat.albedo_color = Color(color.r, color.g, color.b, 0.42)

func _setup_trigger() -> void:
	area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	area.monitorable = false
	
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(3.9, 3.5, 1.8)
	col.shape = box
	col.position.y = 1.75
	area.add_child(col)
	add_child(area)
	
	area.body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	if applied:
		return
	
	if not is_instance_valid(tracked_squad):
		var p_nodes = get_tree().get_nodes_in_group("player")
		if p_nodes.size() > 0:
			tracked_squad = p_nodes[0] as PlayerSquad
		else:
			var parent = get_parent()
			if parent and parent.get_parent() is LevelBase:
				tracked_squad = (parent.get_parent() as LevelBase).player_squad
	
	if is_instance_valid(tracked_squad) and not applied:
		var sz = tracked_squad.global_position.z
		var gz = global_position.z
		if sz <= gz and sz >= gz - 2.5:
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
	applied = true
	
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

func _fade_and_remove() -> void:
	if area:
		area.set_deferred("monitoring", false)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.15, 0.05, 1.15), 0.2).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "position:y", position.y - 0.8, 0.2)
	tween.finished.connect(func(): queue_free())
