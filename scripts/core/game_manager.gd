# gamemanager.gd  

extends Node  
class_name GameManager  

#------------------------------------------------------------------------------  
# 预加载场景资源  
#------------------------------------------------------------------------------  
var battle_scene = preload("res://scenes/battle_scene.tscn")  
var shop_scene = preload("res://scenes/shop_scene.tscn")  
var enemy_select_scene = preload("res://scenes/enemy_select/enemy_select_scene.tscn")  
var node_map_scene = preload("res://scenes/node_map_scene.tscn")  
var reward_scene = preload("res://scenes/reward_scene.tscn")  

#------------------------------------------------------------------------------  
# 引用节点和变量声明  
#------------------------------------------------------------------------------  
# 引用到核心节点  
@onready var player_stats = $"../PlayerStats"  

# 游戏状态枚举  
enum GameState { PLAYER_TURN, ENEMY_TURN, SHOP, GAME_OVER }  
var current_state: GameState = GameState.PLAYER_TURN  
var current_enemy = null  
var current_round: int = 1  
var turns_remaining: int = 3  
var score_required: int = 0  

# 玩家数据和系统变量  
var score_multiplier: float = 1.0  
var player_data = {  
	"max_health": 100,  
	"current_health": 100,  
	"currency": 100  
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

#------------------------------------------------------------------------------  
# 初始化函数  
#------------------------------------------------------------------------------  
var initialized = false

func _ready():
	if not initialized:
		# 确保自己不会被释放
		add_to_group("persistent", true)
		# 确保PlayerStats也不会被释放
		if player_stats and is_instance_valid(player_stats):
			player_stats.add_to_group("persistent", true)
		initialized = true
		print("GameManager: 初始化完成，已标记为持久节点")
		
		# 初始化游戏  
		call_deferred("initialize_game")  
		
		# 连接主菜单按钮信号（如果存在）  
		var main_menu = get_node_or_null("../MainMenu")  
		if main_menu:  
			var start_button = main_menu.get_node_or_null("StartButton")  
			var quit_button = main_menu.get_node_or_null("QuitButton")  
			var map_button = main_menu.get_node_or_null("MapButton")  
			
			if start_button and quit_button:  
				# 默认模式为地图模式  
				start_button.pressed.connect(_on_start_map_mode)  
				quit_button.pressed.connect(_on_quit_game)  
				
				# 隐藏多余的按钮，只保留开始和退出  
				if map_button:  
					map_button.pressed.connect(_on_start_map_mode)  
					map_button.visible = false  
					
				start_button.text = "开始地下城探险"  

func initialize_game():  
	# 初始化游戏状态  
	current_state = GameState.PLAYER_TURN  

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
	# 记录当前场景以便可能的返回  
	var old_scene = current_main_scene  
	
	# 获取Main节点
	var main_node = get_tree().root.get_node_or_null("Main")
	if not main_node:
		push_error("GameManager: 无法找到Main节点")
		return false
	
	# 找到当前的活动场景
	var current_scene_node = null
	for child in main_node.get_children():
		if not child.is_in_group("persistent") and child.name != "GameManager" and child.name != "PlayerStats":
			current_scene_node = child
			break
	
	# 清除当前场景(如果存在)
	if current_scene_node:
		print("GameManager: 移除当前场景:", current_scene_node.name)
		main_node.remove_child(current_scene_node)
		current_scene_node.queue_free()
	
	# 实例化新场景
	var new_scene = scene_resource.instantiate()
	if not new_scene:
		push_error("GameManager: 场景实例化失败")
		return false
	
	# 将新场景添加到Main节点
	main_node.add_child(new_scene)
	
	# 调整新场景的位置 - 确保场景位于正确位置
	_adjust_scene_position(new_scene)
	
	print("GameManager: 添加新场景:", new_scene.name)
	
	# 更新当前场景引用  
	current_main_scene = new_scene.name  
	active_scenes[current_main_scene] = new_scene  
	
	# 等待一帧确保场景已加载
	await get_tree().process_frame
	
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

# 添加子场景 - 也需要调整位置  
func add_subscene(parent_node, scene_resource, scene_name):  
	# 确保父节点存在  
	if not parent_node:  
		push_error("添加子场景失败：父节点不存在")  
		return null  
	
	# 实例化场景  
	var scene_instance = scene_resource.instantiate()  
	if not scene_instance:  
		push_error("场景实例化失败：" + scene_name)  
		return null  
	
	# 设置场景名称  
	scene_instance.name = scene_name  
	
	# 添加为子节点  
	parent_node.add_child(scene_instance)
	
	# 对于特定子场景类型进行位置调整
	if scene_instance is CanvasItem:
		# 优先处理EnemySelectScene和ShopScene等特殊子场景
		if scene_name == "EnemySelectScene" or scene_name == "ShopScene" or scene_name == "RewardScene":
			# 对于UI类型的子场景，设置为铺满父节点区域
			if scene_instance is Control:
				scene_instance.anchors_preset = 15 # 设置锚点预设为全屏
				scene_instance.anchor_left = 0
				scene_instance.anchor_top = 0
				scene_instance.anchor_right = 1
				scene_instance.anchor_bottom = 1
				scene_instance.offset_left = 0
				scene_instance.offset_top = 0
				scene_instance.offset_right = 0
				scene_instance.offset_bottom = 0
				scene_instance.grow_horizontal = 2
				scene_instance.grow_vertical = 2
				print("GameManager: 设置子场景", scene_name, "铺满区域")
			else:
				# 对于非Control类型的CanvasItem，重置其位置
				scene_instance.position = Vector2.ZERO
				print("GameManager: 重置子场景", scene_name, "位置")
	
	# 记录活动场景  
	active_scenes[scene_name] = scene_instance  
	
	print("已添加子场景：", scene_name)  
	return scene_instance  

# 移除场景  
func remove_scene(scene_name):  
	# 检查场景是否存在  
	if not active_scenes.has(scene_name):  
		# 尝试从场景树查找  
		var scene = get_tree().root.get_node_or_null("Main/" + scene_name)  
		if not scene:  
			print("未找到要移除的场景：", scene_name)  
			return false  
		
		scene.queue_free()  
		print("移除了未跟踪的场景：", scene_name)  
		return true  
	
	# 移除场景节点  
	if is_instance_valid(active_scenes[scene_name]):  
		active_scenes[scene_name].queue_free()  
	
	# 从活动场景列表移除  
	active_scenes.erase(scene_name)  
	print("已移除场景：", scene_name)  
	return true  

# 获取活动场景  
func get_scene(scene_name):  
	# 首先检查跟踪的场景  
	if active_scenes.has(scene_name):  
		return active_scenes[scene_name]  
	
	# 尝试从场景树查找  
	var scene = get_tree().root.get_node_or_null("Main/" + scene_name)  
	if scene:  
		# 找到后添加到跟踪列表  
		active_scenes[scene_name] = scene  
		return scene  
	
	return null  

# 显示/隐藏场景  
func set_scene_visibility(scene_name, visible):  
	var scene = get_scene(scene_name)  
	if scene:  
		scene.visible = visible  
		return true  
	return false  

#------------------------------------------------------------------------------  
# 敌人相关功能  
#------------------------------------------------------------------------------  
# 设置游戏的敌人数据  
func set_enemy_data(enemy_data):  
	# 如果没有敌人数据，使用默认数据  
	if not enemy_data:  
		print("警告: 未提供敌人数据，使用默认敌人")  
		enemy_data = create_default_enemy(false)
	
	# 打印详细的敌人数据以便调试
	print("GameManager: 设置敌人数据详情:")
	print(" - 名称:", enemy_data.name if enemy_data.has("name") else "未命名敌人")
	print(" - 生命值:", enemy_data.health if enemy_data.has("health") else "未指定")
	print(" - 所需分数:", enemy_data.required_score if enemy_data.has("required_score") else "未指定")
	print(" - 回合限制:", enemy_data.round_limit if enemy_data.has("round_limit") else "未指定")
	
	# 确保敌人数据包含必要字段
	if not enemy_data.has("description"):
		enemy_data["description"] = "无描述信息"
	
	if not enemy_data.has("round_limit"):
		enemy_data["round_limit"] = 5
		
	if not enemy_data.has("required_score"):
		enemy_data["required_score"] = 100
		
	if not enemy_data.has("health"):
		enemy_data["health"] = 100
	
	# 尝试创建Enemy对象，如果类不存在则使用字典
	var Enemy_Class = load("res://scripts/core/enemy.gd")
	
	if Enemy_Class:
		# 创建新敌人对象
		current_enemy = Enemy_Class.new()
		current_enemy.initialize(enemy_data)
		score_required = current_enemy.required_score
		
		# 打印敌人信息  
		print("加载敌人:", current_enemy.enemy_name)  
		print("击败条件: 需要", score_required, "分")  
		print("回合限制:", current_enemy.round_limit, "回合")  
	else:
		# 如果Enemy类不存在，直接使用字典
		print("注意: Enemy类未找到，使用字典格式")
		current_enemy = enemy_data
		score_required = enemy_data.required_score
		
		# 打印敌人信息
		print("加载敌人:", enemy_data.name)
		print("击败条件: 需要", score_required, "分")
		print("回合限制:", enemy_data.round_limit, "回合")
	
	# 重置游戏状态  
	current_round = 1  
	turns_remaining = 3  
	
	# 更新UI  
	update_enemy_ui()

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
			# 检查敌人是否符合要求（普通或精英）  
			if is_elite and enemy.has("is_elite") and enemy.is_elite:  
				suitable_enemies.append(enemy)  
			elif !is_elite and (!enemy.has("is_elite") or !enemy.is_elite):  
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
		
	# 检查敌人的rewards属性并添加到玩家数据  
	if current_enemy.has_method("get_rewards"):  
		# 如果敌人类有获取奖励的方法  
		var rewards = current_enemy.get_rewards()  
		if rewards and rewards.has("currency"):  
			player_data.currency += rewards.currency  
			if player_stats:  
				player_stats.currency += rewards.currency  
			print("玩家获得", rewards.currency, "货币")  
	elif typeof(current_enemy) == TYPE_DICTIONARY and current_enemy.has("rewards"):  
		# 如果敌人是字典形式  
		if current_enemy.rewards.has("currency"):  
			player_data.currency += current_enemy.rewards.currency  
			if player_stats:  
				player_stats.currency += current_enemy.rewards.currency  
			print("玩家获得", current_enemy.rewards.currency, "货币")  
	else:  
		# 如果没有奖励属性，给予固定奖励  
		print("警告: 敌人没有rewards属性，给予固定奖励")  
		player_data.currency += 50  
		if player_stats:  
			player_stats.currency += 50  
		print("玩家获得50货币")  
	
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
	current_state = GameState.PLAYER_TURN  
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
			set_enemy_data(node_data)  
			
		2: # ELITE  
			print("GameManager: 这是精英敌人节点")  
			# 加载随机精英敌人  
			set_enemy_data(node_data)  
			
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
			set_enemy_data(node_data)  
				
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
		push_error("无法切换到地图场景")  
		return  
	
	# 获取当前场景并连接信号  
	var map_scene = get_tree().current_scene  
	if map_scene.has_signal("node_selected"):  
		map_scene.node_selected.connect(_on_map_node_selected)  
	if map_scene.has_signal("map_completed"):  
		map_scene.map_completed.connect(_on_map_completed)  
	
	print("GameManager: 地图模式启动完成")  

# 处理地图节点选择  
func _on_map_node_selected(node_type, node_data):  
	print("选择了地图节点: 类型=", node_type)  
	
	# 处理节点事件，只需调用一次
	# handle_map_node_event(node_type, node_data)  
	
	# 根据节点类型执行不同操作  
	match node_type:  
		1, 2, 7:  # ENEMY, ELITE, BOSS  
			# 隐藏地图场景（不移除它）  
			set_scene_visibility("NodeMapScene", false)  
			
			# 获取相应敌人数据，确保我们获得有效的敌人  
			var enemy_data = null  
			if node_type == 1:  # ENEMY  
				print("GameManager: 正在获取普通敌人数据")
				enemy_data = get_random_enemy(false)  
			elif node_type == 2:  # ELITE  
				print("GameManager: 正在获取精英敌人数据")
				enemy_data = get_random_enemy(true)  
			elif node_type == 7:  # BOSS  
				print("GameManager: 正在获取Boss敌人数据")
				enemy_data = get_random_boss()  
			
			# 如果没有找到敌人数据，使用默认敌人  
			if enemy_data == null:  
				print("GameManager: 无法获取敌人数据，创建默认敌人")  
				# 创建基本敌人数据以防获取失败
				enemy_data = {
					"id": "default_enemy",
					"name": "未知敌人",
					"health": 50,
					"damage": 10,
					"required_score": 100,
					"round_limit": 5,
					"rewards": {"currency": 30}
				}
				
				# 对于Boss，增加难度
				if node_type == 7:
					enemy_data.name = "神秘Boss"
					enemy_data.health = 100
					enemy_data.required_score = 200
					enemy_data.round_limit = 8
					enemy_data.rewards.currency = 100
				
			# 显示自动模式的敌人选择场景  
			_show_enemy_select_scene(false, true, enemy_data)  
		
		3:  # SHOP  
			print("GameManager: 准备显示商店场景")
			# 隐藏地图场景  
			set_scene_visibility("NodeMapScene", false)  
			
			# 显示商店场景  
			_show_shop_scene()  
			print("GameManager: 商店场景创建完成")

# 地图完成处理  
func _on_map_completed():  
	print("地图已完成，进入下一层")  
	
	# 更新当前层级  
	current_floor_level += 1  
	
	# 移除当前地图场景并创建新的  
	remove_scene("NodeMapScene")  
	
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
func _show_enemy_select_scene(from_shop: bool = false, auto_mode: bool = false, enemy_data = null):  
	print("GameManager: 显示敌人选择场景")  
	
	# 使用统一的添加子场景方法  
	var parent = get_tree().current_scene  
	var enemy_select_instance = add_subscene(parent, enemy_select_scene, "EnemySelectScene")  
	if not enemy_select_instance:  
		push_error("无法创建敌人选择场景")  
		return  
	
	# 等待一帧确保场景已完全添加到场景树中
	await get_tree().process_frame
	
	# 初始化场景并连接信号  
	enemy_select_instance.initialize(from_shop, auto_mode, enemy_data)  
	
	# 断开可能已存在的信号连接
	if enemy_select_instance.is_connected("enemy_selected", _on_enemy_selected):
		enemy_select_instance.disconnect("enemy_selected", _on_enemy_selected)
	if enemy_select_instance.is_connected("return_requested", _on_return_to_map):
		enemy_select_instance.disconnect("return_requested", _on_return_to_map)
	
	# 重新连接信号 - 使用正确的连接方法
	enemy_select_instance.enemy_selected.connect(_on_enemy_selected)  
	enemy_select_instance.return_requested.connect(_on_return_to_map)  
	
	print("GameManager: 敌人选择场景初始化完成，信号已连接")

# 显示商店场景  
func _show_shop_scene():  
	print("GameManager: 显示商店场景")  
	
	# 使用统一的添加子场景方法  
	var parent = get_tree().current_scene  
	var shop_instance = add_subscene(parent, shop_scene, "ShopScene")  
	if not shop_instance:  
		push_error("无法创建商店场景")  
		return  
	
	# 连接商店信号，修正信号名称与shop_scene.gd中定义的一致
	shop_instance.connect("leave_shop_requested", _on_return_to_map)  
	
	# 注意：以下信号可能不存在于当前商店场景中，应移除
	# 如果需要添加从商店中选择敌人的功能，需确保ShopScene中定义了此信号
	if shop_instance.has_signal("shop_enemy_select"):
		shop_instance.connect("shop_enemy_select", _on_shop_enemy_select)

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
	
	# 移除敌人选择场景  
	remove_scene("EnemySelectScene")  
	
	# 延迟创建游戏场景，确保旧场景已清理完毕  
	await get_tree().process_frame  
	
	print("GameManager: 创建战斗场景，敌人: ", enemy_data.name if enemy_data.has("name") else "未知敌人")  
	
	# 使用统一的添加子场景方法  
	var parent = get_tree().current_scene  
	var game_instance = add_subscene(parent, battle_scene, "GameScene")  
	if not game_instance:  
		push_error("无法创建战斗场景")  
		return  
	
	# 确保UI更新  
	await get_tree().process_frame  
	
	# 获取游戏管理器并设置敌人  
	var battle_game_manager = game_instance.get_node_or_null("GameManager")  
	if battle_game_manager == null:  
		push_error("无法获取GameManager节点")
		# 尝试查找其他可能的节点名称
		battle_game_manager = game_instance.get_node_or_null("BattleManager")
		if battle_game_manager == null:
			for child in game_instance.get_children():
				print("GameScene子节点:", child.name)
			return  
	
	# 设置敌人数据  
	print("GameManager: 设置敌人数据: ", enemy_data.name if enemy_data.has("name") else "未知敌人")
	battle_game_manager.set_enemy_data(enemy_data)  
	
	# 连接游戏信号 - 确保每个信号只连接一次
	if battle_game_manager.has_signal("game_over") and not battle_game_manager.is_connected("game_over", _on_game_over):
		battle_game_manager.game_over.connect(_on_game_over)
		
	if battle_game_manager.has_signal("enemy_defeated") and not battle_game_manager.is_connected("enemy_defeated", _on_enemy_defeated):
		battle_game_manager.enemy_defeated.connect(_on_enemy_defeated)
		
	if battle_game_manager.has_signal("enter_shop_requested") and not battle_game_manager.is_connected("enter_shop_requested", _on_return_to_map):
		battle_game_manager.enter_shop_requested.connect(_on_return_to_map)
		
	if battle_game_manager.has_signal("return_to_game_requested") and not battle_game_manager.is_connected("return_to_game_requested", _on_return_to_map):
		battle_game_manager.return_to_game_requested.connect(_on_return_to_map)
	
	print("GameManager: 战斗场景准备完成")

# 从其他场景返回地图  
func _on_return_to_map():  
	print("GameManager: 收到返回地图请求")  
	
	# 移除所有临时场景  
	var scenes_to_remove = ["GameScene", "ShopScene", "EnemySelectScene", "RewardScene"]  
	for scene_name in scenes_to_remove:  
		remove_scene(scene_name)  
	
	# 尝试显示已有的地图场景  
	var map_visible = set_scene_visibility("NodeMapScene", true)  
	
	# 如果没有找到地图场景，切换到新的地图场景  
	if not map_visible:  
		print("GameManager: 未找到地图场景，创建新的地图场景")  
		switch_to_scene(node_map_scene)  
		
		# 获取当前场景并连接信号  
		var map_scene = get_tree().current_scene  
		map_scene.node_selected.connect(_on_map_node_selected)  
		map_scene.map_completed.connect(_on_map_completed)  
	
	print("GameManager: 地图场景已显示")  

# 游戏结束处理  
func _on_game_over(win: bool):  
	if win:  
		print("GameManager: 玩家获胜!")  
		# 胜利处理已在_on_enemy_defeated中完成  
	else:  
		print("GameManager: 玩家失败!")  
		
		# 移除游戏场景  
		remove_scene("GameScene")  
		
		# 失败后重置地图  
		_reset_current_floor_map()  

# 敌人击败处理  
func _on_enemy_defeated():  
	print("GameManager: 收到敌人击败信号，开始处理战利品")  
	
	# 获取当前游戏场景  
	var battle_scene_instance = get_scene("GameScene")  
	if not battle_scene_instance:  
		print("警告: 没有找到游戏场景，使用游戏场景的备用方案")  
		return  
	
	print("GameManager: 找到游戏场景，准备创建奖励场景")  
	
	# 处理奖励计算  
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
	
	print("GameManager: 准备隐藏游戏场景并创建奖励场景")  
	
	# 隐藏游戏场景  
	battle_scene_instance.visible = false  
	
	# 验证奖励场景资源是否加载成功  
	if reward_scene == null:  
		print("严重错误: 奖励场景资源未成功加载")  
		return  
	
	# 使用统一的添加子场景方法  
	var parent = get_tree().current_scene  
	var reward_instance = add_subscene(parent, reward_scene, "RewardScene")  
	if not reward_instance:  
		push_error("无法创建奖励场景")  
		return  
	
	await get_tree().process_frame  
	
	# 设置奖励数据  
	reward_instance.set_reward_data(reward_data)  
	
	# 连接返回地图信号  
	reward_instance.return_to_map_requested.connect(_on_return_to_map)  
	
	print("GameManager: 奖励场景准备完成，奖励数据:", reward_data)  

# 重置当前楼层地图（在战斗失败后调用）  
func _reset_current_floor_map():  
	print("GameManager: 重置当前楼层地图")  
	
	# 切换到新的地图场景  
	switch_to_scene(node_map_scene)  
	
	# 获取当前场景并连接信号  
	var map_scene = get_tree().current_scene  
	map_scene.node_selected.connect(_on_map_node_selected)  
	map_scene.map_completed.connect(_on_map_completed)  
	
	print("GameManager: 地图已重置")  

# 从商店进入敌人选择 - 在地图模式下重定向到返回地图  
func _on_shop_enemy_select():  
	_on_return_to_map()  

#------------------------------------------------------------------------------  
# 测试和调试功能  
#------------------------------------------------------------------------------  
# 这个函数用于测试奖励场景  
func force_show_reward_scene(currency_amount = 10):  
	print("强制显示奖励场景，货币:", currency_amount)  
	
	# 隐藏其他场景  
	var scenes_to_hide = ["GameScene", "ShopScene", "EnemySelectScene"]  
	for scene_name in scenes_to_hide:  
		set_scene_visibility(scene_name, false)  
	
	# 测试奖励场景显示  
	var reward_data = {"currency": currency_amount}  
	
	# 使用统一的添加子场景方法  
	var parent = get_tree().current_scene  
	var reward_instance = add_subscene(parent, reward_scene, "RewardScene")  
	if not reward_instance:  
		push_error("无法创建奖励场景")  
		return  
	
	await get_tree().process_frame  
	
	# 设置奖励数据  
	reward_instance.set_reward_data(reward_data)  
	
	# 连接返回地图信号  
	reward_instance.return_to_map_requested.connect(_on_return_to_map)  
	
	print("测试奖励场景已显示")  
