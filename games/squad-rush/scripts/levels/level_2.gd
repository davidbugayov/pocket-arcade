extends LevelBase

class_name Level2

func _init() -> void:
	level_number = 2
	level_length = 320.0
	boss_z_position = -275.0

func _setup_boss() -> void:
	boss = BossUnit.new()
	boss.position = Vector3(0, 0, boss_z_position)
	add_child(boss)
	# Heavy War Tank: 1400 HP, 220 coins, ~10-12s TTK with balanced squad
	boss.setup("Heavy War Tank", 1400.0, 220, BossUnit.BossType.TANK)
	boss.move_speed = 2.8
	boss.attack_interval = 2.2
	boss.boss_hp_changed.connect(func(cur, m): if hud and hud.has_method("update_boss_hp"): hud.update_boss_hp(cur, m))
	boss.boss_shot_fired.connect(_on_boss_shot_fired)
	boss.boss_defeated.connect(_on_boss_defeated)

func _build_level_layout() -> void:
	spawn_tutorial_text(-10.0, "ZONE 2: INDUSTRIAL CAUSEWAY")

	# =========================================================================
	# SECTION 1: НЕФТЕПЕРЕРАБАТЫВАЮЩАЯ ЭСТАКАДА (Refinery Causeway) [0 to -110m]
	# =========================================================================
	# 1. Opening Obstacle Gates & Median Divider
	spawn_obstacle(Vector3(-2.1, 0, -25.0), Obstacle.ObstacleType.TIRE_STACK, 25.0, 8)
	spawn_obstacle(Vector3(2.1, 0, -25.0), Obstacle.ObstacleType.TIRE_STACK, 25.0, 8)

	# 2. Gate 1: Safe Lane (+4) vs Risky Route (+8 guarded by Runner ambush!)
	# Center concrete median eliminates zero-steering autopilot
	spawn_obstacle(Vector3(0.0, 0, -55.0), Obstacle.ObstacleType.CONCRETE_BLOCK, 25.0, 8)
	spawn_gate_pair(-55.0, MathGate.OperationType.ADD, 4, MathGate.OperationType.ADD, 8)
	spawn_enemy(Vector3(2.0, 0, -45.0), 14.0, 6, true, EnemyUnit.EnemyType.RUNNER)
	spawn_enemy(Vector3(2.0, 0, -48.0), 14.0, 6, true, EnemyUnit.EnemyType.RUNNER)

	# 3. Encounter 1: Crossfire & Runner charge (-85.0 to -92.0)
	# Left: Fast Runner charges. Right: Shooter covers flank with telegraphed laser!
	spawn_enemy(Vector3(-1.8, 0, -86.0), 14.0, 6, true, EnemyUnit.EnemyType.RUNNER)
	spawn_enemy(Vector3(1.8, 0, -92.0), 22.0, 8, false, EnemyUnit.EnemyType.SHOOTER)

	# =========================================================================
	# SECTION 2: ЖЕЛЕЗНОДОРОЖНЫЙ СОРТИРОВОЧНЫЙ УЗЕЛ (Rail Yard) [-110 to -210m]
	# =========================================================================
	# 4. Allied Rescue Barrel (-110.0)
	# Shoot barrel open to rescue 2 allied riflemen into the squad!
	spawn_rescue_barrel(Vector3(-1.8, 0, -110.0), 2, 18.0)

	# 5. Gate 2: Multiplier vs Addition (-135.0)
	# Center divider hazard barrel
	spawn_obstacle(Vector3(0.0, 0, -135.0), Obstacle.ObstacleType.BARREL, 24.0, 8)
	# Left: x2 behind wooden ammo crate (HP 22.0). Right: Safe +6 in open lane
	spawn_obstacle(Vector3(-2.0, 0, -128.0), Obstacle.ObstacleType.CRATE, 22.0, 10)
	spawn_gate_pair(-135.0, MathGate.OperationType.MULTIPLY, 2, MathGate.OperationType.ADD, 6)

	# 6. In-Run Weapon Pickup: Plasma Minigun (-165.0)
	# Rapid-fire rotary cannon in right lane, guarded by a heavy Shielder!
	spawn_enemy(Vector3(2.0, 0, -158.0), 50.0, 16, false, EnemyUnit.EnemyType.SHIELDER)
	spawn_weapon_pickup(Vector3(2.0, 0, -165.0), 2, "PLASMA MINIGUN")

	# 7. Gate 3: High Reward vs Safe Route (-195.0)
	# Center divider
	spawn_obstacle(Vector3(0.0, 0, -195.0), Obstacle.ObstacleType.CONCRETE_BLOCK, 25.0, 8)
	# Left: Safe +8. Right: x2 guarded by 2 hazard barrels (HP 22.0)
	spawn_obstacle(Vector3(1.4, 0, -188.0), Obstacle.ObstacleType.BARREL, 22.0, 10)
	spawn_obstacle(Vector3(2.6, 0, -188.0), Obstacle.ObstacleType.BARREL, 22.0, 10)
	spawn_gate_pair(-195.0, MathGate.OperationType.ADD, 8, MathGate.OperationType.MULTIPLY, 2)

	# =========================================================================
	# SECTION 3: ТАНКОВЫЙ ПЛАЦДАРМ (Proving Grounds & Arena) [-210 to -320m]
	# =========================================================================
	# 8. Encounter 2: Bridge Defense Checkpoint (-225.0 to -232.0)
	# Heavy Shielder blocks center, flanked by Shooter left and Runner right!
	spawn_enemy(Vector3(0.0, 0, -225.0), 55.0, 18, false, EnemyUnit.EnemyType.SHIELDER)
	spawn_enemy(Vector3(-2.0, 0, -230.0), 22.0, 8, false, EnemyUnit.EnemyType.SHOOTER)
	spawn_enemy(Vector3(2.0, 0, -232.0), 14.0, 6, true, EnemyUnit.EnemyType.RUNNER)

	# 9. Gate 4: Final Gate before Heavy Tank (-255.0)
	# Center divider
	spawn_obstacle(Vector3(0.0, 0, -255.0), Obstacle.ObstacleType.CONCRETE_BLOCK, 25.0, 8)
	# Left: Safe +6. Right: +10 behind ammo crate (HP 20.0)
	spawn_obstacle(Vector3(2.0, 0, -248.0), Obstacle.ObstacleType.CRATE, 20.0, 10)
	spawn_gate_pair(-255.0, MathGate.OperationType.ADD, 6, MathGate.OperationType.ADD, 10)

	# =========================================================================
	# THEMATIC ENVIRONMENT ARCHITECTURE & ROADWAY MARKINGS
	# =========================================================================
	_build_section1_refinery_environment()
	_build_section2_railyard_environment()
	_build_section3_proving_grounds_environment()
	_build_roadside_decorations()

# -----------------------------------------------------------------------------
# Section 1 Environment: Нефтеперерабатывающая эстакада (Refinery Causeway)
# -----------------------------------------------------------------------------
func _build_section1_refinery_environment() -> void:
	# 1. Wide start platform (z = 8.0 to -16.0, width = 13.0m)
	var start_plat = MeshInstance3D.new()
	var sp_box = BoxMesh.new()
	sp_box.size = Vector3(13.0, 0.8, 24.0)
	start_plat.mesh = sp_box
	start_plat.position = Vector3(0, -0.4, -4.0)
	var mat_plat = StandardMaterial3D.new()
	mat_plat.albedo_color = Color(0.26, 0.28, 0.32)
	mat_plat.roughness = 0.85
	start_plat.material_override = mat_plat
	add_child(start_plat)

	# Start platform hazard edging
	var mat_warn_y = StandardMaterial3D.new()
	mat_warn_y.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_warn_y.albedo_color = Color(0.95, 0.78, 0.15)
	var mat_warn_k = StandardMaterial3D.new()
	mat_warn_k.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_warn_k.albedo_color = Color(0.12, 0.12, 0.14)

	for i in range(12):
		var stripe = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(0.95, 0.05, 0.35)
		stripe.mesh = s_box
		stripe.position = Vector3(-5.5 + i * 1.0, 0.03, 3.5)
		stripe.material_override = mat_warn_y if i % 2 == 0 else mat_warn_k
		add_child(stripe)

	# 2. Tall Distillation Fraction Columns along sides (x = ±6.5 to ±8.5m)
	var mat_tower = StandardMaterial3D.new()
	mat_tower.albedo_color = Color(0.65, 0.68, 0.72)
	mat_tower.metallic = 0.75
	mat_tower.roughness = 0.35

	var mat_red_cap = StandardMaterial3D.new()
	mat_red_cap.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_red_cap.albedo_color = Color(0.90, 0.20, 0.15)

	var tower_zs = [-22.0, -42.0, -72.0, -96.0]
	for z_pos in tower_zs:
		for side in [-1.0, 1.0]:
			var tower = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 1.1
			cyl.bottom_radius = 1.25
			cyl.height = 14.0
			tower.mesh = cyl
			tower.position = Vector3(side * 7.5, 6.0, z_pos)
			tower.material_override = mat_tower
			add_child(tower)

			# Red warning light cap at top
			var cap = MeshInstance3D.new()
			var cap_mesh = CylinderMesh.new()
			cap_mesh.top_radius = 0.3
			cap_mesh.bottom_radius = 0.3
			cap_mesh.height = 0.6
			cap.mesh = cap_mesh
			cap.position = Vector3(side * 7.5, 13.3, z_pos)
			cap.material_override = mat_red_cap
			add_child(cap)

	# 3. Spherical Gas Storage Tanks at x = ±8.5m
	var mat_sphere = StandardMaterial3D.new()
	mat_sphere.albedo_color = Color(0.85, 0.88, 0.90)
	mat_sphere.metallic = 0.5
	mat_sphere.roughness = 0.4

	for side in [-1.0, 1.0]:
		var sphere = MeshInstance3D.new()
		var s_mesh = SphereMesh.new()
		s_mesh.radius = 2.4
		s_mesh.height = 4.8
		sphere.mesh = s_mesh
		sphere.position = Vector3(side * 8.5, 2.5, -50.0)
		sphere.material_override = mat_sphere
		add_child(sphere)

	# 4. LANDMARK 1: Massive Refinery Pipeline Truss Bridge (z = -65.0m)
	# Spans directly across the road with twin vertical lattice towers and 4 pipes
	var mat_steel_truss = StandardMaterial3D.new()
	mat_steel_truss.albedo_color = Color(0.20, 0.35, 0.45)
	mat_steel_truss.metallic = 0.7
	mat_steel_truss.roughness = 0.4

	var mat_pipe_yellow = StandardMaterial3D.new()
	mat_pipe_yellow.albedo_color = Color(0.92, 0.70, 0.12)
	mat_pipe_yellow.roughness = 0.3

	var mat_pipe_teal = StandardMaterial3D.new()
	mat_pipe_teal.albedo_color = Color(0.15, 0.65, 0.70)
	mat_pipe_teal.roughness = 0.3

	for side in [-1.0, 1.0]:
		var leg = MeshInstance3D.new()
		var l_box = BoxMesh.new()
		l_box.size = Vector3(1.2, 9.5, 1.4)
		leg.mesh = l_box
		leg.position = Vector3(side * 5.2, 4.75, -65.0)
		leg.material_override = mat_steel_truss
		add_child(leg)

	# Horizontal overhead crossbeam
	var beam = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(11.6, 0.85, 1.5)
	beam.mesh = b_box
	beam.position = Vector3(0, 9.2, -65.0)
	beam.material_override = mat_steel_truss
	add_child(beam)

	# 4 Overhead industrial pipelines running through the gantry
	for p_idx in range(4):
		var pipe = MeshInstance3D.new()
		var p_cyl = CylinderMesh.new()
		p_cyl.top_radius = 0.28
		p_cyl.bottom_radius = 0.28
		p_cyl.height = 11.2
		pipe.mesh = p_cyl
		pipe.rotation_degrees = Vector3(0, 0, 90)
		pipe.position = Vector3(0, 9.8 + (p_idx % 2) * 0.7, -65.0 + (p_idx / 2) * 0.7 - 0.35)
		pipe.material_override = mat_pipe_yellow if p_idx % 2 == 0 else mat_pipe_teal
		add_child(pipe)

	# 5. Road Markings: Safe guidance chevrons leading to Gate 1 (+4) vs caution on (+8)
	var mat_guide_y = StandardMaterial3D.new()
	mat_guide_y.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_guide_y.albedo_color = Color(0.20, 0.85, 0.40)

	var mat_danger_r = StandardMaterial3D.new()
	mat_danger_r.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_danger_r.albedo_color = Color(0.95, 0.25, 0.20)

	for step in range(5):
		var z_m = -30.0 - step * 4.5
		# Safe lane guidance dashes (left)
		var dash = MeshInstance3D.new()
		var d_box = BoxMesh.new()
		d_box.size = Vector3(1.2, 0.03, 0.3)
		dash.mesh = d_box
		dash.position = Vector3(-1.9, 0.02, z_m)
		dash.material_override = mat_guide_y
		add_child(dash)

		# Risky lane danger crosshatches (right)
		var cross = MeshInstance3D.new()
		var c_box = BoxMesh.new()
		c_box.size = Vector3(1.3, 0.03, 0.25)
		cross.mesh = c_box
		cross.position = Vector3(1.9, 0.02, z_m)
		cross.rotation_degrees = Vector3(0, 25, 0)
		cross.material_override = mat_danger_r
		add_child(cross)

# -----------------------------------------------------------------------------
# Section 2 Environment: Железнодорожный узел (Rail Yard & Depot)
# -----------------------------------------------------------------------------
func _build_section2_railyard_environment() -> void:
	# 1. Parallel rail tracks on both sides (x = -6.2m and +6.2m, z = -110 to -210m)
	var mat_ballast = StandardMaterial3D.new()
	mat_ballast.albedo_color = Color(0.20, 0.20, 0.22)
	mat_ballast.roughness = 0.95

	var mat_rail = StandardMaterial3D.new()
	mat_rail.albedo_color = Color(0.70, 0.72, 0.75)
	mat_rail.metallic = 0.85
	mat_rail.roughness = 0.25

	for side in [-1.0, 1.0]:
		var ballast = MeshInstance3D.new()
		var b_box = BoxMesh.new()
		b_box.size = Vector3(2.6, 0.15, 100.0)
		ballast.mesh = b_box
		ballast.position = Vector3(side * 6.2, -0.05, -160.0)
		ballast.material_override = mat_ballast
		add_child(ballast)

		# Steel rails (pair)
		for r_offset in [-0.5, 0.5]:
			var rail = MeshInstance3D.new()
			var r_box = BoxMesh.new()
			r_box.size = Vector3(0.08, 0.12, 100.0)
			rail.mesh = r_box
			rail.position = Vector3(side * 6.2 + r_offset, 0.06, -160.0)
			rail.material_override = mat_rail
			add_child(rail)

	# 2. Freight Boxcars and Tankers parked along rail sidings
	var mat_boxcar_rust = StandardMaterial3D.new()
	mat_boxcar_rust.albedo_color = Color(0.55, 0.22, 0.15)
	mat_boxcar_rust.roughness = 0.85

	var mat_boxcar_green = StandardMaterial3D.new()
	mat_boxcar_green.albedo_color = Color(0.18, 0.38, 0.25)
	mat_boxcar_green.roughness = 0.8

	var train_configs = [
		{"side": -1.0, "z": -125.0, "type": "box", "mat": mat_boxcar_rust},
		{"side": 1.0, "z": -142.0, "type": "box", "mat": mat_boxcar_green},
		{"side": -1.0, "z": -175.0, "type": "tank", "mat": mat_boxcar_rust},
		{"side": 1.0, "z": -198.0, "type": "box", "mat": mat_boxcar_rust},
	]

	for cfg in train_configs:
		var wagon = MeshInstance3D.new()
		if cfg["type"] == "box":
			var w_box = BoxMesh.new()
			w_box.size = Vector3(2.2, 2.6, 9.5)
			wagon.mesh = w_box
			wagon.position = Vector3(cfg["side"] * 6.2, 1.45, cfg["z"])
		else:
			var w_cyl = CylinderMesh.new()
			w_cyl.top_radius = 1.15
			w_cyl.bottom_radius = 1.15
			w_cyl.height = 9.2
			wagon.mesh = w_cyl
			wagon.rotation_degrees = Vector3(90, 0, 0)
			wagon.position = Vector3(cfg["side"] * 6.2, 1.45, cfg["z"])
		wagon.material_override = cfg["mat"]
		add_child(wagon)

	# 3. LANDMARK 2: Overhead Railway Signal Gantry Truss (z = -165.0m)
	# Spanning above roadway and framing Plasma Minigun pickup!
	var mat_gantry_dark = StandardMaterial3D.new()
	mat_gantry_dark.albedo_color = Color(0.18, 0.22, 0.28)
	mat_gantry_dark.metallic = 0.6
	mat_gantry_dark.roughness = 0.5

	for side in [-1.0, 1.0]:
		var g_post = MeshInstance3D.new()
		var gp_box = BoxMesh.new()
		gp_box.size = Vector3(0.9, 8.5, 0.9)
		g_post.mesh = gp_box
		g_post.position = Vector3(side * 5.2, 4.25, -165.0)
		g_post.material_override = mat_gantry_dark
		add_child(g_post)

	var g_beam = MeshInstance3D.new()
	var gb_box = BoxMesh.new()
	gb_box.size = Vector3(11.3, 0.8, 1.1)
	g_beam.mesh = gb_box
	g_beam.position = Vector3(0, 8.1, -165.0)
	g_beam.material_override = mat_gantry_dark
	add_child(g_beam)

	# Signal lights (Green left, Amber right)
	var mat_sig_green = StandardMaterial3D.new()
	mat_sig_green.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_sig_green.albedo_color = Color(0.2, 1.0, 0.3)

	var mat_sig_amber = StandardMaterial3D.new()
	mat_sig_amber.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_sig_amber.albedo_color = Color(1.0, 0.65, 0.1)

	var sig_l = MeshInstance3D.new()
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 0.32
	s_mesh.height = 0.64
	sig_l.mesh = s_mesh
	sig_l.position = Vector3(-2.0, 7.5, -165.0)
	sig_l.material_override = mat_sig_green
	add_child(sig_l)

	var sig_r = MeshInstance3D.new()
	sig_r.mesh = s_mesh
	sig_r.position = Vector3(2.0, 7.5, -165.0)
	sig_r.material_override = mat_sig_amber
	add_child(sig_r)

	# 4. Road Markings: Railway crossing hazard diagonal stripes at z = -135 and -188
	var mat_caution_stripe = StandardMaterial3D.new()
	mat_caution_stripe.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_caution_stripe.albedo_color = Color(0.95, 0.65, 0.10)

	for z_mark in [-133.0, -186.0]:
		for s in range(4):
			var stripe = MeshInstance3D.new()
			var st_box = BoxMesh.new()
			st_box.size = Vector3(0.3, 0.02, 1.8)
			stripe.mesh = st_box
			stripe.position = Vector3(-1.8 + s * 1.2, 0.02, z_mark)
			stripe.rotation_degrees = Vector3(0, 45, 0)
			stripe.material_override = mat_caution_stripe
			add_child(stripe)

# -----------------------------------------------------------------------------
# Section 3 Environment: Танковый плацдарм (Proving Grounds & Heavy Tank)
# -----------------------------------------------------------------------------
func _build_section3_proving_grounds_environment() -> void:
	# 1. Anti-tank concrete tetrahedrons ("Dragon's Teeth") flanking highway (z = -215 to -310m)
	var mat_concrete_tooth = StandardMaterial3D.new()
	mat_concrete_tooth.albedo_color = Color(0.35, 0.35, 0.36)
	mat_concrete_tooth.roughness = 0.95

	for z_pos in range(-215, -315, -14):
		for side in [-1.0, 1.0]:
			var tooth = MeshInstance3D.new()
			var p_mesh = PrismMesh.new()
			p_mesh.size = Vector3(1.4, 1.6, 1.4)
			tooth.mesh = p_mesh
			tooth.position = Vector3(side * 5.5, 0.8, float(z_pos))
			tooth.material_override = mat_concrete_tooth
			add_child(tooth)

			# Second staggered row further out
			var tooth2 = MeshInstance3D.new()
			tooth2.mesh = p_mesh
			tooth2.position = Vector3(side * 7.2, 0.8, float(z_pos) - 7.0)
			tooth2.material_override = mat_concrete_tooth
			add_child(tooth2)

	# 2. Watchtowers with elevated searchlight housings at z = -235m and -295m
	var mat_tower_metal = StandardMaterial3D.new()
	mat_tower_metal.albedo_color = Color(0.15, 0.18, 0.22)
	mat_tower_metal.metallic = 0.8
	mat_tower_metal.roughness = 0.4

	var mat_spot_amber = StandardMaterial3D.new()
	mat_spot_amber.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_spot_amber.albedo_color = Color(1.0, 0.85, 0.40)

	for z_tw in [-235.0, -295.0]:
		for side in [-1.0, 1.0]:
			var tower = MeshInstance3D.new()
			var t_box = BoxMesh.new()
			t_box.size = Vector3(1.4, 8.0, 1.4)
			tower.mesh = t_box
			tower.position = Vector3(side * 7.5, 4.0, z_tw)
			tower.material_override = mat_tower_metal
			add_child(tower)

			# Cabin head
			var cab = MeshInstance3D.new()
			var c_box = BoxMesh.new()
			c_box.size = Vector3(2.2, 1.6, 2.2)
			cab.mesh = c_box
			cab.position = Vector3(side * 7.5, 8.8, z_tw)
			cab.material_override = mat_tower_metal
			add_child(cab)

			# Glowing spotlight facing downward onto corridor
			var spot = MeshInstance3D.new()
			var sp_mesh = SphereMesh.new()
			sp_mesh.radius = 0.4
			sp_mesh.height = 0.8
			spot.mesh = sp_mesh
			spot.position = Vector3(side * 6.6, 8.2, z_tw)
			spot.material_override = mat_spot_amber
			add_child(spot)

	# 3. LANDMARK 3: Colossal Armored Bastion Gate Arch at z = -270.0m
	# Towering reinforced bastion framing the Heavy War Tank boss at z = -275m!
	var mat_bastion_armor = StandardMaterial3D.new()
	mat_bastion_armor.albedo_color = Color(0.14, 0.16, 0.20)
	mat_bastion_armor.metallic = 0.75
	mat_bastion_armor.roughness = 0.45

	var mat_hazard_trim = StandardMaterial3D.new()
	mat_hazard_trim.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_hazard_trim.albedo_color = Color(0.95, 0.70, 0.10)

	for side in [-1.0, 1.0]:
		var p_main = MeshInstance3D.new()
		var pm_box = BoxMesh.new()
		pm_box.size = Vector3(2.2, 12.0, 2.8)
		p_main.mesh = pm_box
		p_main.position = Vector3(side * 5.4, 6.0, -270.0)
		p_main.material_override = mat_bastion_armor
		add_child(p_main)

		# Slanted armor plate on outer side
		var plate = MeshInstance3D.new()
		var pl_box = BoxMesh.new()
		pl_box.size = Vector3(1.2, 11.0, 3.2)
		plate.mesh = pl_box
		plate.position = Vector3(side * 6.6, 5.5, -270.0)
		plate.rotation_degrees = Vector3(0, 0, side * 15.0)
		plate.material_override = mat_bastion_armor
		add_child(plate)

	# Colossal overhead blast lintel beam
	var blast_lintel = MeshInstance3D.new()
	var bl_box = BoxMesh.new()
	bl_box.size = Vector3(12.8, 2.2, 3.2)
	blast_lintel.mesh = bl_box
	blast_lintel.position = Vector3(0, 12.0, -270.0)
	blast_lintel.material_override = mat_bastion_armor
	add_child(blast_lintel)

	# Lintel hazard chevron line
	var chevron_strip = MeshInstance3D.new()
	var cs_box = BoxMesh.new()
	cs_box.size = Vector3(10.5, 0.35, 0.1)
	chevron_strip.mesh = cs_box
	chevron_strip.position = Vector3(0, 11.2, -268.3)
	chevron_strip.material_override = mat_hazard_trim
	add_child(chevron_strip)

	# 4. Boss Arena Road Markings: Red firing danger sector vs cyan evasive strips
	var mat_danger_line = StandardMaterial3D.new()
	mat_danger_line.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_danger_line.albedo_color = Color(0.95, 0.15, 0.15)

	var mat_safe_strip = StandardMaterial3D.new()
	mat_safe_strip.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_safe_strip.albedo_color = Color(0.15, 0.85, 1.0)

	# Danger lines marking tank shell trajectory in center lane
	for step in range(8):
		var dl = MeshInstance3D.new()
		var dl_box = BoxMesh.new()
		dl_box.size = Vector3(0.2, 0.02, 3.0)
		dl.mesh = dl_box
		dl.position = Vector3(0.0, 0.03, -245.0 - step * 4.0)
		dl.material_override = mat_danger_line
		add_child(dl)

	# Flank safe evasion strips
	for step in range(6):
		var sf_l = MeshInstance3D.new()
		var sf_box = BoxMesh.new()
		sf_box.size = Vector3(0.25, 0.02, 2.2)
		sf_l.mesh = sf_box
		sf_l.position = Vector3(-2.8, 0.03, -250.0 - step * 5.0)
		sf_l.material_override = mat_safe_strip
		add_child(sf_l)

		var sf_r = MeshInstance3D.new()
		sf_r.mesh = sf_box
		sf_r.position = Vector3(2.8, 0.03, -250.0 - step * 5.0)
		sf_r.material_override = mat_safe_strip
		add_child(sf_r)

# -----------------------------------------------------------------------------
# Roadside Guardrails & Infrastructure
# -----------------------------------------------------------------------------
func _build_roadside_decorations() -> void:
	var mat_guard = StandardMaterial3D.new()
	mat_guard.albedo_color = Color(0.42, 0.45, 0.48)
	mat_guard.metallic = 0.8
	mat_guard.roughness = 0.35

	var mat_amber_reflector = StandardMaterial3D.new()
	mat_amber_reflector.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_amber_reflector.albedo_color = Color(1.0, 0.65, 0.15)

	# Segmented guardrails along full length (320m)
	for z_pos in range(0, -320, -10):
		for side in [-1.0, 1.0]:
			var rail = MeshInstance3D.new()
			var r_box = BoxMesh.new()
			r_box.size = Vector3(0.18, 0.5, 9.6)
			rail.mesh = r_box
			rail.position = Vector3(side * 3.65, 0.45, float(z_pos) - 5.0)
			rail.material_override = mat_guard
			add_child(rail)

			# Amber reflector node every 10m
			var refl = MeshInstance3D.new()
			var ref_box = BoxMesh.new()
			ref_box.size = Vector3(0.08, 0.14, 0.14)
			refl.mesh = ref_box
			refl.position = Vector3(side * 3.55, 0.6, float(z_pos))
			refl.material_override = mat_amber_reflector
			add_child(refl)
