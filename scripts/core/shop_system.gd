extends Node  
class_name ShopSystem  

var available_items: Array = []  
var game_manager = null  

# 初始化商店  
func initialize_shop():  
	available_items.clear()  
	
	# 生成固定的物品列表(简化实现)  
	generate_fixed_items()  
	
# 生成固定的商店物品列表  
func generate_fixed_items():  
	available_items = [  
		{  
			"name": "锻造服务",  
			"description": "将一张普通牌升级为强化牌",  
			"price": 50,  
			"category": "deck_modifier",  
			"effect_id": "forge"  
		},  
		{  
			"name": "人性碎片",  
			"description": "一次重新排列所有手牌的机会",  
			"price": 30,  
			"category": "consumable",  
			"effect_id": "humanity_fragment",  
			"duration": 1  
		},  
		{  
			"name": "灵魂链接",  
			"description": "每完成3次魂链，获得一次额外行动",  
			"price": 100,  
			"category": "permanent",  
			"effect_id": "soul_link"  
		},  
		{  
			"name": "守护之戒",  
			"description": "每回合一次，可以保护一张牌不被敌人效果影响",  
			"price": 80,  
			"category": "passive",  
			"effect_id": "guardian_ring"  
		}  
	]  
	
# 购买物品  
func purchase_item(item_index: int):  
	if item_index < 0 or item_index >= available_items.size():  
		return false  
		
	var item = available_items[item_index]  
	
	if game_manager and game_manager.player_stats.currency >= item.get("price", 0):  
		game_manager.player_stats.currency -= item.get("price", 0)  
		
		# 应用物品效果  
		match item.get("category"):  
			"deck_modifier":  
				apply_deck_modification(item)  
			"consumable", "permanent", "passive":  
				# 简化实现，只需增加得分  
				game_manager.player_stats.add_score(25)  
				
		return true  
	
	return false  
	
# 应用牌堆修改  
func apply_deck_modification(item):  
	match item.get("effect_id"):  
		"forge":  
			# 简化实现，只是创建一张强化牌  
			var card_data = {  
				"nice_name": "强化的红桃A",  
				"suit": "hearts",  
				"value": 1,  
				"card_type": 1  # 强化类型  
			}  
			
			if game_manager and game_manager.card_pile_ui:  
				# 这里假设create_card_in_pile是CardPileUI的方法  
				if game_manager.card_pile_ui.has_method("create_card_in_pile"):  
					game_manager.card_pile_ui.create_card_in_pile(  
						card_data.get("nice_name"),   
						CardPileUI.Piles.draw_pile  
					)  
