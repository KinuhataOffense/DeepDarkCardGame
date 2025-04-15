extends Node

# 预加载场景
var rogue_level_scene = preload("res://scenes/rogue/rogue_level_scene.tscn")
var battle_scene = preload("res://scenes/battle/battle_scene.tscn")
var shop_scene = preload("res://scenes/shop/shop_scene.tscn")
var reward_scene = preload("res://scenes/reward/reward_scene.tscn")

# 引用节点
@onready var game_manager = get_node_or_null("/root/GameManager")
@onready var player_stats = get_node_or_null("/root/PlayerStats")

# 静态变量，用于保存游戏状态以便在场景重载时恢复
static var saved_game_started = false  # 游戏是否已经开始
static var saved_level_index = 0       # 保存的关卡索引
static var saved_enemies = []          # 保存的敌人列表
static var saved_enemy_index = 0       # 保存的敌人索引
static var saved_level_completed = false # 关卡是否已完成
static var saved_enemy_data = null     # 保存的当前敌人数据
static var saved_from_shop = false     # 是否从商店返回

# 变量
var levels_data = []
var current_level_index = 0
var current_level_instance = null
var current_enemy_data = null
var from_shop = false
var game_started = false
var rogue_mode_scene = null

# 信号
signal game_completed
signal return_to_main_menu

func _ready():
	print("RogueManager: 开始初始化")
	
	# 基本初始化代码
	setup_scene_references()
	
	# 加载关卡数据
	_load_levels_data()
	
	# 使用游戏数据和场景路径初始化
	_initialize_game_data()
	
	# 检查是否应该从静态变量恢复状态
	if saved_game_started:
		print("RogueManager: 检测到已保存的游戏状态，从静态变量恢复")
		# 恢复游戏状态
		game_started = saved_game_started
		current_level_index = saved_level_index
		from_shop = saved_from_shop
		current_enemy_data = saved_enemy_data
		
		# 从静态变量恢复场景状态
		call_deferred("_restore_from_static")
	else:
		print("RogueManager: 未检测到已保存的游戏状态，开始新游戏")
		# 开始新游戏
		call_deferred("start_game")
	
	print("RogueManager: 初始化完成")

# 设置场景引用
func setup_scene_references():
	# 获取GameManager引用
	if !game_manager:
		game_manager = get_node_or_null("/root/GameManager")
	
	# 保存当前场景的引用
	rogue_mode_scene = get_parent()
	if !rogue_mode_scene:
		push_error("RogueManager: 无法获取父节点")
		return
	
	print("RogueManager: 场景引用已保存，父节点是:" + rogue_mode_scene.name)

# 从JSON加载关卡数据
func _load_levels_data():
	# 清空现有数据
	levels_data.clear()
	
	var file = FileAccess.open("res://data/rogue_levels.json", FileAccess.READ)
	if not file:
		push_error("无法打开关卡数据文件")
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error == OK:
		levels_data = json.data
		print("成功加载了 ", levels_data.size(), " 个关卡数据")
	else:
		push_error("解析关卡JSON数据失败: " + json.get_error_message())

# 开始Rogue模式游戏
func start_game():
	print("RogueManager: 开始Rogue模式游戏")
	
	# 设置游戏模式为Rogue模式
	if game_manager:
		game_manager.set_game_mode(GameManager.GameMode.ROGUE)
	
	# 重置静态变量
	saved_game_started = false
	saved_level_index = 0
	saved_enemies = []
	saved_enemy_index = 0
	saved_level_completed = false
	saved_enemy_data = null
	saved_from_shop = false
	
	# 重置游戏状态
	current_level_index = 0
	from_shop = false
	game_started = true
	
	# 清除旧的关卡实例
	if current_level_instance:
		if current_level_instance.get_parent():
			current_level_instance.get_parent().remove_child(current_level_instance)
		current_level_instance.queue_free()
		current_level_instance = null
	
	# 确保关卡数据已加载
	if levels_data.size() == 0:
		_load_levels_data()
		print("RogueManager: 在start_game中加载了关卡数据")
	
	# 保存初始状态到静态变量
	saved_game_started = true  # 设置为true，这样重新加载场景时可以从这个状态恢复
	_save_to_static()
	
	# 显示当前关卡
	_show_current_level()

# 显示当前关卡
func _show_current_level():
	print("RogueManager: 开始显示关卡，当前索引: ", current_level_index)
	
	# 检查是否还有关卡
	if levels_data.size() == 0:
		push_error("RogueManager: 关卡数据为空，尝试重新加载")
		_load_levels_data()
		if levels_data.size() == 0:
			push_error("RogueManager: 无法加载关卡数据，无法显示关卡")
			return
	
	if current_level_index >= levels_data.size():
		print("RogueManager: 所有关卡完成，游戏结束")
		emit_signal("game_completed")
		return
	
	print("RogueManager: 显示关卡 ", current_level_index + 1)
	
	# 获取当前关卡数据
	var level_data = levels_data[current_level_index]
	if level_data == null:
		push_error("RogueManager: 关卡数据为空，无法显示关卡")
		return
		
	print("RogueManager: 关卡数据:", level_data.level_name if level_data.has("level_name") else "未命名关卡")
	
	# 如果已有关卡场景，移除它
	if current_level_instance != null:
		if current_level_instance.get_parent():
			current_level_instance.get_parent().remove_child(current_level_instance)
		current_level_instance.queue_free()
		current_level_instance = null
	
	# 创建新的关卡场景
	current_level_instance = rogue_level_scene.instantiate()
	if current_level_instance == null:
		push_error("RogueManager: 无法实例化关卡场景")
		return
		
	print("RogueManager: 已创建关卡场景实例")
	
	# 确保rogue_mode_scene已设置
	if rogue_mode_scene == null:
		rogue_mode_scene = get_parent()
		if rogue_mode_scene == null:
			push_error("RogueManager: 无法获取父节点")
			return
	
	# 将关卡场景添加到Rogue模式场景中
	rogue_mode_scene.add_child(current_level_instance)
	print("RogueManager: 已将关卡场景添加到: " + rogue_mode_scene.name)
	
	# 初始化关卡场景
	current_level_instance.initialize(level_data, from_shop)
	print("RogueManager: 关卡场景已初始化")
	
	# 确保场景可见
	current_level_instance.visible = true
	
	# 断开旧信号连接
	_disconnect_level_signals()
	
	# 连接关卡场景的信号
	current_level_instance.connect("start_battle", _on_level_start_battle)
	current_level_instance.connect("return_requested", _on_level_return_requested)
	current_level_instance.connect("level_completed", _on_level_completed)
	print("RogueManager: 关卡场景信号已连接")
	
	# 保存当前状态到静态变量
	_save_to_static()

# 断开关卡信号连接
func _disconnect_level_signals():
	if current_level_instance:
		if current_level_instance.is_connected("start_battle", _on_level_start_battle):
			current_level_instance.disconnect("start_battle", _on_level_start_battle)
		
		if current_level_instance.is_connected("return_requested", _on_level_return_requested):
			current_level_instance.disconnect("return_requested", _on_level_return_requested)
		
		if current_level_instance.is_connected("level_completed", _on_level_completed):
			current_level_instance.disconnect("level_completed", _on_level_completed)
			
		print("RogueManager: 断开了关卡场景信号")

# 进入战斗
func _enter_battle(enemy_data):
	# 保存当前敌人数据
	current_enemy_data = enemy_data
	
	# 保存状态到静态变量
	_save_to_static()
	
	print("进入战斗，敌人: ", enemy_data.name if enemy_data and enemy_data.has("name") else "未知敌人")
	
	# 确保BOSS正确标记
	if enemy_data:
		if current_level_instance and current_level_instance.selected_enemies.size() > 0:
			# 获取当前关卡数据
			var level_data = current_level_instance.get_level_data()
			
			# 如果是最后一个敌人，检查是否应该是BOSS
			var is_last_enemy = current_level_instance.current_enemy_index >= current_level_instance.selected_enemies.size()
			if is_last_enemy and enemy_data.has("id") and level_data and level_data.has("boss_pool") and enemy_data.id in level_data.boss_pool:
				enemy_data.is_boss = true
				print("进入战斗，标记为BOSS: ", enemy_data.name)
			else:
				print("进入战斗，普通敌人: ", enemy_data.name)
	
	# 保存当前Rogue场景路径
	if game_manager and rogue_mode_scene:
		game_manager.save_rogue_scene_info("res://scenes/rogue/rogue_mode_scene.tscn")
		print("RogueManager: 已保存Rogue场景路径")
	
	# 移除当前关卡场景
	if current_level_instance:
		current_level_instance.hide()
	
	# 使用GameManager的方法进入战斗场景
	if game_manager:
		# 设置敌人数据
		game_manager.set_enemy_data(enemy_data)
		
		# 切换到战斗场景
		game_manager.switch_to_scene(battle_scene)
		
		# 避免使用get_tree().process_frame
		await game_manager.process_one_frame()
		
		# 连接战斗结束信号
		var battle_scene_instance = game_manager.get_current_scene()
		if battle_scene_instance:
			var battle_manager = battle_scene_instance.get_node_or_null("BattleManager")
			if battle_manager:
				if battle_manager.is_connected("enemy_defeated", _on_battle_enemy_defeated):
					battle_manager.disconnect("enemy_defeated", _on_battle_enemy_defeated)
				
				if battle_manager.is_connected("player_defeated", _on_battle_player_defeated):
					battle_manager.disconnect("player_defeated", _on_battle_player_defeated)
					
				battle_manager.connect("enemy_defeated", _on_battle_enemy_defeated)
				battle_manager.connect("player_defeated", _on_battle_player_defeated)
	else:
		push_error("无法找到GameManager节点")

# 进入商店
func _enter_shop():
	print("进入商店")
	from_shop = true
	
	# 保存状态到静态变量
	_save_to_static()
	
	# 移除当前关卡场景
	if current_level_instance:
		current_level_instance.hide()
	
	# 使用GameManager的方法进入商店场景
	if game_manager:
		game_manager.switch_to_scene(shop_scene)
		
		# 避免使用get_tree().process_frame
		await game_manager.process_one_frame()
		
		# 连接商店场景的返回信号
		var shop_instance = game_manager.get_current_scene()
		if shop_instance:
			if shop_instance.is_connected("exit_shop", _on_shop_exit):
				shop_instance.disconnect("exit_shop", _on_shop_exit)
			
			shop_instance.connect("exit_shop", _on_shop_exit)
	else:
		push_error("无法找到GameManager节点")

# 处理关卡完成
func _on_level_completed(level_id):
	print("关卡完成: ", level_id)
	
	# 确保level_id有效
	if level_id.is_empty():
		push_error("RogueManager: 收到空的level_id")
	
	# 获取当前关卡的数据
	var current_level_data = null
	if current_level_index < levels_data.size():
		current_level_data = levels_data[current_level_index]
		
	print("RogueManager: 当前关卡索引: ", current_level_index, ", 总关卡数: ", levels_data.size())
	if current_level_data:
		print("RogueManager: 当前关卡ID: ", current_level_data.level_id if current_level_data.has("level_id") else "无ID")
	
	# 进入下一个关卡
	current_level_index += 1
	from_shop = false
	
	print("RogueManager: 新关卡索引: ", current_level_index)
	
	# 显示下一个关卡或结束游戏
	if current_level_index < levels_data.size():
		print("RogueManager: 有下一关卡，准备显示")
		call_deferred("_show_current_level")
	else:
		print("RogueManager: 所有关卡完成，游戏结束")
		emit_signal("game_completed")
		# 游戏完成，返回主菜单
		call_deferred("emit_signal", "return_to_main_menu")

# 处理关卡场景的开始战斗信号
func _on_level_start_battle(enemy_data):
	_enter_battle(enemy_data)

# 处理关卡场景的返回请求信号
func _on_level_return_requested():
	emit_signal("return_to_main_menu")

# 处理战斗胜利
func _on_battle_enemy_defeated():
	print("Rogue模式: 战斗胜利")
	
	# 确保保存了Rogue场景路径
	if game_manager:
		game_manager.save_rogue_scene_info("res://scenes/rogue/rogue_mode_scene.tscn")
		print("RogueManager: 战斗胜利后已保存Rogue场景路径")
	
	# 检查当前敌人数据
	if not current_enemy_data:
		push_error("RogueManager: 当前敌人数据为空")
		_enter_shop()
		return
	
	# 记录敌人被击败的状态
	print("Rogue模式: 记录敌人被击败:", current_enemy_data.name if current_enemy_data.has("name") else "未知敌人")
	
	# 增加关卡场景中的敌人索引，以确保它反映已击败的敌人
	# 这里不直接使用current_level_instance是因为它可能暂时不可用，而是在返回时通过current_enemy_data来更新
	
	# 检查是否是BOSS战胜利
	var is_boss_victory = current_enemy_data.has("is_boss") and current_enemy_data.is_boss
	print("Rogue模式: 当前敌人是BOSS:", is_boss_victory)
	
	# 使用GameManager的reward_scene处理奖励显示
	if game_manager:
		# 准备奖励数据
		var reward_data = {
			"currency": current_enemy_data.rewards.currency if current_enemy_data.has("rewards") and current_enemy_data.rewards.has("currency") else 50,
			"from_rogue_mode": true, # 标记奖励来自Rogue模式
			"is_boss_reward": is_boss_victory # 标记是否是BOSS奖励
		}
		
		print("Rogue模式: 准备奖励数据:", reward_data)
		
		# 使用GameManager的show_reward_scene方法
		game_manager.show_reward_scene(reward_data)
	else:
		push_error("RogueManager: 无法找到GameManager节点")
		_enter_shop() # 如果无法显示奖励界面，则直接进入商店

# 处理从奖励场景返回
func _on_reward_return_to_map():
	print("Rogue模式: 从奖励场景返回")
	
	# 自检：确保RogueManager已正确初始化
	if !game_started:
		print("Rogue模式: RogueManager尚未初始化，进行初始化")
		_load_levels_data()
		game_started = true
	
	# 恢复引用
	_restore_references()
	
	# 检查当前敌人是否是BOSS
	var is_boss_defeated = current_enemy_data != null and current_enemy_data.has("is_boss") and current_enemy_data.is_boss
	print("Rogue模式: 检查是否击败了BOSS:", is_boss_defeated)
	
	# 在击败敌人后直接进入商店
	_enter_shop()

# 恢复引用
func _restore_references():
	# 检查并设置rogue_mode_scene引用
	if !rogue_mode_scene or !is_instance_valid(rogue_mode_scene):
		rogue_mode_scene = get_parent()
		print("Rogue模式: 重新获取父节点作为rogue_mode_scene: ", rogue_mode_scene.name if rogue_mode_scene else "未找到")
	
	# 检查game_manager是否存在
	if !game_manager:
		game_manager = get_node_or_null("/root/GameManager")
		print("Rogue模式: 重新获取GameManager引用: ", "成功" if game_manager else "失败")
		
		if !game_manager:
			push_error("RogueManager: 无法找到GameManager节点，无法继续")
			return false
	
	return true

# 处理战斗失败
func _on_battle_player_defeated():
	print("战斗失败")
	
	# 结束游戏，返回主菜单
	emit_signal("return_to_main_menu")

# 处理商店离开
func _on_shop_exit():
	print("离开商店，返回关卡")
	
	# 使用GameManager返回到Rogue模式场景
	if game_manager:
		var rogue_mode_scene_res = load("res://scenes/rogue/rogue_mode_scene.tscn")
		game_manager.switch_to_scene(rogue_mode_scene_res)
		
		# 避免使用get_tree().process_frame
		await game_manager.process_one_frame()
		
		# 重新显示关卡场景
		call_deferred("_restore_level_scene")
	else:
		push_error("无法找到GameManager节点")

# 恢复关卡场景
func _restore_level_scene():
	# 获取当前场景实例
	var current_scene = game_manager.get_current_scene()
	if !current_scene:
		push_error("RogueManager: 无法获取当前场景")
		return
	
	print("RogueManager: 正在恢复关卡场景到当前场景:", current_scene.name)
	
	# 如果当前关卡实例为空，使用_restore_from_static重建
	if !current_level_instance or !is_instance_valid(current_level_instance):
		print("RogueManager: 当前关卡实例不存在，使用恢复状态函数重建")
		_restore_from_static()
		return
	
	# 如果实例已经有父节点，先移除
	if current_level_instance.get_parent():
		current_level_instance.get_parent().remove_child(current_level_instance)
		print("RogueManager: 从旧父节点移除关卡场景")
	
	# 将关卡场景添加到当前场景
	current_scene.add_child(current_level_instance)
	
	# 显示关卡场景并更新状态
	current_level_instance.show()
	print("RogueManager: 关卡场景已添加到当前场景并显示")
	
	# 检查是否需要更新关卡状态
	if current_level_instance.has_method("initialize"):
		var current_level_data = get_current_level_data()
		if current_level_data:
			# 使用from_shop=true以保持敌人列表不变
			current_level_instance.initialize(current_level_data, true, false)
			print("RogueManager: 关卡场景已重新初始化（从商店返回）")
	
	# 检查是否最后一个敌人是BOSS且已击败
	var is_boss_defeated = false
	if current_enemy_data and current_enemy_data.has("is_boss") and current_enemy_data.is_boss:
		is_boss_defeated = true
		print("RogueManager: 检测到已击败BOSS:", current_enemy_data.name if current_enemy_data.has("name") else "未知BOSS")
				
	# 检查是否所有敌人都已击败或BOSS已击败
	if is_boss_defeated or (current_level_instance.current_enemy_index >= current_level_instance.selected_enemies.size() - 1 and current_level_instance.selected_enemies.size() > 0):
		print("RogueManager: 检测到关卡已完成，更新关卡完成状态")
		current_level_instance.update_completion_status(true)
	
	# 断开旧信号连接并重新连接信号
	_disconnect_level_signals()
	
	# 连接关卡场景的信号
	current_level_instance.connect("start_battle", _on_level_start_battle)
	current_level_instance.connect("return_requested", _on_level_return_requested)
	current_level_instance.connect("level_completed", _on_level_completed)
	print("RogueManager: 关卡场景信号已连接")

# 获取当前关卡数据
func get_current_level_data():
	if current_level_index < levels_data.size():
		return levels_data[current_level_index]
	return null

# 恢复关卡状态 - 从战斗或奖励场景返回时调用 (保留此函数以保持兼容性)
func _restore_level_state():
	print("RogueManager: _restore_level_state被调用，转发到_restore_from_static")
	_restore_from_static()

# 保存当前状态到静态变量
func _save_to_static():
	print("RogueManager: 保存当前状态到静态变量")
	saved_game_started = game_started
	saved_level_index = current_level_index
	saved_from_shop = from_shop
	saved_enemy_data = current_enemy_data
	
	# 保存当前关卡的敌人状态
	if current_level_instance and is_instance_valid(current_level_instance):
		saved_enemies = current_level_instance.selected_enemies.duplicate(true)
		saved_enemy_index = current_level_instance.current_enemy_index
		saved_level_completed = current_level_instance.level_completed
		print("RogueManager: 已保存关卡状态 - 敌人数量:", saved_enemies.size(), 
			  "当前索引:", saved_enemy_index, 
			  "关卡完成:", saved_level_completed)
	else:
		print("RogueManager: 当前关卡实例无效，无法保存敌人状态")

# 从静态变量恢复状态
func _restore_from_static():
	print("RogueManager: 从静态变量恢复状态")
	
	# 确保关卡数据已加载
	if levels_data.size() == 0:
		print("RogueManager: 关卡数据为空，尝试加载")
		_load_levels_data()
		if levels_data.size() == 0:
			push_error("RogueManager: 无法加载关卡数据，回退到开始新游戏")
			call_deferred("start_game")
			return
	
	# 检查关卡索引是否有效
	if current_level_index >= levels_data.size():
		push_error("RogueManager: 无效的关卡索引，无法恢复")
		current_level_index = 0
		saved_level_index = 0
		call_deferred("start_game")
		return
	
	# 获取当前关卡数据
	var level_data = levels_data[current_level_index]
	if !level_data:
		push_error("RogueManager: 当前关卡索引处没有有效数据")
		call_deferred("start_game")
		return
	
	print("RogueManager: 恢复关卡:", level_data.level_name if level_data.has("level_name") else "未命名关卡")
	
	# 清除旧的关卡实例
	if current_level_instance:
		if current_level_instance.get_parent():
			current_level_instance.get_parent().remove_child(current_level_instance)
		current_level_instance.queue_free()
		current_level_instance = null
	
	# 创建新的关卡场景实例
	current_level_instance = rogue_level_scene.instantiate()
	if !current_level_instance:
		push_error("RogueManager: 无法实例化关卡场景")
		call_deferred("start_game")
		return
	
	# 确保rogue_mode_scene有效
	if !rogue_mode_scene or !is_instance_valid(rogue_mode_scene):
		rogue_mode_scene = get_parent()
		if !rogue_mode_scene:
			push_error("RogueManager: 无法获取父节点")
			call_deferred("start_game")
			return
	
	# 将关卡场景添加到Rogue模式场景中
	rogue_mode_scene.add_child(current_level_instance)
	print("RogueManager: 已将关卡场景添加到: " + rogue_mode_scene.name)
	
	# 从静态变量恢复敌人数据
	if saved_enemies.size() > 0:
		current_level_instance.selected_enemies = saved_enemies.duplicate(true)
		current_level_instance.current_enemy_index = saved_enemy_index
		print("RogueManager: 恢复了敌人列表，敌人数量:", saved_enemies.size(), "，当前索引:", saved_enemy_index)
	
	# 检查是否最后一个敌人是BOSS且已击败
	var is_boss_defeated = false
	if current_enemy_data and current_enemy_data.has("is_boss") and current_enemy_data.is_boss:
		is_boss_defeated = true
		print("RogueManager: 检测到已击败BOSS:", current_enemy_data.name if current_enemy_data.has("name") else "未知BOSS")
	
	# 计算关卡完成状态
	var is_completed = saved_level_completed
	
	# 只有当击败BOSS或所有敌人都被击败时才标记关卡为已完成
	if is_boss_defeated or (saved_enemy_index >= saved_enemies.size() - 1 and saved_enemies.size() > 0):
		is_completed = true
		print("RogueManager: 计算得出关卡已完成")
	
	# 初始化关卡场景
	current_level_instance.initialize(level_data, true, is_completed)
	print("RogueManager: 关卡场景已初始化，已完成状态:", is_completed)
	
	# 确保场景可见
	current_level_instance.visible = true
	
	# 断开旧信号连接并重新连接信号
	_disconnect_level_signals()
	
	# 连接关卡场景的信号
	current_level_instance.connect("start_battle", _on_level_start_battle)
	current_level_instance.connect("return_requested", _on_level_return_requested)
	current_level_instance.connect("level_completed", _on_level_completed)
	print("RogueManager: 关卡场景信号已连接")

# 初始化游戏数据
func _initialize_game_data():
	print("RogueManager: 初始化游戏数据")
	
	# 确保levels_data被正确加载
	if levels_data.size() == 0:
		_load_levels_data()
		print("RogueManager: 在_initialize_game_data中加载了关卡数据")
	
	# 打印当前状态信息，帮助调试
	print("RogueManager: 当前游戏状态 - saved_game_started:", saved_game_started,
		  ", levels_data.size():", levels_data.size(),
		  ", current_level_instance:", "有效" if is_instance_valid(current_level_instance) else "无效或空")
	
	# 注意：不在此函数中调用恢复状态的操作，这些操作已经在_ready中处理
