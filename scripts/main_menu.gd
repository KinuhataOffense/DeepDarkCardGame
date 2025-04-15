extends Control

# 预加载场景
var node_map_scene = preload("res://scenes/map/node_map_scene.tscn")
var rogue_mode_scene = preload("res://scenes/rogue/rogue_mode_scene.tscn")

# 引用UI元素
@onready var map_mode_button = $ModesPanel/MapModeButton
@onready var rogue_mode_button = $ModesPanel/RogueModeButton
@onready var quit_button = $QuitButton

func _ready():
	# 连接按钮信号
	map_mode_button.pressed.connect(_on_map_mode_button_pressed)
	rogue_mode_button.pressed.connect(_on_rogue_mode_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	# 调整按钮大小以匹配文本
	_update_button_sizes()

# 更新按钮大小
func _update_button_sizes():
	for button in [$ModesPanel/MapModeButton, $ModesPanel/RogueModeButton, $QuitButton]:
		if button:
			button.custom_minimum_size.x = button.get_theme_font("font").get_string_size(
				button.text, button.get_theme_font_size("font_size")).x + 50
			button.size.x = button.custom_minimum_size.x

# 启动地图模式
func _on_map_mode_button_pressed():
	print("启动地图探索模式")
	
	var game_manager = get_node_or_null("/root/GameManager")
	
	game_manager.switch_to_scene(node_map_scene)


# 启动Rogue模式
func _on_rogue_mode_button_pressed():
	print("启动随机Rogue模式")
	
	# 获取游戏管理器和Rogue管理器
	var game_manager = get_node_or_null("/root/GameManager")

	await game_manager.switch_to_scene(rogue_mode_scene)

# 退出游戏
func _on_quit_button_pressed():
	get_tree().quit()
