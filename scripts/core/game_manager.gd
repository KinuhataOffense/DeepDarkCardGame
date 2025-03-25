extends Node  
class_name GameManager  

# 引用到核心节点  
@onready var card_pile_ui: CardPileUI = $"../CardPileUI"   
@onready var combination_area: CombinationDropzone = $"../CombinationDropzone"  
@onready var enemy_ui = $"../EnemyDisplay"  
@onready var player_stats = $"../PlayerStats"  

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
	
	# 初始化敌人  
	spawn_first_enemy()  
	
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
	
# 卡牌操作的信号响应函数  
func _on_card_clicked(card: CardUI):  
	if current_state != GameState.PLAYER_TURN:  
		return  
	
	## 这里可以添加卡牌点击的特殊效果处理  
	#var card_data = card.card_data  
	#if card_data.has("effect_id"):  
		#apply_card_effect(card_data)  

func _on_card_dropped(card: CardUI):  
	# 处理卡牌被放下的逻辑  
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
		"name": "失落的骑士",  
		"description": "曾经的王国守卫，现在只是空洞的躯壳。",  
		"health": 100,  
		"round_limit": 5,  
		"required_score": 150,  
		"effects": [  
			{  
				"trigger": "round_start",  
				"frequency": 3,  
				"type": "mark_card",  
				"description": "标记一张手牌，若该轮未使用则受到10点伤害"  
			}  
		]  
	}  
	
	current_enemy = Enemy.new()  
	current_enemy.initialize(enemy_data)  
	score_required = current_enemy.required_score  
	
	# 更新UI  
	update_enemy_ui()  
	
# 开始玩家回合  
func start_player_turn():  
	current_state = GameState.PLAYER_TURN  
	turns_remaining = 3  
	
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
	# 检查是否击败敌人  
	if player_stats.current_score >= score_required:  
		emit_signal("enemy_defeated")  
		return  
		
	# 检查回合限制  
	if current_round >= current_enemy.round_limit:  
		emit_signal("game_over", false)  # 失败  
		
# 检查敌人是否已击败  
func check_enemy_defeated() -> bool:  
	return player_stats.current_score >= score_required  
	
# 降低得分倍率（用于敌人效果）  
func reduce_score_multiplier(factor: float):  
	score_multiplier *= factor  
	
# 进入商店  
func enter_shop():  
	current_state = GameState.SHOP  
	emit_signal("enter_shop_requested")  
	
# 离开商店  
func leave_shop():  
	current_state = GameState.PLAYER_TURN  
	# 生成新敌人  
	spawn_next_enemy()  
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
