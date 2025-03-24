extends Node  
class_name GameManager  

# 引用到核心节点  
@onready var card_pile_ui: CardPileUI = $CardPileUI  
@onready var combination_area: CombinationDropzone = $CombinationArea  
@onready var enemy_display: EnemyDisplay = $EnemyDisplay  
@onready var player_stats: PlayerStats = $PlayerStats  

# 游戏状态  
enum GameState { PLAYER_TURN, ENEMY_TURN, SHOP, GAME_OVER }  
var current_state: GameState = GameState.PLAYER_TURN  
var current_enemy = null  
var current_round: int = 1  
var turns_remaining: int = 0  
var score_required: int = 0  

# 倍率和奖励系统  
var multiplier: float = 1.0  
var currency: int = 0  

# 游戏初始化  
func _ready():  
	initialize_game()  
	
func initialize_game():  
	# 初始化牌堆和玩家状态  
	load_initial_deck()  
	player_stats.reset()  
	# 生成第一个敌人  
	spawn_enemy()  
	
# 回合管理  
func start_player_turn():  
	current_state = GameState.PLAYER_TURN  
	turns_remaining = 3  # 默认每回合3次出牌机会  
	apply_round_effects()  
	
# 组合检测和得分  
func check_combination(cards: Array) -> Dictionary:  
	# 检测出牌组合并返回结果  
	var result = {  
		"type": "INVALID",  
		"base_score": 0,  
		"multiplier": multiplier,  
		"total_score": 0,  
		"effects": []  
	}  
	
	# 组合类型检测  
	if cards.size() == 1:  
		# 灰烬组合 - 单张牌  
		result.type = "ASH"  
		result.base_score = 10  
	elif cards.size() == 2 and is_same_value(cards):  
		# 魂组 - 两张相同点数  
		result.type = "SOUL_PAIR"  
		result.base_score = 15  
	elif cards.size() == 3 and is_consecutive_same_suit(cards):  
		# 魂链 - 三张连续同花色  
		result.type = "SOUL_CHAIN"  
		result.base_score = 25  
	elif cards.size() == 3 and is_same_value(cards):  
		# 刻印 - 三张相同点数  
		result.type = "IMPRINT"  
		result.base_score = 40  
	elif cards.size() == 4 and is_same_value(cards):  
		# 王印 - 四张相同点数  
		result.type = "KING_SEAL"  
		result.base_score = 60  
		
	# 应用特殊卡牌效果和装备效果  
	apply_card_effects(cards, result)  
	
	# 计算最终得分  
	result.total_score = int(result.base_score * result.multiplier)  
	
	return result  
	
# 辅助函数  
func is_same_value(cards: Array) -> bool:  
	var first_value = cards[0].card_data.value  
	for card in cards:  
		if card.card_data.value != first_value:  
			return false  
	return true  
	
func is_consecutive_same_suit(cards: Array) -> bool:  
	# 确保是同花色  
	var suit = cards[0].card_data.suit  
	for card in cards:  
		if card.card_data.suit != suit:  
			return false  
			
	# 排序并检查是否连续  
	var values = []  
	for card in cards:  
		values.append(card.card_data.value)  
	values.sort()  
	
	for i in range(1, values.size()):  
		if values[i] != values[i-1] + 1:  
			return false  
	
	return true  
	
# 敌人系统  
func spawn_enemy():  
	# 生成新敌人并设置其属性  
	pass  
	
# 商店系统  
func enter_shop():  
	current_state = GameState.SHOP  
	# 显示商店界面  
	pass  
