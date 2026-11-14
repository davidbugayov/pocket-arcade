extends CanvasLayer

class_name HUD

signal pause_requested()
signal resume_requested()
signal restart_requested()
signal menu_requested()
signal next_level_requested()

var level_controller: LevelBase

@onready var top_bar: Control = $TopBar
@onready var level_label: Label = $TopBar/LevelLabel
@onready var pause_button: Button = $TopBar/PauseButton
@onready var progress_bar: ProgressBar = $TopBar/ProgressBar
@onready var coins_label: Label = $TopBar/CoinContainer/CoinsLabel

@onready var boss_container: Control = $BossContainer
@onready var boss_name_label: Label = $BossContainer/BossNameLabel
@onready var boss_hp_bar: ProgressBar = $BossContainer/BossHPBar

@onready var pause_overlay: Control = $PauseOverlay
@onready var sound_btn: Button = $PauseOverlay/VBox/SoundBtn

@onready var game_over_overlay: Control = $GameOverOverlay
@onready var game_over_title: Label = $GameOverOverlay/VBox/TitleLabel
@onready var game_over_subtitle: Label = $GameOverOverlay/VBox/SubtitleLabel
@onready var game_over_coins: Label = $GameOverOverlay/VBox/CoinsLabel
@onready var next_btn: Button = $GameOverOverlay/VBox/NextBtn
@onready var retry_btn: Button = $GameOverOverlay/VBox/RetryBtn
@onready var menu_btn: Button = $GameOverOverlay/VBox/MenuBtn

var damage_flash_rect: ColorRect
var toast_label: Label
@onready var tutorial_panel: PanelContainer = $TutorialBox/TutorialPill
@onready var tutorial_label: Label = $TutorialBox/TutorialPill/TutorialLabel
var tutorial_tween: Tween

var start_z: float = 0.0
var end_z: float = -200.0
var fps_log_timer: float = 0.0

func _ready() -> void:
	boss_container.visible = false
	pause_overlay.visible = false
	game_over_overlay.visible = false
	pause_button.text = "" # Ensured clear of fallback unicode square

	_create_damage_flash_overlay()
	_create_toast_ui()
	_setup_tutorial_ui()

	pause_button.pressed.connect(_on_pause_pressed)
	$PauseOverlay/VBox/ResumeBtn.pressed.connect(_on_resume_pressed)
	$PauseOverlay/VBox/RestartBtn.pressed.connect(_on_restart_pressed)
	$PauseOverlay/VBox/MenuBtn.pressed.connect(_on_menu_pressed)
	sound_btn.pressed.connect(_on_sound_toggled)

	next_btn.pressed.connect(func(): next_level_requested.emit())
	retry_btn.pressed.connect(func(): restart_requested.emit())
	menu_btn.pressed.connect(func(): menu_requested.emit())

	_update_sound_btn_text()

func _create_damage_flash_overlay() -> void:
	damage_flash_rect = ColorRect.new()
	damage_flash_rect.name = "DamageFlashOverlay"
	damage_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_flash_rect.color = Color(1.0, 0.0, 0.0, 0.0)
	add_child(damage_flash_rect)

func _create_toast_ui() -> void:
	toast_label = Label.new()
	toast_label.name = "ToastLabel"
	toast_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toast_label.offset_top = 220.0
	toast_label.offset_bottom = 280.0
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 32)
	toast_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	toast_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	toast_label.add_theme_constant_override("shadow_offset_y", 3)
	toast_label.visible = false
	add_child(toast_label)

func _setup_tutorial_ui() -> void:
	if not is_instance_valid(tutorial_panel):
		return
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.15, 0.90)
	style.border_color = Color(0.2, 0.75, 1.0, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	tutorial_panel.add_theme_stylebox_override("panel", style)
	tutorial_panel.visible = false

func show_tutorial_hint(hint_text: String, duration: float = 3.2) -> void:
	if not is_instance_valid(tutorial_panel) or not is_instance_valid(tutorial_label):
		return

	# Strictly one hint visible at a time: kill active tween and smoothly transition
	if tutorial_tween and tutorial_tween.is_valid():
		tutorial_tween.kill()

	tutorial_label.text = hint_text
	tutorial_panel.visible = true
	tutorial_panel.modulate = Color(1, 1, 1, 0.0)

	tutorial_tween = create_tween()
	tutorial_tween.tween_property(tutorial_panel, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE)
	tutorial_tween.tween_interval(duration)
	tutorial_tween.tween_property(tutorial_panel, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	tutorial_tween.finished.connect(func(): if is_instance_valid(tutorial_panel): tutorial_panel.visible = false)

func trigger_damage_flash() -> void:
	if not is_instance_valid(damage_flash_rect):
		return
	damage_flash_rect.color = Color(1.0, 0.05, 0.05, 0.32)
	var tw = create_tween()
	tw.tween_property(damage_flash_rect, "color", Color(1.0, 0.0, 0.0, 0.0), 0.25).set_trans(Tween.TRANS_SINE)

func show_toast(msg: String) -> void:
	if not is_instance_valid(toast_label):
		return
	toast_label.text = msg
	toast_label.visible = true
	toast_label.modulate = Color(1, 1, 1, 1)
	toast_label.scale = Vector2(1.2, 1.2)
	var tw = create_tween()
	tw.tween_property(toast_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(1.2)
	tw.tween_property(toast_label, "modulate:a", 0.0, 0.3)
	tw.finished.connect(func(): toast_label.visible = false)

func setup_level(level: LevelBase) -> void:
	level_controller = level
	level_label.text = "LEVEL " + str(level.level_number)
	start_z = 0.0
	end_z = level.boss_z_position

	boss_container.visible = false
	pause_overlay.visible = false
	game_over_overlay.visible = false

	level.level_won.connect(show_victory)
	level.level_lost.connect(show_defeat)

func _process(delta: float) -> void:
	if not is_instance_valid(level_controller) or not is_instance_valid(level_controller.player_squad):
		return

	var cur_z = level_controller.player_squad.position.z
	var total_dist = abs(end_z - start_z)
	var covered = abs(cur_z - start_z)
	var pct = clampf((covered / total_dist) * 100.0, 0.0, 100.0)
	progress_bar.value = pct

	coins_label.text = str(GameManager.run_coins)

	fps_log_timer += delta
	if fps_log_timer >= 1.0:
		fps_log_timer = 0.0
		var current_fps = Engine.get_frames_per_second()
		var sq_size = level_controller.player_squad.squad_count
		print("[PERF_METRICS] FPS: %d | Squad size: %d | Progress: %d%%" % [current_fps, sq_size, int(pct)])

func show_boss_bar(b_name: String, max_hp: float) -> void:
	boss_name_label.text = b_name.to_upper()
	boss_hp_bar.max_value = max_hp
	boss_hp_bar.value = max_hp
	boss_container.visible = true

func update_boss_hp(cur_hp: float, max_hp: float) -> void:
	boss_hp_bar.max_value = max_hp
	boss_hp_bar.value = cur_hp

func show_victory() -> void:
	boss_container.visible = false
	game_over_title.text = "VICTORY!"
	game_over_title.modulate = Color(0.2, 1.0, 0.4)
	game_over_subtitle.text = "LEVEL COMPLETE"
	game_over_coins.text = "Coins Earned: +" + str(GameManager.run_coins)

	next_btn.visible = (level_controller.level_number < 3)
	game_over_overlay.visible = true

func show_defeat() -> void:
	boss_container.visible = false
	game_over_title.text = "DEFEAT"
	game_over_title.modulate = Color(1.0, 0.25, 0.25)
	game_over_subtitle.text = "ALL FIGHTERS LOST"
	game_over_coins.text = "Coins Earned: +" + str(GameManager.run_coins)
	next_btn.visible = false
	game_over_overlay.visible = true

func trigger_safe_pause() -> void:
	if pause_overlay.visible or game_over_overlay.visible:
		return
	_on_pause_pressed()

func _on_pause_pressed() -> void:
	if pause_overlay.visible:
		return
	SoundManager.play("click")
	pause_overlay.visible = true
	get_tree().paused = true
	pause_requested.emit()

func _on_resume_pressed() -> void:
	SoundManager.play("click")
	pause_overlay.visible = false
	get_tree().paused = false
	resume_requested.emit()

func _on_restart_pressed() -> void:
	SoundManager.play("click")
	pause_overlay.visible = false
	get_tree().paused = false
	restart_requested.emit()

func _on_menu_pressed() -> void:
	SoundManager.play("click")
	pause_overlay.visible = false
	get_tree().paused = false
	menu_requested.emit()

func _on_sound_toggled() -> void:
	GameManager.toggle_sound()
	_update_sound_btn_text()
	SoundManager.play("click")

func _update_sound_btn_text() -> void:
	sound_btn.text = "SOUND: ON" if GameManager.sound_enabled else "SOUND: OFF"
