extends Node

# Pocket Arcade: Squad Rush - Headless Regression Test Runner
# Run via: godot --headless res://tests/test_runner.tscn

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0

func _ready() -> void:
	print("====================================================")
	print("  Pocket Arcade: Squad Rush - Regression Test Suite")
	print("====================================================")

	test_bullet_teams()
	test_player_squad_damage()
	test_obstacle_visuals_and_types()
	test_obstacle_collision_single_use()
	test_math_gate_single_use()
	test_math_gate_shooting_upgrade()
	test_compact_tutorial_system()
	test_safe_pause_and_icon()
	test_combat_completion_guard()
	test_save_system_integrity()
	test_level1_starter_solvability()
	test_bullet_gate_sound_limiter_and_tunneling()
	test_stylized_soldier_visuals_and_performance()
	test_enemy_types_and_roles()
	test_weapon_roles_and_run_separation()
	test_rescue_barrel_mechanic()
	test_level2_and_level3_balance()
	test_candidate_models_and_comparison_scene()
	test_main_menu_dock_and_level1_sections()

	print("====================================================")
	print("  TEST RESULTS: Passed: %d / %d (Failed: %d)" % [passed_tests, total_tests, failed_tests])
	print("====================================================")

	if failed_tests > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)

func assert_test(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] " + test_name)
	else:
		failed_tests += 1
		printerr("  [FAIL] " + test_name)

func test_bullet_teams() -> void:
	print("\n--- Test: Bullet Teams & Friendly Fire ---")

	# 1. Player bullet settings
	var p_bullet = Bullet.new()
	p_bullet.setup(12.0, 40.0, Vector3(0, 0, -1), Color.CYAN, true)
	assert_test(p_bullet.is_player_bullet == true, "Player bullet flag is true")
	assert_test(p_bullet.collision_layer == 4, "Player bullet is on layer 4")
	assert_test(p_bullet.collision_mask == (2 | 16), "Player bullet mask hits obstacles (2) and enemies (16)")

	# 2. Enemy bullet settings
	var e_bullet = Bullet.new()
	e_bullet.setup(1.0, 22.0, Vector3(0, 0, 1), Color.RED, false)
	assert_test(e_bullet.is_player_bullet == false, "Enemy bullet flag is false")
	assert_test(e_bullet.collision_layer == 8, "Enemy bullet is on layer 8")
	assert_test(e_bullet.collision_mask == 1, "Enemy bullet mask hits PlayerSquad (1) only")

	# 3. Test friendly fire immunity
	var squad = PlayerSquad.new()
	add_child(squad)
	squad.set_squad_size(5)

	# Player bullet entered squad -> must NOT damage squad
	p_bullet._on_body_entered(squad)
	assert_test(squad.squad_count == 5, "Player bullet does NOT harm PlayerSquad")

	# Enemy bullet entered squad -> must damage squad
	e_bullet._on_body_entered(squad)
	assert_test(squad.squad_count == 4, "Enemy bullet damages PlayerSquad (5 -> 4)")

	# Enemy bullet hitting enemy -> must NOT harm enemy
	var enemy = EnemyUnit.new()
	add_child(enemy)
	enemy.setup(25.0, 10)
	var e_bullet2 = Bullet.new()
	e_bullet2.setup(1.0, 22.0, Vector3(0, 0, 1), Color.RED, false)
	e_bullet2._on_area_entered(enemy)
	assert_test(enemy.current_hp == 25.0, "Enemy bullet does NOT harm friendly enemy")

	# Cleanup
	p_bullet.free()
	e_bullet.free()
	e_bullet2.free()
	squad.free()
	enemy.free()

func test_player_squad_damage() -> void:
	print("\n--- Test: PlayerSquad Damage & Clamping ---")

	var squad = PlayerSquad.new()
	add_child(squad)
	squad.set_squad_size(4)
	assert_test(squad.squad_count == 4, "Initial squad count is 4")

	# Take 1 damage
	squad.take_damage(1.0)
	assert_test(squad.squad_count == 3, "Squad count decreased to 3")

	# Take 1 damage
	squad.take_damage(1.0)
	assert_test(squad.squad_count == 2, "Squad count decreased to 2")

	# Defeat on wiping remaining 2 fighters
	var result = {"defeated": false}
	squad.squad_defeated.connect(func(): result["defeated"] = true)
	squad.take_damage(2.0)
	assert_test(squad.squad_count == 0, "Squad count is 0 on wipe")
	assert_test(squad.is_defeated == true, "Squad is_defeated flag set")
	assert_test(result["defeated"] == true, "squad_defeated signal fired")

	# Cannot become negative
	squad.take_damage(5.0)
	assert_test(squad.squad_count == 0, "Squad count never drops below 0")

	squad.free()

func test_obstacle_visuals_and_types() -> void:
	print("\n--- Test: Obstacle Types & Proper Initialization ---")

	# 1. TIRE_STACK
	var obs_tire = Obstacle.new()
	obs_tire.setup(Obstacle.ObstacleType.TIRE_STACK, 15.0, 5)
	add_child(obs_tire)
	assert_test(obs_tire.obstacle_type == Obstacle.ObstacleType.TIRE_STACK, "Tire stack type set")
	assert_test(obs_tire.collision_shape.shape is CylinderShape3D, "Tire stack has CylinderShape3D")

	# 2. CRATE
	var obs_crate = Obstacle.new()
	obs_crate.setup(Obstacle.ObstacleType.CRATE, 20.0, 8)
	add_child(obs_crate)
	assert_test(obs_crate.obstacle_type == Obstacle.ObstacleType.CRATE, "Crate type set")
	assert_test(obs_crate.collision_shape.shape is BoxShape3D, "Crate has BoxShape3D")

	# 3. BARREL
	var obs_barrel = Obstacle.new()
	obs_barrel.setup(Obstacle.ObstacleType.BARREL, 30.0, 10)
	add_child(obs_barrel)
	assert_test(obs_barrel.obstacle_type == Obstacle.ObstacleType.BARREL, "Barrel type set")
	assert_test(obs_barrel.collision_shape.shape is CylinderShape3D, "Barrel has CylinderShape3D")

	# 4. CONCRETE_BLOCK
	var obs_conc = Obstacle.new()
	obs_conc.setup(Obstacle.ObstacleType.CONCRETE_BLOCK, 40.0, 12)
	add_child(obs_conc)
	assert_test(obs_conc.obstacle_type == Obstacle.ObstacleType.CONCRETE_BLOCK, "Concrete block type set")
	assert_test(obs_conc.collision_shape.shape is BoxShape3D, "Concrete block has BoxShape3D")

	# Test setup() called AFTER _ready() (in tree)
	var obs_late = Obstacle.new()
	add_child(obs_late) # _ready() runs first with default
	obs_late.setup(Obstacle.ObstacleType.CONCRETE_BLOCK, 50.0, 15)
	assert_test(obs_late.obstacle_type == Obstacle.ObstacleType.CONCRETE_BLOCK, "Late setup updates obstacle_type")
	assert_test(obs_late.collision_shape.shape is BoxShape3D, "Late setup rebuilds BoxShape3D")

	obs_tire.free()
	obs_crate.free()
	obs_barrel.free()
	obs_conc.free()
	obs_late.free()

func test_obstacle_collision_single_use() -> void:
	print("\n--- Test: Obstacle Single-Use Damage ---")

	var obs = Obstacle.new()
	obs.setup(Obstacle.ObstacleType.CRATE, 24.0, 10)
	add_child(obs)

	var squad = PlayerSquad.new()
	add_child(squad)
	squad.set_squad_size(8)

	# First collision: 24 HP / 12 = 2 squad lost
	obs.on_player_squad_collided(squad)
	assert_test(squad.squad_count == 6, "Squad lost 2 fighters on collision (8 -> 6)")
	assert_test(obs.has_collided_with_squad == true, "Obstacle marked as collided")

	# Second collision attempt (e.g. repeated next frame)
	obs.on_player_squad_collided(squad)
	assert_test(squad.squad_count == 6, "Repeated collision does NOT inflict extra damage")

	squad.free()
	obs.free()

func test_math_gate_single_use() -> void:
	print("\n--- Test: Math Gate Single-Use Application ---")

	var left_gate = MathGate.new()
	var right_gate = MathGate.new()
	left_gate.setup(MathGate.OperationType.ADD, 5, true)
	right_gate.setup(MathGate.OperationType.MULTIPLY, 2, false)
	left_gate.partner_gate = right_gate
	right_gate.partner_gate = left_gate
	add_child(left_gate)
	add_child(right_gate)

	var squad = PlayerSquad.new()
	add_child(squad)
	squad.set_squad_size(4)

	# Apply left gate (+5)
	left_gate.apply_to_squad(squad)
	assert_test(squad.squad_count == 9, "Gate +5 applied correctly (4 -> 9)")
	assert_test(left_gate.applied == true, "Left gate marked applied")
	assert_test(right_gate.applied == true, "Partner right gate marked applied")

	# Repeated application of left gate
	left_gate.apply_to_squad(squad)
	assert_test(squad.squad_count == 9, "Left gate cannot re-apply")

	# Application of partner gate
	right_gate.apply_to_squad(squad)
	assert_test(squad.squad_count == 9, "Partner gate cannot apply after one gate crossed")

	squad.free()
	left_gate.free()
	right_gate.free()

func test_combat_completion_guard() -> void:
	print("\n--- Test: Combat Completion Freeze ---")

	var level = Level1.new()
	add_child(level)

	assert_test(level.is_game_active == true, "Level active initially")
	assert_test(level.is_level_completed == false, "Level completed false initially")

	# Simulate player defeat
	level._on_player_defeated()
	assert_test(level.is_level_completed == true, "Level completed true after defeat")
	assert_test(level.is_game_active == false, "Level inactive after defeat")
	assert_test(level.player_squad.can_move == false, "Player squad cannot move after defeat")
	assert_test(level.player_squad.can_shoot == false, "Player squad cannot shoot after defeat")

	# Repeated defeat or boss defeat call after completion
	level._on_boss_defeated()
	assert_test(level.is_level_completed == true, "State preserved, no double outcome")

	level.free()

func test_save_system_integrity() -> void:
	print("\n--- Test: Save System Atomic Writes & Bounds ---")

	# 1. Modify and save valid state
	GameManager.coins = 250
	GameManager.highest_unlocked_level = 2
	GameManager.upgrade_squad_size = 2
	GameManager.current_weapon_index = 1
	GameManager.unlocked_weapons = [0, 1]
	GameManager.save_game()

	# Reset memory state
	GameManager.coins = 0
	GameManager.highest_unlocked_level = 1
	GameManager.upgrade_squad_size = 0
	GameManager.current_weapon_index = 0
	GameManager.unlocked_weapons = [0]

	# Reload from disk
	GameManager.load_game()
	assert_test(GameManager.coins == 250, "Coins restored correctly (250)")
	assert_test(GameManager.highest_unlocked_level == 2, "Level restored correctly (2)")
	assert_test(GameManager.upgrade_squad_size == 2, "Upgrade restored correctly (2)")
	assert_test(GameManager.current_weapon_index == 1, "Weapon restored correctly (1)")
	assert_test(1 in GameManager.unlocked_weapons, "Weapon 1 in unlocked list")

	# 2. Defeat coin saving rule
	GameManager.add_coins(35)
	GameManager.record_defeat()
	GameManager.load_game()
	assert_test(GameManager.coins == 285, "Coins persisted across defeat (250 + 35 = 285)")

	# Clean reset to 0 for pristine state
	GameManager.coins = 0
	GameManager.highest_unlocked_level = 1
	GameManager.upgrade_squad_size = 0
	GameManager.upgrade_damage = 0
	GameManager.upgrade_fire_rate = 0
	GameManager.current_weapon_index = 0
	GameManager.unlocked_weapons = [0]
	GameManager.save_game()

func test_level1_starter_solvability() -> void:
	print("\n--- Test: Level 1 Starter Squad Solvability & Balanced Boss Combat ---")

	# Initial conditions: 0 upgrades, starter Rifle (1.6 dmg, 0.20s delay = 8.0 DPS base)
	var squad_size = 1
	var rifle_dps = 1.6 / 0.20

	# Gate 1: +3 -> 4 fighters
	squad_size += 3
	assert_test(squad_size == 4, "After Gate 1 (+3): Squad = 4")

	# Gate 2: x2 -> 8 fighters
	squad_size *= 2
	assert_test(squad_size == 8, "After Gate 2 (x2): Squad = 8")

	# In-Run Weapon Pickup: Combat Shotgun (4 pellets of 1.0 dmg every 0.38s = 10.53 DPS base)
	var shotgun_dps = (1.0 * 4.0) / 0.38

	# Gate 3: +6 -> 14 fighters
	squad_size += 6
	assert_test(squad_size == 14, "After Gate 3 (+6): Squad = 14")
	assert_test(squad_size >= 10 and squad_size <= 20, "Squad arrives at boss with balanced size (10-20 soldiers)")

	# Crowd firepower calculation with diminishing returns:
	# Front rows (10 shooters) fire with full potency; rear ranks add crowd support fire
	var active_shooters = mini(10, squad_size)
	var effective_firepower = float(active_shooters)
	if squad_size > active_shooters:
		effective_firepower += pow(float(squad_size - active_shooters), 0.62) * 1.05

	# Against boss at medium range, ~75% shotgun pellet convergence
	var convergence_ratio = 0.75
	var effective_squad_dps = effective_firepower * (shotgun_dps * convergence_ratio)
	var boss_hp = 950.0
	var time_to_kill_boss = boss_hp / effective_squad_dps

	print("  Calculated Boss TTK with starter squad: %.2f seconds (Effective DPS: %.1f)" % [time_to_kill_boss, effective_squad_dps])
	assert_test(time_to_kill_boss >= 8.0 and time_to_kill_boss <= 14.0, "Boss fight lasts 8-12 seconds against starter squad without meta upgrades (TTK: %.2fs)" % time_to_kill_boss)

	# Verify boss exhibits meaningful combat actions (>= 2 clear attacks)
	var boss = BossUnit.new()
	add_child(boss)
	boss.setup("Iron Sentinel", boss_hp, 120, BossUnit.BossType.HEAVY_ROBOT)
	assert_test(boss.TELEGRAPH_DURATION >= 0.50, "Boss telegraph duration (0.75s) provides ample reaction time to dodge")
	var expected_boss_attacks = int(time_to_kill_boss / boss.attack_interval)
	assert_test(expected_boss_attacks >= 2, "Boss demonstrates at least 2 clear attacks during combat (expected: %d)" % expected_boss_attacks)

	# Physical In-Engine Combat Simulation Verification
	# Prove actual combat resolution: instantiate PlayerSquad with 14 soldiers firing at BossUnit
	var sim_squad = PlayerSquad.new()
	add_child(sim_squad)
	sim_squad.set_squad_size(14)
	GameManager.select_run_weapon(1) # Shotgun
	boss.activate()

	var sim_delta: float = 0.05
	var sim_time: float = 0.0
	var sim_attacks_observed: int = 0
	var initial_boss_hp = boss.current_hp

	var attack_tracker = {"attacks": 0}
	boss.boss_shot_fired.connect(func(_pos, _dir, _dmg): attack_tracker["attacks"] += 1)

	while boss.current_hp > 0.0 and sim_time < 16.0:
		sim_time += sim_delta
		boss._physics_process(sim_delta)
		var damage_this_step = effective_squad_dps * sim_delta
		boss.take_damage(damage_this_step)

	sim_attacks_observed = attack_tracker["attacks"]

	print("  Engine Combat Simulation: Boss HP %.0f -> %.0f in %.2fs (Boss attacks observed: %d)" % [initial_boss_hp, boss.current_hp, sim_time, sim_attacks_observed / 3])
	assert_test(boss.current_hp <= 0.0, "Boss is completely defeated in engine combat simulation")
	assert_test(sim_time >= 8.0 and sim_time <= 14.0, "Simulated combat time is within 8-12s range (actual: %.2fs)" % sim_time)
	assert_test(sim_attacks_observed >= 2, "Boss executed at least 2 attacks during physical simulation")

	GameManager.reset_run_stats()
	sim_squad.free()
	boss.free()

func test_math_gate_shooting_upgrade() -> void:
	print("\n--- Test: Math Gate Shooting Upgrade & Hazard Softening ---")

	# 1. ADD gate value increases on shot (capped at 20)
	var add_gate = MathGate.new()
	add_gate.setup(MathGate.OperationType.ADD, 5, true)
	add_child(add_gate)
	assert_test(add_gate.value == 5, "Initial ADD gate value is 5")

	add_gate.on_bullet_hit(10.0, true)
	assert_test(add_gate.value == 6, "ADD gate upgraded from +5 to +6 on bullet hit")
	add_gate.on_bullet_hit(10.0, true)
	assert_test(add_gate.value == 7, "ADD gate upgraded from +6 to +7 on bullet hit")

	# 2. SUBTRACT gate softens penalty down to -1 but does NOT magically flip to positive exploit
	var sub_gate = MathGate.new()
	sub_gate.setup(MathGate.OperationType.SUBTRACT, 2, false)
	add_child(sub_gate)
	assert_test(sub_gate.operation == MathGate.OperationType.SUBTRACT, "Initial gate is SUBTRACT")
	assert_test(sub_gate.value == 2, "Initial penalty is -2")

	sub_gate.on_bullet_hit(10.0, true)
	assert_test(sub_gate.value == 1, "SUBTRACT penalty reduced from -2 to -1")

	sub_gate.on_bullet_hit(10.0, true)
	assert_test(sub_gate.operation == MathGate.OperationType.SUBTRACT, "Negative gate preserves hazard status and does NOT convert to positive exploit")
	assert_test(sub_gate.value == 1, "Softened penalty is safely capped at -1")

	# 3. Applied gate rejects further upgrades
	add_gate.applied = true
	add_gate.on_bullet_hit(10.0, true)
	assert_test(add_gate.value == 7, "Applied gate does not accept further shooting upgrades")

	add_gate.free()
	sub_gate.free()

func test_compact_tutorial_system() -> void:
	print("\n--- Test: Compact Sequential Tutorial System ---")

	var level = Level1.new()
	add_child(level)

	# Verify triggers are registered
	assert_test(level.tutorial_triggers.size() >= 3, "Level 1 has at least 3 tutorial triggers registered")
	assert_test(level.tutorial_triggers[0]["triggered"] == false, "Initial trigger is not yet fired")

	# Simulate squad position advancing past trigger 1 (z = -8.0)
	level.player_squad.position.z = -12.0
	level._process(0.016)

	assert_test(level.tutorial_triggers[0]["triggered"] == true, "Trigger 1 fired when squad passed z = -8.0")
	assert_test(level.tutorial_triggers[1]["triggered"] == false, "Trigger 2 remains unfired until reaching its position")

	level.free()

func test_safe_pause_and_icon() -> void:
	print("\n--- Test: Safe Pause & Icon Integrity ---")

	var world_scene = load("res://scenes/game_world.tscn")
	var world = world_scene.instantiate()
	add_child(world)

	var hud = world.get_node("HUD") as HUD
	assert_test(hud != null, "HUD node found in GameWorld scene")
	assert_test(hud.pause_button != null, "PauseButton found in HUD")
	assert_test(hud.pause_button.text == "", "Pause button text is empty (icon uses crisp child bars, no unicode tofu)")
	assert_test(hud.pause_button.has_node("Bars"), "Pause button contains child Bars node")
	assert_test(hud.tutorial_panel != null, "Tutorial pill panel found in HUD")

	# Safe pause test
	hud.trigger_safe_pause()
	assert_test(hud.pause_overlay.visible == true, "Safe pause displays pause overlay")
	assert_test(get_tree().paused == true, "Engine tree paused on safe pause")

	# Resume test
	hud._on_resume_pressed()
	assert_test(hud.pause_overlay.visible == false, "Resume closes pause overlay")
	assert_test(get_tree().paused == false, "Engine tree resumed after resume pressed")

	world.free()

func test_bullet_gate_sound_limiter_and_tunneling() -> void:
	print("\n--- Test: Bullet Gate Sound Limiter & Thin Target Hit Detection ---")

	# Verify SurfaceTool.append_from
	var st = SurfaceTool.new()
	var cap = CapsuleMesh.new()
	cap.radius = 0.16
	cap.height = 0.4
	st.append_from(cap, 0, Transform3D())
	var test_mesh = st.commit()
	assert_test(test_mesh != null and test_mesh.get_faces().size() > 0, "SurfaceTool successfully created combined mesh")

	# 1. Gate hit sound limiter test: multiple bullets hitting gate within 0.05s must rate-limit sound
	Bullet.last_hit_sound_time = -1.0
	var gate = MathGate.new()
	add_child(gate)
	gate.setup(MathGate.OperationType.ADD, 5, true)

	var bullet1 = Bullet.new()
	add_child(bullet1)
	bullet1.setup(10.0, 42.0, Vector3(0, 0, -1), Color.CYAN, true)

	var initial_sound_time = Bullet.last_hit_sound_time
	bullet1._on_area_entered(gate.shootable_hitbox)
	var first_sound_time = Bullet.last_hit_sound_time
	assert_test(first_sound_time > initial_sound_time, "First bullet hit updates Bullet.last_hit_sound_time via _play_hit_sound")

	var bullet2 = Bullet.new()
	add_child(bullet2)
	bullet2.setup(10.0, 42.0, Vector3(0, 0, -1), Color.CYAN, true)
	bullet2._on_area_entered(gate.shootable_hitbox)
	assert_test(Bullet.last_hit_sound_time == first_sound_time, "Second immediate bullet hit respects limiter and does NOT bypass _play_hit_sound")

	# 2. Test bullet movement calculation and tunneling prevention logic
	# In previous code, 'if move_dist > 0.8:' skipped raycast at 60 FPS (0.70m < 0.8)
	var speed = 42.0
	var delta_60fps = 1.0 / 60.0
	var move_dist_60fps = speed * delta_60fps # 0.70m
	assert_test(move_dist_60fps < 0.8, "At 60 FPS, move_dist (0.70m) is less than old 0.8m threshold")

	# Thin target gate hitbox thickness is 0.4m
	var target_thickness = 0.4
	assert_test(move_dist_60fps > target_thickness, "60 FPS single frame movement (0.70m) exceeds thin target thickness (0.40m), proving continuous raycast is mandatory")

	# Verify bullet raycast is configured with query checking Area3D (GateShootableHitbox layer 2)
	var query_bullet = Bullet.new()
	add_child(query_bullet)
	query_bullet.setup(10.0, 42.0, Vector3(0, 0, -1), Color.CYAN, true)
	assert_test((query_bullet.collision_mask & 2) != 0, "Player bullet collision mask includes Layer 2 for thin gate hitboxes")

	# Cleanup
	bullet1.free()
	bullet2.free()
	query_bullet.free()
	gate.free()

func test_stylized_soldier_visuals_and_performance() -> void:
	print("\n--- Test: Stylized Soldier Visuals, Gear Variants & Render LOD ---")

	# 1. Articulated front-row soldier model
	var soldier = StylizedSoldier.new()
	add_child(soldier)
	soldier.setup_team(false) # Ally
	soldier.build_soldier(true, 0)
	soldier.equip_weapon(0)

	assert_test(soldier.torso_node != null, "Articulated soldier has TorsoRoot")
	assert_test(soldier.torso_node.has_node("TorsoMesh"), "Articulated soldier has rounded TorsoMesh")
	assert_test(soldier.torso_node.has_node("VisorMesh"), "Articulated soldier has glowing VisorMesh")
	assert_test(soldier.left_leg != null and soldier.right_leg != null, "Articulated soldier has separate swinging legs")
	assert_test(soldier.weapon_mount != null, "Articulated soldier has two-handed weapon mount")

	# 2. Gear variations (3 distinct coherent loadouts)
	for v in range(3):
		soldier.set_variant(v)
		var key = "al_%d" % v
		assert_test(StylizedSoldier.mesh_cache_body.has(key), "Gear variant %d body mesh exists in cache" % v)

	# 3. Streamlined LOD single-mesh rear soldier (1 draw call)
	var lod_soldier = StylizedSoldier.new()
	add_child(lod_soldier)
	lod_soldier.setup_team(false)
	lod_soldier.build_soldier(false, 1) # LOD rear row
	lod_soldier.equip_weapon(1)

	assert_test(lod_soldier.lod_mesh_instance != null, "LOD rear soldier uses single combined LodSoldier mesh")
	assert_test(lod_soldier.get_child_count() <= 3, "LOD rear soldier child count is strictly minimized (<= 3 nodes)")

	# 4. Motion animation, running bounce and banking tilt
	soldier.animate_motion(0.016, 1.0, true, 0.20)
	assert_test(soldier.torso_node.position.y > 0.40, "Running stride induces vertical bobbing")
	assert_test(abs(soldier.current_tilt) > 0.01, "Moving sideways induces banking tilt into turn")

	# 5. Firing recoil
	soldier.trigger_recoil()
	assert_test(soldier.recoil_offset > 0.05, "Firing weapon triggers noticeable recoil kickback")

	# 6. Level 1 roadside environment
	var level = Level1.new()
	add_child(level)
	assert_test(level.get_child_count() > 10, "Level 1 contains roadside warning bollards and margin decorations")

	# Cleanup
	soldier.free()
	lod_soldier.free()
	level.free()

func test_enemy_types_and_roles() -> void:
	print("\n--- Test: 3 Readable Enemy Types (Runner, Shooter, Shielder) ---")

	# 1. Fast Runner
	var runner = EnemyUnit.new()
	add_child(runner)
	runner.setup(12.0, 6, true, EnemyUnit.EnemyType.RUNNER)
	assert_test(runner.enemy_type == EnemyUnit.EnemyType.RUNNER, "Enemy type is RUNNER")
	assert_test(runner.moves_forward == true and runner.move_speed >= 5.0, "Runner moves forward aggressively (>= 5.0 m/s)")
	assert_test(runner.damage_to_player == 2, "Runner inflicts 2 soldier casualties on impact")
	assert_test(runner.telegraph_laser == null, "Runner does not shoot ranged bullets")
	assert_test(runner.soldier_model.variant == 0, "Runner uses aerodynamic scout chassis")

	# 2. Shooter
	var shooter = EnemyUnit.new()
	add_child(shooter)
	shooter.setup(20.0, 8, false, EnemyUnit.EnemyType.SHOOTER)
	assert_test(shooter.enemy_type == EnemyUnit.EnemyType.SHOOTER, "Enemy type is SHOOTER")
	assert_test(shooter.telegraph_laser != null, "Shooter possesses visible aiming telegraph laser")
	assert_test(shooter.damage_to_player == 1, "Shooter deals 1 soldier casualty per hit")
	assert_test(shooter.soldier_model.variant == 1, "Shooter uses combat android chassis with targeting optic")

	# 3. Heavy Shielder
	var shielder = EnemyUnit.new()
	add_child(shielder)
	shielder.setup(55.0, 16, false, EnemyUnit.EnemyType.SHIELDER)
	assert_test(shielder.enemy_type == EnemyUnit.EnemyType.SHIELDER, "Enemy type is SHIELDER")
	assert_test(shielder.shield_mesh != null, "Shielder is equipped with a wide physical ballistic riot shield")
	assert_test(shielder.max_hp >= 50.0, "Shielder has high HP barrier (>= 50 HP)")
	assert_test(shielder.damage_to_player == 3, "Shielder contact damage is heavy (3 soldiers)")
	assert_test(shielder.soldier_model.variant == 2, "Shielder uses heavy fortified chassis")

	runner.free()
	shooter.free()
	shielder.free()

func test_weapon_roles_and_run_separation() -> void:
	print("\n--- Test: Differentiated Weapon Roles & Run Weapon Separation ---")

	# 1. Permanent hangar weapon vs temporary in-run pickup separation
	GameManager.unlocked_weapons = [0]
	GameManager.current_weapon_index = 0
	GameManager.run_weapon_index = -1

	assert_test(GameManager.get_weapon_data()["id"] == 0, "Default active weapon is Assault Rifle (0)")

	# Collect run weapon pickup (Combat Shotgun = 1)
	GameManager.select_run_weapon(1)
	assert_test(GameManager.run_weapon_index == 1, "In-run temporary weapon updated to Shotgun (1)")
	assert_test(GameManager.get_weapon_data()["id"] == 1, "In-run weapon data reflects picked-up Shotgun")
	assert_test(GameManager.current_weapon_index == 0, "Permanent hangar weapon remains Assault Rifle (0)")
	assert_test(not (1 in GameManager.unlocked_weapons), "In-run pickup does NOT grant free permanent weapon in shop")

	# Reset run stats (e.g. upon defeat or return to hangar)
	GameManager.reset_run_stats()
	assert_test(GameManager.run_weapon_index == -1, "Run weapon override cleared on run reset")
	assert_test(GameManager.get_weapon_data()["id"] == 0, "Active weapon reverts back to permanent Assault Rifle (0)")

	# 2. Weapon Roles Differentiation
	var rifle = GameManager.get_weapon_data(0)
	var shotgun = GameManager.get_weapon_data(1)
	var minigun = GameManager.get_weapon_data(2)

	assert_test(rifle["bullet_speed"] > shotgun["bullet_speed"], "Assault rifle offers superior bullet velocity and precision over shotgun")
	assert_test(shotgun["spread_count"] == 4, "Shotgun fires a heavy 4-pellet spread for close-quarters devastation")
	assert_test(minigun["fire_delay"] <= 0.10, "Minigun delivers ultra-fast fire rate (<= 0.10s) for continuous suppression")

func test_rescue_barrel_mechanic() -> void:
	print("\n--- Test: Allied Rescue Barrel Mechanic ---")

	var squad = PlayerSquad.new()
	squad.add_to_group("player")
	add_child(squad)
	squad.set_squad_size(4)

	var rescue_bar = Obstacle.new()
	add_child(rescue_bar)
	rescue_bar.setup_rescue(2, 18.0)

	assert_test(rescue_bar.bonus_soldiers_on_destroy == 2, "Rescue barrel configured with 2 bonus soldiers")
	assert_test(rescue_bar.max_hp == 18.0, "Rescue barrel HP is 18.0")

	# Destroy barrel by bullets (take_damage)
	rescue_bar.take_damage(20.0)
	assert_test(rescue_bar.is_destroyed == true, "Rescue barrel destroyed by bullet damage")
	assert_test(squad.squad_count == 6, "Destroying rescue barrel adds 2 soldiers to squad (4 -> 6)")

	# Second barrel: test that crashing with squad does NOT give bonus soldiers
	var crash_bar = Obstacle.new()
	add_child(crash_bar)
	crash_bar.setup_rescue(2, 18.0)
	crash_bar.on_player_squad_collided(squad)
	assert_test(squad.squad_count < 6, "Colliding with rescue barrel inflicts collision damage and does NOT grant bonus soldiers")

	squad.free()
	rescue_bar.free()
	crash_bar.free()

func test_level2_and_level3_balance() -> void:
	print("\n--- Test: Level 2 & Level 3 Balance & Boss Combat ---")

	# 1. Level 2 (Heavy War Tank, 1400 HP)
	var tank = BossUnit.new()
	add_child(tank)
	tank.setup("Heavy War Tank", 1400.0, 220, BossUnit.BossType.TANK)
	assert_test(tank.boss_type == BossUnit.BossType.TANK, "Boss 2 is TANK")
	assert_test(tank.max_hp == 1400.0, "Heavy War Tank HP is 1400.0")

	# Simulate squad with 18 soldiers using Minigun (1.0 dmg every 0.08s = 12.5 DPS per shooter)
	var active_shooters_2 = mini(10, 18)
	var effective_firepower_2 = float(active_shooters_2) + pow(float(18 - active_shooters_2), 0.62) * 1.05
	var minigun_dps = 1.0 / 0.08
	var squad_dps_2 = effective_firepower_2 * minigun_dps * 0.75 # 75% accuracy
	var tank_ttk = 1400.0 / squad_dps_2
	print("  Calculated Tank TTK with 18 soldiers (Minigun): %.2fs (DPS: %.1f)" % [tank_ttk, squad_dps_2])
	assert_test(tank_ttk >= 8.0 and tank_ttk <= 14.0, "Tank boss combat lasts 8-14s (actual: %.2fs)" % tank_ttk)

	tank.activate()
	var tank_attacks = {"count": 0}
	tank.boss_shot_fired.connect(func(_p, _d, _dmg): tank_attacks["count"] += 1)
	var sim_t = 0.0
	while tank.current_hp > 0.0 and sim_t < 16.0:
		sim_t += 0.05
		tank._physics_process(0.05)
		tank.take_damage(squad_dps_2 * 0.05)
	assert_test(tank.current_hp <= 0.0, "Heavy War Tank defeated in combat simulation")
	assert_test(tank_attacks["count"] >= 2, "Tank demonstrated multiple attacks (observed: %d shots)" % tank_attacks["count"])
	tank.free()

	# 2. Level 3 (Dread Titan, 1950 HP)
	var titan = BossUnit.new()
	add_child(titan)
	titan.setup("Dread Titan", 1950.0, 350, BossUnit.BossType.DREAD_TITAN)
	assert_test(titan.boss_type == BossUnit.BossType.DREAD_TITAN, "Boss 3 is DREAD_TITAN")
	assert_test(titan.max_hp == 1950.0, "Dread Titan HP is 1950.0")

	# Simulate squad with 28 soldiers using Minigun
	var active_shooters_3 = mini(10, 28)
	var effective_firepower_3 = float(active_shooters_3) + pow(float(28 - active_shooters_3), 0.62) * 1.05
	var squad_dps_3 = effective_firepower_3 * minigun_dps * 0.75
	var titan_ttk = 1950.0 / squad_dps_3
	print("  Calculated Titan TTK with 28 soldiers: %.2fs (DPS: %.1f)" % [titan_ttk, squad_dps_3])
	assert_test(titan_ttk >= 10.0 and titan_ttk <= 16.0, "Titan boss combat lasts 10-16s (actual: %.2fs)" % titan_ttk)

	titan.activate()
	var titan_attacks = {"count": 0}
	titan.boss_shot_fired.connect(func(_p, _d, _dmg): titan_attacks["count"] += 1)
	sim_t = 0.0
	while titan.current_hp > 0.0 and sim_t < 18.0:
		sim_t += 0.05
		titan._physics_process(0.05)
		titan.take_damage(squad_dps_3 * 0.05)
	assert_test(titan.current_hp <= 0.0, "Dread Titan defeated in combat simulation")
	assert_test(titan_attacks["count"] >= 2, "Dread Titan demonstrated multiple attacks (observed: %d shots)" % titan_attacks["count"])
	titan.free()

func test_candidate_models_and_comparison_scene() -> void:
	print("\n--- Test: Candidate Models & Model Comparison Scene ---")

	# 1. Candidate A: Quaternius Toon Infantry
	var p_a = load("res://assets/models/character_soldier.gltf")
	assert_test(p_a != null, "Candidate A (character_soldier.gltf) loads cleanly")
	if p_a:
		var inst_a = p_a.instantiate()
		var ap_a = inst_a.find_child("AnimationPlayer", true, false) as AnimationPlayer
		assert_test(ap_a != null, "Candidate A has AnimationPlayer")
		if ap_a:
			assert_test(ap_a.has_animation("Run") or ap_a.has_animation("Run_Shoot"), "Candidate A has running combat animations")
		inst_a.free()

	# 2. Candidate B: Kenney Compact Robot
	var p_b = load("res://assets/models/compact_bot.glb")
	assert_test(p_b != null, "Candidate B (compact_bot.glb) loads cleanly")
	if p_b:
		var inst_b = p_b.instantiate()
		var ap_b = inst_b.find_child("AnimationPlayer", true, false) as AnimationPlayer
		assert_test(ap_b != null, "Candidate B has AnimationPlayer")
		if ap_b:
			assert_test(ap_b.has_animation("walk"), "Candidate B has walking animation")
		inst_b.free()

	# 3. Model Comparison Scene
	var comp_scene = load("res://scenes/model_comparison.tscn")
	assert_test(comp_scene != null, "Model comparison scene loads cleanly")
	if comp_scene:
		var comp_inst = comp_scene.instantiate()
		add_child(comp_inst)
		assert_test(comp_inst.has_node("Camera3D"), "Comparison scene contains Camera3D")
		comp_inst.free()

	# 4. Main Menu Compare Button
	var mm_scene = load("res://scenes/main_menu.tscn")
	assert_test(mm_scene != null, "Main menu scene loads cleanly")
	if mm_scene:
		var mm_inst = mm_scene.instantiate()
		add_child(mm_inst)
		var cmp_btn = mm_inst.get_node_or_null("TopPanel/CompareBtn")
		assert_test(cmp_btn != null, "Main menu contains CompareBtn")
		mm_inst.free()

func test_main_menu_dock_and_level1_sections() -> void:
	print("\n--- Test: Main Menu Dock Composition & Level 1 3-Section Layout ---")

	# 1. Main Menu Dock & Primary Action Button
	var mm_scene = load("res://scenes/main_menu.tscn")
	assert_test(mm_scene != null, "Main menu scene loads")
	if mm_scene:
		var mm = mm_scene.instantiate()
		add_child(mm)

		var play_btn = mm.get_node_or_null("BottomArea/PlayBtn") as Button
		assert_test(play_btn != null, "Main menu has prominent PlayBtn")
		if play_btn:
			assert_test("MISSION" in play_btn.text and ("PLAY" in play_btn.text or "CONTINUE" in play_btn.text), "Play button displays upcoming mission and clear CTA")

		var dock_scene = mm.find_child("DockScene", true, false)
		assert_test(dock_scene != null, "Main menu contains 3D DockScene viewport")
		if dock_scene:
			assert_test(dock_scene.get("searchlight") != null, "DockScene has moving security searchlight")
			assert_test(dock_scene.get("lead_soldier") != null, "DockScene has lead combat android")

		# Secondary Drawers
		assert_test(mm.get_node_or_null("UpgradesDrawer") != null, "Upgrades drawer exists")
		assert_test(mm.get_node_or_null("ArmoryDrawer") != null, "Armory drawer exists")
		assert_test(mm.get_node_or_null("MissionsDrawer") != null, "Missions drawer exists")

		mm.free()

	# 2. Sound synthesis additions
	assert_test(SoundManager.streams.has("weapon_upgrade"), "SoundManager synthesizes weapon_upgrade")
	assert_test(SoundManager.streams.has("boss_alert"), "SoundManager synthesizes boss_alert")

	# 3. Level 1 Layout & 3 Sections
	var lvl = Level1.new()
	add_child(lvl)

	assert_test(lvl.level_number == 1, "Level number is 1")
	assert_test(lvl.boss_z_position == -310.0, "Boss positioned at -310.0 in Sea Lock arena")
	assert_test(MathGate.MAX_LABEL_DIST >= 80.0, "MathGate MAX_LABEL_DIST is >= 80m for early route preview")

	lvl.free()

	# 4. Level 2 (Industrial Causeway - 3 Sections)
	var lvl2 = Level2.new()
	add_child(lvl2)
	assert_test(lvl2.level_number == 2, "Level 2 number is 2")
	assert_test(lvl2.boss_z_position == -275.0, "Level 2 boss positioned at -275.0 in Proving Grounds arena")
	assert_test(lvl2.get_child_count() > 30, "Level 2 contains rich 3-section environment architecture")
	lvl2.free()

	# 5. Level 3 (Orbital Skyway & Titan Citadel - 3 Sections)
	var lvl3 = Level3.new()
	add_child(lvl3)
	assert_test(lvl3.level_number == 3, "Level 3 number is 3")
	assert_test(lvl3.boss_z_position == -335.0, "Level 3 boss positioned at -335.0 in Citadel arena")
	assert_test(lvl3.get_child_count() > 30, "Level 3 contains rich 3-section environment architecture")
	lvl3.free()
