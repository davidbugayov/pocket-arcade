extends LevelBase

class_name Level1

# Pocket Arcade: Squad Rush — Level 1: Docks Assault
# Structured into three distinct thematic sections:
# 1. Доки (The Docks) [z = 10.0 to -90.0]:
#    Wide embarkation quay, harbor portal crane, navigation pier lights, safe route chevrons
# 2. Грузовой терминал (Cargo Terminal) [z = -90.0 to -215.0]:
#    Multi-tier container stacks, overhead rail container gantry, sodium floodlights, hazard road markings
# 3. Шлюз (Sea Lock & Arena) [z = -215.0 to -330.0]:
#    Bulkhead blast walls, colossal lock gate arch framing Iron Sentinel, emergency strobes, embedded red/cyan runway strips

func _init() -> void:
	level_number = 1
	level_length = 360.0
	boss_z_position = -310.0

func _setup_boss() -> void:
	boss = BossUnit.new()
	boss.setup("Iron Sentinel", 950.0, 120, BossUnit.BossType.HEAVY_ROBOT)
	boss.position = Vector3(0, 0, boss_z_position)
	add_child(boss)
	boss.boss_hp_changed.connect(func(cur, m): if hud and hud.has_method("update_boss_hp"): hud.update_boss_hp(cur, m))
	boss.boss_shot_fired.connect(_on_boss_shot_fired)
	boss.boss_defeated.connect(_on_boss_defeated)

func _build_level_layout() -> void:
	# Tutorial Prompts (compact, single hint at a time as player advances, suppressed near gates)
	spawn_tutorial_text(-8.0, "SWIPE TO STEER SQUAD")
	spawn_tutorial_text(-36.0, "SHOOT TO BREAK TARGETS")
	spawn_tutorial_text(-80.0, "PASS BLUE GATES TO MULTIPLY")

	# =========================================================================
	# SECTION 1: ДОКИ (The Docks) [z = 10.0 to -90.0]
	# =========================================================================
	# 1. Section 1 Intro Warm-up (Center lane open, flank tire stacks 12 HP)
	spawn_obstacle(Vector3(-2.1, 0, -25.0), Obstacle.ObstacleType.TIRE_STACK, 12.0, 5)
	spawn_obstacle(Vector3(2.1, 0, -25.0), Obstacle.ObstacleType.TIRE_STACK, 12.0, 5)

	# 2. Gate 1: Safe vs Risky Route (-55.0)
	# Center: Concrete median barricade prevents zero-steering autopilot
	spawn_obstacle(Vector3(0.0, 0, -55.0), Obstacle.ObstacleType.CONCRETE_BLOCK, 20.0, 5)
	# Left: Safe +3 in open lane. Right: Risky +6 guarded by charging Runner!
	spawn_gate_pair(-55.0, MathGate.OperationType.ADD, 3, MathGate.OperationType.ADD, 6)
	spawn_enemy(Vector3(2.0, 0, -45.0), 12.0, 6, true, EnemyUnit.EnemyType.RUNNER)

	# 3. Encounter 1: Differentiated Enemy Roles (-88.0 to -94.0)
	# Left: Shooter covers lane with telegraphed laser. Right: Fast Runner charges!
	spawn_enemy(Vector3(-1.8, 0, -88.0), 20.0, 8, false, EnemyUnit.EnemyType.SHOOTER)
	spawn_enemy(Vector3(1.8, 0, -94.0), 12.0, 6, true, EnemyUnit.EnemyType.RUNNER)

	# =========================================================================
	# SECTION 2: ГРУЗОВОЙ ТЕРМИНАЛ (Cargo Terminal) [z = -90.0 to -215.0]
	# =========================================================================
	# 4. Gate 2: Multiplier vs Addition (-115.0)
	# Center: Dividing hazard barrel
	spawn_obstacle(Vector3(0.0, 0, -115.0), Obstacle.ObstacleType.BARREL, 18.0, 6)
	# Left: x2 behind wooden ammo crate (HP 16.0). Right: +4 in open lane.
	spawn_obstacle(Vector3(-2.0, 0, -108.0), Obstacle.ObstacleType.CRATE, 16.0, 8)
	spawn_gate_pair(-115.0, MathGate.OperationType.MULTIPLY, 2, MathGate.OperationType.ADD, 4)

	# 5. Encounter 2: Bridge Checkpoint (-145.0)
	# Heavy Shielder blocks center lane; Shooter covers right flank with telegraphed laser!
	spawn_enemy(Vector3(0.0, 0, -145.0), 50.0, 16, false, EnemyUnit.EnemyType.SHIELDER)
	spawn_enemy(Vector3(2.0, 0, -148.0), 20.0, 8, false, EnemyUnit.EnemyType.SHOOTER)

	# 6. In-Run Weapon Pickup (-172.0)
	# Combat Shotgun: positioned in Left Lane (requires deliberate steering to acquire)
	spawn_weapon_pickup(Vector3(-2.0, 0, -172.0), 1, "COMBAT SHOTGUN")

	# 7. Gate 3: High Reward vs Safe Route (-205.0)
	# Center: Concrete divider
	spawn_obstacle(Vector3(0.0, 0, -205.0), Obstacle.ObstacleType.CONCRETE_BLOCK, 20.0, 6)
	# Left: +6 in open lane. Right: x2 guarded by 2 Hazard Barrels (HP 20.0)
	spawn_obstacle(Vector3(1.4, 0, -198.0), Obstacle.ObstacleType.BARREL, 20.0, 10)
	spawn_obstacle(Vector3(2.6, 0, -198.0), Obstacle.ObstacleType.BARREL, 20.0, 10)
	spawn_gate_pair(-205.0, MathGate.OperationType.ADD, 6, MathGate.OperationType.MULTIPLY, 2)

	# =========================================================================
	# SECTION 3: ШЛЮЗ (Sea Lock & Boss Arena) [z = -215.0 to -330.0]
	# =========================================================================
	# 8. Encounter 3: Defense Line before Boss (-240.0)
	# 1 Heavy Shielder + 2 Shooters (dodgeable telegraphed lasers)
	spawn_enemy(Vector3(-2.0, 0, -242.0), 20.0, 8, false, EnemyUnit.EnemyType.SHOOTER)
	spawn_enemy(Vector3(0.0, 0, -238.0), 50.0, 16, false, EnemyUnit.EnemyType.SHIELDER)
	spawn_enemy(Vector3(2.0, 0, -242.0), 20.0, 8, false, EnemyUnit.EnemyType.SHOOTER)

	# 9. Approach Barricades to Boss Arena (-270.0)
	spawn_obstacle(Vector3(-2.1, 0, -268.0), Obstacle.ObstacleType.TIRE_STACK, 15.0, 6)
	spawn_obstacle(Vector3(2.1, 0, -268.0), Obstacle.ObstacleType.TIRE_STACK, 15.0, 6)

	# =========================================================================
	# THEMATIC ENVIRONMENT ARCHITECTURE & ROADWAY MARKINGS
	# =========================================================================
	_build_section1_docks_environment()
	_build_section2_cargo_terminal_environment()
	_build_section3_sea_lock_environment()
	_build_roadside_decorations()

# -----------------------------------------------------------------------------
# Section 1 Environment: Доки (The Docks)
# -----------------------------------------------------------------------------
func _build_section1_docks_environment() -> void:
	# 1. Wide embarkation start quay platform (z = 8.0 to -16.0, width = 14.0m)
	var quay = MeshInstance3D.new()
	var q_box = BoxMesh.new()
	q_box.size = Vector3(14.0, 0.85, 24.0)
	quay.mesh = q_box
	quay.position = Vector3(0, -0.42, -4.0)

	var mat_quay = StandardMaterial3D.new()
	mat_quay.albedo_color = Color(0.24, 0.26, 0.30)
	mat_quay.roughness = 0.86
	quay.material_override = mat_quay
	add_child(quay)

	# Wharf edge yellow/black caution striping along embarkation perimeter
	var mat_yellow = StandardMaterial3D.new()
	mat_yellow.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_yellow.albedo_color = Color(0.98, 0.82, 0.10)

	var mat_black = StandardMaterial3D.new()
	mat_black.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_black.albedo_color = Color(0.12, 0.12, 0.14)

	for side in [-6.8, 6.8]:
		for z_i in range(8):
			var stripe = MeshInstance3D.new()
			var s_box = BoxMesh.new()
			s_box.size = Vector3(0.40, 0.02, 1.4)
			stripe.mesh = s_box
			stripe.position = Vector3(side, 0.02, 6.0 - z_i * 2.8)
			stripe.material_override = mat_yellow if (z_i % 2 == 0) else mat_black
			add_child(stripe)

	# Heavy mooring bollards along wharf rim
	var cyl_bollard = CylinderMesh.new()
	cyl_bollard.top_radius = 0.18
	cyl_bollard.bottom_radius = 0.16
	cyl_bollard.height = 0.65
	cyl_bollard.radial_segments = 8

	var mat_iron = StandardMaterial3D.new()
	mat_iron.albedo_color = Color(0.15, 0.16, 0.19)
	mat_iron.metallic = 0.8
	mat_iron.roughness = 0.35

	for side in [-6.4, 6.4]:
		for z_pos in [4.0, -4.0, -12.0]:
			var bollard = MeshInstance3D.new()
			bollard.mesh = cyl_bollard
			bollard.material_override = mat_iron
			bollard.position = Vector3(side, 0.32, z_pos)
			add_child(bollard)

	# 2. Landmark: Massive Harbor Portal Gantry Crane on Left Wharf (x = -9.2, z = -34.0)
	_build_harbor_crane(Vector3(-9.2, 0, -34.0))

	# 3. Pier Navigation Light Masts
	var mat_lantern = StandardMaterial3D.new()
	mat_lantern.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_lantern.albedo_color = Color(0.2, 0.9, 1.0) # Maritime cyan beacon

	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 0.08
	l_cyl.bottom_radius = 0.10
	l_cyl.height = 3.6
	l_cyl.radial_segments = 6

	var l_head = SphereMesh.new()
	l_head.radius = 0.22
	l_head.height = 0.44
	l_head.radial_segments = 8
	l_head.rings = 4

	for side in [-5.2, 5.2]:
		for z_pos in [2.0, -22.0, -50.0, -78.0]:
			var mast = MeshInstance3D.new()
			mast.mesh = l_cyl
			mast.material_override = mat_iron
			mast.position = Vector3(side, 1.8, z_pos)
			add_child(mast)

			var lantern = MeshInstance3D.new()
			lantern.mesh = l_head
			lantern.material_override = mat_lantern
			lantern.position = Vector3(side, 3.7, z_pos)
			add_child(lantern)

	# 4. Roadway Guidance Markings before Gate 1 (-55.0):
	# Safe Left Lane (+3): High-visibility green/cyan chevron arrows painted on road
	var mat_guide_safe = StandardMaterial3D.new()
	mat_guide_safe.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_guide_safe.albedo_color = Color(0.18, 0.92, 0.45) # Emerald green guidance

	for z_chev in [-26.0, -36.0, -46.0]:
		var chev = MeshInstance3D.new()
		var c_box = BoxMesh.new()
		c_box.size = Vector3(1.2, 0.02, 0.32)
		chev.mesh = c_box
		chev.position = Vector3(-2.1, 0.018, z_chev)
		chev.material_override = mat_guide_safe
		add_child(chev)

	# Risky Right Lane (+6): Painted diagonal yellow hazard warning stripes leading to Runner encounter
	for z_h in [-36.0, -40.0, -44.0]:
		var h_stripe = MeshInstance3D.new()
		var hs_box = BoxMesh.new()
		hs_box.size = Vector3(1.4, 0.02, 0.28)
		h_stripe.mesh = hs_box
		h_stripe.position = Vector3(2.1, 0.018, z_h)
		h_stripe.rotation_degrees = Vector3(0, 30, 0)
		h_stripe.material_override = mat_yellow
		add_child(h_stripe)

func _build_harbor_crane(pos: Vector3) -> void:
	var crane_root = Node3D.new()
	crane_root.position = pos
	add_child(crane_root)

	var mat_steel = StandardMaterial3D.new()
	mat_steel.albedo_color = Color(0.88, 0.45, 0.12) # Industrial safety orange
	mat_steel.metallic = 0.5
	mat_steel.roughness = 0.45

	# 4 Heavy Portal Crane Legs
	var leg_mesh = BoxMesh.new()
	leg_mesh.size = Vector3(0.35, 12.0, 0.35)

	for lx in [-1.5, 1.5]:
		for lz in [-1.8, 1.8]:
			var leg = MeshInstance3D.new()
			leg.mesh = leg_mesh
			leg.material_override = mat_steel
			leg.position = Vector3(lx, 6.0, lz)
			crane_root.add_child(leg)

	# Overhead Crane Gantry Bridge
	var boom = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(4.2, 0.8, 10.0)
	boom.mesh = b_box
	boom.material_override = mat_steel
	boom.position = Vector3(0, 12.4, 0)
	crane_root.add_child(boom)

	# Machinery Cab & Jib Boom extending over water
	var jib = MeshInstance3D.new()
	var j_box = BoxMesh.new()
	j_box.size = Vector3(0.5, 0.5, 14.0)
	jib.mesh = j_box
	jib.material_override = mat_steel
	jib.position = Vector3(0, 13.5, 4.0)
	crane_root.add_child(jib)

# -----------------------------------------------------------------------------
# Section 2 Environment: Грузовой терминал (Cargo Terminal)
# -----------------------------------------------------------------------------
func _build_section2_cargo_terminal_environment() -> void:
	# 1. Multi-tier shipping cargo containers flanking outer perimeter (x = +/-6.5 to 8.5m)
	# Colors: marine navy, rust red, safety orange, olive drab
	var colors = [
		Color(0.12, 0.32, 0.62), # Navy
		Color(0.72, 0.22, 0.14), # Rust Red
		Color(0.85, 0.52, 0.10), # Orange
		Color(0.30, 0.42, 0.28)  # Olive
	]

	var c_mesh = BoxMesh.new()
	c_mesh.size = Vector3(2.2, 1.7, 5.4)

	var c_idx = 0
	for z_pos in [-98.0, -118.0, -138.0, -162.0, -182.0, -202.0]:
		for side in [-6.8, 6.8]:
			var num_tiers = 2 if (int(abs(z_pos)) % 40 == 0) else 1
			for tier in range(num_tiers):
				var mat_c = StandardMaterial3D.new()
				mat_c.albedo_color = colors[c_idx % colors.size()]
				mat_c.roughness = 0.75
				c_idx += 1

				var c = MeshInstance3D.new()
				c.mesh = c_mesh
				c.material_override = mat_c
				c.position = Vector3(side, 0.85 + tier * 1.7, z_pos)
				add_child(c)

	# 2. Landmark: Rail Container Overhead Gantry Crane at z = -158.0
	_build_container_overhead_gantry(Vector3(0, 0, -158.0))

	# 3. Roadway Markings for Risky Routes:
	# Gate 2 (z = -115.0): Left lane caution stripes leading into Ammo Crate (-108.0)
	var mat_caution_yellow = StandardMaterial3D.new()
	mat_caution_yellow.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_caution_yellow.albedo_color = Color(0.98, 0.78, 0.12)

	for z_mark in [-102.0, -105.0]:
		var mark = MeshInstance3D.new()
		var m_box = BoxMesh.new()
		m_box.size = Vector3(1.3, 0.02, 0.30)
		mark.mesh = m_box
		mark.position = Vector3(-2.0, 0.018, z_mark)
		mark.rotation_degrees = Vector3(0, 30, 0)
		mark.material_override = mat_caution_yellow
		add_child(mark)

	# Gate 3 (z = -205.0): Right lane high-contrast hazard crosshatch leading to Barrels (-198.0)
	var mat_danger_red = StandardMaterial3D.new()
	mat_danger_red.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_danger_red.albedo_color = Color(1.0, 0.25, 0.20)

	for z_mark in [-192.0, -195.0]:
		var d_mark = MeshInstance3D.new()
		var dm_box = BoxMesh.new()
		dm_box.size = Vector3(1.4, 0.02, 0.30)
		d_mark.mesh = dm_box
		d_mark.position = Vector3(2.0, 0.018, z_mark)
		d_mark.rotation_degrees = Vector3(0, -30, 0)
		d_mark.material_override = mat_danger_red
		add_child(d_mark)

func _build_container_overhead_gantry(pos: Vector3) -> void:
	var gantry_root = Node3D.new()
	gantry_root.position = pos
	add_child(gantry_root)

	var mat_gantry = StandardMaterial3D.new()
	mat_gantry.albedo_color = Color(0.92, 0.82, 0.15) # High-visibility yellow
	mat_gantry.metallic = 0.4
	mat_gantry.roughness = 0.5

	# Outer vertical gantry pylons
	var pylon_mesh = BoxMesh.new()
	pylon_mesh.size = Vector3(0.55, 10.0, 0.55)

	for side in [-7.2, 7.2]:
		var pylon = MeshInstance3D.new()
		pylon.mesh = pylon_mesh
		pylon.material_override = mat_gantry
		pylon.position = Vector3(side, 5.0, 0)
		gantry_root.add_child(pylon)

	# High overhead bridge beam spanning across the roadway (height 9.8m, clear of camera)
	var beam = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(15.0, 0.85, 0.85)
	beam.mesh = b_box
	beam.material_override = mat_gantry
	beam.position = Vector3(0, 9.8, 0)
	gantry_root.add_child(beam)

	# Hoist trolley
	var trolley = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(1.6, 0.65, 1.2)
	trolley.mesh = t_box
	var mat_trolley = StandardMaterial3D.new()
	mat_trolley.albedo_color = Color(0.2, 0.22, 0.26)
	trolley.material_override = mat_trolley
	trolley.position = Vector3(2.4, 9.2, 0)
	gantry_root.add_child(trolley)

# -----------------------------------------------------------------------------
# Section 3 Environment: Шлюз (Sea Lock & Arena)
# -----------------------------------------------------------------------------
func _build_section3_sea_lock_environment() -> void:
	# 1. Reinforced bulkhead blast walls framing the final arena (z = -230 to -325, x = +/-5.8..7.0m)
	var mat_bulkhead = StandardMaterial3D.new()
	mat_bulkhead.albedo_color = Color(0.18, 0.20, 0.25)
	mat_bulkhead.metallic = 0.6
	mat_bulkhead.roughness = 0.65

	var w_mesh = BoxMesh.new()
	w_mesh.size = Vector3(0.9, 7.0, 16.0)

	for side in [-5.8, 5.8]:
		for z_pos in [-240.0, -265.0, -290.0]:
			var wall = MeshInstance3D.new()
			wall.mesh = w_mesh
			wall.material_override = mat_bulkhead
			wall.position = Vector3(side, 3.5, z_pos)
			add_child(wall)

	# 2. Landmark: Colossal Sea Lock Gate Archway framing Iron Sentinel at z = -322.0
	var mat_lock_gate = StandardMaterial3D.new()
	mat_lock_gate.albedo_color = Color(0.82, 0.18, 0.14) # Emergency industrial crimson
	mat_lock_gate.metallic = 0.7
	mat_lock_gate.roughness = 0.45

	var arch_root = Node3D.new()
	arch_root.position = Vector3(0, 0, -322.0)
	add_child(arch_root)

	# Heavy archway columns
	var arch_col = BoxMesh.new()
	arch_col.size = Vector3(1.6, 12.0, 1.6)

	for side in [-5.8, 5.8]:
		var col = MeshInstance3D.new()
		col.mesh = arch_col
		col.material_override = mat_lock_gate
		col.position = Vector3(side, 6.0, 0)
		arch_root.add_child(col)

	# Archway top crossbeam spanning above the boss
	var arch_beam = MeshInstance3D.new()
	var ab_box = BoxMesh.new()
	ab_box.size = Vector3(13.2, 1.8, 1.8)
	arch_beam.mesh = ab_box
	arch_beam.material_override = mat_lock_gate
	arch_beam.position = Vector3(0, 11.5, 0)
	arch_root.add_child(arch_beam)

	# 3. Emergency Strobe Warning Beacons on bulkhead pillars
	var mat_strobe_red = StandardMaterial3D.new()
	mat_strobe_red.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_strobe_red.albedo_color = Color(1.0, 0.15, 0.10) # Warning red beacon

	var b_sphere = SphereMesh.new()
	b_sphere.radius = 0.28
	b_sphere.height = 0.56
	b_sphere.radial_segments = 8
	b_sphere.rings = 4

	for side in [-5.6, 5.6]:
		for z_pos in [-235.0, -260.0, -285.0, -310.0]:
			var beacon = MeshInstance3D.new()
			beacon.mesh = b_sphere
			beacon.material_override = mat_strobe_red
			beacon.position = Vector3(side, 6.2, z_pos)
			add_child(beacon)

	# 4. High-Contrast Embedded Runway Light Strips (z = -230.0 to -290.0)
	# Ensures safe vs danger lanes are unmistakably distinct even with 30-60 androids!
	var mat_danger_strip = StandardMaterial3D.new()
	mat_danger_strip.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_danger_strip.albedo_color = Color(1.0, 0.10, 0.10) # Bright red danger lane

	var mat_safe_strip = StandardMaterial3D.new()
	mat_safe_strip.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_safe_strip.albedo_color = Color(0.15, 0.95, 1.0) # Bright cyan safe guide lane

	# Danger corridors (Center x = 0 and Right x = +2.0, where shooters cover and boss fires)
	for lane_x in [0.0, 2.0]:
		var strip = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(0.20, 0.02, 60.0)
		strip.mesh = s_box
		strip.position = Vector3(lane_x, 0.016, -260.0)
		strip.material_override = mat_danger_strip
		add_child(strip)

	# Safe corridor (Left x = -2.0)
	var safe_strip = MeshInstance3D.new()
	var ss_box = BoxMesh.new()
	ss_box.size = Vector3(0.20, 0.02, 60.0)
	safe_strip.mesh = ss_box
	safe_strip.position = Vector3(-2.0, 0.016, -260.0)
	safe_strip.material_override = mat_safe_strip
	add_child(safe_strip)

# -----------------------------------------------------------------------------
# Roadside Warning Details
# -----------------------------------------------------------------------------
func _build_roadside_decorations() -> void:
	var mat_bollard = StandardMaterial3D.new()
	mat_bollard.albedo_color = Color(0.95, 0.55, 0.10) # Safety orange
	mat_bollard.roughness = 0.5

	var mat_stripe = StandardMaterial3D.new()
	mat_stripe.albedo_color = Color(0.95, 0.95, 0.95) # White reflector
	mat_stripe.roughness = 0.3

	var mat_sandbag = StandardMaterial3D.new()
	mat_sandbag.albedo_color = Color(0.65, 0.55, 0.38) # Khaki canvas
	mat_sandbag.roughness = 0.9

	# 1. Roadside Warning Bollards along outer curbs (x = +/-4.15)
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.08
	cyl.bottom_radius = 0.09
	cyl.height = 0.70
	cyl.radial_segments = 8
	cyl.rings = 1

	var r_cyl = CylinderMesh.new()
	r_cyl.top_radius = 0.085
	r_cyl.bottom_radius = 0.085
	r_cyl.height = 0.14
	r_cyl.radial_segments = 8
	r_cyl.rings = 1

	for z_pos in [-15.0, -45.0, -85.0, -125.0, -155.0, -195.0, -235.0, -275.0]:
		for side in [-4.15, 4.15]:
			var post = MeshInstance3D.new()
			post.mesh = cyl
			post.material_override = mat_bollard
			post.position = Vector3(side, 0.35, z_pos)
			add_child(post)

			# Reflector stripe ring
			var ring = MeshInstance3D.new()
			ring.mesh = r_cyl
			ring.material_override = mat_stripe
			ring.position = Vector3(side, 0.52, z_pos)
			add_child(ring)

	# 2. Outer Shoulder Sandbag Revetments framing Checkpoint (z = -145.0, x = +/-4.25)
	var b_mesh = CapsuleMesh.new()
	b_mesh.radius = 0.14
	b_mesh.height = 0.55
	b_mesh.radial_segments = 8
	b_mesh.rings = 3

	for side in [-4.25, 4.25]:
		for offset_z in [-1.5, 0.0, 1.5]:
			var bag = MeshInstance3D.new()
			bag.mesh = b_mesh
			bag.material_override = mat_sandbag
			bag.rotation_degrees = Vector3(0, 90, 0)
			bag.position = Vector3(side, 0.12, -145.0 + offset_z)
			add_child(bag)

			var bag_top = MeshInstance3D.new()
			bag_top.mesh = b_mesh
			bag_top.material_override = mat_sandbag
			bag_top.rotation_degrees = Vector3(0, 90, 0)
			bag_top.position = Vector3(side, 0.28, -145.0 + offset_z * 0.6)
			add_child(bag_top)
