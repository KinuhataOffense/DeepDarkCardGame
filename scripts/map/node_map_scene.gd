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
	
	# 检查每层节点数量是否正确
	if nodes_per_layer.size() != layers_count:
		push_error("节点层数配置错误: layers_count=", layers_count, ", nodes_per_layer.size()=", nodes_per_layer.size())
		layers_count = min(layers_count, nodes_per_layer.size())
	
	# 计算容器尺寸和中心点
	var container_size = map_container.size
	var center_x = container_size.x / 2
	var center_y = container_size.y / 2
	
	# 计算每层垂直位置
	var layer_height = container_size.y / (layers_count + 1)
	
	# 创建起点节点
	var start_pos = Vector2(center_x, container_size.y - layer_height)
	_create_node_at_position(node_id, mapnode.NodeType.START, start_pos, 0, {})
	node_id += 1
	
	# 创建中间层节点
	for layer in range(1, layers_count - 1):
		var nodes_count = nodes_per_layer[layer]
		var layer_y = container_size.y - (layer_height * (layer + 1))
		
		# 计算水平位置
		var horizontal_step = container_size.x / (nodes_count + 1)
		var positions = []
		
		for i in range(nodes_count):
			var x = horizontal_step * (i + 1)
			positions.append(Vector2(x, layer_y))
		
		# 根据层数调整节点类型分布
		for i in range(nodes_count):
			var node_type = determine_node_type(layer, i, nodes_count)
			_create_node_at_position(node_id, node_type, positions[i], layer, {})
			node_id += 1
	
	# 创建Boss节点
	var boss_pos = Vector2(center_x, layer_height)
	_create_node_at_position(node_id, mapnode.NodeType.BOSS, boss_pos, layers_count - 1, {})
	
	print("节点创建完成，总数: ", map_nodes.size())

# 在指定位置创建节点
func _create_node_at_position(node_id, node_type, pos, layer, used_positions):
	var mapnode = load("res://scripts/map/map_node.gd")
	print("[node_map_scene.gd:_create_node_at_position] 创建节点: id=", node_id, ", type=", node_type, ", position=", pos, ", layer=", layer)
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
	
	# 基于容器尺寸(1024x500)计算位置
	var container_width = 1024
	var container_height = 500
	var center_x = container_width / 2
	var center_y = container_height / 2
	
	# 计算每层垂直位置 - 均匀分布在容器内
	var layer_height = container_height / (layers_count + 1)
	var vertical_pos = layer_height * (layer + 1)
	
	# 创建网格位置 - 水平均匀分布
	var horizontal_step = container_width / (grid_width + 1)
	for x in range(1, grid_width + 1):
		var horizontal_pos = horizontal_step * x
		var pos = Vector2(horizontal_pos - center_x, vertical_pos - center_y)
		
		# 跳过已使用的位置
		if not used_positions.has(pos):
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
	
	# 根据层数和位置策略性分配节点类型
	var type_weights = {
		mapnode.NodeType.ENEMY: 0.5,
		mapnode.NodeType.EVENT: 0.2,
		mapnode.NodeType.SHOP: 0.15,
		mapnode.NodeType.REST: 0.15
	}
	
	# 调整权重基于层数
	if layer == 3:  # 中间层增加精英敌人
		type_weights[mapnode.NodeType.ELITE] = 0.3
		type_weights[mapnode.NodeType.ENEMY] = 0.4
	elif layer >= layers_count - 2:  # 接近Boss层
		type_weights[mapnode.NodeType.ELITE] = 0.4
		type_weights[mapnode.NodeType.ENEMY] = 0.3
		type_weights[mapnode.NodeType.REST] = 0.2
		type_weights[mapnode.NodeType.SHOP] = 0.1
	
	# 宝箱节点稀少但固定
	if index == 0 and randf() < 0.1:  # 每层第一个节点有10%几率是宝箱
		return mapnode.NodeType.TREASURE
	
	# 根据权重随机选择类型
	var total_weight = 0.0
	for weight in type_weights.values():
		total_weight += weight
	
	var random_value = randf() * total_weight
	var current_weight = 0.0
	
	for type in type_weights:
		current_weight += type_weights[type]
		if random_value <= current_weight:
			return type
	
	# 默认返回敌人节点
	return mapnode.NodeType.ENEMY

# 创建节点连接
func create_connections():
	var mapnode = load("res://scripts/map/map_node.gd")
	
	print("开始创建节点连接，节点总数: ", map_nodes.size())
	
	# 为每一层的节点创建连接
	for layer in range(layers_count - 1):
		var current_layer_nodes = []
		var next_layer_nodes = []
		
		# 收集当前层和下一层节点
		for node in map_nodes:
			if node.floor_level == layer:
				current_layer_nodes.append(node)
			elif node.floor_level == layer + 1:
				next_layer_nodes.append(node)
		
		print("处理第", layer, "层到第", layer+1, "层的连接: 当前层节点=", current_layer_nodes.size(), ", 下一层节点=", next_layer_nodes.size())
		
		# 为每个当前层节点创建连接
		for current_node in current_layer_nodes:
			print("处理节点", current_node.node_id, "的连接")
			
			# 确定连接数量 (1-2)
			var connections_count = 1
			if next_layer_nodes.size() > 1 and randf() < 0.6:  # 60%几率有第二个连接
				connections_count = 2
			
			# 根据位置选择最近的节点
			var possible_targets = next_layer_nodes.duplicate()
			possible_targets.sort_custom(func(a, b): 
				return a.position.distance_to(current_node.position) < b.position.distance_to(current_node.position)
			)
			
			# 创建连接
			for i in range(min(connections_count, possible_targets.size())):
				var target_node = possible_targets[i]
				
				# 确定连接方向
				var direction = _determine_connection_direction(current_node.node_id, target_node.node_id)
				
				# 添加双向连接
				current_node.add_connection(target_node.node_id, direction)
				target_node.add_connection(current_node.node_id, _get_opposite_direction(direction))
				
				# 记录连接关系
				node_connections.append([current_node.node_id, target_node.node_id])
				
				print("成功连接节点", current_node.node_id, "到", target_node.node_id)
	
	# 确保所有下一层节点至少有一个连接
	for layer in range(layers_count - 1):
		var next_layer_nodes = []
		for node in map_nodes:
			if node.floor_level == layer + 1:
				next_layer_nodes.append(node)
		
		for target_node in next_layer_nodes:
			if target_node.connected_nodes.size() == 0:
				# 找到最近的上一层节点
				var closest_node = null
				var min_distance = INF
				
				for node in map_nodes:
					if node.floor_level == layer and node.position.distance_to(target_node.position) < min_distance:
						closest_node = node
						min_distance = node.position.distance_to(target_node.position)
				
				if closest_node:
					# 添加连接
					var direction = _determine_connection_direction(closest_node.node_id, target_node.node_id)
					closest_node.add_connection(target_node.node_id, direction)
					target_node.add_connection(closest_node.node_id, _get_opposite_direction(direction))
					node_connections.append([closest_node.node_id, target_node.node_id])
					
					print("添加缺失连接: ", closest_node.node_id, " -> ", target_node.node_id)
	
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

# 处理节点进入事件
func proceed_to_encounter(node_type, node_data):
	# 保存当前地图状态
	save_map_state()
	
	# 通知游戏管理器处理节点事件
	var gamemanager = get_node("/root/Main/GameManager")
	gamemanager.handle_map_node_event(node_type, node_data)
	
	# 发射节点选择信号
	emit_signal("node_selected", node_type, node_data)



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
