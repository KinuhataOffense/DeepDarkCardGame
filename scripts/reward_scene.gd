extends Control

signal return_to_map_requested

@onready var currency_value = $VBoxContainer/CurrencyReward/CurrencyValue
@onready var return_button = $VBoxContainer/ReturnButton
@onready var other_rewards_container = $VBoxContainer/OtherRewards

var reward_data = {}

func _ready():
	print("奖励场景: _ready() 被调用")
	# 连接返回按钮信号
	return_button.pressed.connect(_on_return_button_pressed)
	
	# 显示奖励数据
	display_rewards()
	
	print("奖励场景: 初始化完成")

# 设置奖励数据
func set_reward_data(data):
	print("奖励场景: 设置奖励数据", data)
	reward_data = data
	# 如果已经准备好了界面，马上更新显示
	if is_inside_tree() and currency_value:
		display_rewards()
	else:
		print("奖励场景: 界面尚未准备好，稍后更新显示")

# 显示奖励内容
func display_rewards():
	print("奖励场景: 显示奖励内容")
	# 显示货币奖励
	if reward_data.has("currency"):
		currency_value.text = str(reward_data.currency)
	else:
		currency_value.text = "0"
	
	# 清除现有的其他奖励显示
	for child in other_rewards_container.get_children():
		child.queue_free()
	
	# 显示其他类型的奖励(未来扩展)
	if reward_data.has("items"):
		for item in reward_data.items:
			var item_label = Label.new()
			item_label.text = "获得物品: " + item.name
			other_rewards_container.add_child(item_label)
	
	if reward_data.has("cards"):
		for card in reward_data.cards:
			var card_label = Label.new()
			card_label.text = "获得卡牌: " + card.name
			other_rewards_container.add_child(card_label)
	
	print("奖励场景: 奖励显示完成")

# 返回按钮点击事件
func _on_return_button_pressed():
	print("奖励场景: 点击返回地图按钮")
	# 发出返回地图信号
	emit_signal("return_to_map_requested")
	print("奖励场景: 已发送返回地图信号")
	# 释放当前场景
	call_deferred("queue_free")
	print("奖励场景: 已标记为待释放") 