extends Node2D  

@onready var card_pile_ui = $CardPileUI  
@onready var combination_zone = $CombinationDropzone  
@onready var enemy_display = $EnemyDisplay  
@onready var game_manager = $GameManager  
@onready var player_stats = $PlayerStats  
@onready var ui = $UI  

# 在场景加载时连接信号  
func _ready():  
	# 连接来自CardPileUI的信号  
	card_pile_ui.card_clicked.connect(_on_card_clicked)  
	card_pile_ui.card_hovered.connect(_on_card_hovered)  
	card_pile_ui.card_unhovered.connect(_on_card_unhovered)  
	
	# 连接组合区域的信号  
	combination_zone.combination_resolved.connect(_on_combination_resolved)  
	
	# 连接按钮信号  
	ui.get_node("ActionButtons/EndTurnButton").pressed.connect(_on_end_turn_pressed)  
	ui.get_node("ActionButtons/UseItemButton").pressed.connect(_on_use_item_pressed)  
	
	# 连接游戏管理器信号  
	game_manager.enemy_defeated.connect(_on_enemy_defeated)  
	game_manager.game_over.connect(_on_game_over)  
	
	# 初始化游戏  
	game_manager.initialize_game()  
	
	# 更新UI初始状态  
	update_ui()  

# 更新UI显示  
func update_ui():  
	ui.get_node("ScoreDisplay").text = "分数: " + str(player_stats.current_score)  
	ui.get_node("TurnsDisplay").text = "剩余行动: " + str(game_manager.turns_remaining)  
	ui.get_node("PlayerHealth").value = player_stats.health  
	ui.get_node("PlayerHealth").max_value = player_stats.max_health  
	
	# 更新敌人显示  
	if game_manager.current_enemy:  
		enemy_display.get_node("EnemyName").text = game_manager.current_enemy.name  
		enemy_display.get_node("EnemyHealth").value = game_manager.current_enemy.health  
		enemy_display.get_node("EnemyHealth").max_value = game_manager.current_enemy.max_health  
		enemy_display.get_node("EnemyDescription").text = game_manager.current_enemy.description  

# 信号处理函数  
func _on_card_clicked(card):  
	# 如果游戏处于玩家回合状态，允许拖动卡牌到组合区  
	if game_manager.current_state == GameManager.GameState.PLAYER_TURN:  
		# 可以在这里添加处理逻辑  
		pass  

func _on_combination_resolved(combination_result):  
	# 显示组合结果  
	var result_display = ui.get_node("CombinationResult")  
	result_display.display_result(combination_result)  
	
	# 更新UI  
	update_ui()  
	
	# 检查是否击败敌人  
	if game_manager.check_enemy_defeated():  
		ui.get_node("VictoryPanel").show()  
		
func _on_end_turn_pressed():  
	game_manager.end_player_turn()  
	update_ui()  
	
func _on_use_item_pressed():  
	# 显示物品选择菜单  
	# 这里需要实现物品使用UI  
	pass  
	
func _on_enemy_defeated():  
	ui.get_node("VictoryPanel").show()  
	await get_tree().create_timer(2.0).timeout  
	game_manager.enter_shop()  
	
func _on_game_over(win):  
	if win:  
		ui.get_node("GameOverPanel").show_victory()  
	else:  
		ui.get_node("GameOverPanel").show_defeat()  
