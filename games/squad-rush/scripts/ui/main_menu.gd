extends Control

class_name MainMenu

# UI References
@onready var coins_label: Label = $TopPanel/CoinBox/CoinsLabel
@onready var sound_btn: Button = $TopPanel/SoundBtn

@onready var lvl1_btn: Button = $VBox/LevelSelect/Lvl1Btn
@onready var lvl2_btn: Button = $VBox/LevelSelect/Lvl2Btn
@onready var lvl3_btn: Button = $VBox/LevelSelect/Lvl3Btn

@onready var upg_squad_btn: Button = $VBox/UpgradesBox/SquadRow/UpgBtn
@onready var upg_squad_lbl: Label = $VBox/UpgradesBox/SquadRow/StatLbl

@onready var upg_dmg_btn: Button = $VBox/UpgradesBox/DmgRow/UpgBtn
@onready var upg_dmg_lbl: Label = $VBox/UpgradesBox/DmgRow/StatLbl

@onready var upg_fire_btn: Button = $VBox/UpgradesBox/FireRow/UpgBtn
@onready var upg_fire_lbl: Label = $VBox/UpgradesBox/FireRow/StatLbl

@onready var weapon_tab: HBoxContainer = $VBox/WeaponArmory/WeaponRow

func _ready() -> void:
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.upgrades_changed.connect(_on_upgrades_changed)
	
	lvl1_btn.pressed.connect(func(): _start_level(1))
	lvl2_btn.pressed.connect(func(): _start_level(2))
	lvl3_btn.pressed.connect(func(): _start_level(3))
	
	upg_squad_btn.pressed.connect(func(): _buy_upgrade("squad"))
	upg_dmg_btn.pressed.connect(func(): _buy_upgrade("damage"))
	upg_fire_btn.pressed.connect(func(): _buy_upgrade("fire_rate"))
	
	sound_btn.pressed.connect(_on_sound_toggled)
	
	_setup_weapon_buttons()
	_refresh_ui()

func _refresh_ui() -> void:
	coins_label.text = str(GameManager.coins)
	sound_btn.text = "SOUND: ON" if GameManager.sound_enabled else "SOUND: OFF"
	
	# Level buttons
	var unl = GameManager.highest_unlocked_level
	lvl1_btn.disabled = false
	lvl2_btn.disabled = (unl < 2)
	lvl3_btn.disabled = (unl < 3)
	
	lvl2_btn.text = "LEVEL 2" if unl >= 2 else "LOCKED (LVL 2)"
	lvl3_btn.text = "LEVEL 3" if unl >= 3 else "LOCKED (LVL 3)"
	
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
		btn.custom_minimum_size = Vector2(180, 70)
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

func _on_coins_changed(_new_coins: int) -> void:
	_refresh_ui()

func _on_upgrades_changed() -> void:
	_refresh_ui()

