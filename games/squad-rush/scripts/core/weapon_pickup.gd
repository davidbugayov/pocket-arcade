extends Area3D

class_name WeaponPickup

@export var weapon_id_to_grant: int = 1 # 1 = Shotgun, 2 = Minigun
@export var pickup_name: String = "COMBAT SHOTGUN"

var is_collected: bool = false
var mesh_root: Node3D
var weapon_display_node: Node3D
var label: Label3D
var bg_badge: MeshInstance3D
var anim_time: float = 0.0

signal weapon_collected(w_id: int, w_name: String)

static var weapon_scenes = {
	0: load("res://assets/models/rifle.glb"),
	1: load("res://assets/models/scattergun.glb"),
	2: load("res://assets/models/rotary_cannon.glb")
}

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 # PlayerSquad layer
	monitoring = true
	monitorable = false

	_build_visuals()
	body_entered.connect(_on_body_entered)

func setup(w_id: int, w_name: String = "") -> void:
	weapon_id_to_grant = w_id
	if w_name != "":
		pickup_name = w_name
	else:
		var wdata = GameManager.get_weapon_data(weapon_id_to_grant)
		pickup_name = wdata.get("name", "WEAPON UPGRADE").to_upper()

	if label:
		label.text = pickup_name
	_update_weapon_model()

func _build_visuals() -> void:
	mesh_root = Node3D.new()
	add_child(mesh_root)

	# Pedestal Base
	var base = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.8
	cyl.bottom_radius = 0.95
	cyl.height = 0.25
	base.mesh = cyl
	base.position.y = 0.12
	var mat_b = StandardMaterial3D.new()
	mat_b.albedo_color = Color(0.18, 0.20, 0.24)
	mat_b.metallic = 0.8
	base.material_override = mat_b
	mesh_root.add_child(base)

	# Glowing Ring / Halo
	var halo = MeshInstance3D.new()
	var h_cyl = CylinderMesh.new()
	h_cyl.top_radius = 1.0
	h_cyl.bottom_radius = 1.0
	h_cyl.height = 0.06
	halo.mesh = h_cyl
	halo.position.y = 0.22
	var mat_h = StandardMaterial3D.new()
	mat_h.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_h.albedo_color = Color(0.2, 0.9, 1.0, 0.8)
	mat_h.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo.material_override = mat_h
	mesh_root.add_child(halo)

	# Floating weapon model root
	weapon_display_node = Node3D.new()
	weapon_display_node.position.y = 1.0
	mesh_root.add_child(weapon_display_node)
	_update_weapon_model()

	# Collision Shape
	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(2.4, 2.0, 1.6)
	col.shape = box_shape
	col.position.y = 1.0
	add_child(col)

	# Floating Badge Background
	bg_badge = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(2.6, 0.6)
	bg_badge.mesh = quad
	bg_badge.position = Vector3(0, 2.05, 0)
	var mat_bg = StandardMaterial3D.new()
	mat_bg.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_bg.albedo_color = Color(0.04, 0.18, 0.38, 0.88)
	mat_bg.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_bg.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bg_badge.material_override = mat_bg
	bg_badge.visibility_range_end = 40.0
	bg_badge.visibility_range_end_margin = 8.0
	bg_badge.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(bg_badge)

	# Text Label
	label = Label3D.new()
	label.pixel_size = 0.012
	label.font_size = 44
	label.outline_size = 14
	label.outline_modulate = Color(0, 0, 0, 1)
	label.modulate = Color(0.2, 0.9, 1.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 2.05, 0.02)
	label.text = pickup_name
	label.visibility_range_end = 40.0
	label.visibility_range_end_margin = 8.0
	label.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(label)

func _update_weapon_model() -> void:
	if not weapon_display_node:
		return
	for c in weapon_display_node.get_children():
		c.queue_free()

	var scene: PackedScene = weapon_scenes.get(weapon_id_to_grant, weapon_scenes[1])
	if scene:
		var w = scene.instantiate()
		w.scale = Vector3(1.1, 1.1, 1.1)
		weapon_display_node.add_child(w)

func _physics_process(delta: float) -> void:
	if is_collected:
		return

	# Distance culling for weapon name badge: avoids horizon clutter
	var p_nodes = get_tree().get_nodes_in_group("player")
	if p_nodes.size() > 0 and is_instance_valid(p_nodes[0]):
		var dist = abs(global_position.z - p_nodes[0].global_position.z)
		var show_badge = (dist <= 40.0)
		if is_instance_valid(label) and label.visible != show_badge:
			label.visible = show_badge
		if is_instance_valid(bg_badge) and bg_badge.visible != show_badge:
			bg_badge.visible = show_badge

	anim_time += delta * 2.8
	if weapon_display_node:
		weapon_display_node.position.y = 1.0 + sin(anim_time) * 0.12
		weapon_display_node.rotation_degrees.y += 65.0 * delta

func _on_body_entered(body: Node3D) -> void:
	if is_collected:
		return

	if body is PlayerSquad:
		is_collected = true
		SoundManager.play("weapon_upgrade")
		GameManager.select_run_weapon(weapon_id_to_grant)

		weapon_collected.emit(weapon_id_to_grant, pickup_name)

		set_deferred("monitoring", false)

		var tw = create_tween().set_parallel(true)
		tw.tween_property(mesh_root, "scale", Vector3(1.8, 1.8, 1.8), 0.18).set_trans(Tween.TRANS_BACK)
		tw.tween_property(mesh_root, "position:y", 2.5, 0.22)
		tw.tween_property(label, "scale", Vector3(0.01, 0.01, 0.01), 0.2)
		tw.tween_property(bg_badge, "scale", Vector3(0.01, 0.01, 0.01), 0.2)
		tw.chain().tween_callback(func(): queue_free())
