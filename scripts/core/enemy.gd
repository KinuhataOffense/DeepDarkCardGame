extends Node  
class_name Enemy  

# 使用enemy_name避免与Node.name冲突  
var enemy_name: String  
var description: String  
var health: int  
var max_health: int  
var round_limit: int  # 击败敌人的回合限制  
var required_score: int  # 击败敌人需要的最低分数  

# 特殊效果  
var effects: Array = []  
var round_counter: int = 0  

# 奖励
var rewards = {}

# 初始化敌人  
func initialize(enemy_data: Dictionary):  
	enemy_name = enemy_data.get("name", "未知敌人")  
	description = enemy_data.get("description", "")  
	health = enemy_data.get("health", 100)  
	max_health = health  
	round_limit = enemy_data.get("round_limit", 5)  
	required_score = enemy_data.get("required_score", 150)  
	effects = enemy_data.get("effects", [])  
	
	# 初始化奖励
	if enemy_data.has("rewards"):
		rewards = enemy_data.get("rewards", {})
	else:
		# 设置默认奖励
		rewards = {"currency": 50}
		
# 获取奖励
func get_rewards():
	return rewards

# 回合开始时应用效果  
func apply_round_start_effects(game_manager):  
	round_counter += 1  
	
	for effect in effects:  
		if effect.get("trigger") == "round_start":  
			if round_counter % effect.get("frequency", 1) == 0:  
				execute_effect(effect, game_manager)  
				
# 回合结束时应用效果  
func apply_round_end_effects(game_manager):  
	for effect in effects:  
		if effect.get("trigger") == "round_end":  
			if round_counter % effect.get("frequency", 1) == 0:  
				execute_effect(effect, game_manager)  
				
# 执行特殊效果  
func execute_effect(effect, game_manager):  
	match effect.get("type"):  
		"mark_card":  
			# 标记随机手牌  
			var hand_cards = game_manager.card_pile_ui.get_cards_in_pile(CardPileUI.Piles.hand_pile)  
			if hand_cards.size() > 0:  
				var random_index = randi() % hand_cards.size()  
				# 简单地用元数据标记卡牌  
				hand_cards[random_index].set_meta("marked", true)  
				
		"reduce_multiplier":  
			# 降低倍率（通过游戏管理器）  
			game_manager.reduce_score_multiplier(0.5)  
			
		"disable_magic_cards":  
			# 禁用魔法牌（通过修改卡牌可用性）  
			var hand_cards = game_manager.card_pile_ui.get_cards_in_pile(CardPileUI.Piles.hand_pile)  
			#for card in hand_cards:  
				#if card.card_data.get("card_type", 0) == 2:  # 假设2是魔法牌类型  
					#card.set_disabled(true)  
