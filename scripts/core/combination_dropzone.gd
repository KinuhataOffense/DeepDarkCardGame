extends CardDropzone  
class_name CombinationDropzone  

@onready var game_manager: GameManager = get_node("/root/GameManager")  

# 覆盖卡牌放置规则  
func can_drop_card(card_ui: CardUI) -> bool:  
	# 检查是否在玩家回合且还有剩余行动次数  
	if game_manager.current_state != GameManager.GameState.PLAYER_TURN:  
		return false  
	if game_manager.turns_remaining <= 0:  
		return false  
		
	# 检查卡牌是否被锁定  
	if card_ui.card_data.is_locked:  
		return false  
		
	return true  
	
# 处理牌组合检测  
func card_ui_dropped(card_ui: CardUI):  
	# 将卡牌添加到组合区  
	super.card_ui_dropped(card_ui)  
	
	# 当玩家停止拖拽或点击"确认组合"按钮时调用  
	check_and_resolve_combination()  
	
func check_and_resolve_combination():  
	var cards = get_held_cards()  
	if cards.empty():  
		return  
		
	# 检测组合  
	var result = game_manager.check_combination(cards)  
	
	# 如果是有效组合，处理结算  
	if result.type != "INVALID":  
		# 增加分数  
		game_manager.player_stats.add_score(result.total_score)  
		
		# 应用特殊效果  
		for effect in result.effects:  
			apply_effect(effect)  
			
		# 消耗一次行动  
		game_manager.turns_remaining -= 1  
		
		# 处理卡牌（移除或返回手牌）  
		process_cards_after_combination(cards)  
		
		# 抽取新卡牌补充手牌  
		draw_replacement_cards(cards.size())  
	else:  
		# 无效组合，返回手牌  
		return_cards_to_hand(cards)  
		
func process_cards_after_combination(cards: Array):  
	for card in cards:  
		var card_data = card.card_data as DarkCardData  
		
		# 检查特殊效果  
		if card_data.burn_after_use:  
			# 永久销毁  
			card_pile_ui.remove_card_from_game(card)  
		else:  
			# 移到弃牌堆  
			card_pile_ui.set_card_pile(card, CardPileUI.Piles.discard_pile)  
			
func draw_replacement_cards(count: int):  
	card_pile_ui.draw(count)  
