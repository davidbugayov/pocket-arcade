extends LevelBase

class_name Level1

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
	# Tutorial Prompts (compact, single hint at a time as player advances)
	spawn_tutorial_text(-8.0, "SWIPE TO STEER SQUAD")
	spawn_tutorial_text(-36.0, "SHOOT TO BREAK TARGETS")
	spawn_tutorial_text(-80.0, "PASS BLUE GATES TO MULTIPLY")

	# 1. Section 1: Intro Warm-up (Center lane open, flank tire stacks 12 HP)
	spawn_obstacle(Vector3(-2.1, 0, -25.0), Obstacle.ObstacleType.TIRE_STACK, 12.0, 5)
	spawn_obstacle(Vector3(2.1, 0, -25.0), Obstacle.ObstacleType.TIRE_STACK, 12.0, 5)

	# 2. Gate 1: Safe vs Risky Route (-55.0)
	# Left: Safe +3 in open lane. Right: Risky +7 guarded by a charging Runner!
	spawn_gate_pair(-55.0, MathGate.OperationType.ADD, 3, MathGate.OperationType.ADD, 7)
	spawn_enemy(Vector3(2.1, 0, -45.0), 12.0, 6, true, EnemyUnit.EnemyType.RUNNER)

	# 3. Encounter 1: Fast Charging Enemy Runners (-85.0 to -92.0)
	# Forces player to shoot or steer before runners crash into the squad!
	spawn_enemy(Vector3(-1.2, 0, -88.0), 12.0, 6, true, EnemyUnit.EnemyType.RUNNER)
	spawn_enemy(Vector3(1.2, 0, -92.0), 12.0, 6, true, EnemyUnit.EnemyType.RUNNER)

	# 4. Gate 2: Multiplier vs Addition (-115.0)
	# Left: x2 behind wooden ammo crate (HP 16.0). Right: +5 in open lane.
	spawn_obstacle(Vector3(-2.1, 0, -108.0), Obstacle.ObstacleType.CRATE, 16.0, 8)
	spawn_gate_pair(-115.0, MathGate.OperationType.MULTIPLY, 2, MathGate.OperationType.ADD, 5)

	# 5. Encounter 2: Bridge Checkpoint (-145.0)
	# Heavy Shielder blocks center lane; Shooter covers right flank with telegraphed laser!
	spawn_enemy(Vector3(0.0, 0, -145.0), 50.0, 16, false, EnemyUnit.EnemyType.SHIELDER)
	spawn_enemy(Vector3(2.1, 0, -148.0), 20.0, 8, false, EnemyUnit.EnemyType.SHOOTER)

	# 6. In-Run Weapon Pickup (-172.0)
	# Combat Shotgun: heavy close-range 4-pellet spread for clearing barriers and clusters!
	spawn_weapon_pickup(Vector3(0.0, 0, -172.0), 1, "COMBAT SHOTGUN")

	# 7. Gate 3: High Reward vs Safe Route (-205.0)
	# Left: +6 in open lane. Right: x2 guarded by 2 Hazard Barrels (HP 20.0)
	spawn_obstacle(Vector3(1.4, 0, -198.0), Obstacle.ObstacleType.BARREL, 20.0, 10)
	spawn_obstacle(Vector3(2.8, 0, -198.0), Obstacle.ObstacleType.BARREL, 20.0, 10)
	spawn_gate_pair(-205.0, MathGate.OperationType.ADD, 6, MathGate.OperationType.MULTIPLY, 2)

	# 8. Encounter 3: Defense Line before Boss (-240.0)
	# 1 Heavy Shielder + 2 Shooters (dodgeable telegraphed lasers)
	spawn_enemy(Vector3(-2.0, 0, -242.0), 20.0, 8, false, EnemyUnit.EnemyType.SHOOTER)
	spawn_enemy(Vector3(0.0, 0, -238.0), 50.0, 16, false, EnemyUnit.EnemyType.SHIELDER)
	spawn_enemy(Vector3(2.0, 0, -242.0), 20.0, 8, false, EnemyUnit.EnemyType.SHOOTER)

	# 9. Approach Barricades to Boss Arena (-270.0)
	spawn_obstacle(Vector3(-2.1, 0, -268.0), Obstacle.ObstacleType.TIRE_STACK, 15.0, 6)
	spawn_obstacle(Vector3(2.1, 0, -268.0), Obstacle.ObstacleType.TIRE_STACK, 15.0, 6)

	# 10. Roadside environment details
	_build_roadside_decorations()

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
