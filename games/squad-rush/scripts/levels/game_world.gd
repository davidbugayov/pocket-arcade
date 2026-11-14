extends Node3D

class_name GameWorld

var current_level_node: LevelBase
var hud_node: HUD

func _ready() -> void:
	hud_node = $HUD as HUD
	if is_instance_valid(hud_node):
		hud_node.restart_requested.connect(_on_restart_level)
		hud_node.next_level_requested.connect(_on_next_level)
		hud_node.menu_requested.connect(_on_menu_requested)
	
	_load_level(GameManager.selected_level)

func _load_level(level_num: int) -> void:
	if is_instance_valid(current_level_node):
		current_level_node.queue_free()
	
	match level_num:
		1:
			current_level_node = Level1.new()
		2:
			current_level_node = Level2.new()
		3:
			current_level_node = Level3.new()
		_:
			current_level_node = Level1.new()
	
	add_child(current_level_node)
	
	if is_instance_valid(hud_node):
		current_level_node.hud = hud_node
		hud_node.setup_level(current_level_node)

func _on_restart_level() -> void:
	get_tree().paused = false
	_load_level(GameManager.selected_level)

func _on_next_level() -> void:
	get_tree().paused = false
	var next_lvl = mini(3, GameManager.selected_level + 1)
	GameManager.selected_level = next_lvl
	_load_level(next_lvl)

func _on_menu_requested() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
