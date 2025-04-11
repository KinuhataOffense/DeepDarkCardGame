class_name CardUIData extends Resource

signal card_data_updated

@export var nice_name : String
@export var value : int = 0  # 卡牌点数
@export var suit : String = ""  # 卡牌花色：spades(黑桃), hearts(红心), diamonds(方块), clubs(梅花)
@export var is_special_card : bool = false  # 是否是特殊卡牌
@export var effect_id : String = ""  # 卡牌效果ID
@export var description : String = ""  # 卡牌描述
@export var burn_after_use : bool = false  # 使用后是否销毁
@export var multiplier : float = 1.0  # 卡牌倍率
@export var power_decrease_rate : float = 0.0  # 卡牌力量减少率

# 获取卡牌的完整名称
func get_full_name() -> String:
	if is_special_card:
		return nice_name
	else:
		var suit_name = ""
		match suit:
			"spades": suit_name = "黑桃"
			"hearts": suit_name = "红心"
			"diamonds": suit_name = "方块"
			"clubs": suit_name = "梅花"
		return suit_name + str(value)

# 检查是否是特殊卡牌
func is_special() -> bool:
	return is_special_card

# 获取卡牌描述
func get_description() -> String:
	if !description:
		return "普通卡牌: " + get_full_name()
	return description

# 设置卡牌属性并发出更新信号
func set_properties(properties: Dictionary):
	for key in properties:
		if self[key]:
			self[key] = properties[key]
	
	emit_signal("card_data_updated")
