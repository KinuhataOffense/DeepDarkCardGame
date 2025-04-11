extends Control

# 使用统一的信号名，与GameManager保持一致
signal return_to_map_requested

# 引用UI元素
@onready var currency_value = $VBoxContainer/CurrencyReward/CurrencyValue
@onready var return_button = $VBoxContainer/ReturnButton
@onready var other_rewards_container = $VBoxContainer/OtherRewards
@onready var title_label = $VBoxContainer/TitleLabel

var reward_data = {}

func _ready():
	print("奖励场景: _ready() 被调用")
	
	# 检查和修复场景布局
	_check_and_fix_layout()
	
	# 确保UI元素存在
	if !currency_value or !return_button or !other_rewards_container:
		print("奖励场景错误: UI元素未找到!")
		_print_scene_structure()
		return
	
	# 设置标题
	if title_label:
		title_label.text = "战斗胜利!"
	
	# 连接返回按钮信号
	if !return_button.is_connected("pressed", _on_return_button_pressed):
		return_button.pressed.connect(_on_return_button_pressed)
		print("奖励场景: 返回按钮信号已连接")
	
	# 显示奖励数据
	display_rewards()
	
	print("奖励场景: 初始化完成")

# 检查和修复场景布局
func _check_and_fix_layout():
	print("奖励场景: 检查布局")
	
	# 检查基本结构
	var vbox = get_node_or_null("VBoxContainer")
	if !vbox:
		print("奖励场景错误: 主VBoxContainer不存在，创建基本布局")
		_create_basic_layout()
		return
	
	# 检查并修复各个组件
	if !title_label:
		var title = Label.new()
		title.name = "TitleLabel"
		title.text = "战斗胜利!"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.custom_minimum_size = Vector2(0, 60)
		vbox.add_child(title)
		vbox.move_child(title, 0)
		title_label = title
		print("奖励场景: 添加了标题标签")
	
	# 检查货币奖励容器
	var currency_container = vbox.get_node_or_null("CurrencyReward")
	if !currency_container:
		print("奖励场景: 创建货币奖励容器")
		currency_container = HBoxContainer.new()
		currency_container.name = "CurrencyReward"
		
		var currency_label = Label.new()
		currency_label.name = "CurrencyLabel"
		currency_label.text = "获得金币: "
		currency_container.add_child(currency_label)
		
		var value_label = Label.new()
		value_label.name = "CurrencyValue"
		value_label.text = "0"
		currency_container.add_child(value_label)
		
		vbox.add_child(currency_container)
		currency_value = value_label
		print("奖励场景: 添加了货币奖励显示")
	
	# 检查其他奖励容器
	if !other_rewards_container:
		print("奖励场景: 创建其他奖励容器")
		var rewards_container = VBoxContainer.new()
		rewards_container.name = "OtherRewards"
		vbox.add_child(rewards_container)
		other_rewards_container = rewards_container
		print("奖励场景: 添加了其他奖励容器")
	
	# 检查返回按钮
	if !return_button:
		print("奖励场景: 创建返回按钮")
		var button = Button.new()
		button.name = "ReturnButton"
		button.text = "返回地图"
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.custom_minimum_size = Vector2(200, 60)
		vbox.add_child(button)
		return_button = button
		print("奖励场景: 添加了返回按钮")
	
	print("奖励场景: 布局检查完成")

# 创建基本布局（当场景结构严重损坏时）
func _create_basic_layout():
	print("奖励场景: 创建基本布局")
	
	# 移除所有现有子节点
	for child in get_children():
		child.queue_free()
	
	# 创建主容器
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.size_flags_horizontal = Control.SIZE_FILL
	vbox.size_flags_vertical = Control.SIZE_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)
	
	# 创建标题
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "战斗胜利!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(title)
	
	# 创建货币奖励容器
	var currency_container = HBoxContainer.new()
	currency_container.name = "CurrencyReward"
	currency_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var currency_label = Label.new()
	currency_label.name = "CurrencyLabel"
	currency_label.text = "获得金币: "
	currency_container.add_child(currency_label)
	
	var value_label = Label.new()
	value_label.name = "CurrencyValue"
	value_label.text = "0"
	currency_container.add_child(value_label)
	
	vbox.add_child(currency_container)
	
	# 创建其他奖励容器
	var rewards_container = VBoxContainer.new()
	rewards_container.name = "OtherRewards"
	rewards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(rewards_container)
	
	# 创建返回按钮
	var button = Button.new()
	button.name = "ReturnButton"
	button.text = "返回地图"
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.custom_minimum_size = Vector2(200, 60)
	vbox.add_child(button)
	
	# 重新获取引用
	title_label = title
	currency_value = value_label
	return_button = button
	other_rewards_container = rewards_container
	
	print("奖励场景: 基本布局创建完成")

# 调试打印场景结构
func _print_scene_structure():
	print("奖励场景: 场景结构如下 ===")
	_print_node_recursive(self)
	print("奖励场景: 场景结构结束 ===")

func _print_node_recursive(node, indent = ""):
	print(indent + "- " + node.name + " [" + node.get_class() + "]")
	for child in node.get_children():
		_print_node_recursive(child, indent + "  ")

# 设置奖励数据
func set_reward_data(data):
	print("奖励场景: 设置奖励数据", data)
	if data == null:
		print("奖励场景错误: 收到空奖励数据!")
		data = {"currency": 50}  # 使用默认值
	
	reward_data = data
	
	# 如果已经准备好了界面，马上更新显示
	if is_inside_tree() and currency_value:
		display_rewards()
	else:
		print("奖励场景: 界面尚未准备好，稍后更新显示")
		# 推迟到下一帧尝试更新
		call_deferred("_try_update_display")

# 尝试再次更新显示（当初始化时间不对时）
func _try_update_display():
	if is_inside_tree() and currency_value:
		display_rewards()
	else:
		print("奖励场景: 界面仍未准备好，无法显示奖励")

# 显示奖励内容
func display_rewards():
	print("奖励场景: 显示奖励内容")
	
	# 再次检查UI元素
	if !currency_value or !other_rewards_container:
		print("奖励场景错误: 无法显示奖励，UI元素缺失")
		return
	
	# 显示货币奖励
	if reward_data.has("currency"):
		currency_value.text = str(reward_data.currency)
		print("奖励场景: 显示货币奖励:", reward_data.currency)
	else:
		currency_value.text = "0"
		print("奖励场景: 没有货币奖励数据，显示0")
	
	# 清除现有的其他奖励显示
	for child in other_rewards_container.get_children():
		child.queue_free()
	
	# 显示其他类型的奖励(未来扩展)
	if reward_data.has("items"):
		for item in reward_data.items:
			var item_label = Label.new()
			item_label.text = "获得物品: " + item.name
			other_rewards_container.add_child(item_label)
			print("奖励场景: 添加物品奖励:", item.name)
	
	if reward_data.has("cards"):
		for card in reward_data.cards:
			var card_label = Label.new()
			card_label.text = "获得卡牌: " + card.name
			other_rewards_container.add_child(card_label)
			print("奖励场景: 添加卡牌奖励:", card.name)
	
	print("奖励场景: 奖励显示完成")

# 返回按钮点击事件
func _on_return_button_pressed():
	print("奖励场景: 点击返回地图按钮")
	
	# 在销毁前发出返回地图信号
	emit_signal("return_to_map_requested")
	print("奖励场景: 已发送return_to_map_requested信号")
	
	# 解除按钮的信号连接以防止多次触发
	if return_button and return_button.is_connected("pressed", _on_return_button_pressed):
		return_button.disconnect("pressed", _on_return_button_pressed)
	
	# 注意：不要在这里使用queue_free()，应该由GameManager处理场景切换 

# 场景退出树时的清理
func _exit_tree():
	print("奖励场景: _exit_tree() 被调用，场景即将销毁")
	
	# 断开所有信号连接
	if return_button and return_button.is_connected("pressed", _on_return_button_pressed):
		return_button.disconnect("pressed", _on_return_button_pressed)
	
	print("奖励场景: 信号连接已断开，场景退出树")
