extends Control

# 地图配置
var layers_count = 7           # 地图层数
var nodes_per_layer = [1, 3, 4, 4, 4, 3, 1]  # 每层节点数量
var horizontal_spacing = 100   # 水平间隔（减小以使地图更紧凑）
var vertical_spacing = 100     # 垂直间隔（减小以使地图更紧凑）
var edge_thickness = 3         # 边线粗细
var current_floor = 1          # 当前层数

# 节点及连接
var map_nodes = []             # 所有地图节点
var node_connections = []      # 节点连接关系
var current_node_id = -1       # 当前节点ID
var available_nodes = []       # 可用节点ID列表

# 节点场景引用
var map_node_scene = preload("res://scenes/map/map_node.tscn")

# UI引用
@onready var map_title = $MapTitle
@onready var map_container = $MapContainer
@onready var nodes_container = $MapContainer/NodeContainer
@onready var edges_container = $MapContainer/EdgeContainer
@onready var player_health_label = $PlayerInfo/HealthLabel
@onready var player_gold_label = $PlayerInfo/GoldLabel
@onready var return_button = $ReturnButton

# 信号
signal node_selected(node_type, node_data)
signal map_completed

func _ready():
	# 设置地图标题
	map_title.text = "地下城 - 第%s层" % current_floor
	
	# 连接返回按钮信号
	return_button.pressed.connect(_on_return_button_pressed)
	
	# 更新玩家信息
	update_player_info()
	
	# 尝试加载保存的地图状态
	if !load_map_state():
		# 如果没有保存的状态，生成新地图
		generate_map()
	
	# 确保当前节点被选中并可见
	ensure_current_node_selected()

# 更新玩家信息
func update_player_info():
	var game_manager = get_node("/root/Main/GameManager")
	if game_manager:
		var player_data = game_manager.player_data
		player_health_label.text = "生命: %d/%d" % [player_data.current_health, player_data.max_health]
		player_gold_label.text = "金币: %d" % player_data.currency
	else:
		# 默认值，用于测试
		
		player_health_label.text = "生命: 80/80"
		player_gold_label.text = "金币: 100"

# 生成地图
func generate_map():
	# 清除现有地图
	clear_map()
	
	# 创建节点
	create_nodes()
	
	# 创建节点连接
	create_connections()
	
	# 更新节点状态
	update_node_states()

# 清除现有地图
func clear_map():
	# 清除节点容器
	for child in nodes_container.get_children():
		nodes_container.remove_child(child)
		child.queue_free()
	
	# 清除边线容器
	for child in edges_container.get_children():
		edges_container.remove_child(child)
		child.queue_free()
	
	# 重置数据
	map_nodes.clear()
	node_connections.clear()
	available_nodes.clear()
	current_node_id = -1

# 创建节点
func create_nodes():
	print("开始创建节点，layers_count=", layers_count, ", nodes_per_layer=", nodes_per_layer)
	
	var node_id = 0
	var mapnode = load("res://scripts/map/map_node.gd")
	
	# 为了更像《以撒的结合》的房间布局，我们用网格方式排列节点
	var grid_width = 7  # 地图网格宽度
	var grid_height = 7  # 地图网格高度
	var used_positions = {}  # 记录已使用的位置
	
	# 检查每层节点数量是否正确
	if nodes_per_layer.size() != layers_count:
		push_error("节点层数配置错误: layers_count=", layers_count, ", nodes_per_layer.size()=", nodes_per_layer.size())
		# 修正层数和节点数组，确保一致
		layers_count = min(layers_count, nodes_per_layer.size())
	
	print("开始创建节点，总层数: ", layers_count)
	
	# 遍历每一层
	for layer in range(layers_count):
		var nodes_count = nodes_per_layer[layer]
		print("创建第", layer, "层节点，计划数量: ", nodes_count)
		
		# 如果是第一层（起点）
		if layer == 0:
			# 起点放在中间偏下位置
			var start_pos = Vector2(0, 0)
			_create_node_at_position(node_id, mapnode.NodeType.START, start_pos, layer, used_positions)
			print("创建起点节点: id=", node_id, ", position=", start_pos)
			node_id += 1
			continue
			
		# 如果是最后一层（Boss）
		if layer == layers_count - 1:
			# Boss房间放在中间偏上位置
			var boss_pos = Vector2(0, -vertical_spacing * 3)
			_create_node_at_position(node_id, mapnode.NodeType.BOSS, boss_pos, layer, used_positions)
			print("创建Boss节点: id=", node_id, ", position=", boss_pos)
			node_id += 1
			continue
		
		# 中间层随机分布节点
		var available_positions = _get_available_positions(grid_width, grid_height, layer, used_positions)
		
		if available_positions.size() == 0:
			print("警告: 第", layer, "层没有可用的位置")
			continue
		
		# 随机洗牌可用位置列表
		available_positions.shuffle()
		
		# 取前N个位置用于当前层
		var positions_for_layer = available_positions.slice(0, min(nodes_count, available_positions.size()))
		
		print("第", layer, "层实际创建节点数量: ", positions_for_layer.size())
		
		# 在选定位置创建节点
		for i in range(min(nodes_count, positions_for_layer.size())):
			var pos = positions_for_layer[i]
			var node_type = determine_node_type(layer, i, nodes_count)
			_create_node_at_position(node_id, node_type, pos, layer, used_positions)
			print("创建节点: id=", node_id, ", layer=", layer, ", type=", node_type, ", position=", pos)
			node_id += 1
	
	print("节点创建完成，总数: ", map_nodes.size())

# 在指定位置创建节点
func _create_node_at_position(node_id, node_type, pos, layer, used_positions):
	var mapnode = load("res://scripts/map/map_node.gd")
	
	# 记录位置已使用
	used_positions[pos] = true
	
	# 创建节点实例
	var node_instance = map_node_scene.instantiate()
	if node_instance == null:
		push_error("无法实例化地图节点场景")
		return
		
	nodes_container.add_child(node_instance)
	node_instance.initialize(node_id, node_type, pos, layer)
	node_instance.position = pos
	
	# 连接节点信号
	node_instance.node_clicked.connect(_on_node_clicked)
	
	# 添加到节点列表
	map_nodes.append(node_instance)

# 获取可用的位置
func _get_available_positions(grid_width, grid_height, layer, used_positions):
	var positions = []
	
	# 根据层级调整位置范围
	var vertical_offset = -vertical_spacing * (layer - layers_count/2)
	
	# 创建网格位置
	for x in range(0, grid_width/2 + 1):
		for y in range(0, grid_height/2 + 1):
			# 跳过中心位置，因为它通常是起点
			if x == 0 and y == 0:
				continue
				
			var pos = Vector2(x * horizontal_spacing, y * vertical_spacing + vertical_offset)
			
			# 如果位置未被使用，添加到可用位置列表
			if not used_positions.has(pos):
				# 根据距中心的距离设置权重，使节点集中在中间
				var distance = sqrt(x*x + y*y)
				if distance <= layer * 0.7:
					positions.append(pos)
	
	return positions

# 确定节点类型
func determine_node_type(layer, index, layer_nodes):
	var mapnode = load("res://scripts/map/map_node.gd")
	
	# 起点和终点
	if layer == 0:
		return mapnode.NodeType.START
	elif layer == layers_count - 1:
		return mapnode.NodeType.BOSS
	
	# 其他节点类型随机分配
	var possible_types = []
	
	# 中间层分配不同类型的节点
	if layer < layers_count - 2:
		# 常规层
		possible_types = [
			mapnode.NodeType.ENEMY,
			mapnode.NodeType.ENEMY,
			mapnode.NodeType.EVENT,
			mapnode.NodeType.SHOP,
			mapnode.NodeType.REST
		]
		
		# 第三层有精英敌人
		if layer == 3:
			possible_types.append(mapnode.NodeType.ELITE)
			possible_types.append(mapnode.NodeType.ELITE)
		
		# 宝箱节点稀少
		if randf() < 0.1:
			possible_types.append(mapnode.NodeType.TREASURE)
	else:
		# 倒数第二层主要是精英和休息
		possible_types = [
			mapnode.NodeType.ELITE,
			mapnode.NodeType.REST,
			mapnode.NodeType.SHOP
		]
	
	# 随机选择类型
	return possible_types[randi() % possible_types.size()]

# 创建节点连接
func create_connections():
	var mapnode = load("res://scripts/map/map_node.gd")
	
	print("开始创建节点连接，节点总数: ", map_nodes.size())
	
	# 为每一层的节点创建连接
	for layer in range(layers_count - 1):
		var current_layer_start = 0
		var next_layer_start = 0
		
		# 计算当前层和下一层的起始索引
		for l in range(layer):
			current_layer_start += nodes_per_layer[l]
		for l in range(layer + 1):
			next_layer_start += nodes_per_layer[l]
		
		# 当前层节点数
		var current_layer_nodes = nodes_per_layer[layer]
		# 下一层节点数
		var next_layer_nodes = nodes_per_layer[layer + 1]
		
		print("处理第", layer, "层到第", layer+1, "层的连接: 起始索引=", current_layer_start, "/", next_layer_start)
		
		# 确保索引不超出map_nodes范围
		if current_layer_start >= map_nodes.size():
			print("警告: 当前层起始索引超出范围: ", current_layer_start, "/", map_nodes.size())
			continue
			
		if next_layer_start >= map_nodes.size():
			print("警告: 下一层起始索引超出范围: ", next_layer_start, "/", map_nodes.size())
			continue
		
		# 为每个当前层节点创建连接
		for i in range(current_layer_nodes):
			var current_node_idx = current_layer_start + i
			
			# 检查索引是否有效
			if current_node_idx >= map_nodes.size():
				print("警告: 当前节点索引超出范围: ", current_node_idx, "/", map_nodes.size())
				continue
			
			print("处理节点", current_node_idx, "的连接")
			
			# 确定连接数量 (1-2)
			var connections_count = 1 + (randi() % 2 if next_layer_nodes > 1 else 0)
			connections_count = min(connections_count, next_layer_nodes)
			
			# 可能的下一层节点索引范围
			var possible_next_indices = []
			for j in range(next_layer_nodes):
				var next_idx = next_layer_start + j
				if next_idx < map_nodes.size():  # 确保索引有效
					possible_next_indices.append(next_idx)
			
			# 如果没有有效的下一层节点，跳过
			if possible_next_indices.size() == 0:
				print("警告: 当前节点没有有效的下一层节点: ", current_node_idx)
				continue
			
			print("节点", current_node_idx, "可能的连接目标: ", possible_next_indices)
			
			# 随机选择连接节点
			var selected_connections = []
			for _j in range(connections_count):
				if possible_next_indices.size() > 0:
					var random_idx = randi() % possible_next_indices.size()
					var target_node_idx = possible_next_indices[random_idx]
					
					print("尝试连接节点", current_node_idx, "到", target_node_idx)
					
					# 确保索引有效
					if target_node_idx < map_nodes.size():
						# 确定连接方向
						var direction = _determine_connection_direction(current_node_idx, target_node_idx)
						
						# 添加连接
						selected_connections.append(target_node_idx)
						map_nodes[current_node_idx].add_connection(target_node_idx, direction)
						
						# 添加反向连接
						var reverse_direction = _get_opposite_direction(direction)
						map_nodes[target_node_idx].add_connection(current_node_idx, reverse_direction)
						
						# 记录连接关系
						node_connections.append([current_node_idx, target_node_idx])
						
						print("成功连接节点", current_node_idx, "到", target_node_idx)
					else:
						print("警告: 目标节点索引无效: ", target_node_idx)
					
					# 移除已选择的节点，避免重复连接
					possible_next_indices.remove_at(random_idx)
				else:
					print("无更多可连接的节点")
					break
			
			# 打印已建立的连接
			print("节点", current_node_idx, "已建立的连接: ", selected_connections)
		
		# 确保每个下一层节点至少有一个连接
		if layer == 0 and next_layer_nodes > 0:
			print("确保第一层的每个节点都有连接")
			
			# 获取第一层节点索引（通常是0）
			var first_layer_node_idx = 0
			if first_layer_node_idx >= map_nodes.size():
				print("警告: 第一层节点索引无效: ", first_layer_node_idx)
				continue
				
			for j in range(next_layer_nodes):
				var target_idx = next_layer_start + j
				
				# 确保索引有效
				if target_idx >= map_nodes.size():
					print("警告: 目标节点索引超出范围: ", target_idx, "/", map_nodes.size())
					continue
				
				# 检查节点是否已有连接
				var has_connection = false
				for conn in node_connections:
					if conn[1] == target_idx:
						has_connection = true
						break
				
				if !has_connection:
					print("为节点", target_idx, "添加缺失的连接")
					
					var direction = _determine_connection_direction(first_layer_node_idx, target_idx)
					map_nodes[first_layer_node_idx].add_connection(target_idx, direction)
					
					var reverse_direction = _get_opposite_direction(direction)
					map_nodes[target_idx].add_connection(first_layer_node_idx, reverse_direction)
					
					node_connections.append([first_layer_node_idx, target_idx])
					
					print("添加连接成功: ", first_layer_node_idx, " -> ", target_idx)
	
	print("节点连接创建完成，连接总数: ", node_connections.size())

# 确定连接方向
func _determine_connection_direction(from_id, to_id):
	var mapnode = load("res://scripts/map/map_node.gd")
	
	# 确保索引有效
	if from_id >= map_nodes.size() or to_id >= map_nodes.size():
		print("警告: 确定连接方向时索引超出范围: from_id=", from_id, ", to_id=", to_id, ", map_nodes.size()=", map_nodes.size())
		return mapnode.DoorDirection.BOTTOM
	
	var from_node = map_nodes[from_id]
	var to_node = map_nodes[to_id]
	
	var from_pos = from_node.position
	var to_pos = to_node.position
	
	# 计算方向向量
	var direction = to_pos - from_pos
	
	# 确定主要方向
	if abs(direction.x) > abs(direction.y):
		# 水平方向为主
		if direction.x > 0:
			return mapnode.DoorDirection.RIGHT
		else:
			return mapnode.DoorDirection.LEFT
	else:
		# 垂直方向为主
		if direction.y > 0:
			return mapnode.DoorDirection.BOTTOM
		else:
			return mapnode.DoorDirection.TOP

# 获取相反的方向
func _get_opposite_direction(direction):
	var mapnode = load("res://scripts/map/map_node.gd")
	
	match direction:
		mapnode.DoorDirection.TOP:
			return mapnode.DoorDirection.BOTTOM
		mapnode.DoorDirection.RIGHT:
			return mapnode.DoorDirection.LEFT
		mapnode.DoorDirection.BOTTOM:
			return mapnode.DoorDirection.TOP
		mapnode.DoorDirection.LEFT:
			return mapnode.DoorDirection.RIGHT
	
	return mapnode.DoorDirection.BOTTOM

# 绘制连接线（保留但不实际使用，由门替代）
func draw_connections():
	# 连接已经由门表示，不需要额外的线条
	pass

# 更新节点状态
func update_node_states():
	var mapnode = load("res://scripts/map/map_node.gd")
	
	print("更新节点状态，当前节点ID: ", current_node_id)
	
	# 初始时，所有节点都设为隐藏状态
	for i in range(map_nodes.size()):
		var node = map_nodes[i]
		# 设置所有节点为锁定状态
		node.set_state(mapnode.NodeState.LOCKED)
		# 隐藏远处节点
		node.set_visibility(false)
	
	# 如果有当前节点，设置当前节点和相邻节点的状态
	if current_node_id >= 0 and current_node_id < map_nodes.size():
		# 设置当前节点为当前状态并可见
		map_nodes[current_node_id].set_state(mapnode.NodeState.CURRENT)
		map_nodes[current_node_id].set_visibility(true)
	else:
		# 如果没有当前节点，使用起点作为当前节点
		for i in range(map_nodes.size()):
			var node = map_nodes[i]
			if node.node_type == mapnode.NodeType.START:
				node.set_state(mapnode.NodeState.CURRENT)
				current_node_id = node.node_id
				node.set_visibility(true)
				break
	
	# 更新可用节点
	update_available_nodes()
	
	# 更新路径和节点可见性
	update_path_visibility()

# 更新可用节点列表
func update_available_nodes():
	var mapnode = load("res://scripts/map/map_node.gd")
	available_nodes.clear()
	
	# 如果当前节点有效
	if current_node_id >= 0 and current_node_id < map_nodes.size():
		var current_node = map_nodes[current_node_id]
		
		print("当前节点:", current_node_id, ", 连接节点:", current_node.connected_nodes)
		
		# 将当前节点的连接添加到可用列表
		for target_id in current_node.connected_nodes:
			if target_id < map_nodes.size():
				var target_node = map_nodes[target_id]
				
				# 只有未访问的节点可以变为可用
				if target_node.node_state == mapnode.NodeState.LOCKED:
					target_node.set_state(mapnode.NodeState.AVAILABLE)
					available_nodes.append(target_id)
					
					# 确保相邻节点可见
					target_node.set_visibility(true)
					
					print("设置节点", target_id, "为可用状态")
	else:
		print("警告: 更新可用节点时，当前节点ID无效: ", current_node_id)

# 更新路径和节点可见性
func update_path_visibility():
	var mapnode = load("res://scripts/map/map_node.gd")
	
	# 更新所有连接线的可见性
	for connection in node_connections:
		var from_id = connection[0]
		var to_id = connection[1]
		
		# 如果起点是当前节点或已访问节点，终点是可用节点，则显示该路径
		var is_visible = _is_path_available(from_id, to_id)
		
		# 在这里您可以根据需要绘制连接线或更新其可见性
		# 例如，您可以在EdgeContainer中创建/更新一条线
		if is_visible:
			# 如果需要，可以在这里添加连接线的可见性更新逻辑
			pass

# 检查路径是否可用
func _is_path_available(from_id, to_id):
	var mapnode = load("res://scripts/map/map_node.gd")
	
	# 确保索引有效
	if from_id < 0 or to_id < 0 or from_id >= map_nodes.size() or to_id >= map_nodes.size():
		print("警告: 检查路径可用性时索引超出范围: from_id=", from_id, ", to_id=", to_id, ", map_nodes.size()=", map_nodes.size())
		return false
	
	# 如果起点是当前节点且终点是可用节点，则路径可用
	if from_id == current_node_id:
		for available_id in available_nodes:
			if to_id == available_id:
				return true
	
	# 或者如果是已访问路径
	var from_node = map_nodes[from_id]
	var to_node = map_nodes[to_id]
	if from_node.node_state == mapnode.NodeState.VISITED and to_node.node_state == mapnode.NodeState.VISITED:
		return true
	
	return false

# 节点点击事件处理
func _on_node_clicked(node):
	var mapnode = load("res://scripts/map/map_node.gd")
	
	# 检查节点是否为null或无效
	if node == null:
		push_error("点击的节点为null")
		return
		
	var node_id = node.node_id
	print("节点被点击: id=", node_id, ", type=", node.get_node_type_string())
	
	# 检查节点是否可用（相邻节点）
	var is_available = false
	for available_id in available_nodes:
		if node_id == available_id:
			is_available = true
			break
	
	# 如果节点不可用（不是相邻节点），则不处理
	if !is_available:
		print("节点不可用（不是相邻节点）: id=", node_id)
		# 可以添加一个提示或反馈效果
		# 例如播放无效点击音效或显示提示
		return
	
	# 播放选择音效
	# AudioManager.play_sfx("door_open")
	
	# 更新当前节点和已访问节点
	if current_node_id >= 0 and current_node_id < map_nodes.size():
		map_nodes[current_node_id].set_state(mapnode.NodeState.VISITED)
	
	# 设置新的当前节点
	current_node_id = node_id
	node.set_state(mapnode.NodeState.CURRENT)
	
	# 更新可用节点
	update_available_nodes()
	
	# 更新路径和节点可见性
	update_path_visibility()
	
	# 检查是否到达终点
	if node.node_type == mapnode.NodeType.BOSS:
		print("恭喜！已到达Boss节点！")
		emit_signal("map_completed")
	
	# 发出节点选择信号
	emit_signal("node_selected", node.node_type, node.node_data)
	
	# 执行对应的处理逻辑
	proceed_to_encounter(node.node_type, node.node_data)

# 返回按钮事件处理
func _on_return_button_pressed():
	# 返回主菜单或上一个场景
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# 添加到游戏流程中
func proceed_to_encounter(node_type, node_data):
	var mapnode = load("res://scripts/map/map_node.gd")
	
	# 保存当前地图状态
	save_map_state()
	
	# 根据节点类型获取场景和处理方式
	match node_type:
		mapnode.NodeType.ENEMY, mapnode.NodeType.ELITE, mapnode.NodeType.BOSS:
			print("处理敌人节点，类型: ", node_type)
			
			# 获取敌人数据
			var enemy_data = _get_enemy_data_for_node_type(node_type)
			if enemy_data:
				# 输出调试信息
				print("成功获取敌人数据: ", enemy_data.name)
				
				# 首先尝试查找场景管理器
				var scene_manager = get_node_or_null("/root/SceneManager")
				if scene_manager:
					print("使用场景管理器处理敌人选择")
					
					# 通知场景管理器处理节点选择
					emit_signal("node_selected", node_type, enemy_data)
					
					# 等待一帧确保信号传递
					await get_tree().process_frame
					
					# 隐藏当前地图
					self.visible = false
					return
				
				# 如果找不到场景管理器，回退到传统方法
				print("找不到场景管理器，尝试自行处理敌人选择")
				
				# 加载敌人选择场景
				var enemy_select_scene = load("res://scenes/enemy_select_scene.tscn")
				if enemy_select_scene:
					var instance = enemy_select_scene.instantiate()
					# 设置实例名称以便后续查找
					instance.name = "EnemySelectScene"
					
					# 初始化为自动模式，传递敌人数据
					instance.initialize(false, true, enemy_data)
					
					# 隐藏当前场景
					self.visible = false
					
					# 连接信号到本地处理函数
					instance.enemy_selected.connect(_on_enemy_selected_direct)
					
					# 添加敌人选择场景
					get_tree().root.add_child(instance)
					
					print("进入敌人选择场景（自动模式），敌人：", enemy_data.name)
					return
			
			# 如果无法获取敌人数据，回退到传统方式
			print("无法获取敌人数据，使用传统方式切换场景")
			get_tree().change_scene_to_file("res://scenes/enemy_select_scene.tscn")
			
		mapnode.NodeType.SHOP:
			print("进入商店场景")
			get_tree().change_scene_to_file("res://scenes/shop_scene.tscn")
		mapnode.NodeType.REST:
			print("进入休息场景")
			get_tree().change_scene_to_file("res://scenes/rest_scene.tscn")
		mapnode.NodeType.EVENT:
			print("进入事件场景")
			get_tree().change_scene_to_file("res://scenes/event_scene.tscn")
		mapnode.NodeType.TREASURE:
			print("进入宝箱场景")
			get_tree().change_scene_to_file("res://scenes/treasure_scene.tscn")

# 直接处理敌人选择信号（当没有场景管理器时）
func _on_enemy_selected_direct(enemy_data):
	print("直接处理敌人选择信号：", enemy_data.name)
	
	# 移除敌人选择场景
	var enemy_select = get_tree().root.get_node_or_null("EnemySelectScene")
	if enemy_select:
		print("移除敌人选择场景")
		enemy_select.queue_free()
	else:
		print("警告：找不到敌人选择场景")
	
	# 延迟创建游戏场景
	await get_tree().process_frame
	
	# 切换到游戏场景
	var battle_scene = load("res://scenes/battle_scene.tscn")
	if battle_scene:
		print("创建战斗场景")
		
		# 创建游戏场景
		var game_instance = battle_scene.instantiate()
		game_instance.name = "BattleScene"
		get_tree().root.add_child(game_instance)
		
		# 确保UI更新
		await get_tree().process_frame
		
		# 设置敌人数据
		var game_manager = game_instance.get_node_or_null("GameManager")
		if game_manager:
			print("设置敌人数据: ", enemy_data.name)
			game_manager.set_enemy_data(enemy_data)
		else:
			push_error("无法获取GameManager节点")
	else:
		push_error("无法加载游戏场景")

# 根据节点类型获取合适的敌人数据
func _get_enemy_data_for_node_type(node_type):
	var mapnode = load("res://scripts/map/map_node.gd")
	var game_manager = get_node("/root/game_manager")
	
	if game_manager:
		match node_type:
			mapnode.NodeType.ENEMY:
				# 获取普通敌人
				return game_manager.get_random_enemy(false)
				
			mapnode.NodeType.ELITE:
				# 获取精英敌人
				return game_manager.get_random_enemy(true)
				
			mapnode.NodeType.BOSS:
				# 获取Boss敌人
				return game_manager.get_random_boss()
	else:
		# 如果没有游戏管理器，使用自定义的默认敌人数据
		var default_enemy = {
			"id": "default_enemy",
			"name": "路径阻碍者 - 骑士幽魂",
			"description": "一个守护地下城通道的幽灵骑士。",
			"health": 80,
			"round_limit": 5,
			"required_score": 15,
			"difficulty": 1,
			"rewards": {
				"currency": 10
			},
			"effects": [
				{
					"trigger": "round_start",
					"frequency": 2,
					"type": "mark_card",
					"description": "每两回合标记一张手牌，若该轮未使用则受到10点伤害"
				}
			]
		}
		
		# 根据节点类型调整敌人难度
		if node_type == mapnode.NodeType.ELITE:
			default_enemy.name = "精英守卫 - 黑暗骑士"
			default_enemy.health = 120
			default_enemy.required_score = 25
			default_enemy.difficulty = 2
			default_enemy.rewards.currency = 20
		elif node_type == mapnode.NodeType.BOSS:
			default_enemy.name = "黑暗领主 - 亡灵君王"
			default_enemy.health = 200
			default_enemy.required_score = 50
			default_enemy.difficulty = 3
			default_enemy.rewards.currency = 50
		
		return default_enemy
	
	return null

# 保存地图状态
func save_map_state():
	# 保存当前地图状态，以便返回时恢复
	var game_manager = get_node("/root/Main/GameManager")
	if game_manager:
		var map_state = {
			"current_floor": current_floor,
			"current_node_id": current_node_id,
			"nodes_state": []
		}
		
		# 保存每个节点的状态
		for node in map_nodes:
			map_state.nodes_state.append({
				"id": node.node_id,
				"type": node.node_type,
				"state": node.node_state,
				"position": {"x": node.position.x, "y": node.position.y},
				"connections": node.connected_nodes.duplicate()
			})
		
		# 保存到游戏管理器
		game_manager.save_map_state(map_state)

# 确保当前节点被选中并可见
func ensure_current_node_selected():
	var mapnode = load("res://scripts/map/map_node.gd")
	
	# 设置当前节点
	if current_node_id < 0 or current_node_id >= map_nodes.size():
		# 如果当前节点无效，查找起点或之前访问过的节点作为当前节点
		for i in range(map_nodes.size()):
			if map_nodes[i].node_type == mapnode.NodeType.START and map_nodes[i].node_state != mapnode.NodeState.VISITED:
				current_node_id = i
				break
			elif map_nodes[i].node_state == mapnode.NodeState.VISITED and i > current_node_id:
				# 选择最后一个已访问的节点
				current_node_id = i
	
	# 更新节点状态
	update_node_states()
	
	print("当前选中节点: ", current_node_id, " 类型: ", map_nodes[current_node_id].get_node_type_string() if current_node_id >= 0 and current_node_id < map_nodes.size() else "无效")

# 加载地图状态
func load_map_state():
	var game_manager = get_node("/root/Main/GameManager")
	if game_manager:
		var map_state = game_manager.get_map_state()
		if map_state:
			current_floor = map_state.current_floor
			current_node_id = map_state.current_node_id
			
			# 设置地图标题
			map_title.text = "地下城 - 第%s层" % current_floor
			
			# 重建地图节点和连接
			generate_map()
			
			# 根据保存的状态恢复节点状态
			for i in range(min(map_nodes.size(), map_state.nodes_state.size())):
				var saved_node = map_state.nodes_state[i]
				if i < map_nodes.size():
					map_nodes[i].set_state(saved_node.state)
			
			print("成功加载地图状态，当前节点ID: ", current_node_id)
			return true
	
	print("没有找到保存的地图状态，将生成新地图")
	return false 
