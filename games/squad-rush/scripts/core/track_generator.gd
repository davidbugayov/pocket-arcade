extends Node3D

class_name TrackGenerator

@export var track_length: float = 300.0
@export var bridge_width: float = 8.6

func generate_track(length: float) -> void:
	track_length = length
	_build_water()
	_build_bridge_deck()
	_build_railings()
	_build_pillars()

func _build_water() -> void:
	var water = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(160.0, track_length + 200.0)
	water.mesh = plane
	water.position = Vector3(0, -3.5, -track_length * 0.5)
	
	var mat_water = StandardMaterial3D.new()
	mat_water.albedo_color = Color(0.10, 0.42, 0.72) # Rich vibrant ocean blue
	mat_water.metallic = 0.15
	mat_water.roughness = 0.25
	water.material_override = mat_water
	add_child(water)

func _build_bridge_deck() -> void:
	var deck = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(bridge_width, 0.8, track_length + 40.0)
	deck.mesh = box
	deck.position = Vector3(0, -0.4, -track_length * 0.5)
	
	var mat_deck = StandardMaterial3D.new()
	# Pleasant matte asphalt/slate gray - eliminates blown-out overexposure
	mat_deck.albedo_color = Color(0.46, 0.49, 0.53)
	mat_deck.roughness = 0.90
	deck.material_override = mat_deck
	add_child(deck)
	
	# Center dashed line markings (crisp yellow)
	var num_dashes = int(track_length / 6.0)
	var mat_dash = StandardMaterial3D.new()
	mat_dash.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_dash.albedo_color = Color(1.0, 0.85, 0.15) # Bold yellow road paint
	
	for i in range(num_dashes):
		var dash = MeshInstance3D.new()
		var d_box = BoxMesh.new()
		d_box.size = Vector3(0.28, 0.02, 3.2)
		dash.mesh = d_box
		dash.position = Vector3(0, 0.01, -i * 6.0)
		dash.material_override = mat_dash
		add_child(dash)

func _build_railings() -> void:
	var mat_rail = StandardMaterial3D.new()
	mat_rail.albedo_color = Color(0.92, 0.93, 0.95) # Clean light border
	mat_rail.metallic = 0.2
	mat_rail.roughness = 0.4
	
	for side in [-1, 1]:
		var rail = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.35, 0.85, track_length + 40.0)
		rail.mesh = box
		rail.position = Vector3(side * (bridge_width * 0.5 - 0.18), 0.42, -track_length * 0.5)
		rail.material_override = mat_rail
		add_child(rail)

func _build_pillars() -> void:
	var mat_pillar = StandardMaterial3D.new()
	mat_pillar.albedo_color = Color(0.58, 0.60, 0.64)
	mat_pillar.roughness = 0.85
	
	var interval = 35.0
	var count = int(track_length / interval)
	for i in range(count + 1):
		var z_pos = -i * interval
		for side in [-1, 1]:
			var post = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.35
			cyl.bottom_radius = 0.45
			cyl.height = 4.5
			post.mesh = cyl
			post.position = Vector3(side * (bridge_width * 0.5 + 0.35), 1.8, z_pos)
			post.material_override = mat_pillar
			add_child(post)
