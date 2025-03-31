extends Node  
class_name GameManager  

# 引用到核心节点  
@onready var player_stats = $"../PlayerStats"

# 游戏状态  
enum GameState { PLAYER_TURN, ENEMY_TURN, SHOP, GAME_OVER }  
var current_state: GameState = GameState.PLAYER_TURN  
var current_enemy = null  
var current_round: int = 1  
var turns_remaining: int = 3  
var score_required: int = 0  

# 倍率和奖励系统  
var score_multiplier: float = 1.0  
var currency: int = 0  

# 信号  
signal enemy_defeated  
signal game_over(win)  
signal enter_shop_requested  
signal return_to_game_requested  

# 添加玩家数据
var player_data = {
	"max_health": 100,
	"current_health": 100,
	"currency": 100
}

# 添加地图系统相关变量
var current_map_state = null
var current_floor_level = 1
var current_map_node = null

# 游戏初始化  
func _ready():  
	
	# 初始化游戏  
	call_deferred("initialize_game")  # 使用call_deferred确保所有节点都已准备好  
	
func initialize_game():  
	# 初始化游戏状态  
	current_state = GameState.PLAYER_TURN  	
	


# 随机事件触发  
func trigger_random_event():  
	var random_value = randf()  
	if random_value < 0.25:  
		# 正面事件  
		player_stats.heal(10)  
	elif random_value < 0.5:  
		# 中性事件  
		player_stats.take_damage(5)  

	
# 降低得分倍率（用于敌人效果）  
func reduce_score_multiplier(factor: float):  
	score_multiplier *= factor  
	
# 商店系统相关
var current_shop_items: Array = []

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
	
# 生成下一个敌人  
func spawn_next_enemy():  
	# 简化起见，这里只实现一个示例敌人  
	var enemy_data = {  
		"name": "失落的王",  
		"description": "被初火腐蚀的统治者，他的力量源自破碎的王冠。",  
		"health": 250,  
		"round_limit": 8,  
		"required_score": 400,  
		"effects": [  
			{  
				"trigger": "round_start",  
				"frequency": 3,  
				"type": "disable_magic_cards",  
				"description": "使你下一轮无法使用魔法牌"  
			}  
		]  
	}  
	
	current_enemy = Enemy.new()  
	current_enemy.initialize(enemy_data)  
	score_required = current_enemy.required_score  
	
	# 更新UI  
	update_enemy_ui()  
	
# 更新敌人UI  
func update_enemy_ui():  
	pass

# 设置游戏的敌人数据
func set_enemy_data(enemy_data):
	# 如果没有敌人数据，使用默认数据
	if not enemy_data:
		print("警告: 未提供敌人数据，使用默认敌人")
		return
		
	# 创建新敌人
	current_enemy = Enemy.new()
	current_enemy.initialize(enemy_data)
	score_required = current_enemy.required_score
	
	# 打印敌人信息
	print("加载敌人:", current_enemy.enemy_name)
	print("击败条件: 需要", score_required, "分")
	print("回合限制:", current_enemy.round_limit, "回合")
	
	# 重置游戏状态
	current_round = 1
	turns_remaining = 3
	
	# 更新UI
	update_enemy_ui()
	
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

# 游戏胜利时的奖励处理
func process_victory_rewards():
	# 检查敌人对象和rewards属性是否存在
	if current_enemy == null:
		print("警告: 当前没有敌人对象")
		return
		
	# 检查是否达到击败敌人所需分数
	if player_stats.current_score < score_required:
		print("警告: 未达到击败敌人所需分数，不能领取奖励")
		return
		
	print("玩家击败敌人，处理奖励")
		
	# 检查敌人的rewards属性并添加到玩家数据
	if current_enemy.has_method("get_rewards"):
		# 如果敌人类有获取奖励的方法
		var rewards = current_enemy.get_rewards()
		if rewards and rewards.has("currency"):
			player_stats.currency += rewards.currency
			print("玩家获得", rewards.currency, "货币")
	elif typeof(current_enemy) == TYPE_DICTIONARY and current_enemy.has("rewards"):
		# 如果敌人是字典形式
		if current_enemy.rewards.has("currency"):
			player_stats.currency += current_enemy.rewards.currency
			print("玩家获得", current_enemy.rewards.currency, "货币")
	else:
		# 如果没有奖励属性，给予固定奖励
		print("警告: 敌人没有rewards属性，给予固定奖励")
		player_stats.currency += 50
		print("玩家获得50货币")
	
	# 更新玩家数据，确保同步
	player_data.currency = player_stats.currency
	
	# 在地图模式下，胜利后通过场景管理器处理后续流程
	print("GameManager: 胜利奖励处理完成，等待场景管理器切换到奖励场景")

# 游戏失败处理
func process_defeat():
	# 游戏失败的逻辑处理
	print("游戏失败，玩家将返回地图并重置当前楼层")
	
	# 在地图模式下，失败后返回地图并重置当前楼层
	print("GameManager: 失败处理完成，等待场景管理器将玩家返回地图")

# 添加地图状态保存和加载功能
func save_map_state(map_state):
	current_map_state = map_state
	print("地图状态已保存: 当前层级=", map_state.current_floor, "，当前节点=", map_state.current_node_id)
	
	# 确保玩家数据同步
	if player_stats:
		player_data.currency = player_stats.currency
		player_data.current_health = player_stats.health
		print("玩家数据已同步: 生命=", player_data.current_health, "，货币=", player_data.currency)

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

# 处理地图节点事件
func handle_map_node_event(node_type, node_data):
	print("处理地图节点事件: 类型=", node_type)
	
	# 根据节点类型执行相应操作
	match node_type:
		# 假设这里MapNode.NodeType定义与map_node.gd中的enum相匹配
		0: # START
			print("这是起点节点")
			# 起点通常不需要特殊处理
			
		1: # ENEMY
			print("这是普通敌人节点")
			# 加载随机普通敌人
			var enemy_data = get_random_enemy(false)
			if enemy_data:
				set_enemy_data(enemy_data)
			
		2: # ELITE
			print("这是精英敌人节点")
			# 加载随机精英敌人
			var enemy_data = get_random_enemy(true)
			if enemy_data:
				set_enemy_data(enemy_data)
			
		3: # SHOP
			print("这是商店节点")
			# 进入商店
			enter_shop()
			
		4: # REST
			print("这是休息点节点")
			# 恢复一定生命值
			player_data.current_health = min(player_data.max_health, player_data.current_health + 20)
			print("玩家恢复20点生命值，当前生命: ", player_data.current_health)
			
		5: # TREASURE
			print("这是宝箱节点")
			# 获得随机奖励
			var reward = randi() % 50 + 20
			player_data.currency += reward
			print("玩家获得", reward, "货币")
			
		6: # EVENT
			print("这是事件节点")
			# 触发随机事件
			trigger_random_event()
			
		7: # BOSS
			print("这是Boss节点")
			# 加载随机Boss敌人
			var enemy_data = get_random_boss()
			if enemy_data:
				set_enemy_data(enemy_data)
				
		8: # END
			print("这是终点节点")
			# 完成当前层级，进入下一层
			current_floor_level += 1
			print("进入下一层级: ", current_floor_level)

# 获取随机敌人数据
func get_random_enemy(is_elite: bool):
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
			return suitable_enemies[randi() % suitable_enemies.size()]
	
	print("未找到合适的敌人")
	return null

# 获取随机Boss敌人数据
func get_random_boss():
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
		var boss_enemies = []
		
		# 筛选Boss敌人
		for enemy in enemies:
			if enemy.has("is_boss") and enemy.is_boss:
				boss_enemies.append(enemy)
		
		# 如果有Boss敌人，随机选择一个
		if boss_enemies.size() > 0:
			return boss_enemies[randi() % boss_enemies.size()]
	
	print("未找到Boss敌人")
	return null
