extends Node  

var battle_scene = preload("res://scenes/battle_scene.tscn")  
var shop_scene = preload("res://scenes/shop_scene.tscn")  
var enemy_select_scene = preload("res://scenes/enemy_select/enemy_select_scene.tscn")
var node_map_scene = preload("res://scenes/node_map_scene.tscn")
var reward_scene = preload("res://scenes/reward_scene.tscn")

var current_game_manager = null
var player_data = {
	"currency": 0,
	"health": 100,
	"max_health": 100
}

func _ready():  
	# 连接主菜单按钮信号  
	var start_button = get_node("../MainMenu/StartButton")  
	var quit_button = get_node("../MainMenu/QuitButton")  
	var map_button = get_node("../MainMenu/MapButton")
	
	# 默认模式为地图模式
	start_button.pressed.connect(_on_start_map_mode)  
	quit_button.pressed.connect(_on_quit_game)  
	map_button.pressed.connect(_on_start_map_mode)
	
	# 隐藏多余的按钮，只保留开始和退出
	map_button.visible = false
	start_button.text = "开始地下城探险"

# 移除直接开始游戏的方法，只保留地图模式
func _on_start_game():  
	# 重定向到地图模式
	_on_start_map_mode()

func _on_quit_game():  
	get_tree().quit()  

# 显示敌人选择场景 - 只在地图节点选择后使用
func _show_enemy_select_scene(from_shop: bool = false, auto_mode: bool = false, enemy_data = null):
	print("场景管理器: 显示敌人选择场景")
	# 创建敌人选择场景
	var enemy_select_instance = enemy_select_scene.instantiate()
	enemy_select_instance.name = "EnemySelectScene"
	
	# 根据不同情况添加到不同节点
	if get_tree().root.has_node("Main"):
		# 添加到Main节点下
		get_tree().root.get_node("Main").add_child(enemy_select_instance)
	else:
		# 添加到当前节点下
		add_child(enemy_select_instance)
	
	# 初始化场景并连接信号
	enemy_select_instance.initialize(from_shop, auto_mode, enemy_data)
	enemy_select_instance.enemy_selected.connect(_on_enemy_selected)
	
	# 在地图模式下不需要返回商店，直接返回地图
	if from_shop:
		enemy_select_instance.return_requested.connect(_on_return_to_map)
	else:
		enemy_select_instance.return_requested.connect(_on_return_to_map)

# 从商店返回
func _on_return_to_shop():
	print("场景管理器: 从商店返回")
	# 移除商店场景
	var shop_scene_instance = get_node_or_null("ShopScene")
	if shop_scene_instance:
		shop_scene_instance.queue_free()
	
	# 在地图模式下，从商店返回地图
	_on_return_to_map()

# 返回游戏场景 - 在地图模式下不再使用
func _on_return_to_game():
	# 在地图模式下，重定向到返回地图
	_on_return_to_map()

# 启动地图模式
func _on_start_map_mode():
	print("场景管理器: 启动地图模式")
	
	# 获取主菜单引用
	var main_menu = get_node_or_null("../MainMenu")
	if main_menu:
		print("场景管理器: 销毁主菜单")
		main_menu.queue_free()
	elif get_tree().root.has_node("Main/MainMenu"):
		print("场景管理器: 销毁Main下的主菜单")
		get_tree().root.get_node("Main/MainMenu").queue_free()
	
	# 移除可能存在的所有场景
	var scenes_to_remove = ["GameScene", "ShopScene", "EnemySelectScene", "RewardScene", "NodeMapScene", "MainMenu"]
	for scene_name in scenes_to_remove:
		# 尝试多种路径查找场景
		var scene = get_node_or_null(scene_name)
		if scene:
			scene.queue_free()
			
		# 尝试在Main下查找场景
		scene = get_tree().root.get_node_or_null("Main/" + scene_name)
		if scene:
			scene.queue_free()
	
	# 等待一帧确保旧场景已移除
	await get_tree().process_frame
	
	# 创建节点地图场景
	print("场景管理器: 创建地图场景")
	var map_instance = node_map_scene.instantiate()
	map_instance.name = "NodeMapScene"
	map_instance.position = Vector2(0,0)
	# 根据不同情况添加到不同节点
	if get_tree().root.has_node("Main"):
		get_tree().root.get_node("Main").add_child(map_instance)
	else:
		add_child(map_instance)
	
	# 连接地图场景信号
	map_instance.node_selected.connect(_on_map_node_selected)
	map_instance.map_completed.connect(_on_map_completed)
	
	print("场景管理器: 地图模式启动完成")

# 处理地图节点选择
func _on_map_node_selected(node_type, node_data):
	print("选择了地图节点: 类型=", node_type)
	
	# 获取游戏管理器
	var game_manager = get_node("/root/Main/GameManager")
	if game_manager:
		# 处理节点事件
		game_manager.handle_map_node_event(node_type, node_data)
	
	# 根据节点类型执行不同操作
	match node_type:
		1, 2, 7:  # ENEMY, ELITE, BOSS
			# 隐藏地图场景
			var map_scene = get_node_or_null("NodeMapScene")
			if map_scene:
				map_scene.visible = false
			
			# 获取相应敌人数据
			var enemy_data = null
			if game_manager:
				if node_type == 1:  # ENEMY
					enemy_data = game_manager.get_random_enemy(false)
				elif node_type == 2:  # ELITE
					enemy_data = game_manager.get_random_enemy(true)
				elif node_type == 7:  # BOSS
					enemy_data = game_manager.get_random_boss()
			
			# 如果没有找到敌人数据，使用默认敌人
			if enemy_data == null:
				print("SceneManager Error: enemy_data == null")
				
			# 显示自动模式的敌人选择场景
			_show_enemy_select_scene(false, true, enemy_data)
		
		3:  # SHOP
			# 隐藏地图场景
			var map_scene = get_node_or_null("NodeMapScene")
			if map_scene:
				map_scene.visible = false
			
			# 创建商店场景
			var shop_instance = shop_scene.instantiate()
			shop_instance.name = "ShopScene"
			add_child(shop_instance)
			
			# 连接商店信号
			shop_instance.connect("return_to_game", _on_return_to_map)
			shop_instance.connect("shop_enemy_select", _on_shop_enemy_select)

# 地图完成处理
func _on_map_completed():
	print("地图已完成，进入下一层")
	
	# 更新游戏管理器的当前层级
	var game_manager = get_node("/root/Main/GameManager")
	if game_manager:
		var current_level = game_manager.get_floor_level()
		game_manager.set_floor_level(current_level + 1)
	
	# 重新加载地图场景
	var map_scene = get_node_or_null("NodeMapScene")
	if map_scene:
		map_scene.queue_free()
	
	# 创建新的地图场景
	var map_instance = node_map_scene.instantiate()
	map_instance.name = "NodeMapScene"
	add_child(map_instance)
	
	# 连接地图场景信号
	map_instance.node_selected.connect(_on_map_node_selected)
	map_instance.map_completed.connect(_on_map_completed)

# 从其他场景返回地图
func _on_return_to_map():
	print("场景管理器: 收到返回地图请求")
	
	# 移除可能存在的各种场景
	var scenes_to_remove = ["GameScene", "ShopScene", "EnemySelectScene", "RewardScene"]
	for scene_name in scenes_to_remove:
		# 尝试多种路径查找场景
		var scene = get_node_or_null(scene_name)
		if scene:
			print("场景管理器: 移除场景", scene_name)
			scene.queue_free()
			
		# 尝试在Main下查找场景
		scene = get_tree().root.get_node_or_null("Main/" + scene_name)
		if scene:
			print("场景管理器: 移除Main下的场景", scene_name)
			scene.queue_free()
	
	# 显示地图场景
	var map_scene = get_node_or_null("NodeMapScene")
	if map_scene:
		map_scene.visible = true
		print("场景管理器: 显示当前节点下的地图场景")
	elif get_tree().root.has_node("Main/NodeMapScene"):
		get_tree().root.get_node("Main/NodeMapScene").visible = true
		print("场景管理器: 显示Main下的地图场景")
	else:
		# 如果没有地图场景，创建一个新的
		print("场景管理器: 未找到地图场景，创建新的地图场景")
		var map_instance = node_map_scene.instantiate()
		map_instance.name = "NodeMapScene"
		
		# 根据不同情况添加到不同节点
		if get_tree().root.has_node("Main"):
			get_tree().root.get_node("Main").add_child(map_instance)
			print("场景管理器: 将新地图场景添加到Main下")
		else:
			add_child(map_instance)
			print("场景管理器: 将新地图场景添加到当前节点")
		
		# 连接地图场景信号
		map_instance.node_selected.connect(_on_map_node_selected)
		map_instance.map_completed.connect(_on_map_completed)
	
	print("场景管理器: 地图场景已显示")


# 这个函数用于直接测试奖励场景
func force_show_reward_scene(currency_amount = 10):
	print("强制显示奖励场景，货币:", currency_amount)
	
	# 隐藏其他场景
	var scenes_to_hide = ["GameScene", "ShopScene", "EnemySelectScene"]
	for scene_name in scenes_to_hide:
		# 尝试多种路径查找场景
		var scene = get_node_or_null(scene_name)
		if scene:
			scene.visible = false
		elif get_tree().root.has_node("Main/" + scene_name):
			get_tree().root.get_node("Main/" + scene_name).visible = false
	
	# 测试奖励场景显示
	var reward_data = {"currency": currency_amount}
	
	# 验证奖励场景资源
	if reward_scene == null:
		print("严重错误: 无法加载奖励场景资源")
		return
	
	# 创建奖励场景
	var reward_instance = reward_scene.instantiate()
	reward_instance.name = "RewardScene"
	
	# 根据不同情况添加到不同节点
	if get_tree().root.has_node("Main"):
		# 添加到Main节点下
		get_tree().root.get_node("Main").add_child(reward_instance)
	else:
		# 添加到当前节点下
		add_child(reward_instance)
	
	await get_tree().process_frame
	
	# 设置奖励数据
	reward_instance.set_reward_data(reward_data)
	
	# 连接返回地图信号
	reward_instance.return_to_map_requested.connect(_on_return_to_map)
	
	print("测试奖励场景已显示")

# 当选择敌人后
func _on_enemy_selected(enemy_data):
	print("场景管理器: 收到敌人选择信号，准备创建战斗场景")
	
	# 移除敌人选择场景
	var enemy_select = null
	if get_node_or_null("EnemySelectScene"):
		enemy_select = get_node("EnemySelectScene")
	elif get_tree().root.has_node("Main/EnemySelectScene"):
		enemy_select = get_tree().root.get_node("Main/EnemySelectScene")
	
	if enemy_select:
		print("场景管理器: 移除敌人选择场景")
		enemy_select.queue_free()
	
	# 延迟创建游戏场景，确保旧场景已清理完毕
	await get_tree().process_frame
	
	print("场景管理器: 创建战斗场景，敌人: ", enemy_data.name)
	
	# 创建游戏场景
	var game_instance = battle_scene.instantiate()
	game_instance.name = "GameScene"
	
	# 根据不同情况添加到不同节点
	if get_tree().root.has_node("Main"):
		get_tree().root.get_node("Main").add_child(game_instance)
	else:
		add_child(game_instance)
	
	# 确保UI更新
	await get_tree().process_frame
	
	# 获取游戏管理器并设置敌人
	var game_manager = game_instance.get_node("GameManager")
	if game_manager == null:
		push_error("无法获取GameManager节点")
		return
		
	current_game_manager = game_manager
	
	# 设置敌人数据
	print("场景管理器: 设置敌人数据: ", enemy_data.name)
	game_manager.set_enemy_data(enemy_data)
	
	# 连接游戏信号
	game_manager.game_over.connect(_on_game_over)
	game_manager.enemy_defeated.connect(_on_enemy_defeated)
	
	# 在地图模式下，胜利和商店操作都返回地图
	game_manager.enter_shop_requested.connect(_on_return_to_map)
	game_manager.return_to_game_requested.connect(_on_return_to_map)
	
	print("场景管理器: 战斗场景准备完成")
	
	# 确保地图场景已隐藏
	var map_scene = null
	if get_node_or_null("NodeMapScene"):
		map_scene = get_node("NodeMapScene")
		map_scene.visible = false
	elif get_tree().root.has_node("Main/NodeMapScene"):
		map_scene = get_tree().root.get_node("Main/NodeMapScene")
		map_scene.visible = false

# 游戏结束处理
func _on_game_over(win: bool):
	if win:
		print("场景管理器: 玩家获胜!")
		# 胜利处理已在_on_enemy_defeated中完成
	else:
		print("场景管理器: 玩家失败!")
		
		# 获取游戏场景
		var battle_scene_instance = get_node_or_null("GameScene")
		if !battle_scene_instance and get_tree().root.has_node("Main/GameScene"):
			battle_scene_instance = get_tree().root.get_node("Main/GameScene")
			
		if battle_scene_instance:
			# 移除游戏场景
			battle_scene_instance.queue_free()
		
		# 在地图模式下，失败后返回地图或创建新地图
		# 而不是返回已被销毁的主菜单
		_reset_current_floor_map()

# 敌人击败处理
func _on_enemy_defeated():
	print("场景管理器: 收到敌人击败信号，开始处理战利品")
	
	# 获取当前游戏场景 - 修改获取路径方式
	var battle_scene_instance = null
	if get_node_or_null("GameScene"):
		# 场景管理器直接子节点
		battle_scene_instance = get_node("GameScene")
	elif get_tree().root.has_node("Main/GameScene"):
		# 主场景路径
		battle_scene_instance = get_tree().root.get_node("Main/GameScene")
	elif get_parent().get_node_or_null("GameScene"):
		# 父节点的子节点
		battle_scene_instance = get_parent().get_node("GameScene")
	
	if !battle_scene_instance:
		print("警告: 没有找到游戏场景，使用游戏场景的备用方案")
		return
	
	print("场景管理器: 找到游戏场景，准备创建奖励场景")
	
	# 获取奖励数据
	var reward_data = {}
	if current_game_manager:
		print("场景管理器: 找到游戏管理器，处理奖励计算")
		# 处理奖励计算
		current_game_manager.process_victory_rewards()
		
		# 获取敌人奖励信息
		if current_game_manager.current_enemy != null:
			if current_game_manager.current_enemy is Enemy:
				print("场景管理器: 从Enemy类型敌人获取奖励数据")
				reward_data = current_game_manager.current_enemy.get_rewards()
			elif typeof(current_game_manager.current_enemy) == TYPE_DICTIONARY and current_game_manager.current_enemy.has("rewards"):
				print("场景管理器: 从敌人字典获取奖励数据")
				reward_data = current_game_manager.current_enemy.rewards
			else:
				# 默认奖励
				print("场景管理器: 使用默认奖励数据")
				reward_data = {"currency": 50}
		else:
			print("警告: 游戏管理器中没有有效的敌人对象")
			reward_data = {"currency": 50}
	else:
		print("警告: 场景管理器中没有找到游戏管理器引用")
	
	print("场景管理器: 准备隐藏游戏场景并创建奖励场景")
	
	# 隐藏游戏场景
	battle_scene_instance.visible = false
	
	# 验证奖励场景资源是否加载成功
	if reward_scene == null:
		print("严重错误: 奖励场景资源未成功加载")
		return
		
	print("场景管理器: 创建奖励场景实例")
	
	# 创建奖励场景
	var reward_instance = reward_scene.instantiate()
	reward_instance.name = "RewardScene"
	
	# 根据不同情况添加到不同节点
	if get_tree().root.has_node("Main"):
		# 添加到Main节点下
		get_tree().root.get_node("Main").add_child(reward_instance)
	else:
		# 添加到当前节点下
		add_child(reward_instance)
	
	await get_tree().process_frame
	
	# 验证奖励场景是否成功添加
	var reward_scene_check = null
	if get_node_or_null("RewardScene"):
		reward_scene_check = get_node("RewardScene")
	elif get_tree().root.has_node("Main/RewardScene"):
		reward_scene_check = get_tree().root.get_node("Main/RewardScene")
	
	if reward_scene_check == null:
		print("严重错误: 奖励场景实例未成功添加到场景树")
		return
		
	print("场景管理器: 设置奖励数据")
	
	# 设置奖励数据
	reward_instance.set_reward_data(reward_data)
	
	# 连接返回地图信号 - 在地图模式下，战斗胜利后返回地图
	reward_instance.return_to_map_requested.connect(_on_return_to_map)
	
	print("场景管理器: 奖励场景准备完成，奖励数据:", reward_data)

# 进入商店 - 在地图模式下，从地图直接进入商店
func _on_enter_shop():
	print("场景管理器: 进入商店")
	
	# 隐藏所有可能的场景
	var scenes_to_hide = ["GameScene", "NodeMapScene", "EnemySelectScene", "RewardScene"]
	for scene_name in scenes_to_hide:
		var scene = get_node_or_null(scene_name)
		if scene:
			scene.visible = false
		elif get_tree().root.has_node("Main/" + scene_name):
			get_tree().root.get_node("Main/" + scene_name).visible = false
	
	# 创建商店场景
	var shop_instance = shop_scene.instantiate()
	shop_instance.name = "ShopScene"
	
	# 根据不同情况添加到不同节点
	if get_tree().root.has_node("Main"):
		get_tree().root.get_node("Main").add_child(shop_instance)
	else:
		add_child(shop_instance)
	
	# 在地图模式下，商店操作后都返回地图
	shop_instance.connect("return_to_game", _on_return_to_map)
	shop_instance.connect("shop_enemy_select", _on_return_to_map)
	
	print("场景管理器: 商店场景已创建")

# 重置当前楼层地图（在战斗失败后调用）
func _reset_current_floor_map():
	print("场景管理器: 重置当前楼层地图")
	
	# 移除现有地图场景
	var map_scene = get_node_or_null("NodeMapScene")
	if map_scene:
		map_scene.queue_free()
	elif get_tree().root.has_node("Main/NodeMapScene"):
		get_tree().root.get_node("Main/NodeMapScene").queue_free()
	
	# 创建新的地图场景
	var map_instance = node_map_scene.instantiate()
	map_instance.name = "NodeMapScene"
	
	# 根据不同情况添加到不同节点
	if get_tree().root.has_node("Main"):
		get_tree().root.get_node("Main").add_child(map_instance)
	else:
		add_child(map_instance)
	
	# 连接地图场景信号
	map_instance.node_selected.connect(_on_map_node_selected)
	map_instance.map_completed.connect(_on_map_completed)
	
	print("场景管理器: 地图已重置")

# 从商店进入敌人选择 - 在地图模式下不需要
func _on_shop_enemy_select():
	# 在地图模式下，重定向到返回地图
	_on_return_to_map()
