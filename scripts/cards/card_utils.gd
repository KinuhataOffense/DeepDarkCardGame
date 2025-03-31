extends Node
class_name CardUtils

# 卡牌数据加载函数
static func load_cards_from_json(file_path: String) -> Array[CardData]:
	var cards: Array[CardData] = []
	
	if not FileAccess.file_exists(file_path):
		print("错误: 找不到卡牌数据文件 " + file_path)
		return cards
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		print("错误: 解析卡牌数据失败: " + json.get_error_message())
		return cards
	
	var card_data_array = json.get_data()
	if typeof(card_data_array) != TYPE_ARRAY:
		print("错误: 卡牌数据应为数组")
		return cards
	
	for card_info in card_data_array:
		if typeof(card_info) != TYPE_DICTIONARY:
			continue
			
		var card = CardData.new()
		
		# 必须字段
		if not "id" in card_info or not "name" in card_info:
			print("警告: 卡牌缺少必须的ID或名称字段，跳过")
			continue
			
		card.id = card_info.id
		card.name = card_info.name
		
		# 可选字段
		card.description = card_info.get("description", "")
		card.value = card_info.get("value", 0)
		
		# 设置花色
		if "suit" in card_info:
			match card_info.suit:
				"spades": card.suit = CardData.CardSuit.SPADES
				"hearts": card.suit = CardData.CardSuit.HEARTS
				"clubs": card.suit = CardData.CardSuit.CLUBS
				"diamonds": card.suit = CardData.CardSuit.DIAMONDS
				"special": card.suit = CardData.CardSuit.SPECIAL
		
		# 设置类型
		if "type" in card_info:
			match card_info.type:
				"attack": card.card_type = CardData.CardType.ATTACK
				"defense": card.card_type = CardData.CardType.DEFENSE
				"skill": card.card_type = CardData.CardType.SKILL
				"power": card.card_type = CardData.CardType.POWER
				"status": card.card_type = CardData.CardType.STATUS
				"curse": card.card_type = CardData.CardType.CURSE
		
		# 设置稀有度
		if "rarity" in card_info:
			match card_info.rarity:
				"common": card.rarity = CardData.CardRarity.COMMON
				"uncommon": card.rarity = CardData.CardRarity.UNCOMMON
				"rare": card.rarity = CardData.CardRarity.RARE
				"legendary": card.rarity = CardData.CardRarity.LEGENDARY
		
		# 设置纹理路径
		if "texture" in card_info:
			card.texture_path = card_info.texture
		
		# 设置背面纹理路径
		if "backface" in card_info:
			card.backface_texture_path = card_info.backface
		
		# 设置使用后销毁
		if "burn_after_use" in card_info:
			card.burn_after_use = card_info.burn_after_use
		
		# 加载卡牌效果
		if "effects" in card_info and card_info.effects is Array:
			for effect_info in card_info.effects:
				if effect_info is Dictionary:
					card.effects.append(create_effect_from_dict(effect_info))
		
		# 设置自定义属性
		if "custom_properties" in card_info and card_info.custom_properties is Dictionary:
			card.custom_properties = card_info.custom_properties.duplicate()
		
		cards.append(card)
	
	print("成功加载 " + str(cards.size()) + " 张卡牌")
	return cards

# 从字典创建效果
static func create_effect_from_dict(effect_info: Dictionary) -> CardEffect:
	var effect_type = CardEffect.EffectType.DAMAGE
	var target_type = CardEffect.EffectTarget.ENEMY
	var value = 0
	
	# 解析效果类型
	if "type" in effect_info:
		match effect_info.type:
			"damage": effect_type = CardEffect.EffectType.DAMAGE
			"block": effect_type = CardEffect.EffectType.BLOCK
			"heal": effect_type = CardEffect.EffectType.HEAL
			"buff": effect_type = CardEffect.EffectType.BUFF
			"debuff": effect_type = CardEffect.EffectType.DEBUFF
			"draw": effect_type = CardEffect.EffectType.DRAW
			"discard": effect_type = CardEffect.EffectType.DISCARD
			"energy": effect_type = CardEffect.EffectType.ENERGY
			"special": effect_type = CardEffect.EffectType.SPECIAL
	
	# 解析目标类型
	if "target" in effect_info:
		match effect_info.target:
			"self": target_type = CardEffect.EffectTarget.SELF
			"enemy": target_type = CardEffect.EffectTarget.ENEMY
			"all_enemies": target_type = CardEffect.EffectTarget.ALL_ENEMIES
			"random_enemy": target_type = CardEffect.EffectTarget.RANDOM_ENEMY
			"all": target_type = CardEffect.EffectTarget.ALL
	
	# 解析效果值
	if "value" in effect_info:
		value = effect_info.value
	
	# 创建效果
	var effect = CardEffect.new(effect_type, target_type, value)
	
	# 添加额外参数
	if "extra_params" in effect_info and effect_info.extra_params is Dictionary:
		effect.extra_params = effect_info.extra_params.duplicate()
	
	return effect

# 保存卡牌数据到文件
static func save_cards_to_json(cards: Array[CardData], file_path: String) -> bool:
	var json_array = []
	
	for card in cards:
		var card_dict = {
			"id": card.id,
			"name": card.name,
			"description": card.description,
			"value": card.value
		}
		
		# 添加花色
		match card.suit:
			CardData.CardSuit.SPADES: card_dict["suit"] = "spades"
			CardData.CardSuit.HEARTS: card_dict["suit"] = "hearts"
			CardData.CardSuit.CLUBS: card_dict["suit"] = "clubs"
			CardData.CardSuit.DIAMONDS: card_dict["suit"] = "diamonds"
			CardData.CardSuit.SPECIAL: card_dict["suit"] = "special"
		
		# 添加类型
		match card.card_type:
			CardData.CardType.ATTACK: card_dict["type"] = "attack"
			CardData.CardType.DEFENSE: card_dict["type"] = "defense"
			CardData.CardType.SKILL: card_dict["type"] = "skill"
			CardData.CardType.POWER: card_dict["type"] = "power"
			CardData.CardType.STATUS: card_dict["type"] = "status"
			CardData.CardType.CURSE: card_dict["type"] = "curse"
		
		# 添加稀有度
		match card.rarity:
			CardData.CardRarity.COMMON: card_dict["rarity"] = "common"
			CardData.CardRarity.UNCOMMON: card_dict["rarity"] = "uncommon"
			CardData.CardRarity.RARE: card_dict["rarity"] = "rare"
			CardData.CardRarity.LEGENDARY: card_dict["rarity"] = "legendary"
		
		# 添加纹理路径
		if card.texture_path:
			card_dict["texture"] = card.texture_path
		
		# 添加背面纹理路径
		if card.backface_texture_path:
			card_dict["backface"] = card.backface_texture_path
		
		# 添加使用后销毁标志
		card_dict["burn_after_use"] = card.burn_after_use
		
		# 添加效果
		var effects_array = []
		for effect in card.effects:
			if effect is CardEffect:
				var effect_dict = effects_to_dict(effect)
				effects_array.append(effect_dict)
		
		if effects_array.size() > 0:
			card_dict["effects"] = effects_array
		
		# 添加自定义属性
		if card.custom_properties.size() > 0:
			card_dict["custom_properties"] = card.custom_properties.duplicate()
		
		json_array.append(card_dict)
	
	var json_string = JSON.stringify(json_array, "  ")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("卡牌数据已保存到文件: " + file_path)
		return true
	else:
		print("错误: 无法保存卡牌数据到文件: " + file_path)
		return false

# 将效果转换为字典
static func effects_to_dict(effect: CardEffect) -> Dictionary:
	var effect_dict = {
		"value": effect.value
	}
	
	# 添加效果类型
	match effect.effect_type:
		CardEffect.EffectType.DAMAGE: effect_dict["type"] = "damage"
		CardEffect.EffectType.BLOCK: effect_dict["type"] = "block"
		CardEffect.EffectType.HEAL: effect_dict["type"] = "heal"
		CardEffect.EffectType.BUFF: effect_dict["type"] = "buff"
		CardEffect.EffectType.DEBUFF: effect_dict["type"] = "debuff"
		CardEffect.EffectType.DRAW: effect_dict["type"] = "draw"
		CardEffect.EffectType.DISCARD: effect_dict["type"] = "discard"
		CardEffect.EffectType.ENERGY: effect_dict["type"] = "energy"
		CardEffect.EffectType.SPECIAL: effect_dict["type"] = "special"
	
	# 添加目标类型
	match effect.target_type:
		CardEffect.EffectTarget.SELF: effect_dict["target"] = "self"
		CardEffect.EffectTarget.ENEMY: effect_dict["target"] = "enemy"
		CardEffect.EffectTarget.ALL_ENEMIES: effect_dict["target"] = "all_enemies"
		CardEffect.EffectTarget.RANDOM_ENEMY: effect_dict["target"] = "random_enemy"
		CardEffect.EffectTarget.ALL: effect_dict["target"] = "all"
	
	# 添加额外参数
	if effect.extra_params.size() > 0:
		effect_dict["extra_params"] = effect.extra_params.duplicate()
	
	return effect_dict

# 获取稀有度颜色
static func get_rarity_color(rarity: CardData.CardRarity) -> Color:
	match rarity:
		CardData.CardRarity.COMMON:
			return Color(0.7, 0.7, 0.7)  # 灰色
		CardData.CardRarity.UNCOMMON:
			return Color(0.2, 0.5, 1.0)  # 蓝色
		CardData.CardRarity.RARE:
			return Color(0.7, 0.2, 1.0)  # 紫色
		CardData.CardRarity.LEGENDARY:
			return Color(1.0, 0.8, 0.0)  # 金色
	return Color(1, 1, 1)  # 默认白色

# 获取卡牌类型颜色
static func get_card_type_color(card_type: CardData.CardType) -> Color:
	match card_type:
		CardData.CardType.ATTACK:
			return Color(0.8, 0.2, 0.2)  # 红色
		CardData.CardType.DEFENSE:
			return Color(0.2, 0.6, 0.8)  # 蓝色
		CardData.CardType.SKILL:
			return Color(0.2, 0.8, 0.2)  # 绿色
		CardData.CardType.POWER:
			return Color(0.8, 0.2, 0.8)  # 紫色
		CardData.CardType.STATUS:
			return Color(0.7, 0.7, 0.2)  # 黄色
		CardData.CardType.CURSE:
			return Color(0.4, 0.0, 0.0)  # 暗红色
	return Color(0.5, 0.5, 0.5)  # 默认灰色

# 打乱卡牌顺序
static func shuffle_cards(cards: Array) -> Array:
	var shuffled = cards.duplicate()
	randomize()
	shuffled.shuffle()
	return shuffled

# 按稀有度筛选卡牌
static func filter_by_rarity(cards: Array[CardData], rarity: CardData.CardRarity) -> Array[CardData]:
	var filtered: Array[CardData] = []
	
	for card in cards:
		if card.rarity == rarity:
			filtered.append(card)
	
	return filtered

# 按类型筛选卡牌
static func filter_by_type(cards: Array[CardData], card_type: CardData.CardType) -> Array[CardData]:
	var filtered: Array[CardData] = []
	
	for card in cards:
		if card.card_type == card_type:
			filtered.append(card)
	
	return filtered

# 按花色筛选卡牌
static func filter_by_suit(cards: Array[CardData], suit: CardData.CardSuit) -> Array[CardData]:
	var filtered: Array[CardData] = []
	
	for card in cards:
		if card.suit == suit:
			filtered.append(card)
	
	return filtered

# 按卡牌ID查找卡牌
static func find_card_by_id(cards: Array[CardData], card_id: String) -> CardData:
	for card in cards:
		if card.id == card_id:
			return card
	
	return null 
