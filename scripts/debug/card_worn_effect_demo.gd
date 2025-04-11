extends Node2D

# 卡牌老旧效果演示脚本
# 此脚本用于展示不同程度的卡牌老旧效果

@export var card_scene: PackedScene # 卡牌场景
@export var cards_per_row: int = 4 # 每行卡牌数量
@export var card_spacing: Vector2 = Vector2(220, 300) # 卡牌间距增大，防止重叠

# 预加载效果脚本，确保路径正确
var _worn_effect_script = preload("res://scripts/effects/card_worn_effect.gd")
var _worn_helper_script = preload("res://scripts/debug/card_worn_effect_helper.gd")
var _cards = [] # 存储创建的卡牌节点

# 调试标志
var debug_mode: bool = true

func _ready():
	# 输出调试信息
	if debug_mode:
		print("卡牌老旧效果演示初始化...")
	
	# 如果没有指定卡牌场景，尝试加载默认的
	if not card_scene:
		card_scene = load("res://scenes/card/card.tscn")
		if not card_scene:
			push_error("无法加载卡牌场景！")
			return
	
	# 检查_worn_effect_script是否正确加载
	if not _worn_effect_script:
		push_error("无法加载卡牌老旧效果脚本！")
		if debug_mode:
			print("尝试加载的路径: res://scripts/effects/card_worn_effect.gd")
		return
		
	# 检查_worn_helper_script是否正确加载
	if not _worn_helper_script:
		push_error("无法加载卡牌老旧效果辅助脚本！")
		if debug_mode:
			print("尝试加载的路径: res://scripts/debug/card_worn_effect_helper.gd")
		return
	
	# 创建卡牌网格
	create_card_grid()
	
	# 添加UI控件
	create_ui_controls()

# 创建卡牌网格
func create_card_grid():
	# 定义不同的卡牌类型和磨损级别
	var card_types = [
		{"name": "无磨损", "preset": _worn_effect_script.WornPreset.NONE},
		{"name": "轻度磨损", "preset": _worn_effect_script.WornPreset.LIGHT},
		{"name": "中度磨损", "preset": _worn_effect_script.WornPreset.MEDIUM},
		{"name": "重度磨损", "preset": _worn_effect_script.WornPreset.HEAVY},
		{"name": "随机 (低)", "preset": _worn_effect_script.WornPreset.MEDIUM, "random": [0.1, 0.3]},
		{"name": "随机 (中)", "preset": _worn_effect_script.WornPreset.MEDIUM, "random": [0.3, 0.6]},
		{"name": "随机 (高)", "preset": _worn_effect_script.WornPreset.MEDIUM, "random": [0.6, 0.9]},
		{"name": "自定义", "preset": _worn_effect_script.WornPreset.MEDIUM, "custom": true}
	]
	
	# 创建卡牌网格
	for i in range(card_types.size()):
		var card_data = card_types[i]
		var row = i / cards_per_row
		var col = i % cards_per_row
		
		# 创建卡牌实例
		var card = card_scene.instantiate()
		add_child(card)
		
		# 设置卡牌数据（如果支持）
		if card.has_method("set_card_data"):
			var mock_data = {
				"nice_name": card_data.name,
				"value": "A",
				"suit": "♠",
				"name": card_data.name
			}
			card.set_card_data(mock_data)
		
		# 计算并设置卡牌位置
		var pos = Vector2(col * card_spacing.x, row * card_spacing.y) + Vector2(200, 150)
		card.position = pos
		
		# 输出调试信息
		if debug_mode:
			print("创建卡牌 %d 在位置 (%d, %d)" % [i, pos.x, pos.y])
		
		# 检查卡牌是否有原点(pivot)属性，如果有则居中
		if card.has_method("set_pivot_offset"):
			var size = card.size if card.has_method("get_size") else Vector2(100, 150)
			card.set_pivot_offset(size / 2)
		
		# 添加卡牌老旧效果组件
		var worn_effect = _worn_effect_script.new()
		worn_effect.name = "WornEffect"
		card.add_child(worn_effect)
		
		# 添加辅助脚本，确保效果正确应用
		var helper = _worn_helper_script.new()
		helper.name = "WornEffectHelper"
		card.add_child(helper)
		
		# 设置磨损级别
		worn_effect.preset = card_data.preset
		
		# 如果需要随机参数
		if card_data.has("random"):
			worn_effect.randomize_worn_parameters(card_data.random[0], card_data.random[1])
		
		# 添加标签
		var label = Label.new()
		label.text = card_data.name
		label.position = Vector2(-50, -120)
		label.add_theme_color_override("font_color", Color(1, 1, 1))
		label.add_theme_font_size_override("font_size", 16)
		card.add_child(label)
		
		# 保存到卡牌数组中
		_cards.append({"node": card, "worn_effect": worn_effect, "custom": card_data.get("custom", false)})

# 创建UI控件
func create_ui_controls():
	# 只为自定义卡牌创建控件
	var custom_card = null
	for card in _cards:
		if card.custom:
			custom_card = card
			break
	
	if not custom_card:
		return
	
	# 创建UI容器
	var ui_container = Control.new()
	ui_container.position = Vector2(820, 100)  # 移到右侧，避免与卡牌重叠
	add_child(ui_container)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(0, 0)
	ui_container.add_child(vbox)
	
	# 添加标题
	var title = Label.new()
	title.text = "自定义磨损参数"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	# 添加每个参数的滑块
	add_parameter_slider(vbox, custom_card.worn_effect, "worn_amount", "磨损程度")
	add_parameter_slider(vbox, custom_card.worn_effect, "edge_worn", "边缘磨损")
	add_parameter_slider(vbox, custom_card.worn_effect, "stain_amount", "污渍程度")
	add_parameter_slider(vbox, custom_card.worn_effect, "dust_amount", "灰尘程度")
	add_parameter_slider(vbox, custom_card.worn_effect, "crease_amount", "折痕程度")
	add_parameter_slider(vbox, custom_card.worn_effect, "color_fade", "颜色褪色")
	add_parameter_slider(vbox, custom_card.worn_effect, "yellowing", "泛黄程度")
	add_parameter_slider(vbox, custom_card.worn_effect, "edge_darkness", "边缘暗度")
	add_parameter_slider(vbox, custom_card.worn_effect, "randomness", "随机程度")
	
	# 添加一个随机化按钮
	var randomize_button = Button.new()
	randomize_button.text = "随机化参数"
	randomize_button.pressed.connect(func(): 
		custom_card.worn_effect.randomize_worn_parameters()
		# 确保应用效果
		if custom_card.worn_effect.has_method("apply_effect"):
			custom_card.worn_effect.apply_effect()
		elif custom_card.worn_effect.has_method("update_shader_parameters"):
			custom_card.worn_effect.update_shader_parameters()
	)
	vbox.add_child(randomize_button)

# 添加参数滑块
func add_parameter_slider(parent, worn_effect, param_name, label_text):
	var hbox = HBoxContainer.new()
	parent.add_child(hbox)
	
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 100
	hbox.add_child(label)
	
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	
	# 使用安全的方式获取初始值
	var initial_value = 0.5  # 默认值
	if worn_effect.has_method("get_" + param_name):
		initial_value = worn_effect.call("get_" + param_name)
	elif param_name in worn_effect:
		initial_value = worn_effect[param_name]
	
	slider.value = initial_value
	slider.custom_minimum_size.x = 200
	hbox.add_child(slider)
	
	var value_label = Label.new()
	value_label.text = str(snappedf(initial_value, 0.01))
	value_label.custom_minimum_size.x = 50
	hbox.add_child(value_label)
	
	# 连接滑块的值变化信号，使用更安全的方式更新属性
	slider.value_changed.connect(func(value):
		# 尝试使用setter方法
		if worn_effect.has_method("set_" + param_name):
			worn_effect.call("set_" + param_name, value)
		# 尝试使用直接属性访问
		elif param_name in worn_effect:
			worn_effect[param_name] = value
		
		# 确保更新着色器参数
		if worn_effect.has_method("apply_effect"):
			worn_effect.apply_effect()
		elif worn_effect.has_method("update_shader_parameters"):
			worn_effect.update_shader_parameters()
		
		value_label.text = str(snappedf(value, 0.01))
		
		if debug_mode:
			print("更新参数 %s = %f" % [param_name, value]))
