extends LevelBase

class_name Level1

func _init() -> void:
	level_number = 1
	level_length = 250.0
	boss_z_position = -210.0

func _setup_boss() -> void:
	boss = BossUnit.new()
	boss.position = Vector3(0, 0, boss_z_position)
	add_child(boss)
	boss.setup("Iron Sentinel", 250.0, 100)
	boss.boss_hp_changed.connect(func(cur, m): if hud and hud.has_method("update_boss_hp"): hud.update_boss_hp(cur, m))
	boss.boss_shot_fired.connect(_on_boss_shot_fired)
	boss.boss_defeated.connect(_on_boss_defeated)

func _build_level_layout() -> void:
	# Tutorial Prompts
	spawn_tutorial_text(-10.0, "SWIPE LEFT & RIGHT TO MOVE")
	spawn_tutorial_text(-40.0, "SHOOT TO BREAK TARGETS")
	spawn_tutorial_text(-80.0, "CROSS GATES TO MULTIPLY SQUAD")
	
	# Section 1: Intro Obstacles (Low HP for 1 fighter)
	spawn_obstacle(Vector3(-1.8, 0, -25.0), Obstacle.ObstacleType.TIRE_STACK, 12.0, 5)
	spawn_obstacle(Vector3(1.8, 0, -25.0), Obstacle.ObstacleType.TIRE_STACK, 12.0, 5)
	
	# Gate 1: +5 vs +2
	spawn_gate_pair(-55.0, MathGate.OperationType.ADD, 5, MathGate.OperationType.ADD, 2)
	
	# Section 2: Wooden Crates
	spawn_obstacle(Vector3(-2.0, 0, -75.0), Obstacle.ObstacleType.CRATE, 20.0, 8)
	spawn_obstacle(Vector3(2.0, 0, -75.0), Obstacle.ObstacleType.CRATE, 20.0, 8)
	
	# Gate 2: x2 vs +10
	spawn_gate_pair(-105.0, MathGate.OperationType.MULTIPLY, 2, MathGate.OperationType.ADD, 10)
	
	# Section 3: Red Enemy Squad
	spawn_enemy(Vector3(-1.5, 0, -135.0), 18.0, 10)
	spawn_enemy(Vector3(0.0, 0, -137.0), 18.0, 10)
	spawn_enemy(Vector3(1.5, 0, -135.0), 18.0, 10)
	
	# Gate 3: +15 vs x2
	spawn_gate_pair(-165.0, MathGate.OperationType.ADD, 15, MathGate.OperationType.MULTIPLY, 2)
	
	# Heavy Barrel Barricade before Boss
	spawn_obstacle(Vector3(-2.2, 0, -185.0), Obstacle.ObstacleType.BARREL, 30.0, 15)
	spawn_obstacle(Vector3(0.0, 0, -185.0), Obstacle.ObstacleType.BARREL, 30.0, 15)
	spawn_obstacle(Vector3(2.2, 0, -185.0), Obstacle.ObstacleType.BARREL, 30.0, 15)
