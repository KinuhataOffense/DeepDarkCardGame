extends Control

# 引用到UI元素
@onready var enemy_container = $EnemyContainer
@onready var enemy_details_panel = $EnemyDetailsPanel
@onready var enemy_name_label = $EnemyDetailsPanel/EnemyName
@onready var enemy_description_label = $EnemyDetailsPanel/EnemyDescription
@onready var difficulty_label = $EnemyDetailsPanel/DifficultyLabel
@onready var start_button = $StartButton
@onready var return_button = $ReturnButton

# 变量
var enemy_card_scene = preload("res://scenes/enemy_select/enemy_card.tscn")
var enemies_data = []
var selected_enemy = null
var from_shop = false  # 标记是否从商店进入
var auto_mode = true  # 标记是否为自动模式（从地图进入）
var auto_selected_enemy = null  # 从地图传入的敌人数据
var display_timer = null  # 用于自动模式的定时器
var signal_emitted = false  # 防止信号重复发送

# 信号
signal enemy_selected(enemy_data)
signal return_requested

func _ready():
	print("敌人选择场景初始化，自动模式：", auto_mode)
	
	# 连接按钮信号
	start_button.pressed.connect(_on_start_button_pressed)
	return_button.pressed.connect(_on_return_button_pressed)
	
	# 加载敌人数据
	_load_enemy_data()
	
	# 创建敌人卡片
	_create_enemy_cards()
	
	# 默认禁用开始按钮
	start_button.disabled = false
	
	# 根据来源显示或隐藏返回按钮
	return_button.visible = from_shop

	# 如果是自动模式，直接进入自动选择流程
	if auto_mode and auto_selected_enemy != null:
		print("启动自动模式流程")
		call_deferred("_setup_auto_mode")

# 设置自动模式，显示敌人信息并在延迟后进入战斗
func _setup_auto_mode():
	print("自动模式：显示敌人信息 - ", auto_selected_enemy.name if auto_selected_enemy.has("name") else "未知敌人")
	
	# 确保在处理前信号未发送
	signal_emitted = false
	
	# 先确保敌人信息可用于显示
	if auto_selected_enemy != null:
		# 更新详细信息面板
		_display_enemy_info(auto_selected_enemy)
		
		# 显示敌人详情面板，确保其可见
		enemy_details_panel.visible = true
		
		# 隐藏敌人卡片容器
		enemy_container.visible = false
		
		# 在自动模式下仍显示开始按钮，但禁用返回按钮
		start_button.visible = true
		start_button.disabled = false
		return_button.visible = false
		
		# 清理可能已存在的定时器
		if display_timer:
			display_timer.stop()
			if display_timer.is_connected("timeout", _auto_start_battle):
				display_timer.timeout.disconnect(_auto_start_battle)
			display_timer.queue_free()
			display_timer = null
		
		# 创建并启动新的定时器
		display_timer = Timer.new()
		add_child(display_timer)
		display_timer.wait_time = 3.0  # 3秒后自动进入战斗
		display_timer.one_shot = true
		display_timer.timeout.connect(_auto_start_battle)
		display_timer.start()
		
		print("启动定时器，3秒后自动进入战斗")
	else:
		print("错误：自动模式下没有敌人数据")

# 自动开始战斗
func _auto_start_battle():
	print("定时器触发，准备自动进入战斗")
	
	# 避免重复发送信号
	if signal_emitted:
		print("信号已发送，跳过")
		return
		
	if auto_selected_enemy:
		print("发送敌人选择信号: ", auto_selected_enemy.name)
		signal_emitted = true
		emit_signal("enemy_selected", auto_selected_enemy)
		
		# 添加延迟确保信号已被处理
		await get_tree().create_timer(0.5).timeout
		
		# 检查是否被处理，如果没有被处理（例如：信号未被连接），尝试直接切换到战斗场景
		if is_instance_valid(self) and self.is_inside_tree():
			print("信号可能未被处理，尝试直接切换场景")
			_try_fallback_to_battle()
	else:
		print("错误：没有选择敌人数据")

# 尝试直接切换到战斗场景的备用方案
func _try_fallback_to_battle():
	if auto_selected_enemy:
		print("执行备用方案：直接切换到战斗场景")
		
		# 加载战斗场景
		var battle_scene = load("res://scenes/game_scene.tscn")
		if battle_scene:
			# 创建并添加战斗场景
			var battle_instance = battle_scene.instantiate()
			battle_instance.name = "GameScene"
			get_tree().root.add_child(battle_instance)
			
			# 确保UI更新
			await get_tree().process_frame
			
			# 设置敌人数据
			var game_manager = battle_instance.get_node_or_null("GameManager")
			if game_manager:
				print("设置敌人数据: ", auto_selected_enemy.name)
				game_manager.set_enemy_data(auto_selected_enemy)
				
				# 移除自身
				queue_free()
			else:
				push_error("无法获取GameManager节点")
		else:
			push_error("无法加载战斗场景")

func _process(delta):
	# 在自动模式下，检查定时器状态并输出调试信息
	if auto_mode and display_timer and display_timer.time_left > 0:
		# 每秒打印一次剩余时间（四舍五入到整数）
		if int(display_timer.time_left) != int(display_timer.time_left + delta):
			print("倒计时: ", int(display_timer.time_left), "秒")

# 显示敌人信息
func _display_enemy_info(enemy_data):
	selected_enemy = enemy_data
	
	# 打印选择信息
	print("显示敌人详情: ", enemy_data.id if enemy_data.has("id") else "未知ID", " - ", enemy_data.name if enemy_data.has("name") else "未知敌人")
	
	# 更新详细信息面板
	enemy_name_label.text = enemy_data.name if enemy_data.has("name") else "未知敌人"
	
	# 处理可能缺少的description字段
	if enemy_data.has("description"):
		enemy_description_label.text = enemy_data.description
	else:
		enemy_description_label.text = "无可用描述"
	
	# 设置难度显示
	var difficulty_text = "难度: "
	if enemy_data.has("difficulty"):
		for i in range(enemy_data.difficulty):
			difficulty_text += "★"
		for i in range(4 - enemy_data.difficulty):
			difficulty_text += "☆"
	else:
		difficulty_text += "★☆☆☆" # 默认难度
	difficulty_label.text = difficulty_text
	
	# 启用开始按钮
	start_button.disabled = false

# 从JSON加载敌人数据
func _load_enemy_data():
	var file = FileAccess.open("res://data/enemies.json", FileAccess.READ)
	if not file:
		print("无法打开敌人数据文件")
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error == OK:
		enemies_data = json.data
	else:
		print("解析敌人JSON数据失败: ", json.get_error_message())

# 创建敌人选择卡片
func _create_enemy_cards():
	# 清空现有卡片
	for child in enemy_container.get_children():
		child.queue_free()
	
	# 为每个敌人创建卡片
	for enemy in enemies_data:
		var card = enemy_card_scene.instantiate()
		enemy_container.add_child(card)
		card.setup(enemy)
		# 直接连接卡片的信号，它会传递enemy_data
		card.enemy_card_clicked.connect(_on_enemy_card_clicked)

# 初始化场景，设置是否来自商店或自动模式
func initialize(shop_mode: bool = false, auto: bool = false, enemy_data = null):
	print("初始化敌人选择场景: 商店模式=", shop_mode, ", 自动模式=", auto, ", 敌人数据=", "有" if enemy_data else "无")
	
	from_shop = shop_mode
	auto_mode = auto
	auto_selected_enemy = enemy_data
	signal_emitted = false
	
	# 在下一帧更新UI
	call_deferred("_update_ui")

# 更新UI根据场景状态
func _update_ui():
	# 设置返回按钮可见性
	return_button.visible = from_shop
	
	# 更新标题
	$TitleLabel.text = "选择下一个对手" if from_shop else "遭遇敌人"
	
	# 如果是自动模式，隐藏敌人卡片容器
	if auto_mode:
		enemy_container.visible = false

# 当玩家点击敌人卡片
func _on_enemy_card_clicked(enemy_data):
	_display_enemy_info(enemy_data)

# 按下开始按钮
func _on_start_button_pressed():
	if selected_enemy:
		# 避免重复发送信号
		if signal_emitted:
			return
			
		signal_emitted = true
		print("手动开始按钮按下，发送敌人信号: ", selected_enemy.name)
		emit_signal("enemy_selected", selected_enemy)

# 按下返回按钮
func _on_return_button_pressed():
	emit_signal("return_requested")

# 当场景被移除前清理资源
func _exit_tree():
	print("敌人选择场景退出")
	
	# 清理定时器
	if display_timer:
		display_timer.stop()
		if display_timer.is_connected("timeout", _auto_start_battle):
			display_timer.timeout.disconnect(_auto_start_battle)
		display_timer = null 
