extends Node3D

class_name SquadMember

var target_offset: Vector3 = Vector3.ZERO
var fire_timer: float = 0.0
var is_active: bool = true
var current_equipped_weapon: int = -1

var soldier_model: StylizedSoldier
var body_mesh: MeshInstance3D
var muzzle_point: Node3D

signal shot_fired(spawn_pos: Vector3, direction: Vector3, damage: float, speed: float, color: Color)

func _ready() -> void:
	_build_model()
	fire_timer = randf() * 0.15

func _build_model() -> void:
	soldier_model = StylizedSoldier.new()
	add_child(soldier_model)
	soldier_model.setup_team(false) # Ally (Blue)

	# Compatibility references for PlayerSquad
	var t_m = soldier_model.torso_node.get_node_or_null("TorsoMesh")
	if t_m is MeshInstance3D:
		body_mesh = t_m
	muzzle_point = soldier_model.muzzle_point

func set_target_offset(offset: Vector3) -> void:
	target_offset = offset

func update_member(delta: float, can_shoot: bool, weapon_data: Dictionary, dmg_mult: float, fire_mult: float, articulate: bool = true) -> void:
	if not is_active:
		return

	position = position.lerp(target_offset, delta * 12.0)

	# Update weapon model only when changed
	var wid: int = weapon_data.get("id", 0)
	if soldier_model:
		if current_equipped_weapon != wid:
			current_equipped_weapon = wid
			soldier_model.equip_weapon(wid)
		soldier_model.animate_motion(delta, 1.0, articulate)

	if can_shoot:
		fire_timer -= delta
		var base_delay: float = weapon_data.get("fire_delay", 0.22)
		var actual_delay = maxf(0.05, base_delay / fire_mult)

		if fire_timer <= 0.0:
			fire_timer = actual_delay
			_fire(weapon_data, dmg_mult)

func _fire(weapon_data: Dictionary, dmg_mult: float) -> void:
	var base_dmg: float = weapon_data.get("damage", 10.0)
	var final_dmg: float = base_dmg * dmg_mult
	var b_speed: float = weapon_data.get("bullet_speed", 40.0)
	var spread_count: int = weapon_data.get("spread_count", 1)
	var b_color: Color = weapon_data.get("color", Color(0.2, 0.8, 1.0))
	var wid: int = weapon_data.get("id", 0)

	if soldier_model:
		soldier_model.trigger_recoil()

	var spawn_pos = soldier_model.get_muzzle_global_position() if soldier_model else global_position + Vector3(0, 0.45, -0.45)
	var forward = -global_transform.basis.z
	var right = global_transform.basis.x

	if spread_count <= 1:
		shot_fired.emit(spawn_pos, forward, final_dmg, b_speed, b_color)
	else:
		var spread_angle_step = 0.08
		var start_angle = -spread_angle_step * (spread_count - 1) * 0.5
		for i in range(spread_count):
			var angle = start_angle + i * spread_angle_step
			var dir = (forward + right * tan(angle)).normalized()
			shot_fired.emit(spawn_pos, dir, final_dmg, b_speed, b_color)

func play_spawn_anim() -> void:
	if soldier_model:
		soldier_model.play_spawn()
	else:
		scale = Vector3(0.05, 0.05, 0.05)
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func play_death_anim(on_complete: Callable) -> void:
	is_active = false
	if soldier_model:
		soldier_model.play_defeat(on_complete)
	else:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.finished.connect(on_complete)
