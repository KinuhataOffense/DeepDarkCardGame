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
	
	# 更新得分  
	player_stats.add_score(combination_result.score)  
	
	# 更新UI  
	update_ui()  
	
	# 检查是否击败敌人  
	if game_manager.check_enemy_defeated():  
		if ui.has_node("VictoryPanel"):  
			ui.get_node("VictoryPanel").visible = true  
		
func _on_end_turn_pressed():  
	game_manager.end_player_turn()  
	update_ui()  

func _on_enter_shop_pressed():
	game_manager.enter_shop()  
		
func _on_enemy_defeated():  
	if ui.has_node("VictoryPanel"):  
		ui.get_node("VictoryPanel").visible = true  
	
	# 延迟进入商店  
	await get_tree().create_timer(2.0).timeout  
	game_manager.enter_shop()  
	
func _on_game_over(win):  
	if ui.has_node("GameOverPanel"):  
		if win:  
			ui.get_node("GameOverPanel").get_node("ResultLabel").text = "胜利!"  
		else:  
			ui.get_node("GameOverPanel").get_node("ResultLabel").text = "失败!"  
		ui.get_node("GameOverPanel").visible = true  
