extends Node2D  

@onready var card_pile_ui = $CardPileUI  
@onready var combination_zone = $CombinationDropzone  
@onready var queue_dropzone = $CardQueueDropzone
@onready var enemy_ui = $EnemyDisplay  
@onready var game_manager = null
@onready var player_stats = null
@onready var ui = $UI  
@onready var battle_manager = null

# 卡牌选择变量
var selected_card: CardUI = null

# 在场景加载时连接信号  
func _ready():  
	print("BattleScene: 开始初始化...")
	game_manager = get_node("/root/GameManager")  
	player_stats = get_node("/root/PlayerStats")
	battle_manager = get_node("BattleManager")
	randomize()
	
	print("BattleScene: 获取到管理器引用:", 
		"GameManager=", "有" if game_manager else "无", 
		", BattleManager=", "有" if battle_manager else "无")
	
	# 确保敌人数据正确传递
	if game_manager and battle_manager:
		var enemy_data = null
		
		# 检查GameManager是否有获取敌人数据的方法
		if game_manager.has_method("get_current_enemy_data"):
			enemy_data = game_manager.get_current_enemy_data()
			if enemy_data:
				print("BattleScene: 从GameManager获取到敌人数据:", 
					enemy_data.name if enemy_data.has("name") else "未知敌人")
				
				# 重要：设置敌人数据到BattleManager
				battle_manager.set_enemy_data(enemy_data)
				print("BattleScene: 已将敌人数据设置到BattleManager")
			else:
				print("BattleScene: 警告 - GameManager返回的敌人数据为空")
		else:
			print("BattleScene: 警告 - GameManager没有get_current_enemy_data方法")
	
	# 连接组合区域的信号  
	if combination_zone:  
		combination_zone.connect("combination_resolved", _on_combination_resolved)  
	
	# 连接队列区域的信号
	if queue_dropzone:
		queue_dropzone.connect("combinations_evaluated", _on_queue_combinations_evaluated)
	
	# 连接按钮信号  
	if ui.has_node("ActionButtons/EndTurnButton"):  
		ui.get_node("ActionButtons/EndTurnButton").connect("pressed", _on_end_turn_pressed)  
	
	# 连接出牌按钮信号
	if ui.has_node("ActionButtons/PlayCardButton"):
		ui.get_node("ActionButtons/PlayCardButton").connect("pressed", _on_play_card_pressed)
		
	if ui.has_node("ActionButtons/EnterShopButton"):  
		ui.get_node("ActionButtons/EnterShopButton").connect("pressed", _on_enter_shop_pressed)  
	
	# 连接测试按钮信号（如果存在）
	if ui.has_node("ActionButtons/TestRewardButton"):
		ui.get_node("ActionButtons/TestRewardButton").connect("pressed", _on_test_reward_pressed)
	
	# 连接游戏管理器信号
	if game_manager:
		game_manager.connect("enemy_defeated", _on_enemy_defeated)
		game_manager.connect("game_over", _on_game_over)
	
	# 连接战斗管理器信号
	if battle_manager:
		if not battle_manager.is_connected("enemy_defeated", _on_enemy_defeated):
			battle_manager.connect("enemy_defeated", _on_enemy_defeated)
			print("BattleScene: 已连接BattleManager的enemy_defeated信号")
		
		# 移除initialize_game，改为调用battle_manager的初始化
		if battle_manager.has_method("initialize_game"):
			battle_manager.initialize_game()
			print("BattleScene: 调用BattleManager.initialize_game()完成")
		else:
			print("BattleScene: 警告 - BattleManager没有initialize_game方法")
	else:
		print("BattleScene: 严重错误 - 找不到BattleManager节点")

	# 连接卡牌点击信号
	if card_pile_ui:
		card_pile_ui.connect("card_clicked", _on_card_clicked)
	
	# 更新UI初始状态  
	call_deferred("update_ui")
	print("BattleScene: 初始化完成")

# 更新UI显示  
func update_ui():  
	if ui.has_node("ScoreDisplay"):  
		ui.get_node("ScoreDisplay").text = "分数: " + str(player_stats.current_score)  
	
	if ui.has_node("TurnsDisplay"):  
		ui.get_node("TurnsDisplay").text = "剩余行动: " + str(game_manager.turns_remaining)  
	
	if ui.has_node("PlayerHealth"):  
		ui.get_node("PlayerHealth").value = player_stats.health  
		ui.get_node("PlayerHealth").max_value = player_stats.max_health  

# 处理卡牌点击事件
func _on_card_clicked(card: CardUI):
	# 只允许选择手牌中的卡牌
	if not card_pile_ui.is_card_ui_in_hand(card):
		return
		
	# 如果之前有选中的卡牌，取消选中状态
	if selected_card != null and selected_card != card:
		# 取消显示高亮状态，这里使用简单的方式模拟（未实现卡牌高亮效果）
		print("取消选中卡牌: ", selected_card.card_data.nice_name if selected_card.card_data else "未知卡牌")
	
	# 如果点击的是已选中的卡牌，取消选中
	if selected_card == card:
		selected_card = null
		print("取消选中卡牌")
	else:
		# 选中新卡牌
		selected_card = card
		print("选中卡牌: ", card.card_data.nice_name if card.card_data else "未知卡牌")
		
	# 更新打出卡牌按钮状态
	if ui.has_node("ActionButtons/PlayCardButton"):
		ui.get_node("ActionButtons/PlayCardButton").disabled = (selected_card == null)

# 处理打出卡牌按钮点击
func _on_play_card_pressed():
	if selected_card == null:
		print("请先选择要打出的卡牌")
		return
		
	if game_manager.turns_remaining <= 0:
		print("没有剩余行动次数")
		return
		
	# 添加卡牌到队列
	queue_dropzone.add_card_to_queue(selected_card)
	
	# 重置选中状态
	selected_card = null
	
	# 禁用打出卡牌按钮
	if ui.has_node("ActionButtons/PlayCardButton"):
		ui.get_node("ActionButtons/PlayCardButton").disabled = true
	
	# 更新UI
	update_ui()

# 处理队列组合评估结果
func _on_queue_combinations_evaluated(results):
	# 更新分数显示
	var total_score = results.total_score
	
	# 更新UI中的队列分数显示
	if ui.has_node("QueueScoreDisplay"):
		ui.get_node("QueueScoreDisplay").text = "队列得分: " + str(total_score)
	else:
		# 如果不存在则创建队列分数显示
		var score_display = Label.new()
		score_display.name = "QueueScoreDisplay"
		score_display.text = "队列得分: " + str(total_score)
		score_display.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		score_display.position = Vector2(840, 120)
		ui.add_child(score_display)
	
	# 显示组合详情
	_display_combinations_info(results.combinations)
	
	# 更新UI
	update_ui()
	
	# 检查游戏状态
	battle_manager.check_game_state()

# 显示组合详情信息
func _display_combinations_info(combinations):
	# 清除之前的组合信息
	var combo_info = ui.get_node_or_null("CombinationsInfo")
	if combo_info:
		combo_info.queue_free()
	
	# 创建新的组合信息显示
	combo_info = VBoxContainer.new()
	combo_info.name = "CombinationsInfo"
	combo_info.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	combo_info.position = Vector2(840, 160)
	combo_info.custom_minimum_size = Vector2(300, 400)
	ui.add_child(combo_info)
	
	# 显示组合标题
	var title = Label.new()
	title.text = "当前组合:"
	combo_info.add_child(title)
	
	# 显示每个组合的信息
	var types_shown = {}
	
	for combo in combinations:
		# 按组合类型分组，避免显示太多灰烬组合
		if combo.type == "ASH":
			if not types_shown.has(combo.type):
				_add_combination_info(combo_info, combo, true)
				types_shown[combo.type] = 1
			else:
				types_shown[combo.type] += 1
		else:
			_add_combination_info(combo_info, combo)
	
	# 显示灰烬组合的数量
	if types_shown.has("ASH") and types_shown["ASH"] > 1:
		var ash_label = Label.new()
		ash_label.text = "还有 " + str(types_shown["ASH"] - 1) + " 个灰烬组合"
		combo_info.add_child(ash_label)

# 添加单个组合信息
func _add_combination_info(parent, combo, first_of_type = false):
	var combo_label = Label.new()
	
	# 构造组合信息文本
	var combo_text = combo.name + " (+" + str(combo.score) + "分)"
	
	# 根据组合类型设置颜色
	var text_color = Color.WHITE
	match combo.type:
		"ASH":
			text_color = Color(0.7, 0.7, 0.7)
		"SOUL_PAIR":
			text_color = Color(0.2, 0.6, 1.0)
		"SOUL_CHAIN":
			text_color = Color(0.0, 0.8, 0.4)
		"IMPRINT":
			text_color = Color(1.0, 0.5, 0.0)
		"KING_SEAL":
			text_color = Color(1.0, 0.8, 0.0)
	
	combo_label.add_theme_color_override("font_color", text_color)
	combo_label.text = combo_text
	parent.add_child(combo_label)

# 信号处理函数  
func _on_combination_resolved(combination_result):  
	print("BattleScene: 收到组合结算信号")
	
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
	print("BattleScene: 玩家获得", score_gained, "分，当前总分:", player_stats.current_score)
	
	# 更新UI  
	update_ui()  
	
	# 检查游戏状态，让信号系统处理
	if battle_manager:
		print("BattleScene: 使用battle_manager检查游戏状态")
		battle_manager.check_game_state()
	else:
		print("BattleScene警告: battle_manager为空，使用game_manager检查游戏状态")
		game_manager.check_game_state()
	
	print("BattleScene: turns_remaining =", 
		battle_manager.turns_remaining if battle_manager else game_manager.turns_remaining)

func _on_end_turn_pressed():  
	battle_manager.end_player_turn()  
	update_ui()  

func _on_enter_shop_pressed():
	game_manager.enter_shop()  
		
func _on_enemy_defeated():  
	print("BattleScene: 收到enemy_defeated信号")
	
	if ui.has_node("VictoryPanel"):  
		ui.get_node("VictoryPanel").visible = true  
		print("BattleScene: 显示胜利面板")
	
	# 再次检查分数是否满足条件
	if player_stats.current_score < game_manager.score_required:
		print("BattleScene: 警告 - 分数不足，无法击败敌人")
		print("  当前分数:", player_stats.current_score, "，所需分数:", game_manager.score_required)
		return
		
	print("BattleScene: 玩家分数:", player_stats.current_score, "，所需分数:", game_manager.score_required)
	
	# 处理战利品和奖励
	if battle_manager and battle_manager.has_method("process_victory_rewards"):
		print("BattleScene: 调用BattleManager.process_victory_rewards()")
		battle_manager.process_victory_rewards()
	else:
		print("BattleScene: 无法处理胜利奖励，没有合适的方法")
		
	await get_tree().create_timer(0.5).timeout

# 测试奖励场景 - 在地图模式下，此功能仅用于调试
func _on_test_reward_pressed():
	print("测试按钮点击：直接显示奖励场景")
	
	# 使用GameManager替代SceneManager
	var game_manager_node = get_node_or_null("/root/GameManager")
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
