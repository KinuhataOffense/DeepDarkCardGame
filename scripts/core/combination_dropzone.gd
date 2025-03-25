extends CardDropzone  
class_name CombinationDropzone  

# 游戏管理器引用  
var game_manager = null  

# 自定义信号  
signal combination_resolved(result)  

# 初始化  
func _ready():  
	# 获取CardPileUI引用  
	await get_tree().process_frame  
	card_pile_ui = get_node("../CardPileUI")  

# 覆盖卡牌放置规则  
func can_drop_card(card_ui: CardUI) -> bool:  
	# 默认允许放置任何卡牌  
	return true  
	
# 处理牌组合检测  
func card_ui_dropped(card_ui: CardUI):  
	# 将卡牌添加到组合区  
	super.card_ui_dropped(card_ui)  
	
	# 检测组合  
	check_and_resolve_combination()  
	
func check_and_resolve_combination():  
	var cards = get_held_cards()  
	if cards.empty():  
		return  
		
	# 检测组合类型  
	var combination_type = "INVALID"  
	var base_score = 0  
	
	# 根据卡牌数量和特性确定组合类型  
	if cards.size() == 1:  
		# 灰烬 - 单张牌  
		combination_type = "ASH"  
		base_score = 10  
	elif cards.size() == 2 and is_same_value(cards):  
		# 魂组 - 两张相同点数  
		combination_type = "SOUL_PAIR"  
		base_score = 15  
	elif cards.size() == 3 and is_consecutive_same_suit(cards):  
		# 魂链 - 三张连续同花色  
		combination_type = "SOUL_CHAIN"  
		base_score = 25  
	elif cards.size() == 3 and is_same_value(cards):  
		# 刻印 - 三张相同点数  
		combination_type = "IMPRINT"  
		base_score = 40  
	elif cards.size() == 4 and is_same_value(cards):  
		# 王印 - 四张相同点数  
		combination_type = "KING_SEAL"  
		base_score = 60  
	
	# 有效组合  
	if combination_type != "INVALID":  
		# 计算得分  
		var total_score = base_score  
		
		# 应用倍率  
		if game_manager:  
			total_score = int(total_score * game_manager.score_multiplier)  
		
		# 处理卡牌(移到弃牌堆)  
		for card in cards:  
			if card.card_data.has("burn_after_use") and card.card_data.burn_after_use:  
				# 永久移除牌  
				card_pile_ui.remove_card_from_game(card)  
			else:  
				# 移到弃牌堆  
				card_pile_ui.set_card_pile(card, CardPileUI.Piles.discard_pile)  
		
		# 抽取新卡牌  
		card_pile_ui.draw(cards.size())  
		
		# 发送组合成功信号  
		emit_signal("combination_resolved", {  
			"type": combination_type,  
			"score": total_score,  
			"cards": cards  
		})  
		
		# 减少回合行动次数  
		if game_manager:  
			game_manager.turns_remaining -= 1  
	else:  
		# 无效组合，返回手牌  
		move_cards_to_hand(cards)  

# 将卡牌移回手牌  
func move_cards_to_hand(cards: Array):  
	for card in cards:  
		card_pile_ui.set_card_pile(card, CardPileUI.Piles.hand_pile)  

# 辅助函数：检查是否相同点数  
func is_same_value(cards: Array) -> bool:  
	if cards.size() < 2:  
		return false  
		
	var first_card_data = cards[0].card_data  
	if not first_card_data.has("value"):  
		return false  
		
	var first_value = first_card_data.value  
	
	for card in cards:  
		if not card.card_data.has("value") or card.card_data.value != first_value:  
			return false  
			
	return true  
	
# 辅助函数：检查是否连续同花色  
func is_consecutive_same_suit(cards: Array) -> bool:  
	if cards.size() < 3:  
		return false  
		
	# 检查花色  
	var first_card_data = cards[0].card_data  
	if not first_card_data.has("suit") or not first_card_data.has("value"):  
		return false  
		
	var suit = first_card_data.suit  
	
	# 收集所有点数  
	var values = []  
	for card in cards:  
		if not card.card_data.has("suit") or not card.card_data.has("value"):  
			return false  
			
		if card.card_data.suit != suit:  
			return false  
			
		values.append(card.card_data.value)  
	
	# 排序点数  
	values.sort()  
	
	# 检查是否连续  
	for i in range(1, values.size()):  
		if values[i] != values[i-1] + 1:  
			return false  
	
	return true  
