extends Node  

var game_scene = preload("res://scenes/game_scene.tscn")  
var shop_scene = preload("res://scenes/shop_scene.tscn")  
var current_game_manager = null  

func _ready():  
	# 连接主菜单按钮信号  
	var start_button = get_node("../MainMenu/StartButton")  
	var quit_button = get_node("../MainMenu/QuitButton")  
	
	start_button.pressed.connect(_on_start_game)  
	quit_button.pressed.connect(_on_quit_game)  

func _on_start_game():  
	# 隐藏主菜单  
	get_node("../MainMenu").visible = false  
	
	# 实例化游戏场景  
	var game_instance = game_scene.instantiate()  
	add_child(game_instance)  
	
	# 保存游戏管理器引用  
	current_game_manager = game_instance.get_node("GameManager")  
	
	# 连接游戏管理器的商店信号  
	current_game_manager.enter_shop_requested.connect(_on_enter_shop)  
	current_game_manager.return_to_game_requested.connect(_on_return_to_game)  

func _on_quit_game():  
	get_tree().quit()  
	
func _on_enter_shop():  
	# 移除当前游戏场景，但保留游戏状态  
	var current_game = get_node_or_null("GameScene")  
	if current_game:  
		current_game.visible = false  
	
	# 实例化商店场景  
	var shop_instance = shop_scene.instantiate()  
	add_child(shop_instance)  
	shop_instance.initialize(current_game_manager)  
	
func _on_return_to_game():  
	# 移除商店场景  
	var current_shop = get_node_or_null("ShopScene")  
	if current_shop:  
		current_shop.queue_free()  
	
	# 恢复游戏场景  
	var current_game = get_node_or_null("GameScene")  
	if current_game:  
		current_game.visible = true  
	else:  
		# 如果游戏场景已被移除，则重新创建  
		var game_instance = game_scene.instantiate()  
		add_child(game_instance)  
		current_game_manager = game_instance.get_node("GameManager")  
