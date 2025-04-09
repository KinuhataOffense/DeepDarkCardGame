# 为卡牌添加老旧效果
# card_node: 卡牌节点
# rarity: 稀有度 (0-普通, 1-稀有, 2-史诗, 3-传说)
func apply_worn_effect(card_node, rarity = 0):
	# 检查是否已经有老旧效果组件
	var worn_effect = card_node.get_node_or_null("WornEffect")
	
	# 如果没有，则添加组件
	if not worn_effect:
		worn_effect = load("res://scripts/effects/card_worn_effect.gd").new()
		worn_effect.name = "WornEffect"
		card_node.add_child(worn_effect)
	
	# 根据稀有度设置不同的老旧程度
	match rarity:
		0: # 普通卡牌 - 中等老旧
			worn_effect.set_worn_preset(worn_effect.WornPreset.MEDIUM)
			worn_effect.randomize_worn_parameters(0.3, 0.5)
		1: # 稀有卡牌 - 轻微老旧
			worn_effect.set_worn_preset(worn_effect.WornPreset.LIGHT)
			worn_effect.randomize_worn_parameters(0.1, 0.3)
		2: # 史诗卡牌 - 几乎无老旧
			worn_effect.set_worn_preset(worn_effect.WornPreset.LIGHT)
			worn_effect.randomize_worn_parameters(0.05, 0.15)
		3: # 传说卡牌 - 无老旧效果
			worn_effect.set_worn_preset(worn_effect.WornPreset.NONE)
		4: # 特殊古老卡牌 - 严重老旧
			worn_effect.set_worn_preset(worn_effect.WornPreset.HEAVY)
			worn_effect.randomize_worn_parameters(0.6, 0.9)

# 更新现有的创建卡牌方法，添加老旧效果
func create_card(card_data):
	var card_instance = card_scene.instantiate()
	# ... 现有代码 ...
	
	# 添加老旧效果
	apply_worn_effect(card_instance, card_data.rarity if "rarity" in card_data else 0)
	
	return card_instance 