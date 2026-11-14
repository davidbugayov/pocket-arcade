extends Node

# Pocket Arcade: Squad Rush - Global Game Manager

const SAVE_PATH = "user://squad_rush_save.json"

signal coins_changed(new_coins: int)
signal upgrades_changed()

var coins: int = 0
var highest_unlocked_level: int = 1
var selected_level: int = 1
var sound_enabled: bool = true

# Upgrade levels (0-based)
var upgrade_squad_size: int = 0     # +1 starting squad per level
var upgrade_damage: int = 0         # +25% damage per level
var upgrade_fire_rate: int = 0      # +10% fire rate per level

# Weapons: 0 = Rifle, 1 = Shotgun, 2 = Minigun
var current_weapon_index: int = 0
var unlocked_weapons: Array[int] = [0] # 0 always unlocked

# In-run transient state
var run_coins: int = 0
var run_kills: int = 0

const UPGRADE_BASE_COSTS = {
	"squad": 40,
	"damage": 50,
	"fire_rate": 45,
}

const WEAPON_DATA = [
	{
		"id": 0,
		"name": "Assault Rifle",
		"desc": "Balanced rate and precision",
		"damage": 12.0,
		"fire_delay": 0.22,
		"bullet_speed": 40.0,
		"spread_count": 1,
		"color": Color(0.2, 0.8, 1.0),
		"cost": 0,
	},
	{
		"id": 1,
		"name": "Combat Shotgun",
		"desc": "3-pellet heavy spread",
		"damage": 9.0,
		"fire_delay": 0.38,
		"bullet_speed": 36.0,
		"spread_count": 3,
		"color": Color(1.0, 0.6, 0.1),
		"cost": 150,
	},
	{
		"id": 2,
		"name": "Plasma Minigun",
		"desc": "Rapid-fire plasma stream",
		"damage": 7.0,
		"fire_delay": 0.11,
		"bullet_speed": 46.0,
		"spread_count": 1,
		"color": Color(0.9, 0.2, 1.0),
		"cost": 300,
	}
]

func _ready() -> void:
	load_game()

func get_starting_squad_size() -> int:
	return 1 + upgrade_squad_size

func get_damage_multiplier() -> float:
	return 1.0 + (upgrade_damage * 0.25)

func get_fire_rate_multiplier() -> float:
	return 1.0 + (upgrade_fire_rate * 0.12)

func get_weapon_data(idx: int = -1) -> Dictionary:
	var id = current_weapon_index if idx < 0 else idx
	id = clampi(id, 0, WEAPON_DATA.size() - 1)
	return WEAPON_DATA[id]

func get_upgrade_cost(type: String) -> int:
	var lvl = 0
	match type:
		"squad": lvl = upgrade_squad_size
		"damage": lvl = upgrade_damage
		"fire_rate": lvl = upgrade_fire_rate
	var base = UPGRADE_BASE_COSTS.get(type, 50)
	return int(base * (1.0 + lvl * 0.75))

func buy_upgrade(type: String) -> bool:
	var cost = get_upgrade_cost(type)
	if coins < cost:
		return false
	coins -= cost
	match type:
		"squad": upgrade_squad_size += 1
		"damage": upgrade_damage += 1
		"fire_rate": upgrade_fire_rate += 1
	save_game()
	coins_changed.emit(coins)
	upgrades_changed.emit()
	return true

func buy_weapon(idx: int) -> bool:
	if idx in unlocked_weapons:
		select_weapon(idx)
		return true
	if idx < 0 or idx >= WEAPON_DATA.size():
		return false
	var cost = WEAPON_DATA[idx]["cost"]
	if coins < cost:
		return false
	coins -= cost
	unlocked_weapons.append(idx)
	current_weapon_index = idx
	save_game()
	coins_changed.emit(coins)
	upgrades_changed.emit()
	return true

func select_weapon(idx: int) -> void:
	if idx in unlocked_weapons:
		current_weapon_index = idx
		save_game()
		upgrades_changed.emit()

func add_coins(amount: int) -> void:
	coins += amount
	run_coins += amount
	coins_changed.emit(coins)

func reset_run_stats() -> void:
	run_coins = 0
	run_kills = 0

func complete_level(level_num: int) -> void:
	if level_num >= highest_unlocked_level and highest_unlocked_level < 3:
		highest_unlocked_level = level_num + 1
	save_game()

func toggle_sound() -> bool:
	sound_enabled = !sound_enabled
	save_game()
	return sound_enabled

func save_game() -> void:
	var data = {
		"coins": coins,
		"highest_unlocked_level": highest_unlocked_level,
		"sound_enabled": sound_enabled,
		"upgrade_squad_size": upgrade_squad_size,
		"upgrade_damage": upgrade_damage,
		"upgrade_fire_rate": upgrade_fire_rate,
		"current_weapon_index": current_weapon_index,
		"unlocked_weapons": unlocked_weapons,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "  "))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var content = file.get_as_text()
	file.close()
	var test_json_conv = JSON.new()
	var parse_err = test_json_conv.parse(content)
	if parse_err != OK:
		return
	var data = test_json_conv.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return
	
	coins = int(data.get("coins", 0))
	highest_unlocked_level = clampi(int(data.get("highest_unlocked_level", 1)), 1, 3)
	sound_enabled = bool(data.get("sound_enabled", true))
	upgrade_squad_size = int(data.get("upgrade_squad_size", 0))
	upgrade_damage = int(data.get("upgrade_damage", 0))
	upgrade_fire_rate = int(data.get("upgrade_fire_rate", 0))
	current_weapon_index = int(data.get("current_weapon_index", 0))
	var unl_w = data.get("unlocked_weapons", [0])
	unlocked_weapons.clear()
	for w in unl_w:
		unlocked_weapons.append(int(w))
	if 0 not in unlocked_weapons:
		unlocked_weapons.append(0)

