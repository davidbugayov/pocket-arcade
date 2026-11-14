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

var start_z: float = 0.0
var end_z: float = -200.0

func _ready() -> void:
	boss_container.visible = false
	pause_overlay.visible = false
	game_over_overlay.visible = false
	
	pause_button.pressed.connect(_on_pause_pressed)
	$PauseOverlay/VBox/ResumeBtn.pressed.connect(_on_resume_pressed)
	$PauseOverlay/VBox/RestartBtn.pressed.connect(_on_restart_pressed)
	$PauseOverlay/VBox/MenuBtn.pressed.connect(_on_menu_pressed)
	sound_btn.pressed.connect(_on_sound_toggled)
	
	next_btn.pressed.connect(func(): next_level_requested.emit())
	retry_btn.pressed.connect(func(): restart_requested.emit())
	menu_btn.pressed.connect(func(): menu_requested.emit())
	
	_update_sound_btn_text()

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

func _process(_delta: float) -> void:
	if not is_instance_valid(level_controller) or not is_instance_valid(level_controller.player_squad):
		return
	
	var cur_z = level_controller.player_squad.position.z
	var total_dist = abs(end_z - start_z)
	var covered = abs(cur_z - start_z)
	var pct = clampf((covered / total_dist) * 100.0, 0.0, 100.0)
	progress_bar.value = pct
	
	coins_label.text = str(GameManager.run_coins)

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

func _on_pause_pressed() -> void:
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
