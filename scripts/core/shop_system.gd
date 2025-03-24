extends Node  
class_name ShopSystem  

var available_items: Array = []  
@onready var game_manager: GameManager = get_node("/root/GameManager")  

# 初始化商店  
func initialize_shop():  
	# 生成可购买的道具  
	generate_available_items()  
	
# 生成商店物品  
func generate_available_items():  
	available_items.clear()  
	
	# 根据游戏进度选择可用物品  
	var shop_tier = calculate_shop_tier()  
	
	# 添加随机道具  
	add_random_deck_modifiers(shop_tier)  
	add_random_consumables(shop_tier)  
	add_random_permanent_upgrades(shop_tier)  
	add_random_passive_items(shop_tier)  
	
# 购买物品  
func purchase_item(item_index: int):  
	if item_index >= available_items.size():  
		return false  
		
	var item = available_items[item_index]  
	
	if game_manager.player_stats.currency >= item.price:  
		game_manager.player_stats.currency -= item.price  
		
		# 应用物品效果  
		match item.category:  
			"deck_modifier":  
				apply_deck_modification(item)  
			"consumable":  
				game_manager.player_stats.add_item(item)  
			"permanent":  
				game_manager.player_stats.add_item(item)  
			"passive":  
				game_manager.player_stats.add_item(item)  
				
		return true  
	
	return false  
	
# 应用牌堆修改  
func apply_deck_modification(item):  
	match item.effect_id:  
		"forge":  
			# 升级普通牌  
			var selected_cards = [] # 这里需要让玩家选择  
			for card in selected_cards:  
				upgrade_card_to_enhanced(card)  
				
		"special_card":  
			# 添加特殊牌  
			var card_data = create_special_card(item.card_id)  
			game_manager.card_pile_ui.create_card_in_pile(  
				card_data.nice_name,   
				CardPileUI.Piles.draw_pile  
			)  
			
		"remove_cards":  
			# 移除牌  
			var selected_cards = [] # 这里需要让玩家选择  
			for card in selected_cards:  
				game_manager.card_pile_ui.remove_card_from_game(card)  
				
# 创建特殊卡牌  
func create_special_card(card_id: String) -> Dictionary:  
	var card_data = {}  
	
	match card_id:  
		"humanity_card":  
			card_data = {  
				"nice_name": "人性牌",  
				"texture_path": "res://cards/humanity_card.png",  
				"backface_texture_path": "res://cards/card_back.png",  
				"suit": "special",  
				"value": 0,  
				"card_type": DarkCardData.CardType.SPECIAL,  
				"effect_id": "humanity",  
				"effect_description": "可作为任意牌参与组合，使用后触发随机事件"  
			}  
			
		"chaos_card":  
			# 类似地设置混沌牌  
			pass  
			
	return card_data  
