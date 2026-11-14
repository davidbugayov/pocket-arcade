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
	mat_water.albedo_color = Color(0.12, 0.45, 0.78)
	mat_water.metallic = 0.2
	mat_water.roughness = 0.15
	water.material_override = mat_water
	add_child(water)

func _build_bridge_deck() -> void:
	var deck = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(bridge_width, 0.8, track_length + 40.0)
	deck.mesh = box
	deck.position = Vector3(0, -0.4, -track_length * 0.5)
	
	var mat_deck = StandardMaterial3D.new()
	mat_deck.albedo_color = Color(0.85, 0.87, 0.9) # Light concrete
	mat_deck.roughness = 0.8
	deck.material_override = mat_deck
	add_child(deck)
	
	# Center dashed line markings
	var num_dashes = int(track_length / 6.0)
	for i in range(num_dashes):
		var dash = MeshInstance3D.new()
		var d_box = BoxMesh.new()
		d_box.size = Vector3(0.25, 0.02, 3.0)
		dash.mesh = d_box
		dash.position = Vector3(0, 0.01, -i * 6.0)
		
		var mat_dash = StandardMaterial3D.new()
		mat_dash.albedo_color = Color(1.0, 0.85, 0.2) # Yellow lane marker
		dash.material_override = mat_dash
		add_child(dash)

func _build_railings() -> void:
	var mat_rail = StandardMaterial3D.new()
	mat_rail.albedo_color = Color(0.95, 0.95, 0.98) # White clean railing
	mat_rail.metallic = 0.3
	
	for side in [-1, 1]:
		var rail = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.3, 0.8, track_length + 40.0)
		rail.mesh = box
		rail.position = Vector3(side * (bridge_width * 0.5 - 0.15), 0.4, -track_length * 0.5)
		rail.material_override = mat_rail
		add_child(rail)

func _build_pillars() -> void:
	var mat_pillar = StandardMaterial3D.new()
	mat_pillar.albedo_color = Color(0.65, 0.68, 0.72)
	
	var interval = 35.0
	var count = int(track_length / interval)
	for i in range(count + 1):
		var z_pos = -i * interval
		for side in [-1, 1]:
			var post = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.3
			cyl.bottom_radius = 0.4
			cyl.height = 4.5
			post.mesh = cyl
			post.position = Vector3(side * (bridge_width * 0.5 + 0.3), 1.8, z_pos)
			post.material_override = mat_pillar
			add_child(post)

