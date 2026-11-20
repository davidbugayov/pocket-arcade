extends Node3D

class_name MenuDockScene

# 3D Dock scene before deployment (pre-mission loading platform)
# Features:
# - Squad of 2-3 combat androids on the embarkation platform
# - Gentle idle animation (breathing bob and weapon ready stance)
# - Directional key sunlight and industrial maritime atmosphere
# - Dynamic moving security searchlight sweeping across the dock floor

var camera: Camera3D
var searchlight: SpotLight3D
var sun: DirectionalLight3D

var lead_soldier: StylizedSoldier
var left_soldier: StylizedSoldier
var right_soldier: StylizedSoldier

var anim_time: float = 0.0
# Planted firmly on the dock deck (Y = 0.0)
var lead_base_pos: Vector3 = Vector3(0, 0.0, 0.25)
var left_base_pos: Vector3 = Vector3(-0.95, 0.0, -0.45)
var right_base_pos: Vector3 = Vector3(0.95, 0.0, -0.45)

func _ready() -> void:
	_setup_environment()
	_setup_dock_geometry()
	_setup_lighting()
	_setup_camera()
	_setup_android_squad()

	if GameManager.has_signal("upgrades_changed"):
		GameManager.upgrades_changed.connect(_on_upgrades_or_weapon_changed)

func _setup_environment() -> void:
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	# Maritime industrial naval dock atmosphere
	env.background_color = Color(0.08, 0.13, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.44, 0.62)
	env.ambient_light_energy = 0.65
	env.fog_enabled = true
	env.fog_light_color = Color(0.12, 0.18, 0.28)
	env.fog_density = 0.006
	world_env.environment = env
	add_child(world_env)

func _setup_lighting() -> void:
	# 1. Warm directional sun key light
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	sun.light_color = Color(1.0, 0.98, 0.92)
	sun.light_energy = 1.30
	sun.shadow_enabled = true
	add_child(sun)

	# 2. Moving security searchlight sweeping across the platform
	searchlight = SpotLight3D.new()
	searchlight.position = Vector3(0, 6.5, -0.5)
	searchlight.rotation_degrees = Vector3(-45, 0, 0)
	searchlight.light_color = Color(0.75, 0.92, 1.0) # Intense cyan-white beam
	searchlight.light_energy = 3.5
	searchlight.spot_range = 16.0
	searchlight.spot_angle = 32.0
	searchlight.spot_attenuation = 0.7
	searchlight.shadow_enabled = false
	add_child(searchlight)

	# 3. Soft amber dock rim light from side
	var rim = OmniLight3D.new()
	rim.position = Vector3(-3.5, 1.8, 1.0)
	rim.light_color = Color(1.0, 0.70, 0.25)
	rim.light_energy = 1.2
	rim.omni_range = 8.0
	add_child(rim)

func _setup_camera() -> void:
	camera = Camera3D.new()
	camera.name = "DockCamera"
	camera.fov = 52.0
	# Positioned back to comfortably frame the 3-android squad on portrait screen
	camera.position = Vector3(0, 2.05, 5.85)
	camera.rotation_degrees = Vector3(-13.5, 0, 0)
	add_child(camera)

func _setup_dock_geometry() -> void:
	# 1. Heavy reinforced concrete dock slab
	var dock_slab = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(10.0, 0.60, 9.0)
	dock_slab.mesh = box
	dock_slab.position = Vector3(0, -0.30, 0)

	var mat_dock = StandardMaterial3D.new()
	mat_dock.albedo_color = Color(0.20, 0.22, 0.26) # Dark slate industrial concrete
	mat_dock.roughness = 0.85
	dock_slab.material_override = mat_dock
	add_child(dock_slab)

	# 2. Safety yellow/black hazard border along front edge of platform
	var mat_yellow = StandardMaterial3D.new()
	mat_yellow.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_yellow.albedo_color = Color(0.98, 0.82, 0.10)

	var mat_black = StandardMaterial3D.new()
	mat_black.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_black.albedo_color = Color(0.12, 0.12, 0.14)

	var num_hazard_stripes = 24
	for i in range(num_hazard_stripes):
		var stripe = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(0.18, 0.015, 0.22)
		stripe.mesh = s_box
		stripe.position = Vector3(-3.2 + i * 0.28, 0.01, 1.85)
		stripe.rotation_degrees = Vector3(0, 35, 0)
		stripe.material_override = mat_yellow if (i % 2 == 0) else mat_black
		add_child(stripe)

	# 3. Mooring bollards on outer edges
	var cyl_bollard = CylinderMesh.new()
	cyl_bollard.top_radius = 0.14
	cyl_bollard.bottom_radius = 0.12
	cyl_bollard.height = 0.45
	cyl_bollard.radial_segments = 8

	var mat_iron = StandardMaterial3D.new()
	mat_iron.albedo_color = Color(0.14, 0.15, 0.18)
	mat_iron.metallic = 0.8
	mat_iron.roughness = 0.4

	for side in [-1.85, 1.85]:
		for z_pos in [1.2, -0.4, -1.8]:
			var bollard = MeshInstance3D.new()
			bollard.mesh = cyl_bollard
			bollard.material_override = mat_iron
			bollard.position = Vector3(side, 0.22, z_pos)
			add_child(bollard)

	# 4. Background industrial bulkhead wall & pillars
	var mat_wall = StandardMaterial3D.new()
	mat_wall.albedo_color = Color(0.13, 0.16, 0.20)
	mat_wall.roughness = 0.88

	var wall = MeshInstance3D.new()
	var wall_box = BoxMesh.new()
	wall_box.size = Vector3(12.0, 6.0, 0.5)
	wall.mesh = wall_box
	wall.position = Vector3(0, 2.5, -3.2)
	wall.material_override = mat_wall
	add_child(wall)

	# Reinforced structural vertical pillars
	var mat_pillar = StandardMaterial3D.new()
	mat_pillar.albedo_color = Color(0.18, 0.22, 0.28)
	mat_pillar.metallic = 0.4
	mat_pillar.roughness = 0.6
	var p_box = BoxMesh.new()
	p_box.size = Vector3(0.45, 6.0, 0.45)
	for px in [-2.4, -0.8, 0.8, 2.4]:
		var p_mesh = MeshInstance3D.new()
		p_mesh.mesh = p_box
		p_mesh.material_override = mat_pillar
		p_mesh.position = Vector3(px, 2.5, -3.0)
		add_child(p_mesh)

	# Heavy steel gantry truss beam overhead with hazard stripes
	var gantry = MeshInstance3D.new()
	var g_box = BoxMesh.new()
	g_box.size = Vector3(8.0, 0.40, 0.40)
	gantry.mesh = g_box
	gantry.position = Vector3(0, 3.2, -2.4)
	var mat_gantry = StandardMaterial3D.new()
	mat_gantry.albedo_color = Color(0.92, 0.48, 0.10) # Industrial safety orange
	mat_gantry.metallic = 0.5
	mat_gantry.roughness = 0.45
	gantry.material_override = mat_gantry
	add_child(gantry)

	# Background stacked shipping cargo containers flanking the sides
	_build_dock_containers()

func _build_dock_containers() -> void:
	var mat_container_blue = StandardMaterial3D.new()
	mat_container_blue.albedo_color = Color(0.12, 0.32, 0.62)
	mat_container_blue.roughness = 0.7

	var mat_container_rust = StandardMaterial3D.new()
	mat_container_rust.albedo_color = Color(0.72, 0.22, 0.14)
	mat_container_rust.roughness = 0.75

	var c_mesh = BoxMesh.new()
	c_mesh.size = Vector3(1.6, 1.4, 3.2)

	# Left container stack (clearly visible in portrait frame!)
	var c1 = MeshInstance3D.new()
	c1.mesh = c_mesh
	c1.material_override = mat_container_blue
	c1.position = Vector3(-1.95, 0.70, -1.8)
	add_child(c1)

	var c2 = MeshInstance3D.new()
	c2.mesh = c_mesh
	c2.material_override = mat_container_rust
	c2.position = Vector3(-1.95, 2.10, -1.8)
	add_child(c2)

	# Right container stack (framing right flank!)
	var c3 = MeshInstance3D.new()
	c3.mesh = c_mesh
	c3.material_override = mat_container_rust
	c3.position = Vector3(1.95, 0.70, -1.8)
	add_child(c3)

	var c4 = MeshInstance3D.new()
	c4.mesh = c_mesh
	c4.material_override = mat_container_blue
	c4.position = Vector3(1.95, 2.10, -1.8)
	add_child(c4)

func _setup_android_squad() -> void:
	# Lead Android (Center, Hero stance, equips current selected weapon)
	lead_soldier = StylizedSoldier.new()
	lead_soldier.team = StylizedSoldier.Team.ALLY
	lead_soldier.variant = 0 # Sleek tactical rifleman
	lead_soldier.position = lead_base_pos
	lead_soldier.rotation_degrees = Vector3(0, 0, 0)
	add_child(lead_soldier)
	lead_soldier.equip_weapon(GameManager.current_weapon_index)

	# Left Flanker Android (Heavy Trooper silhouette with pauldrons)
	left_soldier = StylizedSoldier.new()
	left_soldier.team = StylizedSoldier.Team.ALLY
	left_soldier.variant = 1
	left_soldier.position = left_base_pos
	left_soldier.rotation_degrees = Vector3(0, 14, 0)
	add_child(left_soldier)
	left_soldier.equip_weapon(0) # Standard rifle

	# Right Flanker Android (Specialist silhouette with antenna)
	right_soldier = StylizedSoldier.new()
	right_soldier.team = StylizedSoldier.Team.ALLY
	right_soldier.variant = 2
	right_soldier.position = right_base_pos
	right_soldier.rotation_degrees = Vector3(0, -14, 0)
	add_child(right_soldier)
	right_soldier.equip_weapon(0) # Standard rifle

func _on_upgrades_or_weapon_changed() -> void:
	if is_instance_valid(lead_soldier):
		lead_soldier.equip_weapon(GameManager.current_weapon_index)

func _process(delta: float) -> void:
	anim_time += delta

	# 1. Moving Searchlight: Slow, realistic security sweep
	if is_instance_valid(searchlight):
		var sweep_y = sin(anim_time * 0.72) * 0.44
		var sweep_x = deg_to_rad(-48.0) + sin(anim_time * 0.48) * 0.08
		searchlight.rotation.y = sweep_y
		searchlight.rotation.x = sweep_x

	# 2. Gentle idle breathing animation for the squad
	if is_instance_valid(lead_soldier):
		var bob_lead = sin(anim_time * 2.2) * 0.024
		lead_soldier.position.y = lead_base_pos.y + bob_lead
		if lead_soldier.weapon_mount:
			lead_soldier.weapon_mount.position.y = -0.02 + sin(anim_time * 2.2) * 0.015

	if is_instance_valid(left_soldier):
		var bob_left = sin(anim_time * 2.2 + 1.2) * 0.020
		left_soldier.position.y = left_base_pos.y + bob_left
		if left_soldier.weapon_mount:
			left_soldier.weapon_mount.position.y = -0.02 + sin(anim_time * 2.2 + 1.2) * 0.012

	if is_instance_valid(right_soldier):
		var bob_right = sin(anim_time * 2.2 + 2.4) * 0.020
		right_soldier.position.y = right_base_pos.y + bob_right
		if right_soldier.weapon_mount:
			right_soldier.weapon_mount.position.y = -0.02 + sin(anim_time * 2.2 + 2.4) * 0.012
