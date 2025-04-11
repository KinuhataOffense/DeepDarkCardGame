extends CardDropzone
class_name CardQueueDropzone

# 队列设置
@export var max_queue_size: int = 5
@export var queue_layout: CardPileUI.PilesCardLayouts = CardPileUI.PilesCardLayouts.right
@export var queue_spacing: float = 120.0  # 队列中卡牌的间距

# 战斗管理器引用
var battle_manager = null

# 自定义信号
signal card_added_to_queue(card)
signal card_removed_from_queue(card)
signal combinations_evaluated(results)

# 组合类型和分数
const COMBINATION_TYPES = {
	"ASH": {"name": "灰烬", "base_score": 10, "min_cards": 1, "max_cards": 1},
	"SOUL_PAIR": {"name": "魂组", "base_score": 15, "min_cards": 2, "max_cards": 2},
	"SOUL_CHAIN": {"name": "魂链", "base_score": 25, "min_cards": 3, "max_cards": 3},
	"IMPRINT": {"name": "刻印", "base_score": 40, "min_cards": 3, "max_cards": 3},
	"KING_SEAL": {"name": "王印", "base_score": 60, "min_cards": 4, "max_cards": 4}
}

# 当前活跃的组合效果
var active_combinations = []

func _ready():
	# 初始化队列
	_held_cards = []
	await get_tree().process_frame
	
	# 设置队列为横向布局
	layout = CardPileUI.PilesCardLayouts.right
	
	# 获取战斗管理器引用
	battle_manager = get_parent().get_node("BattleManager")
	if not battle_manager:
		battle_manager = get_parent().get_node_or_null("../BattleManager")
	
	# 创建组合可视化显示容器
	_create_combination_container()

# 创建组合可视化显示容器
func _create_combination_container():
	var combination_container = Control.new()
	combination_container.name = "CombinationContainer"
	combination_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combination_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(combination_container)

# 重写卡牌放置处理
func card_ui_dropped(card_ui: CardUI):
	# 确保卡牌先从手牌中移除
	if card_pile_ui:
		# 添加卡牌到队列
		add_card_to_queue(card_ui)

# 添加卡牌到队列
func add_card_to_queue(card_ui: CardUI):
	# 如果队列已满，移除最旧的卡牌
	if _held_cards.size() >= max_queue_size:
		var oldest_card = _held_cards[0]
		card_pile_ui.set_card_pile(oldest_card, CardPileUI.Piles.discard_pile)
		emit_signal("card_removed_from_queue", oldest_card)
	
	# 添加新卡牌到队列
	card_pile_ui.set_card_dropzone(card_ui, self)
	emit_signal("card_added_to_queue", card_ui)
	
	# 更新队列卡牌位置
	_update_queue_layout()
	
	# 计算所有可能的组合
	evaluate_combinations()
	
	# 减少剩余行动次数
	if battle_manager:
		battle_manager.turns_remaining -= 1

# 更新队列卡牌布局
func _update_queue_layout():
	var cards = get_held_cards()
	for i in range(cards.size()):
		var card = cards[i]
		card.target_position = position + Vector2(i * queue_spacing, 0)
		card.z_index = i

# 计算队列中所有可能的组合
func evaluate_combinations():
	var cards = get_held_cards()
	if cards.size() == 0:
		return
	
	# 清除之前的组合效果
	_clear_combination_effects()
	
	var all_results = []
	var total_score = 0
	
	# 检查所有可能的组合（同一张牌可以多次计算）
	
	# 1. 先检查每张单独的牌（灰烬）
	for card in cards:
		var result = {"type": "ASH", "name": "灰烬", "base_score": 10, "cards": [card], "score": 10}
		if battle_manager:
			result.score = int(result.base_score * battle_manager.score_multiplier)
		all_results.append(result)
		total_score += result.score
	
	# 2. 检查所有可能的魂组（两张相同的牌）
	for i in range(cards.size()):
		for j in range(i+1, cards.size()):
			var card1 = cards[i]
			var card2 = cards[j]
			if _is_same_value([card1, card2]):
				var result = {"type": "SOUL_PAIR", "name": "魂组", "base_score": 15, "cards": [card1, card2], "score": 15}
				if battle_manager:
					result.score = int(result.base_score * battle_manager.score_multiplier)
				all_results.append(result)
				total_score += result.score
	
	# 3. 检查所有可能的魂链（三张连续同花色牌）
	for i in range(cards.size()):
		for j in range(i+1, cards.size()):
			for k in range(j+1, cards.size()):
				var card_set = [cards[i], cards[j], cards[k]]
				if _is_consecutive_same_suit(card_set):
					var result = {"type": "SOUL_CHAIN", "name": "魂链", "base_score": 25, "cards": card_set, "score": 25}
					if battle_manager:
						result.score = int(result.base_score * battle_manager.score_multiplier)
					all_results.append(result)
					total_score += result.score
	
	# 4. 检查所有可能的刻印（三张相同的牌）
	for i in range(cards.size()):
		for j in range(i+1, cards.size()):
			for k in range(j+1, cards.size()):
				var card_set = [cards[i], cards[j], cards[k]]
				if _is_same_value(card_set):
					var result = {"type": "IMPRINT", "name": "刻印", "base_score": 40, "cards": card_set, "score": 40}
					if battle_manager:
						result.score = int(result.base_score * battle_manager.score_multiplier)
					all_results.append(result)
					total_score += result.score
	
	# 5. 检查所有可能的王印（四张相同的牌）
	if cards.size() >= 4:
		for i in range(cards.size()):
			for j in range(i+1, cards.size()):
				for k in range(j+1, cards.size()):
					for l in range(k+1, cards.size()):
						var card_set = [cards[i], cards[j], cards[k], cards[l]]
						if _is_same_value(card_set):
							var result = {"type": "KING_SEAL", "name": "王印", "base_score": 60, "cards": card_set, "score": 60}
							if battle_manager:
								result.score = int(result.base_score * battle_manager.score_multiplier)
							all_results.append(result)
							total_score += result.score
	
	# 显示组合可视化效果
	_show_combinations_visual(all_results)
	
	# 发送组合评估结果
	var summary = {
		"combinations": all_results,
		"total_score": total_score
	}
	emit_signal("combinations_evaluated", summary)
	
	# 更新玩家分数
	var player_stats = get_node_or_null("/root/PlayerStats")
	if player_stats:
		player_stats.add_score(total_score)

# 显示组合可视化效果
func _show_combinations_visual(combinations):
	active_combinations = combinations
	
	# 获取组合容器
	var container = get_node_or_null("CombinationContainer")
	if not container:
		return
	
	# 清除之前的效果
	for child in container.get_children():
		child.queue_free()
	
	# 为每个组合创建可视化效果
	for i in range(combinations.size()):
		var combo = combinations[i]
		var combo_cards = combo.cards
		
		# 创建组合显示器
		var combo_display = _create_combination_display(combo)
		combo_display.position = Vector2(0, -100 - i * 50)  # 垂直排列组合显示
		container.add_child(combo_display)
		
		# 创建卡牌连接线
		if combo_cards.size() > 1:
			_create_card_connections(combo_cards, combo.type, container)
		
		# 高亮显示参与组合的卡牌
		for card in combo_cards:
			_highlight_card(card, combo.type)
		
		# 创建得分显示
		var score_label = Label.new()
		score_label.text = "+" + str(combo.score)
		var first_card = combo_cards[0]
		score_label.position = first_card.target_position - position + Vector2(0, -30)
		container.add_child(score_label)
		
		# 添加短暂的动画效果
		_animate_combination_effect(combo, container)

# 创建组合显示器
func _create_combination_display(combo):
	var display = Label.new()
	display.text = combo.name + ": " + str(combo.score) + "分"
	
	# 根据组合类型设置颜色
	match combo.type:
		"ASH":
			display.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		"SOUL_PAIR":
			display.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
		"SOUL_CHAIN":
			display.add_theme_color_override("font_color", Color(0.0, 0.8, 0.4))
		"IMPRINT":
			display.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
		"KING_SEAL":
			display.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	
	return display

# 创建卡牌连接线
func _create_card_connections(cards, combo_type, container):
	if cards.size() < 2:
		return
	
	# 根据组合类型选择连接线颜色
	var line_color = Color.WHITE
	match combo_type:
		"SOUL_PAIR":
			line_color = Color(0.2, 0.6, 1.0, 0.7)
		"SOUL_CHAIN":
			line_color = Color(0.0, 0.8, 0.4, 0.7)
		"IMPRINT":
			line_color = Color(1.0, 0.5, 0.0, 0.7)
		"KING_SEAL":
			line_color = Color(1.0, 0.8, 0.0, 0.7)
	
	# 创建连接所有卡牌的线条
	for i in range(cards.size() - 1):
		var line = Line2D.new()
		line.default_color = line_color
		line.width = 3.0
		
		var start_card = cards[i]
		var end_card = cards[i + 1]
		
		line.add_point(start_card.target_position - position + Vector2(start_card.custom_minimum_size.x / 2, start_card.custom_minimum_size.y / 2))
		line.add_point(end_card.target_position - position + Vector2(end_card.custom_minimum_size.x / 2, end_card.custom_minimum_size.y / 2))
		
		container.add_child(line)

# 高亮显示参与组合的卡牌
func _highlight_card(card, combo_type):
	# 使用CardUI的高亮功能
	card.set_highlight(true, combo_type, 1.0)

# 动画化组合效果
func _animate_combination_effect(combo, container):
	# 创建组合类型标签显示
	var anim = Label.new()
	anim.text = combo.name + "!"
	
	# 设置标签位置：在卡牌上方居中
	var center_pos = Vector2(0, 0)
	for card in combo.cards:
		center_pos += card.target_position - position
	center_pos /= combo.cards.size()
	center_pos.y -= 50  # 上移一些
	
	anim.position = center_pos
	
	# 根据组合类型设置颜色和字体大小
	match combo.type:
		"ASH":
			anim.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			anim.add_theme_font_size_override("font_size", 18)
		"SOUL_PAIR":
			anim.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
			anim.add_theme_font_size_override("font_size", 22)
		"SOUL_CHAIN":
			anim.add_theme_color_override("font_color", Color(0.0, 0.8, 0.4))
			anim.add_theme_font_size_override("font_size", 24)
		"IMPRINT":
			anim.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
			anim.add_theme_font_size_override("font_size", 26)
		"KING_SEAL":
			anim.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
			anim.add_theme_font_size_override("font_size", 30)
	
	container.add_child(anim)
	
	# 创建得分显示
	var score_anim = Label.new()
	score_anim.text = "+" + str(combo.score)
	score_anim.position = center_pos + Vector2(0, 30)
	score_anim.add_theme_color_override("font_color", anim.get_theme_color("font_color", ""))
	score_anim.add_theme_font_size_override("font_size", 20)
	container.add_child(score_anim)
	
	# 设置标签动画
	_animate_label(anim)
	_animate_label(score_anim)
	
	# 设置自动清除
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.autostart = true
	anim.add_child(timer)
	timer.connect("timeout", func(): 
		anim.queue_free()
		score_anim.queue_free()
	)
	
	# 设置卡牌特效动画
	for card in combo.cards:
		_animate_card_effect(card, combo.type)

# 给标签添加动画效果
func _animate_label(label):
	# 创建一个动画效果：放大然后缩小
	var tween = get_tree().create_tween()
	tween.tween_property(label, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.3)
	
	# 添加淡出效果
	tween = get_tree().create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)

# 给卡牌添加特效动画
func _animate_card_effect(card, combo_type):
	# 抖动效果
	var tween = get_tree().create_tween()
	var original_pos = card.target_position
	
	# 根据组合类型设置不同的抖动强度
	var shake_intensity = 3.0
	match combo_type:
		"SOUL_PAIR":
			shake_intensity = 4.0
		"SOUL_CHAIN":
			shake_intensity = 5.0
		"IMPRINT":
			shake_intensity = 6.0
		"KING_SEAL":
			shake_intensity = 8.0
	
	# 创建抖动序列
	for i in range(5):
		var random_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		tween.tween_property(card, "position", original_pos + random_offset, 0.05)
	
	# 回到原始位置
	tween.tween_property(card, "target_position", original_pos, 0.1)

# 清除组合效果
func _clear_combination_effects():
	var container = get_node_or_null("CombinationContainer")
	if container:
		for child in container.get_children():
			child.queue_free()
	
	# 清除卡牌高亮效果
	var cards = get_held_cards()
	for card in cards:
		card.set_highlight(false)
	
	active_combinations = []

# 辅助函数：检查是否相同点数
func _is_same_value(cards: Array) -> bool:
	if cards.size() < 2:
		return false
		
	var first_card_data = cards[0].card_data
	if not first_card_data.value:
		return false
		
	var first_value = first_card_data.value
	
	for card in cards:
		if not card.card_data.value or card.card_data.value != first_value:
			return false
			
	return true

# 辅助函数：检查是否连续同花色
func _is_consecutive_same_suit(cards: Array) -> bool:
	if cards.size() < 3:
		return false
		
	# 检查花色
	var first_card_data = cards[0].card_data
	if not first_card_data.suit or not first_card_data.value:
		return false
		
	var suit = first_card_data.suit
	
	# 收集所有点数
	var values = []
	for card in cards:
		if not card.card_data.suit or not card.card_data.value:
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

# 清空队列
func clear_queue():
	var cards_to_remove = _held_cards.duplicate()
	for card in cards_to_remove:
		card_pile_ui.set_card_pile(card, CardPileUI.Piles.discard_pile)
		emit_signal("card_removed_from_queue", card) 
	
	# 清除组合效果
	_clear_combination_effects()

# 覆盖原有的更新目标位置方法，使用自定义的队列布局
func _update_target_positions():
	_update_queue_layout() 
