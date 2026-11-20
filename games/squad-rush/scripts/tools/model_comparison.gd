extends Node3D

# Tool to render and capture high-fidelity in-engine comparisons of soldier archetypes
# View 1: From behind (Exact in-game camera)
# View 2: From front 3/4 angle
# View 3: Group formation

var camera: Camera3D
var step: int = 0
var timer: float = 0.0

func _ready() -> void:
	_setup_environment()
	_setup_track()
	_setup_camera()
	_spawn_archetypes()

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
	gen.generate_track(60.0)

func _setup_camera() -> void:
	camera = Camera3D.new()
	camera.fov = 49.0
	camera.position = Vector3(0, 4.6, 5.8)
	camera.rotation_degrees = Vector3(-23.5, 0, 0)
	add_child(camera)

func _spawn_archetypes() -> void:
	# 1. Variant 0: Rifleman / Shooter (x = -1.3, z = 0.0)
	var s0 = StylizedSoldier.new()
	s0.position = Vector3(-1.3, 0, 0)
	add_child(s0)
	s0.setup_team(false)
	s0.build_soldier(true, 0)
	s0.equip_weapon(0)

	# 2. Variant 1: Heavy Trooper (x = 0.0, z = 0.0)
	var s1 = StylizedSoldier.new()
	s1.position = Vector3(0.0, 0, 0)
	add_child(s1)
	s1.setup_team(false)
	s1.build_soldier(true, 1)
	s1.equip_weapon(1)

	# 3. Variant 2: Specialist (x = 1.3, z = 0.0)
	var s2 = StylizedSoldier.new()
	s2.position = Vector3(1.3, 0, 0)
	add_child(s2)
	s2.setup_team(false)
	s2.build_soldier(true, 2)
	s2.equip_weapon(0)

	# 4. Enemy Archetypes down the road (z = -12.0)
	var r = EnemyUnit.new()
	r.position = Vector3(-1.8, 0, -12.0)
	add_child(r)
	r.setup(12.0, 6, false, EnemyUnit.EnemyType.RUNNER)

	var sh = EnemyUnit.new()
	sh.position = Vector3(0.0, 0, -12.0)
	add_child(sh)
	sh.setup(50.0, 16, false, EnemyUnit.EnemyType.SHIELDER)

	var st = EnemyUnit.new()
	st.position = Vector3(1.8, 0, -12.0)
	add_child(st)
	st.setup(20.0, 8, false, EnemyUnit.EnemyType.SHOOTER)
