extends LevelBase

class_name Level2

func _init() -> void:
	level_number = 2
	level_length = 310.0
	boss_z_position = -265.0

func _setup_boss() -> void:
	boss = BossUnit.new()
	boss.position = Vector3(0, 0, boss_z_position)
	add_child(boss)
	boss.setup("Heavy War Tank", 600.0, 200, BossUnit.BossType.TANK)
	boss.move_speed = 3.5
	boss.attack_interval = 1.4
	boss.boss_hp_changed.connect(func(cur, m): if hud and hud.has_method("update_boss_hp"): hud.update_boss_hp(cur, m))
	boss.boss_shot_fired.connect(_on_boss_shot_fired)
	boss.boss_defeated.connect(_on_boss_defeated)

func _build_level_layout() -> void:
	spawn_tutorial_text(-10.0, "DODGE RED GATES!")

	# Obstacles
	spawn_obstacle(Vector3(-1.8, 0, -25.0), Obstacle.ObstacleType.CRATE, 25.0, 8)
	spawn_obstacle(Vector3(1.8, 0, -25.0), Obstacle.ObstacleType.CRATE, 25.0, 8)

	# Gate 1: +10 (left) vs -5 (right)
	spawn_gate_pair(-50.0, MathGate.OperationType.ADD, 10, MathGate.OperationType.SUBTRACT, 5)

	# Section 2: Concrete barriers
	spawn_obstacle(Vector3(-2.2, 0, -80.0), Obstacle.ObstacleType.CONCRETE_BLOCK, 35.0, 12)
	spawn_obstacle(Vector3(0.0, 0, -82.0), Obstacle.ObstacleType.BARREL, 30.0, 10)
	spawn_obstacle(Vector3(2.2, 0, -80.0), Obstacle.ObstacleType.CONCRETE_BLOCK, 35.0, 12)

	# Gate 2: -8 (left) vs +15 (right)
	spawn_gate_pair(-115.0, MathGate.OperationType.SUBTRACT, 8, MathGate.OperationType.ADD, 15)

	# Section 3: Patrol group advancing
	spawn_enemy(Vector3(-1.8, 0, -145.0), 30.0, 12, true)
	spawn_enemy(Vector3(-0.6, 0, -148.0), 30.0, 12, true)
	spawn_enemy(Vector3(0.6, 0, -148.0), 30.0, 12, true)
	spawn_enemy(Vector3(1.8, 0, -145.0), 30.0, 12, true)

	# Gate 3: x2 (left) vs /2 (right)
	spawn_gate_pair(-180.0, MathGate.OperationType.MULTIPLY, 2, MathGate.OperationType.DIVIDE, 2)

	# Section 4: Heavy Barricade
	spawn_obstacle(Vector3(-2.0, 0, -210.0), Obstacle.ObstacleType.TIRE_STACK, 45.0, 15)
	spawn_obstacle(Vector3(2.0, 0, -210.0), Obstacle.ObstacleType.TIRE_STACK, 45.0, 15)

	# Gate 4: +20 vs x3
	spawn_gate_pair(-235.0, MathGate.OperationType.ADD, 20, MathGate.OperationType.MULTIPLY, 3)
