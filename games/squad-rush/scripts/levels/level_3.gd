extends LevelBase

class_name Level3

func _init() -> void:
	level_number = 3
	level_length = 370.0
	boss_z_position = -325.0

func _setup_boss() -> void:
	boss = BossUnit.new()
	boss.position = Vector3(0, 0, boss_z_position)
	add_child(boss)
	boss.setup("Dread Titan", 1200.0, 350, BossUnit.BossType.DREAD_TITAN)
	boss.move_speed = 4.0
	boss.attack_interval = 1.0
	boss.boss_hp_changed.connect(func(cur, m): if hud and hud.has_method("update_boss_hp"): hud.update_boss_hp(cur, m))
	boss.boss_shot_fired.connect(_on_boss_shot_fired)
	boss.boss_defeated.connect(_on_boss_defeated)

func _build_level_layout() -> void:
	spawn_tutorial_text(-10.0, "FINAL ASSAULT: DREAD TITAN")

	# Dense initial obstacles
	spawn_obstacle(Vector3(-2.2, 0, -25.0), Obstacle.ObstacleType.CONCRETE_BLOCK, 40.0, 10)
	spawn_obstacle(Vector3(0.0, 0, -25.0), Obstacle.ObstacleType.BARREL, 35.0, 10)
	spawn_obstacle(Vector3(2.2, 0, -25.0), Obstacle.ObstacleType.CONCRETE_BLOCK, 40.0, 10)

	# Gate 1: +15 vs +10
	spawn_gate_pair(-55.0, MathGate.OperationType.ADD, 15, MathGate.OperationType.ADD, 10)

	# Armored Crate Wall
	spawn_obstacle(Vector3(-1.8, 0, -90.0), Obstacle.ObstacleType.CRATE, 55.0, 15)
	spawn_obstacle(Vector3(1.8, 0, -90.0), Obstacle.ObstacleType.CRATE, 55.0, 15)

	# Gate 2: x2 vs -10
	spawn_gate_pair(-125.0, MathGate.OperationType.MULTIPLY, 2, MathGate.OperationType.SUBTRACT, 10)

	# Elite Guard Squad
	spawn_enemy(Vector3(-2.0, 0, -160.0), 45.0, 15, true)
	spawn_enemy(Vector3(-0.7, 0, -162.0), 45.0, 15, true)
	spawn_enemy(Vector3(0.7, 0, -162.0), 45.0, 15, true)
	spawn_enemy(Vector3(2.0, 0, -160.0), 45.0, 15, true)

	# Gate 3: -12 vs +25
	spawn_gate_pair(-195.0, MathGate.OperationType.SUBTRACT, 12, MathGate.OperationType.ADD, 25)

	# Fortified Barricade
	spawn_obstacle(Vector3(-2.5, 0, -230.0), Obstacle.ObstacleType.CONCRETE_BLOCK, 60.0, 20)
	spawn_obstacle(Vector3(0.0, 0, -230.0), Obstacle.ObstacleType.BARREL, 50.0, 20)
	spawn_obstacle(Vector3(2.5, 0, -230.0), Obstacle.ObstacleType.CONCRETE_BLOCK, 60.0, 20)

	# Gate 4: x3 vs +30
	spawn_gate_pair(-265.0, MathGate.OperationType.MULTIPLY, 3, MathGate.OperationType.ADD, 30)

	# Final Guard Line before Titan
	spawn_enemy(Vector3(-1.5, 0, -295.0), 50.0, 20)
	spawn_enemy(Vector3(0.0, 0, -297.0), 60.0, 25)
	spawn_enemy(Vector3(1.5, 0, -295.0), 50.0, 20)
