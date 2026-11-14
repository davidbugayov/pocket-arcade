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
var is_level_completed: bool = false

var camera_shake_trauma: float = 0.0

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
	is_level_completed = false

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
	# Directional sun - balanced warm sunlight
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 28, 0)
	sun.light_color = Color(1.0, 0.98, 0.94)
	sun.light_energy = 0.92
	sun.shadow_enabled = true
	add_child(sun)

	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	# Balanced coastal azure sky
	env.background_color = Color(0.24, 0.52, 0.82)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.74, 0.88)
	env.ambient_light_energy = 0.40
	# Subtle horizon fog for depth and seamless water/sky blending
	env.fog_enabled = true
	env.fog_light_color = Color(0.36, 0.60, 0.82)
	env.fog_density = 0.003
	env.fog_sky_affect = 0.35
	world_env.environment = env
	add_child(world_env)

func _setup_camera() -> void:
	camera = Camera3D.new()
	# Closer camera with focused 49 FOV brings action up close, cuts out empty sky
	camera.fov = 49.0
	camera.position = Vector3(0, 4.6, 5.8)
	camera.rotation_degrees = Vector3(-23.5, 0, 0)
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
	player_squad.squad_damaged.connect(_on_squad_damaged)
	player_squad.camera_shake_requested.connect(shake_camera)

func _setup_boss() -> void:
	pass

func _build_level_layout() -> void:
	pass

func _process(delta: float) -> void:
	if is_instance_valid(player_squad) and is_instance_valid(camera):
		var target_pos = Vector3(
			player_squad.position.x * 0.35,
			player_squad.position.y + 5.2,
			player_squad.position.z + 6.8
		)

		# Camera shake offset
		if camera_shake_trauma > 0.0:
			camera_shake_trauma = maxf(0.0, camera_shake_trauma - delta * 4.0)
			var shake_offset = Vector3(
				randf_range(-0.15, 0.15) * camera_shake_trauma,
				randf_range(-0.10, 0.10) * camera_shake_trauma,
				randf_range(-0.10, 0.10) * camera_shake_trauma
			)
			target_pos += shake_offset

		camera.position = camera.position.lerp(target_pos, delta * 12.0)

		if is_instance_valid(boss) and not is_boss_phase and is_game_active:
			if player_squad.position.z <= boss_z_position + 42.0:
				_start_boss_battle()

func shake_camera(intensity: float) -> void:
	camera_shake_trauma = clampf(camera_shake_trauma + intensity, 0.0, 1.0)

func _start_boss_battle() -> void:
	is_boss_phase = true
	if is_instance_valid(player_squad):
		player_squad.stop_at_boss(boss_z_position)
	if is_instance_valid(boss):
		boss.activate()
	if is_instance_valid(hud) and hud.has_method("show_boss_bar"):
		hud.show_boss_bar(boss.boss_name, boss.max_hp)

func _on_bullet_spawn_requested(pos: Vector3, dir: Vector3, dmg: float, spd: float, col: Color) -> void:
	if not is_game_active or is_level_completed:
		return
	var b = Bullet.new()
	b.setup(dmg, spd, dir, col, true)
	bullets_container.add_child(b)
	b.global_position = pos

func _on_boss_shot_fired(pos: Vector3, dir: Vector3, dmg: float) -> void:
	if not is_game_active or is_level_completed:
		return
	var b = Bullet.new()
	b.setup(dmg, 26.0, dir, Color(1.0, 0.2, 0.2), false)
	bullets_container.add_child(b)
	b.global_position = pos

func _on_enemy_shot_fired(pos: Vector3, dir: Vector3, dmg: float) -> void:
	if not is_game_active or is_level_completed:
		return
	var b = Bullet.new()
	# Distinct dodgeable enemy bullet (speed 21.0 m/s, glowing orange-red)
	b.setup(dmg, 21.0, dir, Color(1.0, 0.35, 0.1), false)
	bullets_container.add_child(b)
	b.global_position = pos

func _on_squad_damaged(_loss: int) -> void:
	if is_instance_valid(hud) and hud.has_method("trigger_damage_flash"):
		hud.trigger_damage_flash()

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
	obs.setup(type, hp, coins)
	obs.position = pos
	obstacles_container.add_child(obs)
	return obs

func spawn_enemy(pos: Vector3, hp: float, coins: int, moves: bool = false) -> EnemyUnit:
	var enemy = EnemyUnit.new()
	enemy.setup(hp, coins, moves)
	enemy.position = pos
	enemies_container.add_child(enemy)
	enemy.enemy_shot_fired.connect(_on_enemy_shot_fired)
	return enemy

const WeaponPickupScript = preload("res://scripts/core/weapon_pickup.gd")

func spawn_weapon_pickup(pos: Vector3, weapon_id: int, pickup_name: String = "") -> Node3D:
	var pickup = WeaponPickupScript.new()
	pickup.setup(weapon_id, pickup_name)
	pickup.position = pos
	add_child(pickup)
	pickup.weapon_collected.connect(_on_weapon_collected)
	return pickup

func _on_weapon_collected(_w_id: int, w_name: String) -> void:
	if is_instance_valid(hud) and hud.has_method("show_toast"):
		hud.show_toast("ACQUIRED: " + w_name + "!")

func spawn_tutorial_text(z_pos: float, text_content: String) -> void:
	var lbl = Label3D.new()
	lbl.text = text_content
	lbl.font_size = 56
	lbl.outline_size = 16
	lbl.outline_modulate = Color(0, 0, 0, 1)
	lbl.modulate = Color(1.0, 0.95, 0.3)
	lbl.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	lbl.position = Vector3(0, 2.6, z_pos)
	add_child(lbl)

func _stop_all_combat() -> void:
	is_game_active = false
	if is_instance_valid(player_squad):
		player_squad.stop_squad()
	if is_instance_valid(boss):
		boss.stop_boss()
	for child in enemies_container.get_children():
		if child is EnemyUnit:
			child.is_active = false
	for b in bullets_container.get_children():
		b.queue_free()

func _on_player_defeated() -> void:
	if is_level_completed:
		return
	is_level_completed = true
	_stop_all_combat()
	# Coins collected during the run are safely saved
	GameManager.record_defeat()
	level_lost.emit()

func _on_boss_defeated() -> void:
	if is_level_completed:
		return
	is_level_completed = true
	_stop_all_combat()
	SoundManager.play("victory")
	# Level completion and coins safely saved
	GameManager.complete_level(level_number)
	level_won.emit()

func _on_squad_count_changed(count: int) -> void:
	if is_instance_valid(hud) and hud.has_method("update_squad_count"):
		hud.update_squad_count(count)
