extends Control

class_name MainMenu

# UI References
@onready var coins_label: Label = $TopPanel/CoinBox/CoinsLabel
@onready var sound_btn: Button = $TopPanel/SoundBtn
@onready var compare_btn: Button = $TopPanel.get_node_or_null("CompareBtn")

# Primary CTA Button
@onready var play_btn: Button = $BottomArea/PlayBtn

# Nav Toggle Buttons
@onready var upg_toggle_btn: Button = $BottomArea/NavRow/UpgradesToggleBtn
@onready var armory_toggle_btn: Button = $BottomArea/NavRow/ArmoryToggleBtn
@onready var missions_toggle_btn: Button = $BottomArea/NavRow/MissionsToggleBtn

# Drawers / Overlays
@onready var upgrades_drawer: Control = $UpgradesDrawer
@onready var armory_drawer: Control = $ArmoryDrawer
@onready var missions_drawer: Control = $MissionsDrawer

# Drawer Close Buttons
@onready var upg_close_btn: Button = $UpgradesDrawer/DrawerBox/CloseBtn
@onready var armory_close_btn: Button = $ArmoryDrawer/DrawerBox/CloseBtn
@onready var missions_close_btn: Button = $MissionsDrawer/DrawerBox/CloseBtn

# Level Select Buttons
@onready var lvl1_btn: Button = $MissionsDrawer/DrawerBox/LevelSelect/Lvl1Btn
@onready var lvl2_btn: Button = $MissionsDrawer/DrawerBox/LevelSelect/Lvl2Btn
@onready var lvl3_btn: Button = $MissionsDrawer/DrawerBox/LevelSelect/Lvl3Btn

# Upgrade Row References
@onready var upg_squad_btn: Button = $UpgradesDrawer/DrawerBox/UpgradesBox/SquadRow/UpgBtn
@onready var upg_squad_lbl: Label = $UpgradesDrawer/DrawerBox/UpgradesBox/SquadRow/StatLbl

@onready var upg_dmg_btn: Button = $UpgradesDrawer/DrawerBox/UpgradesBox/DmgRow/UpgBtn
@onready var upg_dmg_lbl: Label = $UpgradesDrawer/DrawerBox/UpgradesBox/DmgRow/StatLbl

@onready var upg_fire_btn: Button = $UpgradesDrawer/DrawerBox/UpgradesBox/FireRow/UpgBtn
@onready var upg_fire_lbl: Label = $UpgradesDrawer/DrawerBox/UpgradesBox/FireRow/StatLbl

# Armory References
@onready var weapon_tab: HBoxContainer = $ArmoryDrawer/DrawerBox/WeaponArmory/WeaponRow

var next_available_mission: int = 1

func _ready() -> void:
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.upgrades_changed.connect(_on_upgrades_changed)

	# Primary Play CTA
	play_btn.pressed.connect(_on_play_pressed)

	# Drawer Toggles
	upg_toggle_btn.pressed.connect(func(): _toggle_drawer(upgrades_drawer))
	armory_toggle_btn.pressed.connect(func(): _toggle_drawer(armory_drawer))
	missions_toggle_btn.pressed.connect(func(): _toggle_drawer(missions_drawer))

	# Drawer Close Buttons
	upg_close_btn.pressed.connect(func(): _close_all_drawers())
	armory_close_btn.pressed.connect(func(): _close_all_drawers())
	missions_close_btn.pressed.connect(func(): _close_all_drawers())

	# Level Buttons
	lvl1_btn.pressed.connect(func(): _start_level(1))
	lvl2_btn.pressed.connect(func(): _start_level(2))
	lvl3_btn.pressed.connect(func(): _start_level(3))

	# Upgrade Actions
	upg_squad_btn.pressed.connect(func(): _buy_upgrade("squad"))
	upg_dmg_btn.pressed.connect(func(): _buy_upgrade("damage"))
	upg_fire_btn.pressed.connect(func(): _buy_upgrade("fire_rate"))

	sound_btn.pressed.connect(_on_sound_toggled)
	if compare_btn:
		compare_btn.pressed.connect(_on_compare_clicked)

	_setup_button_styles()
	_setup_weapon_buttons()
	_close_all_drawers()
	_refresh_ui()

func _setup_button_styles() -> void:
	# 1. Primary Play CTA Button Style (Glowing Emerald Green Military Tactical Style)
	var sb_play = StyleBoxFlat.new()
	sb_play.bg_color = Color(0.05, 0.18, 0.12, 0.92)
	sb_play.border_color = Color(0.18, 0.92, 0.45, 1.0)
	sb_play.set_border_width_all(3)
	sb_play.set_corner_radius_all(18)
	sb_play.shadow_color = Color(0.18, 0.92, 0.45, 0.25)
	sb_play.shadow_size = 8

	var sb_play_pressed = StyleBoxFlat.new()
	sb_play_pressed.bg_color = Color(0.10, 0.32, 0.20, 0.98)
	sb_play_pressed.border_color = Color(0.40, 1.0, 0.60, 1.0)
	sb_play_pressed.set_border_width_all(3)
	sb_play_pressed.set_corner_radius_all(18)

	play_btn.add_theme_stylebox_override("normal", sb_play)
	play_btn.add_theme_stylebox_override("hover", sb_play)
	play_btn.add_theme_stylebox_override("pressed", sb_play_pressed)

	# 2. Secondary Pill Navigation Buttons
	var sb_nav = StyleBoxFlat.new()
	sb_nav.bg_color = Color(0.08, 0.12, 0.18, 0.88)
	sb_nav.border_color = Color(0.25, 0.45, 0.65, 0.8)
	sb_nav.set_border_width_all(1)
	sb_nav.set_corner_radius_all(12)

	for btn in [upg_toggle_btn, armory_toggle_btn, missions_toggle_btn]:
		if is_instance_valid(btn):
			btn.add_theme_stylebox_override("normal", sb_nav)

	# 3. Drawer Styles
	var sb_drawer = StyleBoxFlat.new()
	sb_drawer.bg_color = Color(0.06, 0.09, 0.15, 0.96)
	sb_drawer.border_color = Color(0.20, 0.55, 0.85, 0.90)
	sb_drawer.set_border_width_all(2)
	sb_drawer.set_corner_radius_all(18)
	sb_drawer.content_margin_left = 24.0
	sb_drawer.content_margin_right = 24.0
	sb_drawer.content_margin_top = 20.0
	sb_drawer.content_margin_bottom = 20.0

	for d in [upgrades_drawer, armory_drawer, missions_drawer]:
		if is_instance_valid(d):
			d.add_theme_stylebox_override("panel", sb_drawer)

func _close_all_drawers() -> void:
	upgrades_drawer.visible = false
	armory_drawer.visible = false
	missions_drawer.visible = false

func _toggle_drawer(target_drawer: Control) -> void:
	SoundManager.play("click")
	var will_open = not target_drawer.visible
	_close_all_drawers()
	target_drawer.visible = will_open

func _on_play_pressed() -> void:
	SoundManager.play("click")
	_start_level(next_available_mission)

func _refresh_ui() -> void:
	coins_label.text = str(GameManager.coins)
	sound_btn.text = "SOUND: ON" if GameManager.sound_enabled else "SOUND: OFF"

	# Calculate nearest available mission
	var unl = GameManager.highest_unlocked_level
	next_available_mission = clampi(unl, 1, 3)

	# Primary Action Button: Clear, prominent, shows immediate next step
	var mission_names = {
		1: "MISSION 1: DOCKS ASSAULT",
		2: "MISSION 2: THE DIVIDE",
		3: "MISSION 3: FINAL TITAN"
	}
	var m_name = mission_names.get(next_available_mission, "MISSION " + str(next_available_mission))

	if unl == 1 and GameManager.coins == 0:
		play_btn.text = m_name + "\n▶ PLAY"
	else:
		play_btn.text = m_name + "\n▶ CONTINUE"

	# Level buttons in Missions Drawer
	lvl1_btn.disabled = false
	lvl2_btn.disabled = (unl < 2)
	lvl3_btn.disabled = (unl < 3)

	lvl2_btn.text = "LEVEL 2: THE DIVIDE" if unl >= 2 else "LOCKED (LVL 2)"
	lvl3_btn.text = "LEVEL 3: FINAL TITAN" if unl >= 3 else "LOCKED (LVL 3)"

	# Upgrade Squad Size
	var sq_cost = GameManager.get_upgrade_cost("squad")
	upg_squad_lbl.text = "Squad Size: " + str(GameManager.get_starting_squad_size())
	upg_squad_btn.text = str(sq_cost) + " COINS"
	upg_squad_btn.disabled = (GameManager.coins < sq_cost)

	# Upgrade Damage
	var dmg_cost = GameManager.get_upgrade_cost("damage")
	upg_dmg_lbl.text = "Damage: +" + str(GameManager.upgrade_damage * 25) + "%"
	upg_dmg_btn.text = str(dmg_cost) + " COINS"
	upg_dmg_btn.disabled = (GameManager.coins < dmg_cost)

	# Upgrade Fire Rate
	var fire_cost = GameManager.get_upgrade_cost("fire_rate")
	upg_fire_lbl.text = "Fire Rate: +" + str(GameManager.upgrade_fire_rate * 12) + "%"
	upg_fire_btn.text = str(fire_cost) + " COINS"
	upg_fire_btn.disabled = (GameManager.coins < fire_cost)

	_update_weapon_buttons_state()

func _setup_weapon_buttons() -> void:
	for child in weapon_tab.get_children():
		child.queue_free()

	for i in range(GameManager.WEAPON_DATA.size()):
		var wdata = GameManager.WEAPON_DATA[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(170, 75)
		weapon_tab.add_child(btn)
		var widx = i
		btn.pressed.connect(func(): _on_weapon_clicked(widx))

func _update_weapon_buttons_state() -> void:
	var children = weapon_tab.get_children()
	for i in range(children.size()):
		var btn = children[i] as Button
		var wdata = GameManager.WEAPON_DATA[i]
		var is_unlocked = (i in GameManager.unlocked_weapons)
		var is_selected = (i == GameManager.current_weapon_index)

		if is_selected:
			btn.text = wdata["name"] + "\n[EQUIPPED]"
			btn.modulate = Color(0.2, 1.0, 0.4)
		elif is_unlocked:
			btn.text = wdata["name"] + "\n[EQUIP]"
			btn.modulate = Color(1.0, 1.0, 1.0)
		else:
			btn.text = wdata["name"] + "\n" + str(wdata["cost"]) + " G"
			btn.modulate = Color(1.0, 0.8, 0.2)

func _on_weapon_clicked(idx: int) -> void:
	SoundManager.play("click")
	if idx in GameManager.unlocked_weapons:
		GameManager.select_weapon(idx)
	else:
		GameManager.buy_weapon(idx)
	_refresh_ui()

func _buy_upgrade(type: String) -> void:
	if GameManager.buy_upgrade(type):
		SoundManager.play("coin")
		_refresh_ui()
	else:
		SoundManager.play("gate_negative")

func _start_level(num: int) -> void:
	SoundManager.play("click")
	GameManager.selected_level = num
	get_tree().change_scene_to_file("res://scenes/game_world.tscn")

func _on_sound_toggled() -> void:
	GameManager.toggle_sound()
	sound_btn.text = "SOUND: ON" if GameManager.sound_enabled else "SOUND: OFF"
	SoundManager.play("click")

func _on_compare_clicked() -> void:
	SoundManager.play("click")
	get_tree().change_scene_to_file("res://scenes/model_comparison.tscn")

func _on_coins_changed(_new_coins: int) -> void:
	_refresh_ui()

func _on_upgrades_changed() -> void:
	_refresh_ui()
