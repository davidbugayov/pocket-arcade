extends Area3D

class_name WeaponPickup

@export var weapon_id_to_grant: int = 1 # 1 = Shotgun, 2 = Minigun
@export var pickup_name: String = "COMBAT SHOTGUN"

var is_collected: bool = false
var mesh_root: Node3D
var label: Label3D
var bg_badge: MeshInstance3D
var anim_time: float = 0.0

signal weapon_collected(w_id: int, w_name: String)

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

func _build_visuals() -> void:
	mesh_root = Node3D.new()
	add_child(mesh_root)
	
	# Floating Weapon Crate
	var crate = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.2, 0.7, 0.7)
	crate.mesh = box
	crate.position.y = 0.9
	
	var mat_c = StandardMaterial3D.new()
	mat_c.albedo_color = Color(0.1, 0.55, 0.9)
	mat_c.metallic = 0.8
	mat_c.roughness = 0.2
	mat_c.emission_enabled = true
	mat_c.emission = Color(0.15, 0.65, 1.0)
	mat_c.emission_energy_multiplier = 0.8
	crate.material_override = mat_c
	mesh_root.add_child(crate)
	
	# Glowing Ring / Halo
	var halo = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 0.08
	halo.mesh = cyl
	halo.position.y = 0.2
	var mat_h = StandardMaterial3D.new()
	mat_h.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_h.albedo_color = Color(1.0, 0.85, 0.2, 0.8)
	mat_h.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo.material_override = mat_h
	mesh_root.add_child(halo)
	
	# Text Background Badge
	bg_badge = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(2.4, 0.65)
	bg_badge.mesh = q
	bg_badge.position = Vector3(0, 1.85, 0)
	var mat_bg = StandardMaterial3D.new()
	mat_bg.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_bg.albedo_color = Color(0.05, 0.08, 0.15, 0.88)
	mat_bg.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_bg.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bg_badge.material_override = mat_bg
	add_child(bg_badge)
	
	# Floating Label
	label = Label3D.new()
	label.text = pickup_name
	label.pixel_size = 0.012
	label.font_size = 52
	label.outline_size = 16
	label.outline_modulate = Color(0, 0, 0, 1)
	label.modulate = Color(1.0, 0.88, 0.15)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.85, 0.02)
	add_child(label)
	
	# Trigger Collision
	var col = CollisionShape3D.new()
	var sph = SphereShape3D.new()
	sph.radius = 1.4
	col.shape = sph
	col.position.y = 0.9
	add_child(col)

func _process(delta: float) -> void:
	if is_collected:
		return
	anim_time += delta
	mesh_root.rotation_degrees.y += delta * 60.0
	mesh_root.position.y = sin(anim_time * 3.0) * 0.15

func _on_body_entered(body: Node3D) -> void:
	if is_collected:
		return
	if body is PlayerSquad:
		_collect(body as PlayerSquad)

func _collect(squad: PlayerSquad) -> void:
	if is_collected:
		return
	is_collected = true
	set_deferred("monitoring", false)
	
	# Grant weapon to GameManager
	if weapon_id_to_grant not in GameManager.unlocked_weapons:
		GameManager.unlocked_weapons.append(weapon_id_to_grant)
	GameManager.current_weapon_index = weapon_id_to_grant
	GameManager.save_game()
	GameManager.upgrades_changed.emit()
	
	SoundManager.play("gate_positive")
	squad.add_members(2) # Bonus 2 fighters with the new weapon!
	weapon_collected.emit(weapon_id_to_grant, pickup_name)
	
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3(1.4, 1.4, 1.4), 0.15)
	tw.parallel().tween_property(self, "position:y", position.y + 1.2, 0.25)
	tw.tween_property(self, "scale", Vector3.ZERO, 0.15)
	tw.finished.connect(func(): queue_free())
