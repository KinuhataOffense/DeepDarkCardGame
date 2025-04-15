# gamemanager.gd  

extends Node  

#------------------------------------------------------------------------------  
# 预加载场景资源  
#------------------------------------------------------------------------------  
var battle_scene = preload("res://scenes/battle/battle_scene.tscn")  
var shop_scene = preload("res://scenes/shop/shop_scene.tscn")  
var enemy_select_scene = preload("res://scenes/enemy_select/enemy_select_scene.tscn")  
var node_map_scene = preload("res://scenes/map/node_map_scene.tscn")  
var reward_scene = preload("res://scenes/reward/reward_scene.tscn")  

#------------------------------------------------------------------------------  
# 引用节点和变量声明  
#------------------------------------------------------------------------------  
# 引用到核心节点  
@onready var player_stats = $"../PlayerStats"  

# 游戏状态枚举  
enum GameState { Menu, MAP, BATTLE, SHOP, GAME_OVER }  
var current_state: GameState = GameState.Menu  
var current_enemy = null  
var current_round: int = 1  
var turns_remaining: int = 3  
var score_required: int = 0  

# 玩家数据和系统变量  
var score_multiplier: float = 1.0  
var player_data = {  
	"max_health": 100,  
	"current_health": 100,  
	"currency": 100,
	"shield": 0,
	"damage_multiplier": 1.0
}  

# 地图和商店系统相关变量  
var current_map_state = null  
var current_floor_level = 1  
var current_map_node = null  
var current_shop_items: Array = []  

# 场景追踪  
var active_scenes = {}  
var current_main_scene = ""  

#------------------------------------------------------------------------------  
# 信号声明  
#------------------------------------------------------------------------------  
signal enemy_defeated  
signal game_over(win)  
signal enter_shop_requested  
signal return_to_game_requested
signal player_stats_changed(player_data)  

#------------------------------------------------------------------------------  
# 游戏模式枚举
enum GameMode {
	MAP,    # 地图模式
	ROGUE   # Rogue模式
}

# 当前游戏模式
var current_game_mode = GameMode.MAP

#------------------------------------------------------------------------------  
# 初始化函数  
#------------------------------------------------------------------------------  
var initialized = false

func _ready():
	if not initialized:
		initialized = true
		print("GameManager: 初始化完成")
	
	
		# 连接主菜单按钮信号（如果存在）  
		var main_menu = get_tree().root.get_node_or_null("MainMenu")
		if main_menu:  
			var start_button = main_menu.get_node_or_null("StartButton")  
			var quit_button = main_menu.get_node_or_null("QuitButton")  
			
			if start_button and quit_button:  
				# 默认模式为地图模式  
				start_button.pressed.connect(_on_start_map_mode)  
				quit_button.pressed.connect(_on_quit_game)  
					
				start_button.text = "开始地下城探险"  
				quit_button.text = "离开地下城探险"
		else:
			print("GameManager: 无法找到MainMenu节点")

#------------------------------------------------------------------------------  
# 游戏核心功能  
#------------------------------------------------------------------------------  
# 随机事件触发  
func trigger_random_event():  
	var random_value = randf()  
	if random_value < 0.25:  
		# 正面事件  
		if player_stats:  
			player_stats.heal(10)  
		player_data.current_health = min(player_data.max_health, player_data.current_health + 10)  
	elif random_value < 0.5:  
		# 中性事件  
		if player_stats:  
			player_stats.take_damage(5)  
		player_data.current_health = max(0, player_data.current_health - 5)  

# 降低得分倍率（用于敌人效果）  
func reduce_score_multiplier(factor: float):  
	score_multiplier *= factor  

#------------------------------------------------------------------------------  
# 场景管理系统 - 统一处理场景切换  
#------------------------------------------------------------------------------  
# 切换到新的主场景  
func switch_to_scene(scene_resource):  
	print("GameManager: 开始切换场景...")
	
	# 获取root节点
	var root = get_tree().root
	if not root:
		push_error("GameManager: 无法获取root节点")
		return false
	
	# 保存GameManager和PlayerStats节点的引用
	var game_manager_node = self
	var player_stats_node = player_stats
	
	# 首先保存地图状态（如果是从地图场景切换走）
	var map_node = root.get_node_or_null("NodeMapScene")
	if map_node and map_node.has_method("get_map_state"):
		var map_state = map_node.get_map_state()
		save_map_state(map_state)
		print("GameManager: 地图状态已保存")
	
	# 创建待移除场景列表，这样我们可以跟踪并处理所有非自动加载的场景
	var scenes_to_remove = []
	
	# 遍历所有子节点寻找现有场景
	for i in range(root.get_child_count()):
		var child = root.get_child(i)
		if child.name != "GameManager" and child.name != "PlayerStats" and child.name != "VisualEffectsManager" and not child.name.begins_with("_"):
			# 这是需要移除的场景
			scenes_to_remove.append(child)
			print("GameManager: 将移除场景:", child.name)
	
	# 逐个移除场景
	for scene in scenes_to_remove:
		# 从活动场景跟踪列表中移除
		if active_scenes.has(scene.name):
			active_scenes.erase(scene.name)
			print("GameManager: 从活动场景列表中移除:", scene.name)
		
		# 从场景树中移除
		root.remove_child(scene)
		scene.queue_free()
		print("GameManager: 场景已移除并释放:", scene.name)
	
	# 创建新场景前等待一帧
	if scenes_to_remove.size() > 0:
		await get_tree().process_frame
	
	# 实例化新场景
	var new_scene = scene_resource.instantiate()
	if not new_scene:
		push_error("GameManager: 场景实例化失败")
		return false
	
	# 设置场景名称为其资源名（如果没有其他名称）
	if new_scene.name.contains("@"):
		var scene_path = scene_resource.resource_path
		var scene_name = scene_path.get_file().get_basename()
		new_scene.name = scene_name
		print("GameManager: 设置场景实例名称为:", scene_name)
	
	# 将新场景添加到root节点
	root.add_child(new_scene)
	
	# 调整新场景的位置 - 确保场景位于正确位置
	_adjust_scene_position(new_scene)
	
	print("GameManager: 添加新场景:", new_scene.name)
	
	# 更新当前场景引用  
	current_main_scene = new_scene.name  
	active_scenes[current_main_scene] = new_scene  
	
	# 等待一帧确保场景已加载
	await get_tree().process_frame
	
	# 如果是战斗场景，连接BattleManager
	if new_scene.name == "BattleScene":
		# 确保先清除之前的元数据标志
		if has_meta("enemy_defeated_emitted"):
			remove_meta("enemy_defeated_emitted")
			
		# 尝试连接战斗管理器信号
		var battle_manager = new_scene.get_node_or_null("BattleManager")
		if battle_manager:
			# 先断开之前的连接（如果有）
			if battle_manager.is_connected("enemy_defeated", _on_battle_enemy_defeated):
				battle_manager.disconnect("enemy_defeated", _on_battle_enemy_defeated)
				
			# 重新连接信号
			battle_manager.connect("enemy_defeated", _on_battle_enemy_defeated)
			print("GameManager: 已连接战斗场景的BattleManager信号")
		else:
			print("GameManager: 警告 - 无法在战斗场景中找到BattleManager节点")
	
	print("GameManager: 成功切换到场景：", current_main_scene)  
	return true

# 调整场景位置函数 - 根据Godot 4.4的Canvas变换特性
func _adjust_scene_position(scene_node):
	print("GameManager: 开始调整场景位置")
	
	# 对于所有类型的画布项，先重置变换
	if scene_node is CanvasItem:
		# 重置变换
		scene_node.position = Vector2.ZERO
		
		# 如果是Control节点，确保锚点设置正确
		if scene_node is Control:
			# 获取视口大小
			var viewport_size = get_tree().root.get_viewport().size
			print("GameManager: 视口大小:", viewport_size)
			
			# 设置合适的布局模式
			if scene_node.anchors_preset != 15: # 15 = 填满整个父节点
				scene_node.anchors_preset = 15 # 设置锚点预设为"全屏"
				scene_node.anchor_left = 0
				scene_node.anchor_top = 0
				scene_node.anchor_right = 1
				scene_node.anchor_bottom = 1
				scene_node.offset_left = 0
				scene_node.offset_top = 0
				scene_node.offset_right = 0
				scene_node.offset_bottom = 0
				scene_node.grow_horizontal = 2 # 双向水平增长
				scene_node.grow_vertical = 2   # 双向垂直增长
				print("GameManager: 设置Control锚点预设为全屏")
			
	# 如果是Node2D类型，检查它的子节点
	if scene_node is Node2D:
		# 获取视口大小的一半，这将作为场景居中的参考点
		var viewport_size = get_tree().root.get_viewport().size
		var center = viewport_size / 2
		
		# 检查MapContainer类型的节点并设置居中
		var map_container = scene_node.get_node_or_null("MapContainer")
		if map_container and map_container is Control:
			map_container.position = Vector2.ZERO
			map_container.size = viewport_size
			map_container.pivot_offset = center
			print("GameManager: 调整MapContainer位置到中心")
			
	# 对特殊场景做额外处理
	if scene_node.name == "NodeMapScene":
		# 专门处理地图场景
		var map_container = scene_node.get_node_or_null("MapContainer")
		if map_container:
			map_container.position = Vector2.ZERO
			# 确保所有节点从(0,0)开始布局
			for child in map_container.get_children():
				if child is CanvasItem:
					child.position = Vector2.ZERO
			print("GameManager: 特别调整NodeMapScene的MapContainer")
	
	# 递归检查所有直接子节点
	for child in scene_node.get_children():
		if child is CanvasItem and "position" in child and child.position != Vector2.ZERO:
			print("GameManager: 子节点", child.name, "有非零位置:", child.position)
			# 这里不直接修改子节点，因为场景内部的位置关系是有意设计的
			
	print("GameManager: 场景位置调整完成")

# 获取活动场景  
func get_scene(scene_name):  
	# 首先检查跟踪的场景  
	if active_scenes.has(scene_name) and is_instance_valid(active_scenes[scene_name]):  
		return active_scenes[scene_name]  
	
	# 从活动场景列表中移除无效引用
	if active_scenes.has(scene_name) and not is_instance_valid(active_scenes[scene_name]):
		active_scenes.erase(scene_name)
		print("GameManager: 移除了无效的场景引用:", scene_name)
	
	# 尝试从root节点查找  
	var root = get_tree().root
	if root:
		var scene = root.get_node_or_null(scene_name)
		if scene:
			# 找到后添加到跟踪列表  
			active_scenes[scene_name] = scene  
			return scene
	
	# 在当前场景下查找
	var current_scene = get_tree().current_scene
	if current_scene:
		var scene = current_scene.get_node_or_null(scene_name)
		if scene:
			# 找到后添加到跟踪列表
			active_scenes[scene_name] = scene
			return scene
	
	print("GameManager: 未找到场景:", scene_name)
	return null  

# 显示/隐藏场景  
func set_scene_visibility(scene_name, visible_state):  
	var scene = get_scene(scene_name)  
	if scene:  
		scene.visible = visible_state
		print("GameManager: 设置场景", scene_name, "可见性为", visible_state)
		return true  
	
	print("GameManager: 无法设置场景", scene_name, "的可见性，场景不存在")
	return false

#------------------------------------------------------------------------------  
# 敌人相关功能  
#------------------------------------------------------------------------------  
# 设置游戏的敌人数据  
func set_enemy_data(enemy_data):  
	# 打印enemy_data的详细信息用于调试
	print("GameManager: 设置敌人数据详情:")
	if not enemy_data:
		print("警告：没有敌人数据，使用默认敌人")
		enemy_data = create_default_enemy(false)
		return
	
	# 如果当前是Rogue模式，确保保存了Rogue场景路径
	if is_rogue_mode():
		if not has_meta("last_rogue_scene"):
			save_rogue_scene_info("res://scenes/rogue/rogue_mode_scene.tscn")
			print("GameManager: 在设置敌人数据时保存了Rogue场景路径")
	
	print(" - 名称:", enemy_data.name if enemy_data.has("name") else "未命名敌人")
	print(" - 生命值:", enemy_data.health if enemy_data.has("health") else "未指定")
	print(" - 所需分数:", enemy_data.required_score if enemy_data.has("required_score") else "未指定")
	print(" - 回合限制:", enemy_data.round_limit if enemy_data.has("round_limit") else "未指定")
	
	# 设置默认值如果属性不存在
	if not enemy_data.has("description"):
		enemy_data["description"] = "无描述信息"
	
	if not enemy_data.has("round_limit"):
		enemy_data["round_limit"] = 5
	
	if not enemy_data.has("required_score"):
		enemy_data["required_score"] = 100
	
	if not enemy_data.has("health"):
		enemy_data["health"] = 100
	
	# 判断敌人类型和存储敌人数据
	if enemy_data is Enemy:
		# 如果是Enemy类实例，直接使用
		current_enemy = enemy_data
		score_required = enemy_data.required_score
	else:
		# 如果是字典数据，直接存储为敌人数据
		current_enemy = enemy_data
		score_required = enemy_data.required_score
	
	# 加载敌人数据
	print("加载敌人:", enemy_data.name)
	print("击败条件: 需要", score_required, "分")
	print("回合限制:", enemy_data.round_limit, "回合")
	
	# 设置回合状态
	turns_remaining = 3
	current_round = 1

# 获取当前敌人数据
func get_current_enemy_data():
	if not current_enemy:
		print("GameManager: 当前没有敌人数据，返回null")
		return null
		
	print("GameManager: 返回当前敌人数据:", current_enemy.name if current_enemy.has("name") else "未知敌人")
	return current_enemy

# 更新敌人UI  
func update_enemy_ui():  
	pass  

# 加载敌人数据  
func load_enemy_by_id(enemy_id: String):  
	var file = FileAccess.open("res://data/enemies.json", FileAccess.READ)  
	if not file:  
		print("无法打开敌人数据文件")  
		return null  
	
	var json_text = file.get_as_text()  
	file.close()  
	
	var json = JSON.new()  
	var error = json.parse(json_text)  
	if error == OK:  
		var enemies = json.data  
		for enemy in enemies:  
			if enemy.id == enemy_id:  
				return enemy  
	
	print("未找到ID为" + enemy_id + "的敌人")  
	return null  

# 获取随机敌人数据  
func get_random_enemy(is_elite: bool):  
	print("GameManager: 尝试获取", "精英" if is_elite else "普通", "敌人")
	
	var file = FileAccess.open("res://data/enemies.json", FileAccess.READ)  
	if not file:  
		print("错误: 无法打开敌人数据文件 - 检查res://data/enemies.json是否存在")
		# 创建默认敌人数据
		return create_default_enemy(is_elite)
	
	var json_text = file.get_as_text()  
	file.close()  
	
	print("GameManager: 成功读取敌人数据文件")
	
	var json = JSON.new()  
	var error = json.parse(json_text)  
	if error == OK:  
		var enemies = json.data  
		
		if not enemies or typeof(enemies) != TYPE_ARRAY:
			print("错误: JSON数据不是数组格式 - ", json_text.substr(0, 50), "...")
			return create_default_enemy(is_elite)
			
		print("GameManager: 成功解析JSON，找到", enemies.size(), "个敌人")
		
		var suitable_enemies = []  
		
		# 筛选合适的敌人  
		for enemy in enemies:
			# 跳过Boss敌人
			if enemy.has("is_boss") and enemy.is_boss:
				continue
				
			# 检查敌人是否符合要求（普通或精英）  
			if is_elite and enemy.has("is_elite") and enemy.is_elite:  
				suitable_enemies.append(enemy)  
			elif !is_elite and (!enemy.has("is_elite") or (enemy.has("is_elite") and !enemy.is_elite)):  
				suitable_enemies.append(enemy)  
		
		# 如果有合适的敌人，随机选择一个  
		if suitable_enemies.size() > 0:  
			var selected_enemy = suitable_enemies[randi() % suitable_enemies.size()]
			print("GameManager: 已选择敌人 - ", selected_enemy.name if selected_enemy.has("name") else "未命名敌人")
			return selected_enemy  
		else:
			print("错误: 没有找到合适的", "精英" if is_elite else "普通", "敌人")
	else:  
		print("错误: JSON解析失败 - ", json.get_error_message(), " at line ", json.get_error_line())
	
	# 如果没有找到敌人，创建默认数据
	return create_default_enemy(is_elite)

# 创建默认敌人数据  
func create_default_enemy(is_elite: bool):  
	var enemy_data = {  
		"id": "default_enemy" + ("_elite" if is_elite else ""),  
		"name": "未知" + ("精英" if is_elite else "") + "敌人",  
		"health": 40 if not is_elite else 80,  
		"damage": 8 if not is_elite else 15,  
		"required_score": 80 if not is_elite else 150,  
		"round_limit": 5,  
		"rewards": {"currency": 20 if not is_elite else 50}  
	}  
	
	if is_elite:  
		enemy_data["is_elite"] = true  
		
	print("GameManager: 创建默认", "精英" if is_elite else "普通", "敌人 - ", enemy_data.name)
	return enemy_data  

# 获取随机Boss敌人数据  
func get_random_boss():  
	print("GameManager: 尝试获取Boss敌人")
	
	var file = FileAccess.open("res://data/enemies.json", FileAccess.READ)  
	if not file:  
		print("错误: 无法打开敌人数据文件 - 检查res://data/enemies.json是否存在")
		return create_default_boss()
	
	var json_text = file.get_as_text()  
	file.close()  
	
	print("GameManager: 成功读取敌人数据文件")
	
	var json = JSON.new()  
	var error = json.parse(json_text)  
	if error == OK:  
		var enemies = json.data  
		
		if not enemies or typeof(enemies) != TYPE_ARRAY:
			print("错误: JSON数据不是数组格式 - ", json_text.substr(0, 50), "...")
			return create_default_boss()
			
		print("GameManager: 成功解析JSON，找到", enemies.size(), "个敌人")
		
		var boss_enemies = []  
		
		# 筛选Boss敌人  
		for enemy in enemies:  
			if enemy.has("is_boss") and enemy.is_boss:  
				boss_enemies.append(enemy)  
		
		# 如果有Boss敌人，随机选择一个  
		if boss_enemies.size() > 0:  
			var selected_boss = boss_enemies[randi() % boss_enemies.size()]
			# 确保Boss难度相适应
			if current_floor_level <= 3 and boss_enemies.size() > 1:
				# 选择较容易的Boss
				boss_enemies.sort_custom(func(a, b): return a.difficulty < b.difficulty)
				selected_boss = boss_enemies[0]
			elif current_floor_level >= 8 and boss_enemies.size() > 1:
				# 选择较困难的Boss
				boss_enemies.sort_custom(func(a, b): return a.difficulty > b.difficulty)
				selected_boss = boss_enemies[0]
			else:
				# 完全随机选择
				selected_boss = boss_enemies[randi() % boss_enemies.size()]
				
			print("GameManager: 已选择Boss - ", selected_boss.name if selected_boss.has("name") else "未命名Boss")
			return selected_boss
		else:
			print("错误: 没有找到Boss敌人")
	else:  
		print("错误: JSON解析失败 - ", json.get_error_message(), " at line ", json.get_error_line())
	
	# 如果没有找到Boss，创建默认数据
	return create_default_boss()

# 创建默认Boss数据  
func create_default_boss():  
	var boss_data = {  
		"id": "default_boss",  
		"name": "神秘Boss",  
		"health": 120,  
		"damage": 20,  
		"required_score": 200,  
		"round_limit": 8,  
		"rewards": {"currency": 100},  
		"is_boss": true  
	}  
	
	print("GameManager: 创建默认Boss - ", boss_data.name)
	return boss_data

#------------------------------------------------------------------------------  
# 战斗结果处理  
#------------------------------------------------------------------------------  
# 游戏胜利时的奖励处理  
func process_victory_rewards():  
	# 检查敌人对象和rewards属性是否存在  
	if current_enemy == null:  
		print("GameManager: 警告: 当前没有敌人对象，但触发了领取奖励")  
		return  
		
	# 检查是否达到击败敌人所需分数  
	if player_stats and player_stats.current_score < score_required:  
		print("GameManager: 警告: 未达到击败敌人所需分数，但触发了领取奖励")  
		return  
		
	print("GameManager: 玩家击败敌人，处理奖励")  
		

	player_stats.currency += current_enemy.rewards.currency  
	print("玩家获得", current_enemy.rewards.currency, "货币")  
	
	print("GameManager: 胜利奖励处理完成，等待切换到奖励场景")  

# 游戏失败处理  
func process_defeat():  
	print("GameManager: 失败处理，将玩家返回地图")  
	# 可以在这里添加失败惩罚，比如减少生命值等  

#------------------------------------------------------------------------------  
# 商店系统  
#------------------------------------------------------------------------------  
# 进入商店  
func enter_shop():  
	current_state = GameState.SHOP  
	load_shop_items()  
	emit_signal("enter_shop_requested")  

# 加载商店物品  
func load_shop_items():  
	var file = FileAccess.open("res://data/shop_items.json", FileAccess.READ)  
	if not file:  
		printerr("无法加载商店物品数据")  
		return  
		
	var json_text = file.get_as_text()  
	file.close()  
	
	var json = JSON.new()  
	var error = json.parse(json_text)  
	if error == OK:  
		current_shop_items = json.get_data()  
	else:  
		printerr("解析商店物品JSON失败: ", json.get_error_message())  
	
# 离开商店  
func leave_shop():  
	current_state = GameState.MAP
	emit_signal("return_to_game_requested")  

# 获取当前商店物品  
func get_shop_items() -> Array:  
	return current_shop_items  

# 购买商店物品  
func purchase_shop_item(item_index: int) -> bool:  
	if item_index < 0 or item_index >= current_shop_items.size():  
		return false  
		
	var item = current_shop_items[item_index]  
	if player_data.currency >= item.price:  
		player_data.currency -= item.price  
		if player_stats:  
			player_stats.currency -= item.price  
		# 这里应该添加实际应用物品效果的逻辑  
		return true  
	return false  

#------------------------------------------------------------------------------  
# 地图系统  
#------------------------------------------------------------------------------  
# 添加地图状态保存和加载功能  
func save_map_state(map_state):  
	current_map_state = map_state  
	print("GameManager: 地图状态已保存: 当前层级=", map_state.current_floor, "，当前节点=", map_state.current_node_id)  
	
	# 确保玩家数据同步  
	if player_stats:  
		player_data.currency = player_stats.currency  
		player_data.current_health = player_stats.health  
		print("GameManager: 玩家数据已同步: 生命=", player_data.current_health, "，货币=", player_data.currency)  

# 处理地图节点事件  
func handle_map_node_event(node_type, node_data):  
	print("GameManager: 处理地图节点事件: 类型=", node_type)  
	
	# 根据节点类型执行相应操作  
	match node_type:  
		# 假设这里MapNode.NodeType定义与map_node.gd中的enum相匹配  
		0: # START  
			print("GameManager: 这是起点节点")  
			# 起点通常不需要特殊处理  
			
		1: # ENEMY  
			print("GameManager: 这是普通敌人节点")  
			# 从enemies.json中获取随机普通敌人数据
			var enemy_data = get_random_enemy(false)
			set_enemy_data(enemy_data)  
			
		2: # ELITE  
			print("GameManager: 这是精英敌人节点")  
			# 从enemies.json中获取随机精英敌人数据
			var enemy_data = get_random_enemy(true)
			set_enemy_data(enemy_data)  
			
		3: # SHOP  
			print("GameManager: 这是商店节点")  
			# 进入商店  
			enter_shop()  
			
		4: # REST  
			print("GameManager: 这是休息点节点")  
			# 恢复一定生命值  
			player_data.current_health = min(player_data.max_health, player_data.current_health + 20)  
			print("GameManager: 玩家恢复20点生命值，当前生命: ", player_data.current_health)  
			
		5: # TREASURE  
			print("GameManager: 这是宝箱节点")  
			# 获得随机奖励  
			var reward = randi() % 50 + 20  
			player_data.currency += reward  
			print("GameManager: 玩家获得", reward, "货币")  
			
		6: # EVENT  
			print("GameManager: 这是事件节点")  
			# 触发随机事件  
			trigger_random_event()  
			
		7: # BOSS  
			print("GameManager: 这是Boss节点")  
			# 从enemies.json中获取随机Boss敌人数据
			var enemy_data = get_random_boss()
			set_enemy_data(enemy_data)  
				
		8: # END  
			print("GameManager: 这是终点节点")  
			# 完成当前层级，进入下一层  
			current_floor_level += 1  
			print("GameManager: 进入下一层级: ", current_floor_level)  

#------------------------------------------------------------------------------  
# 数据访问方法  
#------------------------------------------------------------------------------  
func get_player_currency():  
	return player_data.currency  

func get_player_health():  
	return player_data.current_health  

func get_player_max_health():  
	return player_data.max_health  

# 获取地图状态  
func get_map_state():  
	return current_map_state  

# 设置当前层级  
func set_floor_level(level):  
	current_floor_level = level  
	print("设置当前层级为: ", level)  

# 获取当前层级  
func get_floor_level():  
	return current_floor_level  

#------------------------------------------------------------------------------  
# 场景管理功能  
#------------------------------------------------------------------------------  
# 基础场景控制  
func _on_quit_game():  
	get_tree().quit()  

# 启动地图模式  
func _on_start_map_mode():  
	print("GameManager: 启动地图模式")  
	
	# 使用统一的场景切换方法
	var success = await switch_to_scene(node_map_scene)
	if not success:
		push_error("GameManager: 无法切换到地图场景")
		return
	
	# 等待一帧确保场景已完全加载
	await get_tree().process_frame
	
	# 获取当前场景并连接信号
	var map_scene = get_scene("NodeMapScene")
	if not map_scene:
		push_error("GameManager: 无法获取地图场景")
		return
	
	# 断开可能已存在的信号连接
	if map_scene.is_connected("node_selected", _on_map_node_selected):
		map_scene.disconnect("node_selected", _on_map_node_selected)
	if map_scene.is_connected("map_completed", _on_map_completed):
		map_scene.disconnect("map_completed", _on_map_completed)
	
	# 连接信号
	map_scene.node_selected.connect(_on_map_node_selected)
	map_scene.map_completed.connect(_on_map_completed)
	
	print("GameManager: 地图模式启动完成")

# 处理地图节点选择  
func _on_map_node_selected(node_type, node_data):  
	print("GameManager: 选择了地图节点: 类型=", node_type)  
	
	# 保存当前地图状态
	var map_scene = get_scene("NodeMapScene")
	if map_scene and map_scene.has_method("get_map_state"):
		var map_state = map_scene.get_map_state()
		save_map_state(map_state)
		print("GameManager: 地图状态已保存")
	
	# 处理节点事件 - handle_map_node_event会根据节点类型设置合适的敌人
	handle_map_node_event(node_type, node_data)  
	
	# 根据节点类型执行不同操作  
	match node_type:  
		1, 2, 7:  # ENEMY, ELITE, BOSS  
			# 准备敌人数据
			var enemy_data_for_scene = null
			if current_enemy:
				if current_enemy is Enemy:
					# 如果是Enemy对象，获取其原始数据
					enemy_data_for_scene = current_enemy.get_enemy_data() if current_enemy.has_method("get_enemy_data") else current_enemy
				else:
					# 如果已经是字典，直接使用
					enemy_data_for_scene = current_enemy
			else:
				print("GameManager: 警告 - current_enemy没有在handle_map_node_event中设置")
			
			# 如果仍没有敌人数据，则创建一个默认的
			if enemy_data_for_scene == null:
				print("GameManager: 警告 - 没有找到敌人数据，使用默认值")
				if node_type == 7: # BOSS
					enemy_data_for_scene = create_default_boss()
				else:
					enemy_data_for_scene = create_default_enemy(node_type == 2)
			
			# 显示敌人选择场景
			await _show_enemy_select_scene(false, true, enemy_data_for_scene)
		
		3:  # SHOP  
			print("GameManager: 准备显示商店场景")
			# 显示商店场景
			await _show_shop_scene()
			
		4:  # REST
			print("GameManager: 处理休息点，增加玩家生命值")
			# 恢复玩家生命值
			if player_stats:
				var healing_amount = 20
				if node_data and node_data.has("healing_amount"):
					healing_amount = node_data.healing_amount
				
				player_stats.heal(healing_amount)
				print("GameManager: 玩家恢复了", healing_amount, "点生命值")
			
			# 显示休息效果后返回地图
			await get_tree().create_timer(1.0).timeout
			# 无需切换场景，因为我们仍在地图上
			
		5:  # TREASURE
			print("GameManager: 处理宝藏点，增加玩家金币")
			# 增加玩家金币
			if player_stats:
				var gold_amount = 25
				if node_data and node_data.has("min_gold") and node_data.has("max_gold"):
					var min_gold = node_data.min_gold
					var max_gold = node_data.max_gold
					gold_amount = randi() % (max_gold - min_gold + 1) + min_gold
				
				player_stats.currency += gold_amount
				print("GameManager: 玩家获得了", gold_amount, "金币")
			
			# 显示获取宝藏效果后返回地图
			await get_tree().create_timer(1.0).timeout
			# 无需切换场景，因为我们仍在地图上
			
		6:  # EVENT
			print("GameManager: 处理事件点")
			# 随机事件逻辑
			trigger_random_event()
			
			# 显示事件效果后返回地图
			await get_tree().create_timer(1.0).timeout
			# 无需切换场景，因为我们仍在地图上
	
	# 确保地图状态在节点处理后被正确更新和显示
	if map_scene and map_scene.has_method("update_after_node_event"):
		map_scene.update_after_node_event(node_type)
	
	print("GameManager: 地图节点处理完成")

# 地图完成处理  
func _on_map_completed():  
	print("地图已完成，进入下一层")  
	
	# 更新当前层级  
	current_floor_level += 1  
	
	# 切换到新的地图场景  
	var success = await switch_to_scene(node_map_scene)  
	if not success:  
		push_error("无法切换到新地图场景")  
		return  
	
	# 获取当前场景并连接信号  
	var map_scene = get_tree().current_scene  
	map_scene.node_selected.connect(_on_map_node_selected)  
	map_scene.map_completed.connect(_on_map_completed)  

# 显示敌人选择场景  
func _show_enemy_select_scene(from_shop: bool = false, auto_mode: bool = true, enemy_data = null):  
	print("GameManager: 显示敌人选择场景")  
	
	# 使用统一的场景切换方法
	var success = await switch_to_scene(enemy_select_scene)
	if not success:
		push_error("GameManager: 无法切换到敌人选择场景")
		return
	
	# 等待一帧确保场景已完全加载
	await get_tree().process_frame
	
	# 获取敌人选择场景实例
	var enemy_select_instance = get_scene("EnemySelectScene")
	if not enemy_select_instance:
		push_error("GameManager: 无法获取敌人选择场景")
		return
	
	# 初始化场景
	if enemy_select_instance.has_method("initialize"):
		enemy_select_instance.initialize(from_shop, auto_mode, enemy_data)
	else:
		print("GameManager: 警告 - 敌人选择场景没有initialize方法")
	
	# 断开可能已存在的信号连接
	if enemy_select_instance.is_connected("enemy_selected", _on_enemy_selected):
		enemy_select_instance.disconnect("enemy_selected", _on_enemy_selected)
	if enemy_select_instance.is_connected("return_requested", _on_return_to_map):
		enemy_select_instance.disconnect("return_requested", _on_return_to_map)
	
	# 重新连接信号
	enemy_select_instance.enemy_selected.connect(_on_enemy_selected)
	enemy_select_instance.return_requested.connect(_on_return_to_map)
	
	# 确保敌人选择场景可见
	enemy_select_instance.visible = true
	
	print("GameManager: 敌人选择场景初始化完成，信号已连接")

# 显示商店场景  
func _show_shop_scene():  
	print("GameManager: 显示商店场景")  
	
	# 使用统一的场景切换方法
	var success = await switch_to_scene(shop_scene)
	if not success:
		push_error("GameManager: 无法切换到商店场景")
		return
	
	# 等待一帧确保场景已完全加载
	await get_tree().process_frame
	
	# 获取商店场景实例
	var shop_instance = get_scene("ShopScene")
	if not shop_instance:
		push_error("GameManager: 无法获取商店场景")
		return
	
	# 断开可能已存在的信号连接
	if shop_instance.is_connected("leave_shop_requested", _on_return_to_map):
		shop_instance.disconnect("leave_shop_requested", _on_return_to_map)
	if shop_instance.is_connected("shop_enemy_select", _on_shop_enemy_select):
		shop_instance.disconnect("shop_enemy_select", _on_shop_enemy_select)
	
	# 连接信号
	shop_instance.connect("leave_shop_requested", _on_return_to_map)
	
	# 如果需要添加从商店中选择敌人的功能，需确保ShopScene中定义了此信号
	if shop_instance.has_signal("shop_enemy_select"):
		shop_instance.connect("shop_enemy_select", _on_shop_enemy_select)
	
	print("GameManager: 商店场景创建完成，信号已连接")

# 当选择敌人后  
func _on_enemy_selected(enemy_data):  
	print("GameManager: 收到敌人选择信号，准备创建战斗场景")  
	
	# 检查敌人数据
	if enemy_data == null:
		push_error("GameManager: 收到无效的敌人数据")
		return
		
	# 打印敌人详情以便调试
	print("GameManager: 敌人数据:", 
		"\n - 名称:", enemy_data.name if enemy_data.has("name") else "未知", 
		"\n - 生命值:", enemy_data.health if enemy_data.has("health") else "未知",
		"\n - 所需分数:", enemy_data.required_score if enemy_data.has("required_score") else "未知")
	
	# 使用统一的场景切换方法
	var success = await switch_to_scene(battle_scene)
	if not success:
		push_error("GameManager: 无法切换到战斗场景")
		return
	
	# 等待一帧确保场景已完全加载
	await get_tree().process_frame

# 从其他场景返回地图  
func _on_return_to_map():  
	print("GameManager: 收到返回地图请求")
	
	# 首先检查元数据中的记录，确定前一个场景和是否来自Rogue模式
	var from_rogue = false
	var previous_scene = ""
	
	if has_meta("reward_from_rogue_mode"):
		from_rogue = get_meta("reward_from_rogue_mode")
		print("GameManager: 元数据中的from_rogue =", from_rogue)
		
	if has_meta("previous_scene_before_reward"):
		previous_scene = get_meta("previous_scene_before_reward")
		print("GameManager: 元数据中的previous_scene =", previous_scene)
	
	# 然后尝试从当前场景获取is_from_rogue标记
	# 这是冗余检查，以防元数据丢失
	var current_scene = get_current_scene()
	if current_scene and current_scene.has_method("is_from_rogue") and !from_rogue:
		from_rogue = current_scene.is_from_rogue()
		print("GameManager: 从当前场景获取的from_rogue =", from_rogue)
	
	# 如果确定是来自Rogue模式，尝试返回到Rogue模式
	if from_rogue:
		print("GameManager: 确认奖励来自Rogue模式，处理返回Rogue逻辑")
		
		# 1. 尝试使用自动加载的RogueManager
		var rogue_manager = get_node_or_null("/root/RogueManager")
		if rogue_manager and rogue_manager.has_method("_on_reward_return_to_map"):
			print("GameManager: 使用自动加载的RogueManager处理返回")
			rogue_manager._on_reward_return_to_map()
			return
		
		# 2. 尝试在当前场景树中查找RogueManager
		print("GameManager: 在场景树中查找RogueManager")
		for node in get_tree().root.get_children():
			# 检查节点名称是否与Rogue相关
			if node.name.begins_with("RogueMode") or node.name.find("Rogue") != -1:
				print("GameManager: 找到Rogue场景:", node.name)
				var potential_manager = node.get_node_or_null("RogueManager")
				if potential_manager and potential_manager.has_method("_on_reward_return_to_map"):
					print("GameManager: 在场景中找到了RogueManager，调用处理方法")
					potential_manager._on_reward_return_to_map()
					return
		
		# 3. 如果找不到现有RogueManager，重新加载Rogue模式场景
		print("GameManager: 未找到RogueManager，尝试重新加载Rogue模式场景")
		var rogue_mode_scene_res = load("res://scenes/rogue/rogue_mode_scene.tscn")
		if rogue_mode_scene_res:
			# 切换到Rogue模式场景
			var success = await switch_to_scene(rogue_mode_scene_res)
			if success:
				print("GameManager: 成功切换回Rogue模式场景")
				
				# 等待场景加载
				await process_one_frame()
				
				# 尝试再次获取RogueManager
				var rogue_scene = get_current_scene()
				if rogue_scene:
					var rogue_manager_in_new_scene = rogue_scene.get_node_or_null("RogueManager")
					if rogue_manager_in_new_scene and rogue_manager_in_new_scene.has_method("_on_reward_return_to_map"):
						print("GameManager: 在新加载的场景中找到RogueManager，调用处理方法")
						rogue_manager_in_new_scene._on_reward_return_to_map()
						return
			else:
				push_error("GameManager: 无法切换回Rogue模式场景")
		else:
			push_error("GameManager: 无法加载Rogue模式场景资源")
	
	# 处理普通返回地图逻辑（非Rogue模式）
	print("GameManager: 处理普通返回地图逻辑")
	# 使用统一的场景切换方法
	var success = await switch_to_scene(node_map_scene)
	if not success:  
		push_error("GameManager: 无法切换到地图场景")  
		return  
	
	# 等待一帧确保场景已完全加载
	await process_one_frame()
	
	# 获取新创建的地图场景
	var map_scene = get_scene("NodeMapScene")
	if not map_scene:
		push_error("GameManager: 创建地图场景后未找到地图场景节点")
		return
		
	# 断开可能的旧连接
	if map_scene.is_connected("node_selected", _on_map_node_selected):
		map_scene.disconnect("node_selected", _on_map_node_selected)
	if map_scene.is_connected("map_completed", _on_map_completed):
		map_scene.disconnect("map_completed", _on_map_completed)
		
	# 连接信号  
	map_scene.node_selected.connect(_on_map_node_selected)  
	map_scene.map_completed.connect(_on_map_completed)  
	
	# 加载保存的地图状态
	if current_map_state and map_scene.has_method("load_map_state"):
		print("GameManager: 加载地图状态")
		map_scene.load_map_state(current_map_state)
	else:
		print("GameManager: 警告 - 没有地图状态可加载或地图场景没有load_map_state方法")
		
	# 强制更新地图场景显示
	map_scene.visible = true
	if map_scene.has_method("update_after_state_load"):
		map_scene.update_after_state_load()
	
	print("GameManager: 地图场景已显示并初始化")

# 游戏结束处理  
func _on_game_over(win: bool):  
	if win:  
		print("GameManager: 玩家获胜!")  
		# 胜利处理已在_on_enemy_defeated中完成  
	else:  
		print("GameManager: 玩家失败!")  
		# 失败后重置地图  
		_reset_current_floor_map()

# 敌人击败处理  
func _on_enemy_defeated():  
	print("GameManager: 收到战斗管理器发来的敌人被击败信号")  
	
	# 处理胜利奖励
	process_victory_rewards()
	
	# 获取奖励数据  
	var reward_data = {}  
	if current_enemy != null:  
		if current_enemy is Enemy:  
			print("GameManager: 从Enemy类型敌人获取奖励数据")  
			reward_data = current_enemy.get_rewards()  
		elif typeof(current_enemy) == TYPE_DICTIONARY and current_enemy.has("rewards"):  
			print("GameManager: 从敌人字典获取奖励数据")  
			reward_data = current_enemy.rewards  
		else:  
			# 默认奖励  
			print("GameManager: 使用默认奖励数据")  
			reward_data = {"currency": 50}  
	else:  
		print("警告: 游戏管理器中没有有效的敌人对象")  
		reward_data = {"currency": 50}  
	
	# 延迟显示奖励场景，确保战斗场景有时间显示胜利效果
	await get_tree().create_timer(1.0).timeout
	
	# 使用统一的奖励场景显示函数
	await show_reward_scene(reward_data)

# 重置当前楼层地图（在战斗失败后调用）  
func _reset_current_floor_map():  
	print("GameManager: 重置当前楼层地图")  
	
	# 使用统一的场景切换方法
	var success = await switch_to_scene(node_map_scene)  
	if not success:
		push_error("GameManager: 无法切换到新地图场景")
		return
	
	# 获取新创建的地图场景
	var map_scene = get_scene("NodeMapScene")
	if not map_scene:
		push_error("GameManager: 创建地图场景后未找到地图场景节点")
		return
		
	# 断开可能的旧连接
	if map_scene.is_connected("node_selected", _on_map_node_selected):
		map_scene.disconnect("node_selected", _on_map_node_selected)
	if map_scene.is_connected("map_completed", _on_map_completed):
		map_scene.disconnect("map_completed", _on_map_completed)
		
	# 连接信号
	map_scene.node_selected.connect(_on_map_node_selected)  
	map_scene.map_completed.connect(_on_map_completed)  
	
	print("GameManager: 地图已重置")

# 从商店进入敌人选择 - 在地图模式下重定向到返回地图  
func _on_shop_enemy_select():  
	_on_return_to_map()  

#------------------------------------------------------------------------------  
# 测试和调试功能  
#------------------------------------------------------------------------------  
# 游戏胜利时的处理
func _on_battle_enemy_defeated():
	print("GameManager: 收到战斗管理器发来的敌人被击败信号")
	
	# 发出自己的敌人被击败信号
	emit_signal("enemy_defeated")
	
	# 处理胜利奖励
	process_victory_rewards()
	
	# 确保当前场景是BattleScene
	if current_main_scene != "BattleScene":
		print("GameManager警告: 当前场景不是BattleScene，跳过后续处理")
		return
		
	print("GameManager: 准备在1秒后显示奖励场景")
	
	# 延迟切换到奖励场景
	await get_tree().create_timer(1.0).timeout
	
	print("GameManager: 开始切换到奖励场景")
	
	# 从current_enemy获取奖励数据
	var reward_amount = 20
	reward_amount = current_enemy.rewards.currency
	
	# 检查是否来自Rogue模式
	var from_rogue_mode = false
	var current_scene = get_current_scene()
	if current_scene:
		var scene_name = current_scene.name
		if scene_name.begins_with("RogueMode") or scene_name.find("Rogue") != -1:
			from_rogue_mode = true
			print("GameManager: 检测到来自Rogue模式")
	
	print("GameManager: 显示奖励场景，获得奖励:", reward_amount)
	show_reward_scene({
		"currency": reward_amount,
		"from_rogue_mode": from_rogue_mode
	})

# 这个函数用于测试奖励场景  
func force_show_reward_scene(currency_amount = 10):  
	print("GameManager: 强制显示奖励场景，货币:", currency_amount)  
	
	# 调用通用的奖励场景显示函数
	show_reward_scene({"currency": currency_amount})

# 通用的奖励场景显示函数
func show_reward_scene(reward_data: Dictionary):
	print("GameManager: 显示奖励场景，获得奖励:", reward_data.currency if reward_data.has("currency") else "未知")
	
	# 确保reward_data包含from_rogue_mode
	if not reward_data.has("from_rogue_mode"):
		reward_data["from_rogue_mode"] = is_rogue_mode()
	
	print("GameManager: 设置奖励数据到场景:", reward_data)
	
	# 切换到奖励场景
	switch_to_scene(reward_scene)
	
	# 等待一帧确保场景已加载
	await process_one_frame()
	
	# 获取奖励场景实例
	var reward_instance = get_current_scene()
	if reward_instance:
		# 设置奖励数据
		reward_instance.set_reward_data(reward_data)
		print("GameManager: 明确设置奖励场景from_rogue=", reward_data.from_rogue_mode)
	else:
		push_error("GameManager: 无法获取奖励场景实例")
	
	print("GameManager: 奖励场景准备完成，等待用户交互")

# 添加获取当前场景的方法
func get_current_scene():
	return get_tree().current_scene

# 添加等待一帧的方法
func process_one_frame():
	await get_tree().process_frame
	return true

# 玩家属性相关方法

# 治疗玩家
func heal_player(amount: int) -> void:
	player_data["current_health"] = min(player_data["current_health"] + amount, player_data["max_health"])
	print("Player healed for %d. Current health: %d" % [amount, player_data["current_health"]])
	emit_signal("player_stats_changed", player_data)

# 增加玩家护盾
func add_player_shield(amount: int) -> void:
	player_data["shield"] += amount
	print("Player gained %d shield. Current shield: %d" % [amount, player_data["shield"]])
	emit_signal("player_stats_changed", player_data)

# 提升玩家伤害
func boost_player_damage(multiplier: float) -> void:
	player_data["damage_multiplier"] *= multiplier
	print("Player damage boosted by x%.1f. Current multiplier: %.1f" % [multiplier, player_data["damage_multiplier"]])
	emit_signal("player_stats_changed", player_data)

# 增加玩家金币
func add_currency(amount: int) -> void:
	player_data["currency"] += amount
	if player_stats:
		player_stats.currency += amount
	print("Player gained %d currency. Current currency: %d" % [amount, player_data["currency"]])
	emit_signal("player_stats_changed", player_data)

# 返回Rogue模式的函数 - 从奖励场景调用
func return_to_rogue_mode():
	print("GameManager: 返回Rogue模式")
	
	# 检查是否有保存的Rogue模式场景
	if has_meta("last_rogue_scene"):
		var last_scene = get_meta("last_rogue_scene")
		print("GameManager: 找到上次的Rogue场景:", last_scene)
		
		# 加载Rogue模式场景
		var rogue_scene = load(last_scene)
		if rogue_scene:
			switch_to_scene(rogue_scene)
			
			# 等待场景加载
			await process_one_frame()
			
			# 找到RogueManager并通知它从奖励场景返回
			var current_scene = get_current_scene()
			if current_scene:
				var rogue_manager = current_scene.get_node_or_null("RogueManager")
				if rogue_manager and rogue_manager.has_method("_on_reward_return_to_map"):
					print("GameManager: 调用RogueManager._on_reward_return_to_map")
					rogue_manager.call_deferred("_on_reward_return_to_map")
				else:
					print("GameManager: 无法找到RogueManager或方法")
			
			return true
		else:
			push_error("GameManager: 无法加载Rogue场景:", last_scene)
			# 尝试默认路径
			rogue_scene = load("res://scenes/rogue/rogue_mode_scene.tscn")
			if rogue_scene:
				print("GameManager: 使用默认Rogue场景路径")
				switch_to_scene(rogue_scene)
				
				# 等待场景加载
				await process_one_frame()
				
				# 同样尝试连接RogueManager
				var current_scene = get_current_scene()
				if current_scene:
					var rogue_manager = current_scene.get_node_or_null("RogueManager")
					if rogue_manager and rogue_manager.has_method("_on_reward_return_to_map"):
						print("GameManager: 调用RogueManager._on_reward_return_to_map")
						rogue_manager.call_deferred("_on_reward_return_to_map")
				
				return true
	else:
		print("GameManager: 没有找到保存的Rogue场景，尝试使用默认路径")
		var rogue_scene = load("res://scenes/rogue/rogue_mode_scene.tscn")
		if rogue_scene:
			switch_to_scene(rogue_scene)
			
			# 等待场景加载
			await process_one_frame()
			
			# 同样尝试连接RogueManager
			var current_scene = get_current_scene()
			if current_scene:
				var rogue_manager = current_scene.get_node_or_null("RogueManager")
				if rogue_manager and rogue_manager.has_method("_on_reward_return_to_map"):
					print("GameManager: 调用RogueManager._on_reward_return_to_map")
					rogue_manager.call_deferred("_on_reward_return_to_map")
			
			return true
		else:
			push_error("GameManager: 无法加载默认Rogue场景")
	
	return false

func return_to_rogue():
	return await return_to_rogue_mode()

func switch_to_rogue_mode():
	return await return_to_rogue_mode()

# 保存Rogue模式场景信息
func save_rogue_scene_info(scene_path: String):
	print("GameManager: 保存Rogue场景信息:", scene_path)
	set_meta("last_rogue_scene", scene_path)

# 设置游戏模式
func set_game_mode(mode: GameMode):
	print("GameManager: 设置游戏模式为", "Rogue模式" if mode == GameMode.ROGUE else "地图模式")
	current_game_mode = mode

# 获取当前游戏模式
func get_game_mode() -> GameMode:
	return current_game_mode

# 检查是否在Rogue模式
func is_rogue_mode() -> bool:
	return current_game_mode == GameMode.ROGUE
