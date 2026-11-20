extends LevelBase

class_name Level3

func _init() -> void:
	level_number = 3
	level_length = 380.0
	boss_z_position = -335.0

func _setup_boss() -> void:
	boss = BossUnit.new()
	boss.position = Vector3(0, 0, boss_z_position)
	add_child(boss)
	# Dread Titan: 1950 HP, 350 coins, ~11-13s TTK with strong squad
	boss.setup("Dread Titan", 1950.0, 350, BossUnit.BossType.DREAD_TITAN)
	boss.move_speed = 2.4
	boss.attack_interval = 2.2
	boss.boss_hp_changed.connect(func(cur, m): if hud and hud.has_method("update_boss_hp"): hud.update_boss_hp(cur, m))
	boss.boss_shot_fired.connect(_on_boss_shot_fired)
	boss.boss_defeated.connect(_on_boss_defeated)

func _build_level_layout() -> void:
	spawn_tutorial_text(-10.0, "FINAL ASSAULT: DREAD TITAN")

	# =========================================================================
	# SECTION 1: ОРБИТАЛЬНЫЙ ВИАДУК (Orbital Skyway) [0 to -120m]
	# =========================================================================
	# 1. Opening Obstacle Gates & Median Barrier
	spawn_obstacle(Vector3(-2.2, 0, -25.0), Obstacle.ObstacleType.CONCRETE_BLOCK, 30.0, 10)
	spawn_obstacle(Vector3(2.2, 0, -25.0), Obstacle.ObstacleType.CONCRETE_BLOCK, 30.0, 10)

	# 2. Gate 1: Safe Lane (+6) vs High Reward (+10 guarded by Runners!)
	# Center concrete divider forces lane commitment
	spawn_obstacle(Vector3(0.0, 0, -55.0), Obstacle.ObstacleType.CONCRETE_BLOCK, 30.0, 10)
	spawn_gate_pair(-55.0, MathGate.OperationType.ADD, 6, MathGate.OperationType.ADD, 10)
	spawn_enemy(Vector3(2.0, 0, -45.0), 16.0, 8, true, EnemyUnit.EnemyType.RUNNER)
	spawn_enemy(Vector3(2.0, 0, -48.0), 16.0, 8, true, EnemyUnit.EnemyType.RUNNER)

	# 3. Encounter 1: Crossfire Ambush (-88.0 to -94.0)
	# Dual Shooters flanking left and right with telegraphed aiming lasers!
	spawn_enemy(Vector3(-2.0, 0, -88.0), 25.0, 10, false, EnemyUnit.EnemyType.SHOOTER)
	spawn_enemy(Vector3(2.0, 0, -94.0), 25.0, 10, false, EnemyUnit.EnemyType.SHOOTER)

	# =========================================================================
	# SECTION 2: РЕАКТОРНЫЙ КАНЬОН (Quantum Core Conduit) [-120 to -250m]
	# =========================================================================
	# 4. Allied Rescue Barrel (-118.0)
	# Destroy barrel to free 3 allied fighters!
	spawn_rescue_barrel(Vector3(2.0, 0, -118.0), 3, 22.0)

	# 5. Gate 2: Multiplier vs Addition (-145.0)
	# Center dividing hazard barrel
	spawn_obstacle(Vector3(0.0, 0, -145.0), Obstacle.ObstacleType.BARREL, 26.0, 10)
	# Left: Risky x2 behind heavy ammo crate (HP 28.0). Right: Safe +8 in open lane
	spawn_obstacle(Vector3(-2.0, 0, -138.0), Obstacle.ObstacleType.CRATE, 28.0, 12)
	spawn_gate_pair(-145.0, MathGate.OperationType.MULTIPLY, 2, MathGate.OperationType.ADD, 8)

	# 6. In-Run Weapon Pickup: Plasma Minigun (-175.0)
	# Rapid suppression rotary cannon in left lane, guarded by heavy Shielder!
	spawn_enemy(Vector3(-2.0, 0, -168.0), 60.0, 20, false, EnemyUnit.EnemyType.SHIELDER)
	spawn_weapon_pickup(Vector3(-2.0, 0, -175.0), 2, "PLASMA MINIGUN")

	# 7. Encounter 2: Heavy Defense Fortification (-205.0 to -212.0)
	# Dual Shielders guarding the bridge choke point!
	spawn_enemy(Vector3(-1.2, 0, -205.0), 55.0, 18, false, EnemyUnit.EnemyType.SHIELDER)
	spawn_enemy(Vector3(1.2, 0, -208.0), 55.0, 18, false, EnemyUnit.EnemyType.SHIELDER)
	spawn_enemy(Vector3(0.0, 0, -212.0), 16.0, 8, true, EnemyUnit.EnemyType.RUNNER)

	# 8. Gate 3: High Stakes Route (-240.0)
	# Center divider
	spawn_obstacle(Vector3(0.0, 0, -240.0), Obstacle.ObstacleType.CONCRETE_BLOCK, 30.0, 10)
	# Left: Safe +10. Right: x2 guarded by 2 hazard barrels (HP 25.0)
	spawn_obstacle(Vector3(1.4, 0, -232.0), Obstacle.ObstacleType.BARREL, 25.0, 12)
	spawn_obstacle(Vector3(2.6, 0, -232.0), Obstacle.ObstacleType.BARREL, 25.0, 12)
	spawn_gate_pair(-240.0, MathGate.OperationType.ADD, 10, MathGate.OperationType.MULTIPLY, 2)

	# =========================================================================
	# SECTION 3: ЦИТАДЕЛЬ ТИТАНА (Titan Citadel & Arena) [-250 to -380m]
	# =========================================================================
	# 9. Encounter 3: Elite Vanguard Line (-275.0 to -282.0)
	# Shielder center, Shooter left, 2 fast Runners right!
	spawn_enemy(Vector3(0.0, 0, -275.0), 60.0, 20, false, EnemyUnit.EnemyType.SHIELDER)
	spawn_enemy(Vector3(-2.0, 0, -278.0), 25.0, 10, false, EnemyUnit.EnemyType.SHOOTER)
	spawn_enemy(Vector3(2.0, 0, -282.0), 16.0, 8, true, EnemyUnit.EnemyType.RUNNER)

	# 10. Gate 4: Final Preparation Gate (-310.0)
	# Center divider
	spawn_obstacle(Vector3(0.0, 0, -310.0), Obstacle.ObstacleType.CONCRETE_BLOCK, 30.0, 10)
	# Left: Safe +8. Right: +12 behind ammo crate (HP 24.0)
	spawn_obstacle(Vector3(2.0, 0, -302.0), Obstacle.ObstacleType.CRATE, 24.0, 12)
	spawn_gate_pair(-310.0, MathGate.OperationType.ADD, 8, MathGate.OperationType.ADD, 12)

	# =========================================================================
	# THEMATIC ENVIRONMENT ARCHITECTURE & ROADWAY MARKINGS
	# =========================================================================
	_build_section1_skyway_environment()
	_build_section2_reactor_core_environment()
	_build_section3_citadel_environment()
	_build_roadside_decorations()

# -----------------------------------------------------------------------------
# Section 1 Environment: Орбитальный виадук (Orbital Skyway)
# -----------------------------------------------------------------------------
func _build_section1_skyway_environment() -> void:
	# 1. Sleek futuristic concourse platform (z = 8.0 to -16.0, width = 14.0m)
	var skyway_plat = MeshInstance3D.new()
	var sp_box = BoxMesh.new()
	sp_box.size = Vector3(14.0, 0.9, 24.0)
	skyway_plat.mesh = sp_box
	skyway_plat.position = Vector3(0, -0.45, -4.0)
	var mat_sky_plat = StandardMaterial3D.new()
	mat_sky_plat.albedo_color = Color(0.18, 0.20, 0.25)
	mat_sky_plat.metallic = 0.6
	mat_sky_plat.roughness = 0.5
	skyway_plat.material_override = mat_sky_plat
	add_child(skyway_plat)

	# Radiant cyan telemetry edge bands
	var mat_cyan_glow = StandardMaterial3D.new()
	mat_cyan_glow.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_cyan_glow.albedo_color = Color(0.15, 0.90, 1.0)

	for side in [-1.0, 1.0]:
		var band = MeshInstance3D.new()
		var b_box = BoxMesh.new()
		b_box.size = Vector3(0.4, 0.04, 24.0)
		band.mesh = b_box
		band.position = Vector3(side * 6.5, 0.02, -4.0)
		band.material_override = mat_cyan_glow
		add_child(band)

	# 2. Sleek aerodynamic pylon spires along highway edge (x = ±6.8m, z = 0 to -115m)
	var mat_spire = StandardMaterial3D.new()
	mat_spire.albedo_color = Color(0.12, 0.15, 0.20)
	mat_spire.metallic = 0.85
	mat_spire.roughness = 0.3

	var mat_spire_glow = StandardMaterial3D.new()
	mat_spire_glow.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_spire_glow.albedo_color = Color(0.2, 0.85, 1.0)

	var pylon_zs = [-18.0, -40.0, -82.0, -108.0]
	for z_pos in pylon_zs:
		for side in [-1.0, 1.0]:
			var spire = MeshInstance3D.new()
			var s_box = BoxMesh.new()
			s_box.size = Vector3(1.1, 10.0, 1.1)
			spire.mesh = s_box
			spire.position = Vector3(side * 6.8, 5.0, z_pos)
			spire.rotation_degrees = Vector3(0, 0, side * -8.0)
			spire.material_override = mat_spire
			add_child(spire)

			# Cyan illumination beacon at tip
			var beacon = MeshInstance3D.new()
			var b_mesh = CylinderMesh.new()
			b_mesh.top_radius = 0.15
			b_mesh.bottom_radius = 0.25
			b_mesh.height = 1.2
			beacon.mesh = b_mesh
			beacon.position = Vector3(side * 6.8, 10.4, z_pos)
			beacon.material_override = mat_spire_glow
			add_child(beacon)

	# 3. LANDMARK 1: Colossal Skyway Suspension Tower Arch (z = -60.0m)
	# Twin faceted sci-fi towers rising 18m connected by overhead suspension truss
	var mat_tower_composite = StandardMaterial3D.new()
	mat_tower_composite.albedo_color = Color(0.10, 0.12, 0.16)
	mat_tower_composite.metallic = 0.9
	mat_tower_composite.roughness = 0.25

	for side in [-1.0, 1.0]:
		var leg = MeshInstance3D.new()
		var l_box = BoxMesh.new()
		l_box.size = Vector3(2.0, 18.0, 2.2)
		leg.mesh = l_box
		leg.position = Vector3(side * 5.6, 9.0, -60.0)
		leg.material_override = mat_tower_composite
		add_child(leg)

		# Radiant cyan power channel down the leg
		var chan = MeshInstance3D.new()
		var c_box = BoxMesh.new()
		c_box.size = Vector3(0.25, 17.0, 0.25)
		chan.mesh = c_box
		chan.position = Vector3(side * 4.6, 9.0, -59.0)
		chan.material_override = mat_cyan_glow
		add_child(chan)

	# High overhead arch bridge beam
	var arch_beam = MeshInstance3D.new()
	var ab_box = BoxMesh.new()
	ab_box.size = Vector3(13.2, 1.8, 2.4)
	arch_beam.mesh = ab_box
	arch_beam.position = Vector3(0, 17.5, -60.0)
	arch_beam.material_override = mat_tower_composite
	add_child(arch_beam)

	# 4. Road Markings: Cybernetic guidance dashes leading to Gate 1 (+6 safe vs +10 risky)
	var mat_gate_safe = StandardMaterial3D.new()
	mat_gate_safe.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_gate_safe.albedo_color = Color(0.15, 0.95, 0.50)

	var mat_gate_risky = StandardMaterial3D.new()
	mat_gate_risky.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_gate_risky.albedo_color = Color(1.0, 0.40, 0.10)

	for step in range(5):
		var z_m = -32.0 - step * 4.5
		# Safe lane line (left)
		var s_line = MeshInstance3D.new()
		var sl_box = BoxMesh.new()
		sl_box.size = Vector3(1.1, 0.03, 0.35)
		s_line.mesh = sl_box
		s_line.position = Vector3(-1.9, 0.02, z_m)
		s_line.material_override = mat_gate_safe
		add_child(s_line)

		# Risky lane line (right)
		var r_line = MeshInstance3D.new()
		var rl_box = BoxMesh.new()
		rl_box.size = Vector3(1.1, 0.03, 0.35)
		r_line.mesh = rl_box
		r_line.position = Vector3(1.9, 0.02, z_m)
		r_line.rotation_degrees = Vector3(0, 20, 0)
		r_line.material_override = mat_gate_risky
		add_child(r_line)

# -----------------------------------------------------------------------------
# Section 2 Environment: Реакторный каньон (Quantum Core Conduit)
# -----------------------------------------------------------------------------
func _build_section2_reactor_core_environment() -> void:
	# 1. Reactor cooling substation blocks & capacitor banks (x = ±6.5 to ±9.0m, z = -120 to -245m)
	var mat_reactor_hull = StandardMaterial3D.new()
	mat_reactor_hull.albedo_color = Color(0.15, 0.17, 0.22)
	mat_reactor_hull.metallic = 0.7
	mat_reactor_hull.roughness = 0.4

	var mat_plasma_blue = StandardMaterial3D.new()
	mat_plasma_blue.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_plasma_blue.albedo_color = Color(0.20, 0.55, 1.0)

	var sub_zs = [-130.0, -155.0, -195.0, -225.0]
	for z_pos in sub_zs:
		for side in [-1.0, 1.0]:
			var cap_bank = MeshInstance3D.new()
			var cb_box = BoxMesh.new()
			cb_box.size = Vector3(2.6, 4.5, 6.5)
			cap_bank.mesh = cb_box
			cap_bank.position = Vector3(side * 7.5, 2.25, z_pos)
			cap_bank.material_override = mat_reactor_hull
			add_child(cap_bank)

			# Glowing plasma cooling vent slit
			var vent = MeshInstance3D.new()
			var v_box = BoxMesh.new()
			v_box.size = Vector3(0.2, 0.5, 5.5)
			vent.mesh = v_box
			vent.position = Vector3(side * 6.15, 2.5, z_pos)
			vent.material_override = mat_plasma_blue
			add_child(vent)

	# 2. LANDMARK 2: Dual Magnetic Particle Accelerator Rings (z = -175.0m)
	# Towering toroidal magnetic rings encircling the sky right at the Plasma Minigun!
	var mat_ring_metal = StandardMaterial3D.new()
	mat_ring_metal.albedo_color = Color(0.22, 0.25, 0.32)
	mat_ring_metal.metallic = 0.85
	mat_ring_metal.roughness = 0.3

	for ring_idx in range(2):
		var ring_z = -173.0 - ring_idx * 4.0
		var ring = MeshInstance3D.new()
		var t_mesh = TorusMesh.new()
		t_mesh.inner_radius = 5.2
		t_mesh.outer_radius = 6.4
		ring.mesh = t_mesh
		ring.rotation_degrees = Vector3(90, 0, 0)
		ring.position = Vector3(0, 5.5, ring_z)
		ring.material_override = mat_ring_metal
		add_child(ring)

		# Inner glowing magnetic containment band
		var band = MeshInstance3D.new()
		var tb_mesh = TorusMesh.new()
		tb_mesh.inner_radius = 5.3
		tb_mesh.outer_radius = 5.5
		band.mesh = tb_mesh
		band.rotation_degrees = Vector3(90, 0, 0)
		band.position = Vector3(0, 5.5, ring_z)
		band.material_override = mat_plasma_blue
		add_child(band)

	# 3. Road Markings: High-voltage ionization chevrons at choke points (-145m and -205m)
	var mat_ion_warn = StandardMaterial3D.new()
	mat_ion_warn.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_ion_warn.albedo_color = Color(1.0, 0.70, 0.15)

	for z_mark in [-142.0, -202.0]:
		for s in range(4):
			var ch = MeshInstance3D.new()
			var ch_box = BoxMesh.new()
			ch_box.size = Vector3(0.25, 0.02, 1.6)
			ch.mesh = ch_box
			ch.position = Vector3(-1.8 + s * 1.2, 0.02, z_mark)
			ch.rotation_degrees = Vector3(0, 40, 0)
			ch.material_override = mat_ion_warn
			add_child(ch)

# -----------------------------------------------------------------------------
# Section 3 Environment: Цитадель Титана (Titan Citadel & Dread Titan Arena)
# -----------------------------------------------------------------------------
func _build_section3_citadel_environment() -> void:
	# 1. Monolithic Obsidian Blast Spires along arena approach (z = -250 to -370m)
	var mat_obsidian = StandardMaterial3D.new()
	mat_obsidian.albedo_color = Color(0.06, 0.07, 0.09)
	mat_obsidian.metallic = 0.95
	mat_obsidian.roughness = 0.2

	var mat_crimson_fissure = StandardMaterial3D.new()
	mat_crimson_fissure.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_crimson_fissure.albedo_color = Color(0.95, 0.12, 0.15)

	for z_pos in range(-250, -380, -22):
		for side in [-1.0, 1.0]:
			var spire = MeshInstance3D.new()
			var s_box = BoxMesh.new()
			s_box.size = Vector3(2.4, 15.0, 2.4)
			spire.mesh = s_box
			spire.position = Vector3(side * 6.8, 7.5, float(z_pos))
			spire.rotation_degrees = Vector3(0, side * 15, side * -4.0)
			spire.material_override = mat_obsidian
			add_child(spire)

			# Crimson glowing fissure down the inner face
			var fiss = MeshInstance3D.new()
			var f_box = BoxMesh.new()
			f_box.size = Vector3(0.2, 13.0, 0.2)
			f_box.size = Vector3(0.2, 13.0, 0.2)
			fiss.mesh = f_box
			fiss.position = Vector3(side * 5.55, 7.5, float(z_pos))
			fiss.material_override = mat_crimson_fissure
			add_child(fiss)

	# 2. LANDMARK 3: The Great Obsidian Citadel Gateway (z = -330.0m)
	# Colossal portal framing Dread Titan (1950 HP) at z = -335m!
	for side in [-1.0, 1.0]:
		var gate_pillar = MeshInstance3D.new()
		var gp_box = BoxMesh.new()
		gp_box.size = Vector3(2.8, 16.0, 3.4)
		gate_pillar.mesh = gp_box
		gate_pillar.position = Vector3(side * 5.6, 8.0, -330.0)
		gate_pillar.material_override = mat_obsidian
		add_child(gate_pillar)

		# Angular buttress wing
		var wing = MeshInstance3D.new()
		var w_box = BoxMesh.new()
		w_box.size = Vector3(1.6, 14.0, 4.0)
		wing.mesh = w_box
		wing.position = Vector3(side * 7.2, 7.0, -330.0)
		wing.rotation_degrees = Vector3(0, 0, side * 18.0)
		wing.material_override = mat_obsidian
		add_child(wing)

	# Massive Citadel Overhead Lintel Spire
	var lintel = MeshInstance3D.new()
	var l_box = BoxMesh.new()
	l_box.size = Vector3(13.6, 2.8, 3.8)
	lintel.mesh = l_box
	lintel.position = Vector3(0, 15.5, -330.0)
	lintel.material_override = mat_obsidian
	add_child(lintel)

	# Crimson heraldic energy crest on lintel
	var crest = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(8.5, 0.6, 0.1)
	crest.mesh = c_box
	crest.position = Vector3(0, 15.0, -328.0)
	crest.material_override = mat_crimson_fissure
	add_child(crest)

	# 3. Boss Arena Tactical Road Markings: Red death zone vs safe evasion arcs
	for step in range(10):
		var dl = MeshInstance3D.new()
		var dl_box = BoxMesh.new()
		dl_box.size = Vector3(0.25, 0.02, 3.2)
		dl.mesh = dl_box
		dl.position = Vector3(0.0, 0.03, -300.0 - step * 3.5)
		dl.material_override = mat_crimson_fissure
		add_child(dl)

	var mat_cyan_evasion = StandardMaterial3D.new()
	mat_cyan_evasion.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_cyan_evasion.albedo_color = Color(0.2, 0.85, 1.0)

	for step in range(8):
		var ea_l = MeshInstance3D.new()
		var ea_box = BoxMesh.new()
		ea_box.size = Vector3(0.3, 0.02, 2.4)
		ea_l.mesh = ea_box
		ea_l.position = Vector3(-2.8, 0.03, -305.0 - step * 4.5)
		ea_l.material_override = mat_cyan_evasion
		add_child(ea_l)

		var ea_r = MeshInstance3D.new()
		ea_r.mesh = ea_box
		ea_r.position = Vector3(2.8, 0.03, -305.0 - step * 4.5)
		ea_r.material_override = mat_cyan_evasion
		add_child(ea_r)

# -----------------------------------------------------------------------------
# Roadside Guardrails & Telemetry Infrastructure
# -----------------------------------------------------------------------------
func _build_roadside_decorations() -> void:
	var mat_guard_composite = StandardMaterial3D.new()
	mat_guard_composite.albedo_color = Color(0.25, 0.28, 0.35)
	mat_guard_composite.metallic = 0.85
	mat_guard_composite.roughness = 0.3

	var mat_cyan_marker = StandardMaterial3D.new()
	mat_cyan_marker.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_cyan_marker.albedo_color = Color(0.15, 0.85, 1.0)

	for z_pos in range(0, -380, -10):
		for side in [-1.0, 1.0]:
			var rail = MeshInstance3D.new()
			var r_box = BoxMesh.new()
			r_box.size = Vector3(0.2, 0.55, 9.6)
			rail.mesh = r_box
			rail.position = Vector3(side * 3.65, 0.48, float(z_pos) - 5.0)
			rail.material_override = mat_guard_composite
			add_child(rail)

			# Cyan LED telemetry node every 10m
			var led = MeshInstance3D.new()
			var l_box = BoxMesh.new()
			l_box.size = Vector3(0.08, 0.15, 0.15)
			led.mesh = l_box
			led.position = Vector3(side * 3.52, 0.65, float(z_pos))
			led.material_override = mat_cyan_marker
			add_child(led)
