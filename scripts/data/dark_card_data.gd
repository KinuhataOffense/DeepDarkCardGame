extends CardUIData  
class_name DarkCardData  

# 基础属性  
@export var suit: String  # 花色：红桃、方块、梅花、黑桃  
@export var value: int    # 点数：1-13  
@export var power: int = 1  # 卡牌强度倍率  

# 卡牌类型  
enum CardType { NORMAL, ENHANCED, SPECIAL }  
@export var card_type: CardType = CardType.NORMAL  

# 特殊效果  
@export var effect_description: String = ""  
@export var effect_id: String = ""  

# 状态属性  
var is_marked: bool = false  # 被敌人标记  
var is_locked: bool = false  # 被玩家锁定  
var burn_after_use: bool = false  # 使用后销毁  
var temp_effects: Array = []  # 临时效果  

# 可选的增强特性  
var use_count: int = 0  # 使用次数计数  
var power_decrease_rate: int = 0  # 每次使用后降低的强度  
