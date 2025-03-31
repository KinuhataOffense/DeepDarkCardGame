extends Resource
class_name CardData

signal card_data_updated

# 卡牌基础属性
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var value: int = 0

# 卡牌类型定义
enum CardSuit {
	SPADES,    # 黑桃
	HEARTS,    # 红心
	CLUBS,     # 梅花
	DIAMONDS,  # 方块
	SPECIAL    # 特殊(无花色)
}
@export var suit: CardSuit = CardSuit.SPECIAL

# 卡牌类型
enum CardType {
	ATTACK,    # 攻击
	DEFENSE,   # 防御
	SKILL,     # 技能
	POWER,     # 能力
	STATUS,    # 状态
	CURSE      # 诅咒
}
@export var card_type: CardType = CardType.ATTACK

# 稀有度
enum CardRarity {
	COMMON,    # 普通
	UNCOMMON,  # 稀有
	RARE,      # 史诗
	LEGENDARY  # 传说
}
@export var rarity: CardRarity = CardRarity.COMMON

# 卡牌视觉相关
@export var texture_path: String = ""
@export var backface_texture_path: String = ""

# 卡牌效果相关
@export var burn_after_use: bool = false  # 使用后销毁
@export var effects: Array = []  # 效果数组，可以包含多个效果

# 自定义属性
var custom_properties: Dictionary = {}

# 初始化函数
func _init():
	pass

# 获取卡牌全名（包含花色）
func get_full_name() -> String:
	if suit == CardSuit.SPECIAL:
		return name
	
	var suit_symbol = ""
	match suit:
		CardSuit.SPADES:
			suit_symbol = "♠"
		CardSuit.HEARTS:
			suit_symbol = "♥"
		CardSuit.CLUBS:
			suit_symbol = "♣"
		CardSuit.DIAMONDS:
			suit_symbol = "♦"
	
	return name + " " + suit_symbol

# 获取卡牌类型名称
func get_type_name() -> String:
	match card_type:
		CardType.ATTACK:
			return "攻击"
		CardType.DEFENSE:
			return "防御"
		CardType.SKILL:
			return "技能"
		CardType.POWER:
			return "能力"
		CardType.STATUS:
			return "状态"
		CardType.CURSE:
			return "诅咒"
	return "未知"

# 获取卡牌稀有度名称
func get_rarity_name() -> String:
	match rarity:
		CardRarity.COMMON:
			return "普通"
		CardRarity.UNCOMMON:
			return "稀有"
		CardRarity.RARE:
			return "史诗"
		CardRarity.LEGENDARY:
			return "传说"
	return "未知"

# 获取卡牌颜色
func get_color() -> Color:
	match suit:
		CardSuit.HEARTS, CardSuit.DIAMONDS:
			return Color(0.8, 0.2, 0.2)  # 红色
		CardSuit.SPADES, CardSuit.CLUBS:
			return Color(0.2, 0.2, 0.2)  # 黑色
		CardSuit.SPECIAL:
			return Color(0.6, 0.4, 0.8)  # 紫色
	return Color(1, 1, 1)  # 默认白色

# 检查卡牌是否可以使用（如果有特殊条件，子类可以重写这个方法）
func can_be_used() -> bool:
	# 基本实现：所有卡牌都可以使用
	return true

# 复制卡牌数据
func duplicate() -> CardData:
	var copy = get_script().new()
	copy.id = id
	copy.name = name
	copy.description = description
	copy.value = value
	copy.suit = suit
	copy.card_type = card_type
	copy.rarity = rarity
	copy.texture_path = texture_path
	copy.backface_texture_path = backface_texture_path
	copy.burn_after_use = burn_after_use
	
	# 深拷贝效果数组
	copy.effects = []
	for effect in effects:
		copy.effects.append(effect.duplicate() if effect.has_method("duplicate") else effect)
	
	# 深拷贝自定义属性
	copy.custom_properties = {}
	for key in custom_properties:
		var value = custom_properties[key]
		copy.custom_properties[key] = value.duplicate() if value is Object and value.has_method("duplicate") else value
	
	return copy 
