extends Control

# 引用UI元素
@onready var level_name_label = $LevelInfoPanel/LevelName
@onready var level_description_label = $LevelInfoPanel/LevelDescription
@onready var debuff_name_label = $DebuffPanel/DebuffName
@onready var debuff_description_label = $DebuffPanel/DebuffDescription
@onready var enemies_container = $EnemiesContainer
@onready var start_button = $StartButton
@onready var return_button = $ReturnButton
@onready var background = $Background
@onready var title_label = $TitleLabel

# 预加载场景
var enemy_item_scene = preload("res://scenes/rogue/rogue_enemy_item.tscn")

# 变量
var level_data = null
var selected_enemies = []
var current_enemy_index = 0
var from_shop = false
var if_level_completed = false
var game_manager = null

# 信号
signal start_battle(enemy_data)
signal return_requested
signal level_completed(level_id)

func _ready():
	# 获取GameManager引用
	game_manager = get_node_or_null("/root/GameManager")
	if !game_manager:
		push_error("RogueLevelScene: 无法获取GameManager引用")
	
	# 连接按钮信号
	start_button.pressed.connect(_on_start_button_pressed)
	return_button.pressed.connect(_on_return_button_pressed)
	
	# 初始状态下禁用开始按钮
	start_button.disabled = true
	
	print("RogueLevelScene: 初始化完成")

# 初始化关卡场景
func initialize(data, from_shop_param = false, is_completed = false):
	if !data:
		push_error("RogueLevelScene: 初始化时收到空数据")
		return
		
	print("RogueLevelScene: 开始初始化关卡场景，关卡:", data.level_name if data.has("level_name") else "未命名关卡")
	print("RogueLevelScene: 从商店返回:", from_shop_param, ", 关卡已完成:", is_completed)
	print("RogueLevelScene: 当前敌人列表大小:", selected_enemies.size(), ", 当前敌人索引:", current_enemy_index)
		
	level_data = data
	from_shop = from_shop_param
	if_level_completed = is_completed
	
	# 设置关卡信息
	_update_level_info()
	
	# 设置全局debuff信息
	_update_debuff_info()
	
	# 如果是从商店返回且已有敌人列表，则保留现有敌人列表
	if from_shop_param and selected_enemies.size() > 0:
		print("RogueLevelScene: 从商店返回，保留现有敌人列表")
		print("RogueLevelScene: 保留的敌人列表:")
		for i in range(selected_enemies.size()):
			var enemy = selected_enemies[i]
			var is_boss = enemy.has("is_boss") and enemy.is_boss
			var is_current = i == current_enemy_index
			print("  敌人[", i, "]: ", enemy.name, ", 是BOSS:", is_boss, ", 是当前:", is_current)
		
		# 重新创建UI项目但不改变敌人数据
		_recreate_enemy_items()
	else:
		# 清空当前敌人列表
		selected_enemies = []
		current_enemy_index = 0
		# 生成新的敌人列表
		_generate_enemies_list()
		print("RogueLevelScene: 生成新的敌人列表，数量:", selected_enemies.size())
	
	# 设置背景
	_set_background()
	
	# 更新UI状态
	_update_ui_state()
	
	print("RogueLevelScene: 关卡场景初始化完成，当前敌人索引:", current_enemy_index, "/", selected_enemies.size())

# 设置关卡信息
func _update_level_info():
	if level_data:
		level_name_label.text = level_data.level_name
		level_description_label.text = level_data.level_description
	else:
		level_name_label.text = "未知关卡"
		level_description_label.text = "无可用描述"

# 设置debuff信息
func _update_debuff_info():
	if level_data and level_data.has("global_debuff"):
		var debuff = level_data.global_debuff
		debuff_name_label.text = debuff.name
		debuff_description_label.text = debuff.description
	else:
		debuff_name_label.text = "无全局效果"
		debuff_description_label.text = "这个关卡没有全局debuff效果"

# 设置背景
func _set_background():
	if level_data and level_data.has("background_image") and level_data.background_image != "":
		var background_texture = load(level_data.background_image)
		if background_texture:
			background.texture = background_texture

# 根据关卡数据生成敌人列表
func _generate_enemies_list():
	# 先清空容器中的现有敌人
	for child in enemies_container.get_children():
		child.queue_free()
	
	# 如果没有关卡数据或已完成关卡，不生成敌人
	if not level_data or if_level_completed:
		return
	
	# 从JSON加载所有敌人数据
	var all_enemies = _load_enemies_data()
	if all_enemies.size() == 0:
		print("无法加载敌人数据")
		return
	
	# 获取关卡敌人池和BOSS池
	var enemy_pool = level_data.enemy_pool if level_data.has("enemy_pool") else []
	var boss_pool = level_data.boss_pool if level_data.has("boss_pool") else []
	var enemies_count = level_data.enemies_count if level_data.has("enemies_count") else 3
	
	# 确保enemies_count至少为1
	enemies_count = max(1, enemies_count)
	print("RogueLevelScene: 关卡敌人数量设置为:", enemies_count)
	
	# 随机选择敌人和BOSS
	selected_enemies = _select_random_enemies(all_enemies, enemy_pool, boss_pool, enemies_count)
	print("RogueLevelScene: 实际生成敌人数量:", selected_enemies.size())
	
	# 创建敌人项目
	for enemy_data in selected_enemies:
		var enemy_item = enemy_item_scene.instantiate()
		enemies_container.add_child(enemy_item)
		enemy_item.setup(enemy_data)
		print("RogueLevelScene: 创建敌人项目:", enemy_data.name if enemy_data.has("name") else "未命名敌人")
	
	# 如果有敌人，启用开始按钮
	if selected_enemies.size() > 0:
		start_button.disabled = false

# 从JSON加载敌人数据
func _load_enemies_data():
	var enemies_data = []
	var file = FileAccess.open("res://data/enemies.json", FileAccess.READ)
	if not file:
		print("无法打开敌人数据文件")
		return enemies_data
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error == OK:
		enemies_data = json.data
	else:
		print("解析敌人JSON数据失败: ", json.get_error_message())
	
	return enemies_data

# 随机选择敌人和BOSS
func _select_random_enemies(all_enemies, enemy_pool, boss_pool, count):
	var result = []
	var available_enemies = []
	var available_bosses = []
	
	print("RogueLevelScene: 开始选择敌人，总需求数量:", count)
	print("RogueLevelScene: 敌人池大小:", enemy_pool.size(), ", BOSS池大小:", boss_pool.size())
	
	# 筛选可用的普通敌人和BOSS
	for enemy in all_enemies:
		var enemy_id = enemy.id if enemy.has("id") else ""
		
		if enemy_id in enemy_pool:
			# 深度复制敌人数据，确保不会相互干扰
			var enemy_copy = enemy.duplicate(true)
			# 确保普通敌人不会被标记为BOSS
			if enemy_copy.has("is_boss"):
				enemy_copy.is_boss = false
			available_enemies.append(enemy_copy)
		elif enemy_id in boss_pool:
			# 深度复制BOSS数据
			var boss_copy = enemy.duplicate(true)
			# 确保BOSS始终被标记
			boss_copy.is_boss = true
			available_bosses.append(boss_copy)
	
	print("RogueLevelScene: 可用普通敌人:", available_enemies.size(), ", 可用BOSS:", available_bosses.size())
	
	# 选择一个BOSS
	var boss = null
	if available_bosses.size() > 0:
		# 随机选择一个BOSS
		randomize()
		available_bosses.sort_custom(func(a, b): return randf() > 0.5)
		boss = available_bosses[0]
		print("RogueLevelScene: 选择BOSS:", boss.name if boss.has("name") else "未命名BOSS")
	else:
		push_error("RogueLevelScene: 没有可用的BOSS敌人!")
		
	# 计算要选择的普通敌人数量（总数减去BOSS的1个）
	var enemies_to_select = min(count - 1, available_enemies.size())
	print("RogueLevelScene: 将选择普通敌人数量:", enemies_to_select)
	
	# 使用随机数代替shuffle
	randomize()
	available_enemies.sort_custom(func(a, b): return randf() > 0.5)
	
	# 添加普通敌人
	for i in range(enemies_to_select):
		if i < available_enemies.size():
			result.append(available_enemies[i])
			print("RogueLevelScene: 选择普通敌人:", available_enemies[i].name if available_enemies[i].has("name") else "未命名敌人")
	
	# 最后添加BOSS
	if boss:
		result.append(boss)
		print("RogueLevelScene: 添加BOSS作为最后一个敌人")
	
	# 打印最终敌人列表信息
	print("RogueLevelScene: 最终选择敌人数量:", result.size())
	for i in range(result.size()):
		var enemy = result[i]
		var is_boss = enemy.has("is_boss") and enemy.is_boss
		print("RogueLevelScene: 敌人[", i, "]: ", enemy.name, ", 是BOSS:", is_boss)
	
	return result

# 更新UI状态
func _update_ui_state():
	# 设置关卡状态文本
	if if_level_completed:
		title_label.text = "关卡已完成"
		start_button.text = "进入下一关卡"
		start_button.disabled = false
	else:
		title_label.text = "无火的牌局 - 随机模式"
		start_button.text = "开始挑战"
		# 只有在有敌人存在时才启用开始按钮
		start_button.disabled = selected_enemies.size() == 0
	
	# 设置返回按钮可见性
	return_button.visible = (from_shop or if_level_completed)
	
	print("RogueLevelScene: UI状态已更新，关卡完成状态:", if_level_completed)

# 开始按钮点击处理
func _on_start_button_pressed():
	print("RogueLevelScene: 开始按钮被点击，关卡完成状态:", if_level_completed)
	
	if if_level_completed:
		# 如果关卡已完成，发出完成信号
		print("RogueLevelScene: 关卡完成，发送完成信号:", level_data.level_id if level_data and level_data.has("level_id") else "未知关卡ID")
		emit_signal("level_completed", level_data.level_id if level_data and level_data.has("level_id") else "")
	else:
		# 如果还有敌人要挑战
		if current_enemy_index < selected_enemies.size():
			var enemy_data = selected_enemies[current_enemy_index]
			print("RogueLevelScene: 开始挑战敌人:", enemy_data.name if enemy_data.has("name") else "未命名敌人", ", 索引:", current_enemy_index)
			emit_signal("start_battle", enemy_data)
		else:
			# 所有敌人都已挑战完毕
			print("RogueLevelScene: 所有敌人已挑战完毕，标记关卡完成")
			if_level_completed = true
			_update_ui_state()

# 返回按钮点击处理
func _on_return_button_pressed():
	emit_signal("return_requested")

# 获取当前敌人
func get_current_enemy():
	if current_enemy_index < selected_enemies.size():
		return selected_enemies[current_enemy_index]
	return null

# 更新关卡完成状态
func update_completion_status(completed):
	print("RogueLevelScene: 更新关卡完成状态为:", completed)
	if_level_completed = completed
	_update_ui_state()
	
	if completed:
		# 所有敌人都已挑战完毕，更新UI显示
		title_label.text = "关卡已完成"
		start_button.disabled = false
		start_button.text = "进入下一关卡"
		return_button.visible = true

# 获取关卡数据
func get_level_data():
	return level_data 

# 重新创建敌人项目UI，不改变敌人数据
func _recreate_enemy_items():
	# 先清空容器中的现有敌人项目
	for child in enemies_container.get_children():
		child.queue_free()
	
	# 如果没有关卡数据或已完成关卡，不创建敌人项目
	if not level_data or if_level_completed:
		return
	
	print("RogueLevelScene: 重新创建敌人项目UI，敌人数量:", selected_enemies.size())
	
	# 创建敌人项目
	for enemy_data in selected_enemies:
		var enemy_item = enemy_item_scene.instantiate()
		enemies_container.add_child(enemy_item)
		enemy_item.setup(enemy_data)
		print("RogueLevelScene: 重新创建敌人项目:", enemy_data.name if enemy_data.has("name") else "未命名敌人")
		
	# 如果有敌人，启用开始按钮
	if selected_enemies.size() > 0:
		start_button.disabled = false
