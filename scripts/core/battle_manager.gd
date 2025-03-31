extends Node  
class_name BattleManager  

# 引用到核心节点  
@onready var card_pile_ui: CardPileUI = $"../CardPileUI"   
@onready var combination_area: CombinationDropzone = $"../CombinationDropzone"  
@onready var enemy_ui = $"../EnemyDisplay"  
@onready var player_stats = $"../PlayerStats"
@onready var game_scene = $".."  

# 游戏状态  
enum GameState { PLAYER_TURN, ENEMY_TURN, SHOP, GAME_OVER }  
var current_state: GameState = GameState.PLAYER_TURN  
var current_enemy = null  
var current_round: int = 1  
var turns_remaining: int = 3  
var score_required: int = 0  

# 倍率和奖励系统  
var score_multiplier: float = 1.0  
var currency: int = 0  

# 信号  
signal enemy_defeated  
signal game_over(win)  
signal enter_shop_requested  
signal return_to_game_requested  

# 添加玩家数据
var player_data = {
	"max_health": 100,
	"current_health": 100,
	"currency": 100
}

# 添加地图系统相关变量
var current_map_state = null
var current_floor_level = 1
var current_map_node = null

# 游戏初始化  
func _ready():  
	# 连接卡牌相关信号  
	if card_pile_ui:  
		card_pile_ui.connect("card_clicked", _on_card_clicked)  
		card_pile_ui.connect("card_dropped", _on_card_dropped)  
	
	# 初始化游戏  
	call_deferred("initialize_game")  # 使用call_deferred确保所有节点都已准备好  
	
func initialize_game():  
	# 初始化游戏状态  
	current_state = GameState.PLAYER_TURN  
	current_round = 1  
	turns_remaining = 3  
	score_multiplier = 1.0  
	
	# 设置组合区域引用  
	combination_area.game_manager = self  
	
	# 初始化敌人，只有在没有敌人的情况下才初始化第一个敌人  
	if current_enemy == null:
		print("未设置敌人，使用默认敌人")
		spawn_first_enemy()  
	else:
		print("使用已设置的敌人:", current_enemy.enemy_name)
		# 确保score_required是正确的
		score_required = current_enemy.required_score
		update_enemy_ui()
	
	# 加载并重置牌堆  
	print("Loading card pile data...")  
	card_pile_ui.load_json_path()  
	print("Resetting card pile...")  
	card_pile_ui.reset()  
	print("Card pile initialized.")  
	
	# 抽取初始手牌  
	print("Drawing initial hand...")  
	card_pile_ui.draw(5)  
	print("Initial hand drawn.")
	

const MAX_SELECTED_CARDS: int = 1  
var selected_cards: Array = []  

func _on_card_clicked(card: CardUI):  
	pass

func _on_card_dropped(card: CardUI):  
	pass
	
# 应用卡牌效果  
func apply_card_effect(card_data):  
	if not card_data.has("effect_id"):  
		return  
		
	match card_data.effect_id:  
		"joker":  
			# 小丑牌效果处理...  
			pass  
			
		"forge_stone":  
			# 锻造石牌效果...  
			if card_data.has("power_decrease_rate") and card_data.has("value"):  
				card_data.value = max(1, card_data.value - card_data.power_decrease_rate)  
			
		"black_fire":  
			# 黑火牌效果...  
			score_multiplier *= 2.0  
			player_stats.take_damage(5)  
			
		"dragon_pact":  
			# 龙契牌效果...  
			turns_remaining += 1  
			# 下回合手牌上限-1的效果需要单独存储状态并在回合开始时应用  
			
		"humanity":  
			# 人性牌效果...  
			trigger_random_event()  
			
		# 添加其他卡牌效果...  

# 随机事件触发  
func trigger_random_event():  
	var random_value = randf()  
	if random_value < 0.25:  
		# 正面事件  
		player_stats.heal(10)  
	elif random_value < 0.5:  
		# 中性事件  
		card_pile_ui.draw(1)  
	else:  
		# 负面事件  
		player_stats.take_damage(5)  

# 初始化第一个敌人  
func spawn_first_enemy():  
	var enemy_data = {  
		"id": "default_enemy",
		"name": "默认敌人 - 骑士幽魂",  
		"description": "这是默认敌人，通常不应该出现在正常游戏中。如果你看到它，说明敌人选择过程有问题。",  
		"health": 100,  
		"round_limit": 5,  
		"required_score": 10,  
		"difficulty": 1,
		"rewards": {
			"currency": 10
		},
		"effects": [  
			{  
				"trigger": "round_start",  
				"frequency": 3,  
				"type": "mark_card",  
				"description": "标记一张手牌，若该轮未使用则受到10点伤害"  
			}  
		]  
	}  
	
	print("警告：生成默认敌人，这通常表示存在问题")
	
	current_enemy = Enemy.new()  
	current_enemy.initialize(enemy_data)  
	score_required = current_enemy.required_score  
	
	# 更新UI  
	update_enemy_ui()  
	
# 开始玩家回合  
func start_player_turn():  
	current_state = GameState.PLAYER_TURN  
	
	# 重置选中状态  
	for card in selected_cards:  
		card.set_selected(false)  
	selected_cards.clear()  
	
	# 抽牌到手牌上限  
	var cards_to_draw = card_pile_ui.max_hand_size - card_pile_ui.get_card_pile_size(CardPileUI.Piles.hand_pile)  
	if cards_to_draw > 0:  
		card_pile_ui.draw(cards_to_draw)  
	
	# 应用回合开始效果  
	if current_enemy:  
		current_enemy.apply_round_start_effects(self)
	
# 结束玩家回合  
func end_player_turn():  
	if current_state != GameState.PLAYER_TURN:  
		return  
	
	turns_remaining = turns_remaining - 1
	current_round = current_round + 1
	# 应用回合结束效果  
	if current_enemy:  
		current_enemy.apply_round_end_effects(self)  
		
	# 检查游戏状态  
	check_game_state()  
	
	# 进入下一回合  
	current_round += 1  
	start_player_turn()  
	
# 检查游戏状态  
func check_game_state():  
	# 打印当前游戏状态
	print("当前回合:", current_round, "/", current_enemy.round_limit, "，剩余行动:", turns_remaining)
	print("当前分数:", player_stats.current_score, "，击败要求:", score_required)
	
	# 检查是否击败敌人  
	if player_stats.current_score >= score_required:  
		print("玩家分数达到要求，敌人被击败!")
		# 确保信号只发送一次
		if not has_meta("enemy_defeated_emitted"):
			print("BattleManager: 发送enemy_defeated信号")
			emit_signal("enemy_defeated")
			set_meta("enemy_defeated_emitted", true)
		return  
		
	# 检查回合限制  
	if current_round >= current_enemy.round_limit || turns_remaining < 0:  
		print("玩家失败: 回合用尽或行动结束")
		emit_signal("game_over", false)  # 失败参数为false
		
# 检查敌人是否已击败  
func check_enemy_defeated() -> bool: 
	var is_defeated = player_stats.current_score >= score_required
	print("检查敌人是否击败: 玩家分数=", player_stats.current_score, 
		"，要求分数=", score_required, 
		"，结果=", is_defeated) 
	return is_defeated  
	
# 降低得分倍率（用于敌人效果）  
func reduce_score_multiplier(factor: float):  
	score_multiplier *= factor  
	
# 进入商店  
func enter_shop():  
	# 移除直接控制game_scene可见性的代码
	current_state = GameState.SHOP  
	
	# 重置回合状态
	turns_remaining = 3
	current_round = 1
	
	emit_signal("enter_shop_requested")  
	
# 离开商店  
func leave_shop():  
	# 移除对game_scene可见性的直接控制
	current_state = GameState.PLAYER_TURN  
	# 不再生成新敌人，因为会创建新的游戏场景
	emit_signal("return_to_game_requested")  
	
# 生成下一个敌人  
func spawn_next_enemy():  
	# 简化起见，这里只实现一个示例敌人  
	var enemy_data = {  
		"name": "失落的王",  
		"description": "被初火腐蚀的统治者，他的力量源自破碎的王冠。",  
		"health": 250,  
		"round_limit": 8,  
		"required_score": 400,  
		"effects": [  
			{  
				"trigger": "round_start",  
				"frequency": 3,  
				"type": "disable_magic_cards",  
				"description": "使你下一轮无法使用魔法牌"  
			}  
		]  
	}  
	
	current_enemy = Enemy.new()  
	current_enemy.initialize(enemy_data)  
	score_required = current_enemy.required_score  
	
	# 更新UI  
	update_enemy_ui()  
	
# 更新敌人UI  
func update_enemy_ui():  
	if current_enemy and enemy_ui:  
		enemy_ui.get_node("EnemyName").text = current_enemy.enemy_name  
		enemy_ui.get_node("EnemyDescription").text = current_enemy.description  
		enemy_ui.get_node("EnemyHealth").max_value = current_enemy.max_health  
		enemy_ui.get_node("EnemyHealth").value = current_enemy.health  

# 设置游戏的敌人数据
func set_enemy_data(enemy_data):
	# 如果没有敌人数据，使用默认数据
	if not enemy_data:
		print("警告: 未提供敌人数据，使用默认敌人")
		spawn_first_enemy()
		return
		
	# 创建新敌人
	current_enemy = Enemy.new()
	current_enemy.initialize(enemy_data)
	score_required = current_enemy.required_score
	
	# 打印敌人信息
	print("加载敌人:", current_enemy.enemy_name)
	print("击败条件: 需要", score_required, "分")
	print("回合限制:", current_enemy.round_limit, "回合")
	
	# 重置游戏状态
	current_round = 1
	turns_remaining = 3
	
	# 更新UI
	update_enemy_ui()
	
# 加载敌人数据
func load_enemy_by_id(enemy_id: String):
	var file = FileAccess.open("res://data/enemies.json", FileAccess.READ)
	if not file:
		print("无法打开敌人数据文件")
		return null
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error == OK:
		var enemies = json.data
		for enemy in enemies:
			if enemy.id == enemy_id:
				return enemy
	
	print("未找到ID为" + enemy_id + "的敌人")
	return null

# 游戏胜利时的奖励处理
func process_victory_rewards():
	# 检查敌人对象和rewards属性是否存在
	if current_enemy == null:
		print("警告: 当前没有敌人对象")
		return
		
	# 检查是否达到击败敌人所需分数
	if player_stats.current_score < score_required:
		print("警告: 未达到击败敌人所需分数，不能领取奖励")
		return
		
	print("玩家击败敌人，处理奖励")
		
	# 检查敌人的rewards属性并添加到玩家数据
	if current_enemy.has_method("get_rewards"):
		# 如果敌人类有获取奖励的方法
		var rewards = current_enemy.get_rewards()
		if rewards and rewards.has("currency"):
			player_stats.currency += rewards.currency
			print("玩家获得", rewards.currency, "货币")
	elif typeof(current_enemy) == TYPE_DICTIONARY and current_enemy.has("rewards"):
		# 如果敌人是字典形式
		if current_enemy.rewards.has("currency"):
			player_stats.currency += current_enemy.rewards.currency
			print("玩家获得", current_enemy.rewards.currency, "货币")
	else:
		# 如果没有奖励属性，给予固定奖励
		print("警告: 敌人没有rewards属性，给予固定奖励")
		player_stats.currency += 50
		print("玩家获得50货币")
	
	# 更新玩家数据，确保同步
	player_data.currency = player_stats.currency
	
	# 在地图模式下，胜利后通过场景管理器处理后续流程
	print("BattleManager: 胜利奖励处理完成，等待场景管理器切换到奖励场景")

# 游戏失败处理
func process_defeat():
	# 游戏失败的逻辑处理
	print("游戏失败，玩家将返回地图并重置当前楼层")
	
	# 在地图模式下，失败后返回地图并重置当前楼层
	print("BattleManager: 失败处理完成，等待场景管理器将玩家返回地图")

# 添加地图状态保存和加载功能
func save_map_state(map_state):
	current_map_state = map_state
	print("地图状态已保存: 当前层级=", map_state.current_floor, "，当前节点=", map_state.current_node_id)
	
	# 确保玩家数据同步
	if player_stats:
		player_data.currency = player_stats.currency
		player_data.current_health = player_stats.health
		print("玩家数据已同步: 生命=", player_data.current_health, "，货币=", player_data.currency)

# 获取地图状态
func get_map_state():
	return current_map_state

# 设置当前层级
func set_floor_level(level):
	current_floor_level = level
	print("设置当前层级为: ", level)

# 获取当前层级
func get_floor_level():
	return current_floor_level
