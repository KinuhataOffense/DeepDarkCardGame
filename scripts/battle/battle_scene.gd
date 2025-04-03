extends Node2D  

@onready var card_pile_ui = $CardPileUI  
@onready var combination_zone = $CombinationDropzone  
@onready var enemy_ui = $EnemyDisplay  
@onready var game_manager = null
@onready var player_stats = null
@onready var ui = $UI  

# 在场景加载时连接信号  
func _ready():  
	game_manager = get_node("/root/Main/GameManager")  
	player_stats = get_node("/root/Main/PlayerStats")
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
	
	# 由于使用地图模式作为唯一推进方式，简化处理逻辑
	# 无需在游戏场景中处理后续逻辑，完全由GameManager负责
	print("游戏场景: 敌人已击败，由GameManager处理后续流程")
	
	# 游戏场景已胜利，等待GameManager处理后续流程
	# 添加一个小延迟确保信号已被处理
	await get_tree().create_timer(0.5).timeout
	
	# 隐藏场景，由GameManager处理后续
	visible = false

# 测试奖励场景 - 在地图模式下，此功能仅用于调试
func _on_test_reward_pressed():
	print("测试按钮点击：直接显示奖励场景")
	
	# 使用GameManager替代SceneManager
	var game_manager_node = get_node_or_null("/root/Main/GameManager")
	if game_manager_node:
		print("找到游戏管理器，调用测试函数")
		game_manager_node.force_show_reward_scene(20)
	else:
		print("未找到游戏管理器")
		# 在地图模式下，不建议游戏场景自行处理奖励场景
		# 因此移除自行创建奖励场景的代码

func _on_game_over(win: bool = false):  
	if ui.has_node("GameOverPanel"):  
		ui.get_node("GameOverPanel").get_node("ResultLabel").text = "失败!"  
		ui.get_node("GameOverPanel").visible = true  
		
	# 处理失败逻辑
	game_manager.process_defeat()
	
	# 延迟返回地图或重新开始
	await get_tree().create_timer(3.0).timeout
	
	# 在地图模式下，不再自行重新加载场景
	# 而是由GameManager负责处理返回地图的逻辑
	
	# 隐藏当前场景，让GameManager处理后续
	visible = false
