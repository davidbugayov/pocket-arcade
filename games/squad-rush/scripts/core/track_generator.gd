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
	plane.size = Vector2(240.0, track_length + 300.0)
	water.mesh = plane
	water.position = Vector3(0, -3.2, -track_length * 0.5)

	var mat_water = StandardMaterial3D.new()
	mat_water.albedo_color = Color(0.09, 0.38, 0.66) # Vibrant low-poly coastal ocean
	mat_water.metallic = 0.18
	mat_water.roughness = 0.20
	water.material_override = mat_water
	add_child(water)

func _build_bridge_deck() -> void:
	# Main Deck Slab
	var deck = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(bridge_width, 0.85, track_length + 40.0)
	deck.mesh = box
	deck.position = Vector3(0, -0.42, -track_length * 0.5)

	var mat_deck = StandardMaterial3D.new()
	# Matte slate / asphalt gray (eliminates glare / overexposure)
	mat_deck.albedo_color = Color(0.26, 0.28, 0.32)
	mat_deck.roughness = 0.88
	deck.material_override = mat_deck
	add_child(deck)

	# Center Double Yellow Dashed Lines
	var num_dashes = int(track_length / 6.0)
	var mat_dash = StandardMaterial3D.new()
	mat_dash.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_dash.albedo_color = Color(1.0, 0.82, 0.12) # Bold highway yellow

	for i in range(num_dashes):
		for side in [-0.18, 0.18]:
			var dash = MeshInstance3D.new()
			var d_box = BoxMesh.new()
			d_box.size = Vector3(0.14, 0.02, 3.2)
			dash.mesh = d_box
			dash.position = Vector3(side, 0.015, -i * 6.0)
			dash.material_override = mat_dash
			add_child(dash)

	# Outer Lane Solid White Stripes
	var mat_white_line = StandardMaterial3D.new()
	mat_white_line.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_white_line.albedo_color = Color(0.92, 0.94, 0.98)

	for side in [-1, 1]:
		var line = MeshInstance3D.new()
		var l_box = BoxMesh.new()
		l_box.size = Vector3(0.18, 0.02, track_length + 40.0)
		line.mesh = l_box
		line.position = Vector3(side * (bridge_width * 0.5 - 0.55), 0.015, -track_length * 0.5)
		line.material_override = mat_white_line
		add_child(line)

func _build_railings() -> void:
	var mat_curb = StandardMaterial3D.new()
	mat_curb.albedo_color = Color(0.55, 0.58, 0.62)
	mat_curb.roughness = 0.85

	var mat_rail = StandardMaterial3D.new()
	mat_rail.albedo_color = Color(0.88, 0.90, 0.94)
	mat_rail.metallic = 0.6
	mat_rail.roughness = 0.35

	for side in [-1, 1]:
		# Concrete Curb Base
		var curb = MeshInstance3D.new()
		var c_box = BoxMesh.new()
		c_box.size = Vector3(0.40, 0.32, track_length + 40.0)
		curb.mesh = c_box
		curb.position = Vector3(side * (bridge_width * 0.5 - 0.20), 0.16, -track_length * 0.5)
		curb.material_override = mat_curb
		add_child(curb)

		# Steel Guard Rail Beam
		var rail = MeshInstance3D.new()
		var r_box = BoxMesh.new()
		r_box.size = Vector3(0.20, 0.30, track_length + 40.0)
		rail.mesh = r_box
		rail.position = Vector3(side * (bridge_width * 0.5 - 0.22), 0.58, -track_length * 0.5)
		rail.material_override = mat_rail
		add_child(rail)

func _build_pillars() -> void:
	var mat_pillar = StandardMaterial3D.new()
	mat_pillar.albedo_color = Color(0.50, 0.53, 0.58)
	mat_pillar.roughness = 0.85

	var interval = 32.0
	var count = int(track_length / interval)
	for i in range(count + 1):
		var z_pos = -i * interval

		# Under-bridge crossbeam
		var beam = MeshInstance3D.new()
		var b_box = BoxMesh.new()
		b_box.size = Vector3(bridge_width + 0.6, 0.8, 1.4)
		beam.mesh = b_box
		beam.position = Vector3(0, -0.9, z_pos)
		beam.material_override = mat_pillar
		add_child(beam)

		# Twin Support Pier Columns
		for side in [-1, 1]:
			var col = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.55
			cyl.bottom_radius = 0.70
			cyl.height = 4.8
			col.mesh = cyl
			col.position = Vector3(side * (bridge_width * 0.40), -3.0, z_pos)
			col.material_override = mat_pillar
			add_child(col)
