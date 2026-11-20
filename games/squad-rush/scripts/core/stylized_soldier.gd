extends Node3D

class_name StylizedSoldier

enum Team { ALLY, ENEMY }

@export var team: Team = Team.ALLY
@export var is_enemy: bool = false
@export var variant: int = 0
@export var is_lod: bool = false

var torso_node: Node3D
var head_node: Node3D
var helmet_mesh: MeshInstance3D
var visor_mesh: MeshInstance3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var weapon_mount: Node3D
var weapon_mesh_instance: MeshInstance3D
var muzzle_point: Node3D
var muzzle_flash: MeshInstance3D
var lod_mesh_instance: MeshInstance3D

var walk_time: float = 0.0
var recoil_offset: float = 0.0
var flash_timer: float = 0.0
var current_weapon_id: int = 0
var current_tilt: float = 0.0

# -------------------------------------------------------------------------
# Shared Materials Cache (Vertex-colored PBR shaders for 100% zero-state batching)
# -------------------------------------------------------------------------
static var mat_vertex_lit: StandardMaterial3D = null
static var mat_ally_visor: StandardMaterial3D = null
static var mat_enemy_visor: StandardMaterial3D = null
static var mat_flash: StandardMaterial3D = null

# Backward compatibility references
static var mat_ally_uniforms: Array[StandardMaterial3D] = []
static var mat_ally_armors: Array[StandardMaterial3D] = []
static var mat_enemy_uniforms: Array[StandardMaterial3D] = []
static var mat_enemy_armors: Array[StandardMaterial3D] = []
static var mat_dark_metal: StandardMaterial3D = null
static var mat_skin: StandardMaterial3D = null

# -------------------------------------------------------------------------
# Shared Procedural Meshes Cache (Built once via SurfaceTool with vertex colors)
# -------------------------------------------------------------------------
static var mesh_cache_body: Dictionary = {}
static var mesh_cache_visor: Dictionary = {}
static var mesh_cache_leg: Dictionary = {}
static var mesh_cache_weapon: Dictionary = {}
static var mesh_cache_lod: Dictionary = {}
static var materials_initialized: bool = false

# Color Palette Constants
# Ally: Dark graphite fatigue, vibrant cobalt blue armor, rounded navy helmet, luminous cyan visor, khaki gear
const COL_AL_FATIGUE = Color(0.12, 0.14, 0.18)
const COL_AL_ARMOR   = Color(0.12, 0.48, 0.94)
const COL_AL_HELMET  = Color(0.18, 0.32, 0.58)
const COL_AL_BRIM    = Color(0.08, 0.10, 0.14)
const COL_AL_VISOR   = Color(0.10, 0.95, 1.00)
const COL_AL_GEAR    = Color(0.38, 0.32, 0.24)
const COL_AL_PACK    = Color(0.16, 0.22, 0.32)
const COL_AL_BOOTS   = Color(0.10, 0.10, 0.12)

# Enemy: Dark charcoal fatigue, crimson red armor, dark maroon helmet, glowing amber visor, dark leather gear
const COL_EN_FATIGUE = Color(0.14, 0.11, 0.11)
const COL_EN_ARMOR   = Color(0.86, 0.14, 0.14)
const COL_EN_HELMET  = Color(0.42, 0.12, 0.14)
const COL_EN_BRIM    = Color(0.10, 0.08, 0.08)
const COL_EN_VISOR   = Color(1.00, 0.42, 0.04)
const COL_EN_GEAR    = Color(0.24, 0.18, 0.15)
const COL_EN_PACK    = Color(0.22, 0.12, 0.12)
const COL_EN_BOOTS   = Color(0.08, 0.08, 0.08)

# Weapons: Gunmetal receiver, steel barrel, dark grip
const COL_GUN_RECEIVER = Color(0.18, 0.20, 0.24)
const COL_GUN_BARREL   = Color(0.72, 0.76, 0.82)
const COL_GUN_MAGAZINE = Color(0.12, 0.13, 0.16)

func _init() -> void:
	_init_materials()
	_init_mesh_cache()

func _ready() -> void:
	if torso_node == null and lod_mesh_instance == null:
		build_soldier(not is_lod, variant)
	equip_weapon(current_weapon_id)

static func _init_materials() -> void:
	if materials_initialized:
		return
	materials_initialized = true

	# Unified Master Material: uses vertex colors baked into the geometry!
	# This single material renders dark uniform, bright armor, helmet, gear, and weapon in 1 draw call!
	mat_vertex_lit = StandardMaterial3D.new()
	mat_vertex_lit.vertex_color_use_as_albedo = true
	mat_vertex_lit.roughness = 0.55
	mat_vertex_lit.metallic = 0.15

	# Visor materials for front-row glow
	mat_ally_visor = StandardMaterial3D.new()
	mat_ally_visor.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_ally_visor.albedo_color = COL_AL_VISOR

	mat_enemy_visor = StandardMaterial3D.new()
	mat_enemy_visor.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_enemy_visor.albedo_color = COL_EN_VISOR

	# Muzzle flash
	mat_flash = StandardMaterial3D.new()
	mat_flash.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_flash.albedo_color = Color(1.0, 0.95, 0.45)

	# Compatibility fallbacks
	mat_dark_metal = StandardMaterial3D.new()
	mat_dark_metal.albedo_color = COL_GUN_RECEIVER
	mat_dark_metal.metallic = 0.85
	mat_dark_metal.roughness = 0.30

	mat_skin = StandardMaterial3D.new()
	mat_skin.albedo_color = Color(0.86, 0.68, 0.56)

	for i in range(3):
		var m_al = StandardMaterial3D.new()
		m_al.albedo_color = COL_AL_ARMOR
		mat_ally_armors.append(m_al)
		mat_ally_uniforms.append(m_al)

		var m_en = StandardMaterial3D.new()
		m_en.albedo_color = COL_EN_ARMOR
		mat_enemy_armors.append(m_en)
		mat_enemy_uniforms.append(m_en)

static func _init_mesh_cache() -> void:
	if not mesh_cache_weapon.is_empty():
		return

	# Pre-build unified weapon models (single draw call per weapon with vertex colors)
	for wid in [0, 1, 2]:
		mesh_cache_weapon[wid] = _generate_weapon_mesh(wid)

	# Pre-build legs
	for is_en in [false, true]:
		var leg_key = "en" if is_en else "al"
		mesh_cache_leg[leg_key] = _generate_leg_mesh(is_en)
	# Compatibility key
	mesh_cache_leg[true] = mesh_cache_leg["en"]
	mesh_cache_leg[false] = mesh_cache_leg["al"]

	# Pre-build bodies, visors, and LOD models for each team & variant
	for is_en in [false, true]:
		for v in range(3):
			var key = "%s_%d" % ["en" if is_en else "al", v]
			mesh_cache_body[key] = _generate_upper_body_mesh(v, is_en)
			mesh_cache_visor[key] = _generate_visor_mesh(v, is_en)

			# Pre-build LOD single-mesh soldiers (body + legs + weapon all in 1 mesh with vertex colors)
			for wid in [0, 1, 2]:
				var lod_key = "%s_%d_w%d" % ["en" if is_en else "al", v, wid]
				mesh_cache_lod[lod_key] = _generate_lod_mesh(v, wid, is_en)

# -------------------------------------------------------------------------
# SurfaceTool Vertex Color Helper Functions
# -------------------------------------------------------------------------
static func _append_colored_primitive(st: SurfaceTool, prim: PrimitiveMesh, xform: Transform3D, col: Color) -> void:
	var arrays = prim.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

	if indices.size() > 0:
		for idx in indices:
			st.set_color(col)
			if normals.size() > idx:
				st.set_normal((xform.basis * normals[idx]).normalized())
			st.add_vertex(xform * verts[idx])
	else:
		for i in range(verts.size()):
			st.set_color(col)
			if normals.size() > i:
				st.set_normal((xform.basis * normals[i]).normalized())
			st.add_vertex(xform * verts[i])

static func _append_mesh_with_vertex_colors(st: SurfaceTool, mesh: ArrayMesh, xform: Transform3D, default_col: Color = Color.WHITE) -> void:
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var arrays = mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays.size() > Mesh.ARRAY_NORMAL and arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays.size() > Mesh.ARRAY_COLOR and arrays[Mesh.ARRAY_COLOR] != null else PackedColorArray()
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays.size() > Mesh.ARRAY_INDEX and arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()

	var has_colors = colors.size() == verts.size()
	if indices.size() > 0:
		for idx in indices:
			st.set_color(colors[idx] if has_colors else default_col)
			if normals.size() > idx:
				st.set_normal((xform.basis * normals[idx]).normalized())
			st.add_vertex(xform * verts[idx])
	else:
		for i in range(verts.size()):
			st.set_color(colors[i] if has_colors else default_col)
			if normals.size() > i:
				st.set_normal((xform.basis * normals[i]).normalized())
			st.add_vertex(xform * verts[i])

# -------------------------------------------------------------------------
# Low-Poly Mobile Procedural Mesh Generators
# -------------------------------------------------------------------------
static func _make_sphere(radius: float, height: float, rad_segs: int = 10, rings: int = 5) -> SphereMesh:
	var m = SphereMesh.new()
	m.radius = radius
	m.height = height
	m.radial_segments = rad_segs
	m.rings = rings
	return m

static func _make_capsule(radius: float, height: float, rad_segs: int = 10, rings: int = 4) -> CapsuleMesh:
	var m = CapsuleMesh.new()
	m.radius = radius
	m.height = height
	m.radial_segments = rad_segs
	m.rings = rings
	return m

static func _make_cylinder(top_r: float, bot_r: float, height: float, rad_segs: int = 8) -> CylinderMesh:
	var m = CylinderMesh.new()
	m.top_radius = top_r
	m.bottom_radius = bot_r
	m.height = height
	m.radial_segments = rad_segs
	m.rings = 1
	return m

static func _generate_upper_body_mesh(v: int, is_en: bool = false) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var c_fatigue = COL_EN_FATIGUE if is_en else COL_AL_FATIGUE
	var c_armor   = COL_EN_ARMOR if is_en else COL_AL_ARMOR
	var c_helmet  = COL_EN_HELMET if is_en else COL_AL_HELMET
	var c_brim    = COL_EN_BRIM if is_en else COL_AL_BRIM
	var c_visor   = COL_EN_VISOR if is_en else COL_AL_VISOR
	var c_gear    = COL_EN_GEAR if is_en else COL_AL_GEAR
	var c_pack    = COL_EN_PACK if is_en else COL_AL_PACK

	# 1. Torso Undersuit / Fatigue: Dark tactical undersuit
	var torso_cap = _make_capsule(0.16, 0.44, 10, 4)
	_append_colored_primitive(st, torso_cap, Transform3D(Basis(), Vector3(0, 0.0, 0)), c_fatigue)

	# 2. Chest Armor Plate Carrier: Bright vibrant team armor
	var chest_plate = _make_capsule(0.175, 0.32, 10, 4)
	_append_colored_primitive(st, chest_plate, Transform3D(Basis(), Vector3(0, 0.04, 0.02)), c_armor)

	# 3. Tactical Belt with webbing
	var belt = _make_cylinder(0.175, 0.175, 0.08, 8)
	_append_colored_primitive(st, belt, Transform3D(Basis(), Vector3(0, -0.16, 0)), c_gear)

	# Belt buckle / center clasp
	var buckle = BoxMesh.new()
	buckle.size = Vector3(0.08, 0.07, 0.04)
	_append_colored_primitive(st, buckle, Transform3D(Basis(), Vector3(0, -0.16, 0.17)), COL_GUN_BARREL)

	# 4. Shoulders (Pauldrons): Armor color with distinct silhouette
	for side in [-1, 1]:
		var sh_sph = _make_sphere(0.09, 0.14, 8, 4)
		_append_colored_primitive(st, sh_sph, Transform3D(Basis(), Vector3(side * 0.21, 0.15, 0)), c_armor)

	# 5. Head base / Balaclava: Dark tactical fabric
	var head_sph = _make_sphere(0.13, 0.24, 10, 5)
	_append_colored_primitive(st, head_sph, Transform3D(Basis(), Vector3(0, 0.27, 0)), c_fatigue)

	# 6. Large Stylized Combat Helmet: Rounded dome clearly visible from top-down camera
	var helm_sph = _make_sphere(0.23, 0.30, 12, 6)
	_append_colored_primitive(st, helm_sph, Transform3D(Basis(), Vector3(0, 0.30, 0)), c_helmet)

	# Flared Helmet Visor Brow / Rim: Dark contrasting rim
	var brim = BoxMesh.new()
	brim.size = Vector3(0.30, 0.04, 0.12)
	_append_colored_primitive(st, brim, Transform3D(Basis(), Vector3(0, 0.28, 0.16)), c_brim)

	# Visor band embedded in helmet for rear LOD readability
	var visor_bar = BoxMesh.new()
	visor_bar.size = Vector3(0.26, 0.07, 0.06)
	_append_colored_primitive(st, visor_bar, Transform3D(Basis(), Vector3(0, 0.28, 0.18)), c_visor)

	# Flared Ear Guards
	for side in [-1, 1]:
		var ear_pad = BoxMesh.new()
		ear_pad.size = Vector3(0.06, 0.12, 0.14)
		_append_colored_primitive(st, ear_pad, Transform3D(Basis(), Vector3(side * 0.22, 0.24, 0)), c_helmet)

	# 7. Coherent Silhouette Variations (Instantly distinguishable from behind and camera!)
	match v:
		0: # Variant 0: Regular Rifleman — Sleek tactical harness, combat knife on left shoulder, rear utility pouch
			# Left shoulder combat knife sheath
			var knife = BoxMesh.new()
			knife.size = Vector3(0.04, 0.14, 0.05)
			_append_colored_primitive(st, knife, Transform3D(Basis(Vector3(0, 0, 1), deg_to_rad(-15)), Vector3(-0.16, 0.18, 0.12)), COL_GUN_RECEIVER)

			# Rear waist utility pouches (visible from behind!)
			for p_off in [-0.07, 0.07]:
				var pouch = BoxMesh.new()
				pouch.size = Vector3(0.08, 0.08, 0.06)
				_append_colored_primitive(st, pouch, Transform3D(Basis(), Vector3(p_off, -0.14, -0.17)), c_gear)

		1: # Variant 1: Heavy Trooper — Wide reinforced shoulder pauldrons & heavy neck gorget collar
			# Reinforced heavy neck gorget collar (visible in front and side)
			var gorget = BoxMesh.new()
			gorget.size = Vector3(0.30, 0.08, 0.24)
			_append_colored_primitive(st, gorget, Transform3D(Basis(), Vector3(0, 0.18, 0.02)), c_armor)

			# Broad heavy shoulder armor plates (clearly widens shoulders from behind!)
			for side in [-1, 1]:
				var h_plate = BoxMesh.new()
				h_plate.size = Vector3(0.16, 0.09, 0.22)
				_append_colored_primitive(st, h_plate, Transform3D(Basis(Vector3(0, 0, 1), deg_to_rad(side * -15)), Vector3(side * 0.26, 0.16, 0.01)), c_armor)

			# Heavy armored rear battery pack with status diode
			var battery = BoxMesh.new()
			battery.size = Vector3(0.22, 0.22, 0.10)
			_append_colored_primitive(st, battery, Transform3D(Basis(), Vector3(0, 0.02, -0.16)), COL_GUN_RECEIVER)
			var diode = BoxMesh.new()
			diode.size = Vector3(0.06, 0.04, 0.03)
			var diode_col = Color(0.2, 0.9, 0.4) if not is_en else Color(1.0, 0.3, 0.1)
			_append_colored_primitive(st, diode, Transform3D(Basis(), Vector3(0.06, 0.08, -0.215)), diode_col)

			# Heavy chest magazine pouches
			for side in [-0.07, 0.07]:
				var mag = BoxMesh.new()
				mag.size = Vector3(0.06, 0.11, 0.05)
				_append_colored_primitive(st, mag, Transform3D(Basis(), Vector3(side, 0.01, 0.18)), c_gear)

		2: # Variant 2: Specialist — Compact tactical backpack with radio antenna mast (prominent from behind!)
			# Rear communication survival backpack
			var pack = BoxMesh.new()
			pack.size = Vector3(0.24, 0.28, 0.14)
			_append_colored_primitive(st, pack, Transform3D(Basis(), Vector3(0, 0.05, -0.18)), c_pack)

			# Backpack straps over shoulders
			for side in [-0.11, 0.11]:
				var strap = BoxMesh.new()
				strap.size = Vector3(0.04, 0.28, 0.02)
				_append_colored_primitive(st, strap, Transform3D(Basis(), Vector3(side, 0.08, -0.01)), c_gear)

			# Slender tactical radio antenna mast extending up from backpack with luminous tip
			var antenna = _make_cylinder(0.012, 0.018, 0.48, 6)
			_append_colored_primitive(st, antenna, Transform3D(Basis(), Vector3(-0.09, 0.40, -0.22)), COL_GUN_BARREL)
			var tip = _make_sphere(0.025, 0.05, 6, 3)
			_append_colored_primitive(st, tip, Transform3D(Basis(), Vector3(-0.09, 0.65, -0.22)), c_visor)

			# Brow sensor goggles on helmet
			for g_side in [-0.06, 0.06]:
				var goggle = _make_cylinder(0.025, 0.025, 0.05, 6)
				var g_rot = Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(90)), Vector3(g_side, 0.38, 0.14))
				_append_colored_primitive(st, goggle, g_rot, COL_GUN_RECEIVER)

	return st.commit()

static func _generate_visor_mesh(v: int, is_en: bool = false) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c_visor = COL_EN_VISOR if is_en else COL_AL_VISOR
	# Glowing panoramic tactical visor band across helmet brow
	var visor_bar = BoxMesh.new()
	visor_bar.size = Vector3(0.26, 0.07, 0.06)
	_append_colored_primitive(st, visor_bar, Transform3D(Basis(), Vector3(0, 0.28, 0.18)), c_visor)
	return st.commit()

static func _generate_leg_mesh(is_en: bool = false) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var c_fatigue = COL_EN_FATIGUE if is_en else COL_AL_FATIGUE
	var c_boots   = COL_EN_BOOTS if is_en else COL_AL_BOOTS

	# Tapered fatigue leg capsule
	var leg_cap = _make_capsule(0.07, 0.28, 8, 3)
	_append_colored_primitive(st, leg_cap, Transform3D(Basis(), Vector3(0, -0.12, 0)), c_fatigue)

	# Tactical combat boot with sole
	var boot = _make_capsule(0.075, 0.18, 8, 3)
	var b_xform = Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(90)), Vector3(0, -0.22, 0.03))
	_append_colored_primitive(st, boot, b_xform, c_boots)

	return st.commit()

static func _generate_weapon_mesh(wid: int) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	match wid:
		0: # Assault Rifle (Precision dark weapon with steel barrel)
			var rec = BoxMesh.new()
			rec.size = Vector3(0.08, 0.11, 0.32)
			_append_colored_primitive(st, rec, Transform3D(Basis(), Vector3(0, 0, 0)), COL_GUN_RECEIVER)

			var b = _make_cylinder(0.025, 0.025, 0.32, 8)
			var b_rot = Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(90)), Vector3(0, 0.02, 0.28))
			_append_colored_primitive(st, b, b_rot, COL_GUN_BARREL)

			var mag = BoxMesh.new()
			mag.size = Vector3(0.05, 0.15, 0.09)
			_append_colored_primitive(st, mag, Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(15)), Vector3(0, -0.10, 0.06)), COL_GUN_MAGAZINE)

			var stock = BoxMesh.new()
			stock.size = Vector3(0.06, 0.09, 0.18)
			_append_colored_primitive(st, stock, Transform3D(Basis(), Vector3(0, -0.02, -0.22)), COL_GUN_RECEIVER)

		1: # Combat Shotgun (Heavy dual-barrel receiver & wide pump)
			var s_rec = BoxMesh.new()
			s_rec.size = Vector3(0.10, 0.13, 0.34)
			_append_colored_primitive(st, s_rec, Transform3D(Basis(), Vector3(0, 0, 0)), COL_GUN_RECEIVER)

			var s_b = _make_cylinder(0.045, 0.045, 0.34, 8)
			var sb_rot = Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(90)), Vector3(0, 0.02, 0.28))
			_append_colored_primitive(st, s_b, sb_rot, COL_GUN_BARREL)

			var pump = _make_cylinder(0.055, 0.055, 0.16, 8)
			_append_colored_primitive(st, pump, Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(90)), Vector3(0, -0.03, 0.18)), COL_GUN_MAGAZINE)

		2: # Plasma Minigun (Rotary cylinder motor housing & 3-barrel cluster)
			var m_body = _make_cylinder(0.09, 0.09, 0.26, 8)
			var mb_rot = Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(90)), Vector3(0, 0, 0))
			_append_colored_primitive(st, m_body, mb_rot, COL_GUN_RECEIVER)

			for a in [0.0, 120.0, 240.0]:
				var rad = deg_to_rad(a)
				var bx = cos(rad) * 0.055
				var by = sin(rad) * 0.055
				var b_cyl = _make_cylinder(0.022, 0.022, 0.42, 6)
				var b_xform = Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(90)), Vector3(bx, by, 0.28))
				_append_colored_primitive(st, b_cyl, b_xform, COL_GUN_BARREL)

	return st.commit()

static func _generate_lod_mesh(v: int, wid: int, is_en: bool = false) -> ArrayMesh:
	# Single combined mesh for entire soldier (body + legs + weapon all with baked vertex colors!)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 1. Upper body (with baked uniform, armor, helmet, visor, gear colors)
	var body_m = _generate_upper_body_mesh(v, is_en)
	_append_mesh_with_vertex_colors(st, body_m, Transform3D(Basis(), Vector3(0, 0.42, 0)))

	# 2. Left leg in forward stride
	var l_leg = _generate_leg_mesh(is_en)
	_append_mesh_with_vertex_colors(st, l_leg, Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(15)), Vector3(-0.11, 0.24, 0.04)))

	# 3. Right leg in rear stride
	var r_leg = _generate_leg_mesh(is_en)
	_append_mesh_with_vertex_colors(st, r_leg, Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(-15)), Vector3(0.11, 0.24, -0.04)))

	# 4. Weapon (dark gunmetal receiver & steel barrel)
	var w_m = _generate_weapon_mesh(wid)
	_append_mesh_with_vertex_colors(st, w_m, Transform3D(Basis(), Vector3(0.08, 0.44, 0.24)))

	return st.commit()

# -------------------------------------------------------------------------
# Hierarchy & Lifecycle
# -------------------------------------------------------------------------
func setup_team(p_is_enemy: bool) -> void:
	is_enemy = p_is_enemy
	team = Team.ENEMY if is_enemy else Team.ALLY
	rotation_degrees.y = 0.0 if is_enemy else 180.0
	_apply_materials()

func set_variant(var_idx: int) -> void:
	variant = var_idx % 3
	build_soldier(not is_lod, variant)

func set_lod(p_lod: bool) -> void:
	if is_lod == p_lod:
		return
	is_lod = p_lod
	build_soldier(not is_lod, variant)
	equip_weapon(current_weapon_id)

func build_soldier(articulated: bool = true, var_idx: int = 0) -> void:
	variant = var_idx % 3
	is_lod = not articulated

	# Clear previous hierarchy
	for child in get_children():
		remove_child(child)
		child.queue_free()

	torso_node = null
	head_node = null
	left_arm = null
	right_arm = null
	left_leg = null
	right_leg = null
	weapon_mount = null
	weapon_mesh_instance = null
	muzzle_point = null
	muzzle_flash = null
	lod_mesh_instance = null

	var key = "%s_%d" % ["en" if is_enemy else "al", variant]

	if not articulated:
		# STREAMLINED REAR LOD: Exactly 1 single MeshInstance3D node!
		var lod_key = "%s_%d_w%d" % ["en" if is_enemy else "al", variant, current_weapon_id]
		lod_mesh_instance = MeshInstance3D.new()
		lod_mesh_instance.name = "LodSoldier"
		lod_mesh_instance.mesh = mesh_cache_lod.get(lod_key, mesh_cache_lod.values()[0])
		lod_mesh_instance.material_override = mat_vertex_lit
		add_child(lod_mesh_instance)

		# Muzzle point for shooting
		muzzle_point = Node3D.new()
		muzzle_point.position = Vector3(0.08, 0.44, 0.65)
		add_child(muzzle_point)

		# Minimal flash
		muzzle_flash = MeshInstance3D.new()
		muzzle_flash.mesh = _make_sphere(0.10, 0.20, 8, 4)
		muzzle_flash.material_override = mat_flash
		muzzle_flash.visible = false
		muzzle_point.add_child(muzzle_flash)

		# Compatibility torso node reference
		torso_node = Node3D.new()
		torso_node.name = "TorsoRoot"
		add_child(torso_node)
		_apply_materials()
		return

	# FRONT ROW ARTICULATED SOLDIER: 4 meshes total (Body, Left Leg, Right Leg, Weapon)
	torso_node = Node3D.new()
	torso_node.name = "TorsoRoot"
	torso_node.position.y = 0.42
	add_child(torso_node)

	# 1. Combined Upper Body Mesh with baked vertex colors
	var body_mesh = MeshInstance3D.new()
	body_mesh.name = "TorsoMesh"
	body_mesh.mesh = mesh_cache_body.get(key, mesh_cache_body.values()[0])
	body_mesh.material_override = mat_vertex_lit
	torso_node.add_child(body_mesh)

	# Glowing Visor Mesh Overlay (High emission neon visor)
	visor_mesh = MeshInstance3D.new()
	visor_mesh.name = "VisorMesh"
	visor_mesh.mesh = mesh_cache_visor.get(key, mesh_cache_visor.values()[0])
	visor_mesh.material_override = mat_enemy_visor if is_enemy else mat_ally_visor
	torso_node.add_child(visor_mesh)

	# 2. Articulated Legs
	left_leg = Node3D.new()
	left_leg.name = "LeftLeg"
	left_leg.position = Vector3(-0.11, 0.24, 0.0)
	add_child(left_leg)

	var l_leg_mesh = MeshInstance3D.new()
	l_leg_mesh.name = "LeftLegMesh"
	var leg_key = "en" if is_enemy else "al"
	l_leg_mesh.mesh = mesh_cache_leg.get(leg_key, mesh_cache_leg.values()[0])
	l_leg_mesh.material_override = mat_vertex_lit
	left_leg.add_child(l_leg_mesh)

	right_leg = Node3D.new()
	right_leg.name = "RightLeg"
	right_leg.position = Vector3(0.11, 0.24, 0.0)
	add_child(right_leg)

	var r_leg_mesh = MeshInstance3D.new()
	r_leg_mesh.name = "RightLegMesh"
	r_leg_mesh.mesh = mesh_cache_leg.get(leg_key, mesh_cache_leg.values()[0])
	r_leg_mesh.material_override = mat_vertex_lit
	right_leg.add_child(r_leg_mesh)

	# 3. Two-Handed Weapon Mount
	weapon_mount = Node3D.new()
	weapon_mount.name = "WeaponMount"
	weapon_mount.position = Vector3(0.08, 0.02, 0.24)
	torso_node.add_child(weapon_mount)

	weapon_mesh_instance = MeshInstance3D.new()
	weapon_mesh_instance.name = "WeaponMesh"
	weapon_mesh_instance.mesh = mesh_cache_weapon.get(current_weapon_id, mesh_cache_weapon[0])
	weapon_mesh_instance.material_override = mat_vertex_lit
	weapon_mount.add_child(weapon_mesh_instance)

	# Distinct Weapon Grip Arms
	var arm_color = COL_EN_FATIGUE if is_enemy else COL_AL_FATIGUE
	left_arm = Node3D.new()
	left_arm.position = Vector3(-0.21, 0.12, 0.0)
	torso_node.add_child(left_arm)

	var l_arm_cap = _make_capsule(0.055, 0.26, 8, 3)
	var l_arm_mesh = MeshInstance3D.new()
	l_arm_mesh.mesh = l_arm_cap
	l_arm_mesh.material_override = mat_vertex_lit
	l_arm_mesh.rotation_degrees = Vector3(-45, 25, 0)
	l_arm_mesh.position = Vector3(0.08, -0.06, 0.12)
	left_arm.add_child(l_arm_mesh)

	right_arm = Node3D.new()
	right_arm.position = Vector3(0.21, 0.12, 0.0)
	torso_node.add_child(right_arm)

	var r_arm_mesh = MeshInstance3D.new()
	r_arm_mesh.mesh = l_arm_cap
	r_arm_mesh.material_override = mat_vertex_lit
	r_arm_mesh.rotation_degrees = Vector3(-60, -18, 0)
	r_arm_mesh.position = Vector3(-0.06, -0.04, 0.10)
	right_arm.add_child(r_arm_mesh)

	# Muzzle Flash & Emitter Point
	muzzle_point = Node3D.new()
	muzzle_point.position = Vector3(0, 0.04, 0.42)
	weapon_mount.add_child(muzzle_point)

	muzzle_flash = MeshInstance3D.new()
	muzzle_flash.mesh = _make_sphere(0.11, 0.22, 8, 4)
	muzzle_flash.material_override = mat_flash
	muzzle_flash.visible = false
	muzzle_point.add_child(muzzle_flash)

	_apply_materials()

func _apply_materials() -> void:
	if lod_mesh_instance:
		lod_mesh_instance.material_override = mat_vertex_lit
		return

	if visor_mesh:
		visor_mesh.material_override = mat_enemy_visor if is_enemy else mat_ally_visor

func equip_weapon(wid: int) -> void:
	current_weapon_id = wid
	if lod_mesh_instance:
		var lod_key = "%s_%d_w%d" % ["en" if is_enemy else "al", variant, current_weapon_id]
		if mesh_cache_lod.has(lod_key):
			lod_mesh_instance.mesh = mesh_cache_lod[lod_key]
			lod_mesh_instance.material_override = mat_vertex_lit
		return

	if weapon_mesh_instance:
		weapon_mesh_instance.mesh = mesh_cache_weapon.get(wid, mesh_cache_weapon[0])
		weapon_mesh_instance.material_override = mat_vertex_lit
		if muzzle_point:
			match wid:
				0: muzzle_point.position = Vector3(0, 0.04, 0.44)
				1: muzzle_point.position = Vector3(0, 0.04, 0.46)
				2: muzzle_point.position = Vector3(0, 0.04, 0.48)

func animate_motion(delta: float, speed_factor: float = 1.0, is_articulated: bool = true, steer_bank: float = 0.0, phase_offset: float = 0.0) -> void:
	walk_time += delta * 12.0 * speed_factor

	# Smooth banking tilt into directional turns
	current_tilt = lerpf(current_tilt, steer_bank, delta * 14.0)

	if is_articulated:
		var stride = sin(walk_time + phase_offset)
		if left_leg:
			left_leg.rotation_degrees.x = stride * 32.0
		if right_leg:
			right_leg.rotation_degrees.x = -stride * 32.0

		if torso_node:
			# Energetic bouncy stride bobbing & banking tilt
			torso_node.position.y = 0.42 + abs(stride) * 0.055
			torso_node.rotation.z = current_tilt
	else:
		if lod_mesh_instance:
			var bounce = abs(sin(walk_time + phase_offset)) * 0.045
			lod_mesh_instance.position.y = bounce
			lod_mesh_instance.rotation.z = current_tilt

	# Weapon recoil recovery
	if recoil_offset > 0.0:
		recoil_offset = maxf(0.0, recoil_offset - delta * 0.90)
		if weapon_mount:
			weapon_mount.position.z = 0.24 - recoil_offset

	# Muzzle flash timer
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and muzzle_flash:
			muzzle_flash.visible = false

func trigger_recoil() -> void:
	recoil_offset = 0.12
	flash_timer = 0.05
	if weapon_mount:
		weapon_mount.position.z = 0.24 - recoil_offset
	if muzzle_flash:
		muzzle_flash.visible = true
		muzzle_flash.rotation_degrees.z = randf_range(0.0, 360.0)

func get_muzzle_global_position() -> Vector3:
	if muzzle_point and is_instance_valid(muzzle_point):
		return muzzle_point.global_position
	return global_position + Vector3(0, 0.45, -0.45)

func play_spawn() -> void:
	scale = Vector3(0.05, 0.05, 0.05)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func play_defeat(on_complete: Callable = Callable()) -> void:
	play_defeat_tumble(on_complete)

func play_defeat_tumble(on_complete: Callable = Callable()) -> void:
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "position:y", position.y + 0.35, 0.22)
	tw.tween_property(self, "position:z", position.z + 0.45, 0.30)
	tw.tween_property(self, "rotation_degrees:x", rotation_degrees.x + 85.0, 0.30)
	tw.tween_property(self, "rotation_degrees:z", randf_range(-45.0, 45.0), 0.30)
	tw.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.30)
	if on_complete.is_valid():
		tw.chain().tween_callback(on_complete)
