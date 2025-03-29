extends Node2D  

@onready var card_pile_ui = $CardPileUI  
@onready var combination_zone = $CombinationDropzone  
@onready var enemy_ui = $EnemyDisplay  
@onready var game_manager = $GameManager  
@onready var player_stats = $PlayerStats  
@onready var ui = $UI  

# 在场景加载时连接信号  
func _ready():  
	randomize()
	# 连接组合区域的信号  
	if combination_zone:  
		combination_zone.connect("combination_resolved", _on_combination_resolved)  
	
	# 连接按钮信号  
	if ui.has_node("ActionButtons/EndTurnButton"):  
		ui.get_node("ActionButtons/EndTurnButton").connect("pressed", _on_end_turn_pressed)  
		
	if ui.has_node("ActionButtons/EnterShopButton"):  
		ui.get_node("ActionButtons/EnterShopButton").connect("pressed", _on_enter_shop_pressed)  
	
	# 连接测试按钮信号（如果存在）
	if ui.has_node("ActionButtons/TestRewardButton"):
		ui.get_node("ActionButtons/TestRewardButton").connect("pressed", _on_test_reward_pressed)
	
	# 连接游戏管理器信号
	game_manager.connect("enemy_defeated", _on_enemy_defeated)
	game_manager.connect("game_over", _on_game_over)

	# 初始化游戏  
	game_manager.initialize_game()
		
	# 更新UI初始状态  
	call_deferred("update_ui")

# 更新UI显示  
func update_ui():  
	if ui.has_node("ScoreDisplay"):  
		ui.get_node("ScoreDisplay").text = "分数: " + str(player_stats.current_score)  
	
	if ui.has_node("TurnsDisplay"):  
		ui.get_node("TurnsDisplay").text = "剩余行动: " + str(game_manager.turns_remaining)  
	
	if ui.has_node("PlayerHealth"):  
		ui.get_node("PlayerHealth").value = player_stats.health  
		ui.get_node("PlayerHealth").max_value = player_stats.max_health  

# 信号处理函数  
func _on_combination_resolved(combination_result):  
	# 显示组合结果  
	if ui.has_node("CombinationResult"):  
		var result_text = "组合: " + combination_result.type + "\n得分: " + str(combination_result.score)  
		ui.get_node("CombinationResult").text = result_text  
	
	# 记录之前的分数用于计算增加了多少
	var previous_score = player_stats.current_score
	
	# 更新得分  
	player_stats.add_score(combination_result.score)  
	
	# 记录分数增加了多少
	var score_gained = player_stats.current_score - previous_score
	print("玩家获得", score_gained, "分，当前总分:", player_stats.current_score)
	
	# 更新UI  
	update_ui()  
	
	# 检查游戏状态，让信号系统处理
	game_manager.check_game_state()
	
	print("Debug:turns_remaining:", game_manager.turns_remaining)
	
func _on_end_turn_pressed():  
	game_manager.end_player_turn()  
	update_ui()  

func _on_enter_shop_pressed():
	game_manager.enter_shop()  
		
func _on_enemy_defeated():  
	if ui.has_node("VictoryPanel"):  
		ui.get_node("VictoryPanel").visible = true  
	print("Debug: Game_scene detected enemy defeated")
	
	# 再次检查分数是否满足条件
	if player_stats.current_score < game_manager.score_required:
		print("警告: 分数不足，无法击败敌人")
		return
		
	print("玩家分数:", player_stats.current_score, "，所需分数:", game_manager.score_required)
	
	# 尝试找到场景管理器
	var scene_manager = get_node_or_null("/root/Main/SceneManager")
	if scene_manager:
		print("找到场景管理器，让场景管理器处理奖励场景")
		# 什么都不做，让场景管理器处理
	else:
		print("未找到场景管理器，游戏场景自行处理奖励")
		# 游戏场景自行处理奖励
		call_deferred("_show_reward_scene_fallback")
	
	print("胜利事件已触发，等待场景管理器处理...")

# 游戏场景自行处理奖励场景的后备方案
func _show_reward_scene_fallback():
	# 获取奖励数据
	var reward_data = {}
	
	if game_manager.current_enemy:
		if game_manager.current_enemy is Enemy:
			reward_data = game_manager.current_enemy.get_rewards()
		elif typeof(game_manager.current_enemy) == TYPE_DICTIONARY and game_manager.current_enemy.has("rewards"):
			reward_data = game_manager.current_enemy.rewards
		else:
			reward_data = {"currency": 50}
	
	print("游戏场景: 创建奖励场景")
	
	# 尝试加载奖励场景资源
	var reward_scene = load("res://scenes/reward_scene.tscn")
	if reward_scene:
		var reward_instance = reward_scene.instantiate()
		reward_instance.name = "RewardScene"
		get_tree().root.add_child(reward_instance)
		
		# 设置奖励数据
		reward_instance.set_reward_data(reward_data)
		
		# 连接返回地图信号
		reward_instance.return_to_map_requested.connect(_on_return_to_map_requested)
		
		print("游戏场景: 奖励场景创建成功")
	else:
		print("错误: 无法加载奖励场景资源")

# 处理从奖励场景返回地图的请求
func _on_return_to_map_requested():
	print("游戏场景: 收到返回地图请求")
	
	# 隐藏游戏场景
	visible = false
	
	# 移除游戏场景
	queue_free()
	
	# 尝试显示地图场景
	var map_scene = get_node_or_null("/root/Main/NodeMapScene")
	if map_scene:
		map_scene.visible = true
		print("游戏场景: 显示地图场景")
	else:
		print("警告: 无法找到地图场景")
		
		# 返回主菜单
		var main_menu = get_node_or_null("/root/Main/MainMenu")
		if main_menu:
			main_menu.visible = true
			print("游戏场景: 返回主菜单")

# 测试奖励场景
func _on_test_reward_pressed():
	print("测试按钮点击：直接显示奖励场景")
	
	# 尝试不同路径找到场景管理器
	var scene_manager = get_node_or_null("/root/Main/SceneManager")
	if scene_manager:
		print("找到场景管理器，调用测试函数")
		scene_manager.force_show_reward_scene(20)
	else:
		print("未找到场景管理器，游戏场景自行创建奖励场景")
		# 游戏场景自行处理奖励
		var reward_data = {"currency": 20}
		
		# 尝试加载奖励场景资源
		var reward_scene = load("res://scenes/reward_scene.tscn")
		if reward_scene:
			var reward_instance = reward_scene.instantiate()
			reward_instance.name = "RewardScene"
			get_tree().root.add_child(reward_instance)
			
			# 设置奖励数据
			reward_instance.set_reward_data(reward_data)
			
			# 连接返回地图信号
			reward_instance.return_to_map_requested.connect(_on_return_to_map_requested)
			
			print("测试: 奖励场景创建成功")
		else:
			print("错误: 无法加载奖励场景资源")

func _on_game_over(win: bool = false):  
	if ui.has_node("GameOverPanel"):  
		ui.get_node("GameOverPanel").get_node("ResultLabel").text = "失败!"  
		ui.get_node("GameOverPanel").visible = true  
		
	# 处理失败逻辑
	game_manager.process_defeat()
	
	# 延迟返回主菜单或重新开始
	await get_tree().create_timer(3.0).timeout
	
	# 这里可以添加返回主菜单或重新开始的逻辑
	get_tree().reload_current_scene()
