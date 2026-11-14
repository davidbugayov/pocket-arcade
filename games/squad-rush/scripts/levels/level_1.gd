extends LevelBase

class_name Level1

func _init() -> void:
	level_number = 1
	level_length = 250.0
	boss_z_position = -210.0

func _setup_boss() -> void:
	boss = BossUnit.new()
	boss.setup("Iron Sentinel", 220.0, 100)
	boss.position = Vector3(0, 0, boss_z_position)
	add_child(boss)
	boss.boss_hp_changed.connect(func(cur, m): if hud and hud.has_method("update_boss_hp"): hud.update_boss_hp(cur, m))
	boss.boss_shot_fired.connect(_on_boss_shot_fired)
	boss.boss_defeated.connect(_on_boss_defeated)

func _build_level_layout() -> void:
	# Tutorial Prompts
	spawn_tutorial_text(-10.0, "SWIPE LEFT & RIGHT TO MOVE")
	spawn_tutorial_text(-38.0, "SHOOT TO BREAK TARGETS")
	spawn_tutorial_text(-80.0, "CROSS BLUE GATES TO MULTIPLY")
	
	# Section 1: Intro Tire Stacks (Center lane is open, 12 HP easily shot down)
	spawn_obstacle(Vector3(-1.8, 0, -25.0), Obstacle.ObstacleType.TIRE_STACK, 12.0, 5)
	spawn_obstacle(Vector3(1.8, 0, -25.0), Obstacle.ObstacleType.TIRE_STACK, 12.0, 5)
	
	# Gate 1: +5 vs +2 (Player chooses +5, squad becomes 6)
	spawn_gate_pair(-55.0, MathGate.OperationType.ADD, 5, MathGate.OperationType.ADD, 2)
	
	# Section 2: Wooden Crates (HP 18.0)
	spawn_obstacle(Vector3(-1.8, 0, -75.0), Obstacle.ObstacleType.CRATE, 18.0, 8)
	spawn_obstacle(Vector3(1.8, 0, -75.0), Obstacle.ObstacleType.CRATE, 18.0, 8)
	
	# Gate 2: x2 vs +10 (Squad becomes 12 or 16)
	spawn_gate_pair(-102.0, MathGate.OperationType.MULTIPLY, 2, MathGate.OperationType.ADD, 10)
	
	# Weapon Upgrade on Track!
	spawn_weapon_pickup(Vector3(0.0, 0, -118.0), 1, "COMBAT SHOTGUN")
	
	# Section 3: Red Enemy Infantry (Dodgeable bullets, 16 HP)
	spawn_enemy(Vector3(-1.6, 0, -140.0), 16.0, 10)
	spawn_enemy(Vector3(0.0, 0, -142.0), 16.0, 10)
	spawn_enemy(Vector3(1.6, 0, -140.0), 16.0, 10)
	
	# Gate 3: +15 vs x2 (Squad reaches 27 - 32 fighters)
	spawn_gate_pair(-165.0, MathGate.OperationType.ADD, 15, MathGate.OperationType.MULTIPLY, 2)
	
	# Section 4: Heavy Barrels before Boss (HP 25.0)
	spawn_obstacle(Vector3(-2.0, 0, -185.0), Obstacle.ObstacleType.BARREL, 25.0, 15)
	spawn_obstacle(Vector3(0.0, 0, -185.0), Obstacle.ObstacleType.BARREL, 25.0, 15)
	spawn_obstacle(Vector3(2.0, 0, -185.0), Obstacle.ObstacleType.BARREL, 25.0, 15)
