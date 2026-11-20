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
