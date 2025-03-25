extends Node  
class_name GameManager  

# 引用到核心节点  
@onready var card_pile_ui: CardPileUI = $"../CardPileUI"  
@onready var combination_area: CombinationDropzone = $"../CombinationDropzone"  
@onready var enemy_ui = $"../EnemyDisplay"  # 注意这里应该是EnemyDisplay而非EnemyUI  
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
	initialize_game()  
	
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
	
	# 初始化牌堆（使用CardPileUI的API）  
	# 这里不需要手动加载牌组，CardPileUI会自动从JSON加载  
	
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
		
	# 检查游戏是否结束  
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
