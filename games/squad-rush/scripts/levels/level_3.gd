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
