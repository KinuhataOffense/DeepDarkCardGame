extends Node  
class_name Enemy  

var name: String  
var description: String  
var health: int  
var max_health: int  
var round_limit: int  # 击败敌人的回合限制  
var required_score: int  # 击败敌人需要的最低分数  

# 特殊效果  
var effects: Array = []  
var round_counter: int = 0  

# 初始化敌人  
func initialize(enemy_data: Dictionary):  
	name = enemy_data.name  
	description = enemy_data.description  
	health = enemy_data.health  
	max_health = enemy_data.health  
	round_limit = enemy_data.round_limit  
	required_score = enemy_data.required_score  
	effects = enemy_data.effects  
	
# 回合开始时应用效果  
func apply_round_start_effects(game_manager):  
	round_counter += 1  
	
	for effect in effects:  
		if effect.trigger == "round_start":  
			if round_counter % effect.frequency == 0:  
				execute_effect(effect, game_manager)  
				
# 回合结束时应用效果  
func apply_round_end_effects(game_manager):  
	for effect in effects:  
		if effect.trigger == "round_end":  
			if round_counter % effect.frequency == 0:  
				execute_effect(effect, game_manager)  
				
# 执行特殊效果  
func execute_effect(effect, game_manager):  
	match effect.type:  
		"mark_card":  
			# 标记随机手牌  
			var hand_cards = game_manager.card_pile_ui.get_cards_in_pile(CardPileUI.Piles.hand_pile)  
			if hand_cards.size() > 0:  
				var random_card = hand_cards[randi() % hand_cards.size()]  
				random_card.card_data.is_marked = true  
				
		"reduce_multiplier":  
			# 降低倍率  
			game_manager.multiplier *= 0.5  
			
		"disable_magic_cards":  
			# 禁用魔法牌  
			var hand_cards = game_manager.card_pile_ui.get_cards_in_pile(CardPileUI.Piles.hand_pile)  
			for card in hand_cards:  
				if card.card_data.card_type == DarkCardData.CardType.SPECIAL:  
					card.card_data.is_locked = true  
					
		"randomize_values":  
			# 随机改变牌值  
			var hand_cards = game_manager.card_pile_ui.get_cards_in_pile(CardPileUI.Piles.hand_pile)  
			for card in hand_cards:  
				if randf() < 0.3:  # 30%几率改变  
					card.card_data.value = 1 + randi() % 13  
