extends Control

signal return_to_map_requested

# 奖励场景配置
@export var default_currency_reward: int = 10
@export var default_cards_reward: int = 1

# 界面元素
@onready var currency_label = $RewardPanel/CurrencyReward/Value
@onready var return_button = $ReturnButton

# 奖励数据
var reward_data := {}
var is_from_rogue := false # 标记是否来自Rogue模式

func _ready():
	# 连接界面信号
	return_button.pressed.connect(_on_return_button_pressed)
	
	# 设置默认奖励
	set_reward_data({"currency": default_currency_reward})

# 设置奖励数据
func set_reward_data(data: Dictionary):
	reward_data = data
	_update_ui()
	
	# 检查是否来自Rogue模式
	if data.has("from_rogue_mode"):
		is_from_rogue = data.from_rogue_mode

# 显式设置是否来自Rogue模式
func set_from_rogue(value: bool):
	is_from_rogue = value
	print("奖励场景: 设置来源标记 is_from_rogue =", is_from_rogue)

# 更新UI显示
func _update_ui():
	# 更新金币显示
	if reward_data.has("currency"):
		currency_label.text = str(reward_data.currency)
	else:
		currency_label.text = str(default_currency_reward)
	
	# 添加收集到奖励的逻辑
	if reward_data.has("currency") and reward_data.currency > 0:
		GameData.add_currency(reward_data.currency)
		print("奖励场景: 添加", reward_data.currency, "金币到玩家账户")

# 处理返回按钮点击事件
func _on_return_button_pressed():
	print("奖励场景: 返回按钮被点击，is_from_rogue =", is_from_rogue)
	emit_signal("return_to_map_requested")
	
# 获取是否来自Rogue模式
func is_from_rogue() -> bool:
	return is_from_rogue 