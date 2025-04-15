extends Control

# 使用统一的信号名，与GameManager保持一致
signal return_to_map_requested

# 引用UI元素
@onready var currency_value = $MainContainer/RewardPanel/VBoxContainer/RewardsContainer/CurrencyReward/CurrencyValue
@onready var return_button = $MainContainer/RewardPanel/VBoxContainer/ButtonContainer/ReturnButton
@onready var other_rewards = $MainContainer/RewardPanel/VBoxContainer/RewardsContainer/OtherRewards
@onready var title_label = $MainContainer/RewardPanel/VBoxContainer/TitleLabel

# 变量
var reward_data: Dictionary = {}
var is_from_rogue_mode = false
var item_textures = {
	"health_potion": preload("res://assets/ui/rewards/health_potion.png"),
	"damage_boost": preload("res://assets/ui/rewards/damage_boost.png"),
	"shield": preload("res://assets/ui/rewards/shield.png"),
	"gold_chest": preload("res://assets/ui/rewards/gold_chest.png")
}

func _ready():
	print("奖励场景: _ready() 被调用")
	
	# 检查和修复场景布局
	_check_and_fix_layout()
	
	# 确保UI元素存在
	if !currency_value or !return_button or !other_rewards:
		print("奖励场景错误: UI元素未找到!")
		_print_scene_structure()
		return
	
	# 设置标题
	if title_label:
		title_label.text = "战斗胜利!"
	
	# 连接返回按钮信号
	if return_button.is_connected("pressed", _on_return_button_pressed):
		return_button.disconnect("pressed", _on_return_button_pressed)
	
	return_button.pressed.connect(_on_return_button_pressed)
	print("奖励场景: 返回按钮信号已连接")
	
	# 尝试从GameManager中检测是否为Rogue模式
	_detect_game_mode()
	
	# 根据来源模式设置按钮文本
	update_return_button_text()
	
	print("奖励场景: 初始化完成，is_from_rogue_mode =", is_from_rogue_mode)

# 检查和修复场景布局
func _check_and_fix_layout():
	print("奖励场景: 检查布局")
	
	# 检查基本结构
	var vbox = get_node_or_null("MainContainer/RewardPanel/VBoxContainer")
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
	if !other_rewards:
		print("奖励场景: 创建其他奖励容器")
		var rewards_container = VBoxContainer.new()
		rewards_container.name = "OtherRewards"
		vbox.add_child(rewards_container)
		other_rewards = rewards_container
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
	vbox.name = "MainContainer/RewardPanel/VBoxContainer"
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
	other_rewards = rewards_container
	
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

# 显示奖励数据
func update_ui():
	print("奖励场景: 显示奖励数据")
	
	if reward_data.is_empty():
		return
	
	# 更新标题
	title_label.text = "战斗胜利!"
	
	# 更新货币奖励
	if reward_data.has("currency"):
		currency_value.text = str(reward_data.currency)
	
	# 更新其他奖励
	if reward_data.has("items"):
		for item in reward_data.items:
			var item_label = Label.new()
			item_label.text = "获得物品: %s x%d" % [item.name, item.quantity]
			item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			other_rewards.add_child(item_label)
	
	# 更新经验奖励
	if reward_data.has("exp"):
		var exp_label = Label.new()
		exp_label.text = "获得经验: %d" % reward_data.exp
		exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		other_rewards.add_child(exp_label)

# 更新返回按钮文本
func update_return_button_text():
	if return_button:
		return_button.text = "返回关卡" if is_from_rogue_mode else "返回地图"
		print("奖励场景: 更新按钮文本为", return_button.text)

# 设置是否来自Rogue模式
func set_from_rogue(value: bool):
	print("奖励场景: 设置from_rogue标记为", value)
	is_from_rogue_mode = value
	
	# 更新按钮文本
	update_return_button_text()

# 检查是否来自Rogue模式
func is_from_rogue() -> bool:
	print("奖励场景: 检查is_from_rogue_mode，当前值 =", is_from_rogue_mode)
	return is_from_rogue_mode

# 尝试从GameManager检测当前游戏模式
func _detect_game_mode():
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		# 尝试检测游戏模式
		if game_manager.has_method("is_rogue_mode") and game_manager.is_rogue_mode():
			print("奖励场景: 从GameManager检测到当前是Rogue模式")
			is_from_rogue_mode = true
		elif game_manager.has_method("get_current_game_mode"):
			var mode = game_manager.get_current_game_mode()
			print("奖励场景: 从GameManager获取到游戏模式:", mode)
			is_from_rogue_mode = (mode == "rogue" or mode == "ROGUE")
		elif game_manager.get("current_game_mode") != null:
			var mode = game_manager.current_game_mode
			print("奖励场景: 从GameManager变量获取到游戏模式:", mode)
			is_from_rogue_mode = (mode == "rogue" or mode == "ROGUE")

# 处理返回按钮点击
func _on_return_button_pressed():
	print("奖励场景: 返回按钮被点击，is_from_rogue_mode =", is_from_rogue_mode)
	
	# 保存奖励数据到玩家存档
	if not reward_data.is_empty():
		PlayerStats.add_rewards(reward_data)
	
	# 根据来源标志发出不同的信号
	if is_from_rogue_mode:
		print("奖励场景: 从Rogue模式进入，发送返回Rogue模式请求信号")
		# 查找GameManager节点
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager:
			print("奖励场景: 找到GameManager节点")
			
			# 检查GameManager的Rogue模式状态
			if game_manager.has_method("is_rogue_mode"):
				print("奖励场景: GameManager.is_rogue_mode() =", game_manager.is_rogue_mode())
			
			# 检查是否有保存的Rogue场景路径
			if game_manager.has_meta("last_rogue_scene"):
				print("奖励场景: GameManager有保存的Rogue场景路径:", game_manager.get_meta("last_rogue_scene"))
			else:
				print("奖励场景: GameManager没有保存的Rogue场景路径")
			
			# 1. 首先尝试找到RogueManager节点
			var rogue_manager = get_node_or_null("/root/RogueManager")
			if rogue_manager and rogue_manager.has_method("_on_reward_return_to_map"):
				print("奖励场景: 使用RogueManager进入商店")
				rogue_manager._on_reward_return_to_map()
				return
				
			# 尝试所有可能的方法名
			var methods_to_try = ["return_to_rogue_mode", "switch_to_rogue_mode", "continue_rogue_mode", "resume_rogue_mode"]
			var method_called = false
			
			for method in methods_to_try:
				if game_manager.has_method(method):
					print("奖励场景: 调用GameManager方法:", method)
					game_manager.call(method)
					method_called = true
					break
			
			if not method_called:
				push_error("奖励场景: GameManager没有返回Rogue模式的方法，尝试使用信号")
				# 尝试发送通用信号
				if game_manager.has_method("handle_rogue_continue"):
					game_manager.handle_rogue_continue()
				else:
					print("奖励场景: 回退到使用return_to_map_requested信号")
					emit_signal("return_to_map_requested")
		else:
			push_error("奖励场景: 无法找到GameManager")
			# 仍然发出信号，但在调试日志中标记问题
			emit_signal("return_to_map_requested")
	else:
		print("奖励场景: 从地图模式进入，发送返回地图请求信号")
		emit_signal("return_to_map_requested")

# 场景退出树时的清理
func _exit_tree():
	print("奖励场景: _exit_tree() 被调用，场景即将销毁")
	
	# 断开所有信号连接
	if return_button and return_button.is_connected("pressed", _on_return_button_pressed):
		return_button.disconnect("pressed", _on_return_button_pressed)
	
	print("奖励场景: 信号连接已断开，场景退出树")

# 设置奖励数据
func set_reward_data(data: Dictionary):
	print("奖励场景: 设置奖励数据", data)
	if data == null:
		print("奖励场景错误: 收到空奖励数据!")
		data = {"currency": 50}  # 使用默认值
	
	reward_data = data
	
	# 生成随机道具奖励（如果满足条件）
	if not reward_data.has("items"):
		reward_data.items = []
	
	# 根据金币奖励的多少，有几率添加额外奖励
	if reward_data.has("currency") and reward_data.currency >= 100:
		var chance = 0.5  # 50%几率
		if randf() < chance:
			_add_random_item_reward()
	
	# 检查是否来自Rogue模式（优先使用传入的参数）
	if data.has("from_rogue_mode"):
		print("奖励场景: 检测到来自Rogue模式标记，值为", data.from_rogue_mode)
		set_from_rogue(data.from_rogue_mode)
		# 明确打印设置后的状态
		print("奖励场景: 已设置is_from_rogue_mode =", is_from_rogue_mode)
	else:
		# 尝试从GameManager中检测
		_detect_game_mode()
		print("奖励场景: 从GameManager检测后的is_from_rogue_mode =", is_from_rogue_mode)
	
	# 如果已经准备好了界面，马上更新显示
	if is_inside_tree() and currency_value:
		update_ui()
		print("奖励场景: 立即更新了奖励显示")
	else:
		print("奖励场景: 界面尚未准备好，稍后更新显示")
		# 推迟到下一帧尝试更新
		call_deferred("_try_update_display")

# 尝试再次更新显示（当初始化时间不对时）
func _try_update_display():
	if is_inside_tree() and currency_value:
		update_ui()
	else:
		print("奖励场景: 界面仍未准备好，将在下一帧再试")
		# 再次延迟
		call_deferred("_try_update_display")

# 添加随机道具奖励
func _add_random_item_reward():
	var item_types = ["health_potion", "damage_boost", "shield", "gold_chest"]
	var selected_type = item_types[randi() % item_types.size()]
	
	var item = {
		"type": selected_type,
		"name": ""
	}
	
	match selected_type:
		"health_potion":
			var heal_amount = 10 + randi() % 20  # 10-29点恢复
			item.name = "生命药水"
			item.heal_amount = heal_amount
			item.effect_description = "恢复%d点生命值" % heal_amount
		
		"damage_boost":
			var boost_amount = 5 + randi() % 15  # 5-19%伤害提升
			item.name = "力量护符"
			item.boost_amount = boost_amount
			item.effect_description = "伤害提升%d%%" % boost_amount
		
		"shield":
			var shield_amount = 15 + randi() % 25  # 15-39点护盾
			item.name = "防御护盾"
			item.shield_amount = shield_amount
			item.effect_description = "获得%d点护盾" % shield_amount
		
		"gold_chest":
			var gold_amount = 20 + randi() % 40  # 20-59金币
			item.name = "金币宝箱"
			item.gold_amount = gold_amount
			item.effect_description = "获得%d金币" % gold_amount
	
	reward_data.items.append(item)
	print("奖励场景: 添加了随机道具奖励:", item.name)
