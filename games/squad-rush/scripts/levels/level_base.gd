extends Node3D

class_name LevelBase

@export var level_number: int = 1
@export var level_length: float = 240.0
@export var boss_z_position: float = -200.0

var player_squad: PlayerSquad
var camera: Camera3D
var track_generator: TrackGenerator
var boss: BossUnit

var bullets_container: Node3D
var obstacles_container: Node3D
var gates_container: Node3D
var enemies_container: Node3D

var hud: CanvasLayer
var is_game_active: bool = false
var is_boss_phase: bool = false

signal level_won()
signal level_lost()

func _ready() -> void:
	GameManager.reset_run_stats()
	_setup_containers()
	_setup_environment()
	_setup_camera()
	_setup_track()
	_setup_player()
	_build_level_layout()
	_setup_boss()
	
	is_game_active = true

func _setup_containers() -> void:
	bullets_container = Node3D.new()
	bullets_container.name = "Bullets"
	add_child(bullets_container)
	
	obstacles_container = Node3D.new()
	obstacles_container.name = "Obstacles"
	add_child(obstacles_container)
	
	gates_container = Node3D.new()
	gates_container.name = "Gates"
	add_child(gates_container)
	
	enemies_container = Node3D.new()
	enemies_container.name = "Enemies"
	add_child(enemies_container)

func _setup_environment() -> void:
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 35, 0)
	sun.light_color = Color(1.0, 0.98, 0.94)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)
	
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.4, 0.7, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.75, 0.85)
	env.ambient_light_energy = 0.8
	world_env.environment = env
	add_child(world_env)

func _setup_camera() -> void:
	camera = Camera3D.new()
	camera.fov = 65.0
	camera.position = Vector3(0, 7.5, 9.5)
	camera.rotation_degrees = Vector3(-24, 0, 0)
	add_child(camera)

func _setup_track() -> void:
	track_generator = TrackGenerator.new()
	add_child(track_generator)
	track_generator.generate_track(level_length)

func _setup_player() -> void:
	player_squad = PlayerSquad.new()
	player_squad.position = Vector3(0, 0, 0)
	player_squad.add_to_group("player")
	add_child(player_squad)
	
	player_squad.bullet_spawn_requested.connect(_on_bullet_spawn_requested)
	player_squad.squad_defeated.connect(_on_player_defeated)
	player_squad.squad_count_changed.connect(_on_squad_count_changed)

func _setup_boss() -> void:
	pass

func _build_level_layout() -> void:
	pass

func _process(delta: float) -> void:
	if not is_game_active:
		return
	
	if is_instance_valid(player_squad):
		var target_pos = Vector3(player_squad.position.x * 0.4, player_squad.position.y + 7.2, player_squad.position.z + 9.5)
		camera.position = camera.position.lerp(target_pos, delta * 10.0)
		
		if is_instance_valid(boss) and not is_boss_phase:
			if player_squad.position.z <= boss_z_position + 45.0:
				_start_boss_battle()

func _start_boss_battle() -> void:
	is_boss_phase = true
	if is_instance_valid(player_squad):
		player_squad.stop_at_boss(boss_z_position)
	if is_instance_valid(boss):
		boss.activate()
	if is_instance_valid(hud) and hud.has_method("show_boss_bar"):
		hud.show_boss_bar(boss.boss_name, boss.max_hp)

func _on_bullet_spawn_requested(pos: Vector3, dir: Vector3, dmg: float, spd: float, col: Color) -> void:
	var b = Bullet.new()
	bullets_container.add_child(b)
	b.global_position = pos
	b.setup(dmg, spd, dir, col, true)

func _on_boss_shot_fired(pos: Vector3, dir: Vector3, dmg: float) -> void:
	var b = Bullet.new()
	bullets_container.add_child(b)
	b.global_position = pos
	b.setup(dmg, 28.0, dir, Color(1.0, 0.2, 0.2), false)

func spawn_gate_pair(z_pos: float, left_op: MathGate.OperationType, left_val: int, right_op: MathGate.OperationType, right_val: int) -> void:
	var left_gate = MathGate.new()
	left_gate.position = Vector3(-2.1, 0, z_pos)
	gates_container.add_child(left_gate)
	left_gate.setup(left_op, left_val, true)
	
	var right_gate = MathGate.new()
	right_gate.position = Vector3(2.1, 0, z_pos)
	gates_container.add_child(right_gate)
	right_gate.setup(right_op, right_val, false)
	
	left_gate.partner_gate = right_gate
	right_gate.partner_gate = left_gate

func spawn_obstacle(pos: Vector3, type: Obstacle.ObstacleType, hp: float, coins: int) -> Obstacle:
	var obs = Obstacle.new()
	obs.position = pos
	obstacles_container.add_child(obs)
	obs.setup(type, hp, coins)
	return obs

func spawn_enemy(pos: Vector3, hp: float, coins: int, moves: bool = false) -> EnemyUnit:
	var enemy = EnemyUnit.new()
	enemy.position = pos
	enemies_container.add_child(enemy)
	enemy.setup(hp, coins, moves)
	return enemy

func spawn_tutorial_text(z_pos: float, text_content: String) -> void:
	var lbl = Label3D.new()
	lbl.text = text_content
	lbl.font_size = 56
	lbl.outline_size = 14
	lbl.outline_modulate = Color(0, 0, 0, 1)
	lbl.modulate = Color(1.0, 0.95, 0.3)
	lbl.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	lbl.position = Vector3(0, 2.8, z_pos)
	add_child(lbl)

func _on_player_defeated() -> void:
	is_game_active = false
	level_lost.emit()

func _on_boss_defeated() -> void:
	is_game_active = false
	if is_instance_valid(player_squad):
		player_squad.stop_squad()
	SoundManager.play("victory")
	GameManager.complete_level(level_number)
	level_won.emit()

func _on_squad_count_changed(count: int) -> void:
	if is_instance_valid(hud) and hud.has_method("update_squad_count"):
		hud.update_squad_count(count)
