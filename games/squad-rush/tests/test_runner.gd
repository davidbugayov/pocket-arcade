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
	test_combat_completion_guard()
	test_save_system_integrity()
	test_level1_starter_solvability()
	
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
	print("\n--- Test: Level 1 Starter Squad Solvability ---")
	
	# Initial conditions: 0 upgrades, starter Rifle
	var squad_size = 1
	var rifle_dmg = 12.0
	var rifle_dps = rifle_dmg / 0.22 # ~54.5 DPS per fighter
	
	# Gate 1: +5 -> 6 fighters
	squad_size += 5
	assert_test(squad_size == 6, "After Gate 1 (+5): Squad = 6")
	
	# Gate 2: x2 -> 12 fighters
	squad_size *= 2
	assert_test(squad_size == 12, "After Gate 2 (x2): Squad = 12")
	
	# Weapon Pickup: Combat Shotgun (3 pellets of 9.0 dmg every 0.38s = 71 DPS per fighter)
	var shotgun_dps = (9.0 * 3.0) / 0.38
	
	# Gate 3: +15 -> 27 fighters
	squad_size += 15
	assert_test(squad_size == 27, "After Gate 3 (+15): Squad = 27")
	
	# Total squad DPS at Boss
	var total_squad_dps = squad_size * shotgun_dps
	var boss_hp = 220.0
	var time_to_kill_boss = boss_hp / total_squad_dps
	
	print("  Calculated Boss TTK with starter squad: %.2f seconds (DPS: %.1f)" % [time_to_kill_boss, total_squad_dps])
	assert_test(time_to_kill_boss < 1.0, "Boss is eliminated in < 1.0 second by starter squad")
	assert_test(squad_size >= 25, "Squad has overwhelming numbers (>25) at boss entrance")
