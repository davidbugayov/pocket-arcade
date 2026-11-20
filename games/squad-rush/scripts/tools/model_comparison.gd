extends Node3D

# Tool to render and capture in-engine comparisons of soldier candidates
# View 0: From behind (Exact in-game runner camera: FOV 49, Y 4.6, Z 5.8, pitch -23.5)
# View 1: Front 3/4 hero showcase view
# View 2: Crowd formation (10-30 units) with gate and threat visibility

var camera: Camera3D
var view_mode: int = 0
var view_timer: float = 0.0
var hud_label: Label
var hud_stats: Label

var anim_player_a: AnimationPlayer = null
var anim_player_b: AnimationPlayer = null

func _ready() -> void:
	_setup_environment()
	_setup_track()
	_setup_camera()
	_setup_hud()
	_spawn_candidates()
	_spawn_crowd()
	_spawn_track_elements()

func _setup_environment() -> void:
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 28, 0)
	sun.light_color = Color(1.0, 0.98, 0.94)
	sun.light_energy = 0.92
	sun.shadow_enabled = true
	add_child(sun)

	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.24, 0.52, 0.82)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.74, 0.88)
	env.ambient_light_energy = 0.40
	world_env.environment = env
	add_child(world_env)

func _setup_track() -> void:
	var gen = TrackGenerator.new()
	add_child(gen)
	gen.generate_track(80.0)

func _setup_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 49.0
	_set_camera_view(0)
	add_child(camera)

func _set_camera_view(idx: int) -> void:
	view_mode = idx
	match view_mode:
		0: # Behind the back (in-game play perspective)
			camera.position = Vector3(0, 4.6, 5.8)
			camera.rotation_degrees = Vector3(-23.5, 0, 0)
			if hud_label:
				hud_label.text = "VIEW 1: BEHIND THE BACK (IN-GAME PERSPECTIVE)\nLeft: Baseline | Center: Toon Infantry | Right: Compact Robot"
		1: # Front 3/4 hero showcase view
			camera.position = Vector3(0, 1.8, -4.5)
			camera.rotation_degrees = Vector3(-12.0, 180.0, 0)
			if hud_label:
				hud_label.text = "VIEW 2: FRONTAL 3/4 SHOWCASE\nLeft: Compact Robot | Center: Toon Infantry | Right: Baseline"
		2: # Elevated Crowd Formation view
			camera.position = Vector3(0, 7.2, 8.5)
			camera.rotation_degrees = Vector3(-26.0, 0, 0)
			if hud_label:
				hud_label.text = "VIEW 3: CROWD FORMATION & THREAT VISIBILITY\nEvaluates gate reading, silhouette clustering, and contrast"

func _setup_hud() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)

	hud_label = Label.new()
	hud_label.position = Vector2(24, 40)
	hud_label.set("theme_override_font_sizes/font_size", 28)
	hud_label.set("theme_override_colors/font_color", Color(1.0, 1.0, 1.0))
	hud_label.set("theme_override_colors/font_shadow_color", Color(0, 0, 0, 0.9))
	hud_label.set("theme_override_constants/shadow_offset_x", 2)
	hud_label.set("theme_override_constants/shadow_offset_y", 2)
	canvas.add_child(hud_label)

	hud_stats = Label.new()
	hud_stats.position = Vector2(24, 120)
	hud_stats.set("theme_override_font_sizes/font_size", 22)
	hud_stats.set("theme_override_colors/font_color", Color(0.85, 0.95, 1.0))
	hud_stats.set("theme_override_colors/font_shadow_color", Color(0, 0, 0, 0.9))
	hud_stats.set("theme_override_constants/shadow_offset_x", 2)
	hud_stats.set("theme_override_constants/shadow_offset_y", 2)
	hud_stats.text = (
		"1. Baseline: 320 tris/unit, 1 draw call, 0 bones\n" +
		"2. Toon Infantry (Quaternius): 20,725 tris/unit, 18 draw calls, 62 bones (1.24M tris @ 60)\n" +
		"3. Compact Robot (Kenney): 1,114 tris/unit, 6 draw calls, 0 bones (66K tris @ 60)"
	)
	canvas.add_child(hud_stats)

	var btn = Button.new()
	btn.text = "NEXT CAMERA VIEW"
	btn.position = Vector2(24, 850)
	btn.size = Vector2(340, 80)
	btn.pressed.connect(func(): _set_camera_view((view_mode + 1) % 3))
	canvas.add_child(btn)

	var back_btn = Button.new()
	back_btn.text = "MAIN MENU"
	back_btn.position = Vector2(24, 950)
	back_btn.size = Vector2(340, 80)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	canvas.add_child(back_btn)

func _spawn_candidates() -> void:
	# 1. Baseline: Procedural Stylized Fighter (x = -2.4, z = 0.0)
	var base_soldier = StylizedSoldier.new()
	base_soldier.position = Vector3(-2.4, 0, 0)
	add_child(base_soldier)
	base_soldier.setup_team(false)
	base_soldier.build_soldier(true, 1)
	base_soldier.equip_weapon(0)

	# Label for Baseline
	var lbl0 = Label3D.new()
	lbl0.text = "BASELINE\nStylized Fighter\n320 tris"
	lbl0.position = Vector3(-2.4, 1.7, 0)
	lbl0.pixel_size = 0.005
	lbl0.font_size = 28
	lbl0.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl0.modulate = Color(0.3, 0.9, 1.0)
	add_child(lbl0)

	# 2. Candidate A: Quaternius Toon Infantry (x = 0.0, z = 0.0)
	var scene_a = load("res://assets/models/character_soldier.gltf")
	if scene_a:
		var inst_a = scene_a.instantiate()
		inst_a.position = Vector3(0.0, 0, 0)
		inst_a.scale = Vector3(0.65, 0.65, 0.65)
		add_child(inst_a)
		anim_player_a = inst_a.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim_player_a and anim_player_a.has_animation("Run_Shoot"):
			anim_player_a.play("Run_Shoot")
		elif anim_player_a and anim_player_a.has_animation("Run"):
			anim_player_a.play("Run")

	var lbl1 = Label3D.new()
	lbl1.text = "CANDIDATE A\nToon Infantry\n20,725 tris"
	lbl1.position = Vector3(0.0, 1.7, 0)
	lbl1.pixel_size = 0.005
	lbl1.font_size = 28
	lbl1.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl1.modulate = Color(1.0, 0.8, 0.2)
	add_child(lbl1)

	# 3. Candidate B: Compact Robot (x = 2.4, z = 0.0)
	var scene_b = load("res://assets/models/compact_bot.glb")
	if scene_b:
		var inst_b = scene_b.instantiate()
		inst_b.position = Vector3(2.4, 0, 0)
		inst_b.scale = Vector3(1.15, 1.15, 1.15)
		add_child(inst_b)
		anim_player_b = inst_b.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim_player_b and anim_player_b.has_animation("walk"):
			anim_player_b.play("walk")

	var lbl2 = Label3D.new()
	lbl2.text = "CANDIDATE B\nCompact Robot\n1,114 tris"
	lbl2.position = Vector3(2.4, 1.7, 0)
	lbl2.pixel_size = 0.005
	lbl2.font_size = 28
	lbl2.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl2.modulate = Color(0.2, 1.0, 0.5)
	add_child(lbl2)

func _spawn_crowd() -> void:
	# Group formation behind the frontline (z = -4.0 to -9.0)
	# Spawns 12 units to test silhouette overlap, weapon readability and antenna markers
	for i in range(12):
		var row = int(i / 4)
		var col = i % 4
		var x_pos = (float(col) - 1.5) * 1.2
		var z_pos = -4.0 - float(row) * 1.6

		var squad_unit = StylizedSoldier.new()
		squad_unit.position = Vector3(x_pos, 0, z_pos)
		add_child(squad_unit)
		squad_unit.setup_team(false)
		squad_unit.build_soldier(row == 0, i % 3)
		squad_unit.equip_weapon(i % 3)

func _spawn_track_elements() -> void:
	# 1. Math Gate at z = -18.0
	var gate = MathGate.new()
	gate.position = Vector3(0, 0, -18.0)
	add_child(gate)
	gate.setup(MathGate.OperationType.ADD, 5, true)

	# 2. Enemy Units at z = -28.0 (Runner, Shielder, Shooter)
	var runner = EnemyUnit.new()
	runner.position = Vector3(-2.0, 0, -28.0)
	add_child(runner)
	runner.setup(12.0, 6, false, EnemyUnit.EnemyType.RUNNER)

	var shielder = EnemyUnit.new()
	shielder.position = Vector3(0.0, 0, -28.0)
	add_child(shielder)
	shielder.setup(50.0, 16, false, EnemyUnit.EnemyType.SHIELDER)

	var shooter = EnemyUnit.new()
	shooter.position = Vector3(2.0, 0, -28.0)
	add_child(shooter)
	shooter.setup(20.0, 8, false, EnemyUnit.EnemyType.SHOOTER)

func _process(delta: float) -> void:
	view_timer += delta
	# Auto-cycle camera view every 6 seconds if running unattended
	if view_timer >= 6.0:
		view_timer = 0.0
		_set_camera_view((view_mode + 1) % 3)
