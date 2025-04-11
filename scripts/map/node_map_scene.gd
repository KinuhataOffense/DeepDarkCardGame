# node_map_scene.gd  
extends Control  

#------------------------------------------------------------------------------  
# 地图配置  
#------------------------------------------------------------------------------  
var layers_count = 7                       # 地图层数  
var nodes_per_layer = [1, 3, 4, 4, 4, 3, 1] # 每层节点数量  
var vertical_spacing = 80                  # 层间垂直距离  
var node_size = Vector2(60, 60)            # 节点大小  
var current_floor = 1                      # 当前层数  

# 节点及连接  
var map_nodes = []                         # 所有地图节点  
var node_connections = []                  # 节点连接关系  
var current_node_id = -1                   # 当前节点ID  
var available_nodes = []                   # 可用节点ID列表  

# 节点场景引用  
var map_node_scene = preload("res://scenes/map/map_node.tscn")  

#------------------------------------------------------------------------------  
# UI引用  
#------------------------------------------------------------------------------  
@onready var map_title = $MapTitle  
@onready var map_container = $MapContainer  
@onready var nodes_container = $MapContainer/NodeContainer  
@onready var edges_container = $MapContainer/EdgeContainer  
@onready var player_health_label = $PlayerInfo/HealthLabel  
@onready var player_gold_label = $PlayerInfo/GoldLabel  
@onready var return_button = $ReturnButton  

#------------------------------------------------------------------------------  
# 信号  
#------------------------------------------------------------------------------  
signal node_selected(node_type, node_data)  
signal map_completed  

#------------------------------------------------------------------------------  
# 初始化  
#------------------------------------------------------------------------------  
func _ready():  
	# 配置UI  
	map_title.text = "地下城 - 第%s层" % current_floor  
	return_button.pressed.connect(_on_return_button_pressed)  
	
	# 延迟初始化地图，确保UI已正确布局  
	call_deferred("_initialize_map")  

func _initialize_map():  
	# 更新玩家信息  
	update_player_info()  
	
	# 尝试加载保存的地图状态，否则生成新地图  
	if !load_map_state():  
		generate_map()  
	
	# 确保当前节点被选中并可见  
	ensure_current_node_selected()  

#------------------------------------------------------------------------------  
# 玩家信息  
#------------------------------------------------------------------------------  
func update_player_info():  
	var game_manager = get_node("/root/GameManager")  
	if game_manager:  
		var health = game_manager.get_player_health()  
		var max_health = game_manager.get_player_max_health()  
		var currency = game_manager.get_player_currency()  
		
		player_health_label.text = "生命: %d/%d" % [health, max_health]  
		player_gold_label.text = "金币: %d" % currency  
	else:  
		# 默认值，用于测试  
		player_health_label.text = "生命: 80/80"  
		player_gold_label.text = "金币: 100"  

#------------------------------------------------------------------------------  
# 地图生成  
#------------------------------------------------------------------------------  
func generate_map():  
	clear_map()  
	create_nodes()  
	create_connections()  
	update_node_states()  

func clear_map():  
	# 清除节点和边线  
	for child in nodes_container.get_children():  
		nodes_container.remove_child(child)  
		child.queue_free()  
	
	for child in edges_container.get_children():  
		edges_container.remove_child(child)  
		child.queue_free()  
	
	# 重置数据  
	map_nodes.clear()  
	node_connections.clear()  
	available_nodes.clear()  
	current_node_id = -1  

func create_nodes():  
	var node_id = 0  
	var MapNode = load("res://scripts/map/map_node.gd")  
	
	# 验证配置正确性  
	if nodes_per_layer.size() != layers_count:  
		print_debug("节点层数配置不匹配，调整为最小值")  
		layers_count = min(layers_count, nodes_per_layer.size())  
	
	# 获取容器尺寸  
	var container_size = map_container.size  
	
	# 计算垂直分布  
	var total_height = (layers_count - 1) * vertical_spacing  
	var top_margin = (container_size.y - total_height) / 2  
	
	# 创建起点节点（位于底部中心）  
	var start_y = container_size.y - top_margin  
	var start_x = container_size.x / 2  
	_create_node(node_id, MapNode.NodeType.START, Vector2(start_x, start_y), 0)  
	node_id += 1  
	
	# 创建中间层节点  
	for layer in range(1, layers_count - 1):  
		var nodes_in_layer = nodes_per_layer[layer]  
		var layer_y = start_y - (vertical_spacing * layer)  
		
		# 计算水平分布 - 每个节点有相等的空间  
		var layer_width = container_size.x * 0.8  # 使用80%的宽度避免节点太靠近边缘  
		var margin_x = (container_size.x - layer_width) / 2  
		var node_spacing = layer_width / (nodes_in_layer + 1)  
		
		for i in range(nodes_in_layer):  
			var node_x = margin_x + node_spacing * (i + 1)  
			var node_type = determine_node_type(layer, i, nodes_in_layer)  
			
			# 加入随机偏移，避免节点完全对齐（但保持在合理范围内）  
			var offset_x = randf_range(-node_spacing * 0.15, node_spacing * 0.15)  
			if i == 0:  # 第一个节点不向左偏移太多  
				offset_x = max(0, offset_x)  
			elif i == nodes_in_layer - 1:  # 最后一个节点不向右偏移太多  
				offset_x = min(0, offset_x)  
				
			_create_node(node_id, node_type, Vector2(node_x + offset_x, layer_y), layer)  
			node_id += 1  
	
	# 创建Boss节点（位于顶部中心）  
	var boss_y = top_margin  
	_create_node(node_id, MapNode.NodeType.BOSS, Vector2(start_x, boss_y), layers_count - 1)  

func _create_node(node_id, node_type, pos, layer):  
	# 创建节点实例  
	var node_instance = map_node_scene.instantiate()  
	if !node_instance:  
		print_debug("无法实例化地图节点场景")  
		return  
	
	nodes_container.add_child(node_instance)  
	node_instance.initialize(node_id, node_type, pos, layer)  
	node_instance.position = pos  
	
	# 连接节点信号  
	node_instance.node_clicked.connect(_on_node_clicked)  
	
	# 添加到节点列表  
	map_nodes.append(node_instance)  

func determine_node_type(layer, index, layer_nodes):  
	var MapNode = load("res://scripts/map/map_node.gd")  
	
	# 根据层和位置确定节点类型  
	var node_types = {}  
	
	# 第一层是普通敌人  
	if layer == 1:  
		node_types = {  
			MapNode.NodeType.ENEMY: 0.7,  
			MapNode.NodeType.EVENT: 0.2,  
			MapNode.NodeType.TREASURE: 0.1  
		}  
	# 中间层平衡各种类型  
	elif layer == 2 or layer == 3:  
		node_types = {  
			MapNode.NodeType.ENEMY: 0.3,  
			MapNode.NodeType.EVENT: 0.2,  
			MapNode.NodeType.SHOP: 0.2,  
			MapNode.NodeType.REST: 0.2,  
			MapNode.NodeType.ELITE: 0.1  
		}  
	# 接近Boss层增加精英敌人和休息点  
	elif layer == layers_count - 2:  
		node_types = {  
			MapNode.NodeType.ELITE: 0.3,  
			MapNode.NodeType.REST: 0.3,  
			MapNode.NodeType.SHOP: 0.2,  
			MapNode.NodeType.ENEMY: 0.2  
		}  
	# 默认配置  
	else:  
		node_types = {  
			MapNode.NodeType.ENEMY: 0.4,  
			MapNode.NodeType.EVENT: 0.2,  
			MapNode.NodeType.SHOP: 0.2,  
			MapNode.NodeType.REST: 0.2  
		}  
	
	# 确保每层至少有一个商店和休息点  
	if layer == 2 and index == 1:  
		return MapNode.NodeType.SHOP  
	if layer == 4 and index == 2:  
		return MapNode.NodeType.REST  
	
	# 根据权重随机选择类型  
	var total_weight = 0.0  
	for weight in node_types.values():  
		total_weight += weight  
	
	var random_value = randf() * total_weight  
	var cumulative_weight = 0.0  
	
	for type in node_types:  
		cumulative_weight += node_types[type]  
		if random_value <= cumulative_weight:  
			return type  
	
	# 默认为敌人节点  
	return MapNode.NodeType.ENEMY  

#------------------------------------------------------------------------------  
# 节点连接  
#------------------------------------------------------------------------------  
func create_connections():  
	var MapNode = load("res://scripts/map/map_node.gd")  
	
	# 首先收集每层的节点  
	var nodes_by_layer = []  
	for i in range(layers_count):  
		nodes_by_layer.append([])  
	
	for node in map_nodes:  
		if node.floor_level >= 0 and node.floor_level < layers_count:  
			nodes_by_layer[node.floor_level].append(node)  
	
	# 为每层创建连接  
	for layer in range(layers_count - 1):  
		var current_layer = nodes_by_layer[layer]  
		var next_layer = nodes_by_layer[layer + 1]  
		
		# 确保每个上层节点至少有一个连接到下层  
		for current_node in current_layer:  
			# 根据节点在层中的位置，寻找对应的下层节点  
			var potential_targets = []  
			
			for next_node in next_layer:  
				# 计算水平位置差异，以找到最近的节点  
				var horizontal_diff = abs(current_node.position.x - next_node.position.x)  
				
				# 计算可连接性分数（位置越近分数越高）  
				var connection_score = 1.0 / (1.0 + horizontal_diff / 100.0)  
				
				# 随机性因子，避免完全对称的图  
				var randomness = randf_range(0.8, 1.2)  
				
				potential_targets.append({  
					"node": next_node,  
					"score": connection_score * randomness  
				})  
			
			# 按分数排序  
			potential_targets.sort_custom(func(a, b): return a.score > b.score)  
			
			# 确定连接数量（1-2，基于位置）  
			var connections_count = 1  
			if potential_targets.size() > 1 and randf() < 0.7:  # 70%几率有第二个连接  
				connections_count = 2  
			
			# 创建连接  
			for i in range(min(connections_count, potential_targets.size())):  
				var target_node = potential_targets[i].node  
				
				# 避免重复连接  
				if !current_node.is_connected_to(target_node.node_id):  
					# 创建连接  
					var direction = _calculate_direction(current_node.position, target_node.position)  
					current_node.add_connection(target_node.node_id, direction)  
					
					# 添加反向连接  
					var reverse_direction = _get_opposite_direction(direction)  
					target_node.add_connection(current_node.node_id, reverse_direction)  
					
					# 记录连接  
					node_connections.append([current_node.node_id, target_node.node_id])  
	
	# 确保所有节点都有至少一个连接（除了Boss节点）  
	for layer in range(1, layers_count):  
		for node in nodes_by_layer[layer]:  
			# 如果节点没有连接到上一层  
			if !_has_connection_to_layer(node, layer - 1, nodes_by_layer):  
				# 寻找最近的上层节点  
				var closest_node = _find_closest_node_in_layer(node, nodes_by_layer[layer - 1])  
				if closest_node:  
					# 创建连接  
					var direction = _calculate_direction(closest_node.position, node.position)  
					closest_node.add_connection(node.node_id, direction)  
					
					# 添加反向连接  
					var reverse_direction = _get_opposite_direction(direction)  
					node.add_connection(closest_node.node_id, reverse_direction)  
					
					# 记录连接  
					node_connections.append([closest_node.node_id, node.node_id])  

func _calculate_direction(from_pos, to_pos):  
	var MapNode = load("res://scripts/map/map_node.gd")  
	
	# 计算方向向量  
	var direction = to_pos - from_pos  
	
	# 在地牢地图中，通常下一层是向上的  
	if direction.y < 0:  
		return MapNode.DoorDirection.TOP  
	else:  
		return MapNode.DoorDirection.BOTTOM  

func _get_opposite_direction(direction):  
	var MapNode = load("res://scripts/map/map_node.gd")  
	
	match direction:  
		MapNode.DoorDirection.TOP:  
			return MapNode.DoorDirection.BOTTOM  
		MapNode.DoorDirection.RIGHT:  
			return MapNode.DoorDirection.LEFT  
		MapNode.DoorDirection.BOTTOM:  
			return MapNode.DoorDirection.TOP  
		MapNode.DoorDirection.LEFT:  
			return MapNode.DoorDirection.RIGHT  
	
	return MapNode.DoorDirection.BOTTOM  

func _has_connection_to_layer(node, layer, nodes_by_layer):  
	for other_node in nodes_by_layer[layer]:  
		if node.is_connected_to(other_node.node_id):  
			return true  
	return false  

func _find_closest_node_in_layer(node, layer_nodes):  
	var closest_node = null  
	var min_distance = INF  
	
	for other_node in layer_nodes:  
		var distance = node.position.distance_to(other_node.position)  
		if distance < min_distance:  
			min_distance = distance  
			closest_node = other_node  
	
	return closest_node  

#------------------------------------------------------------------------------  
# 节点状态管理  
#------------------------------------------------------------------------------  
func update_node_states():  
	var MapNode = load("res://scripts/map/map_node.gd")  
	
	# 初始化所有节点为锁定状态  
	for node in map_nodes:  
		node.set_state(MapNode.NodeState.LOCKED)  
		node.set_visibility(false)  
	
	# 设置当前节点状态  
	if current_node_id >= 0 && current_node_id < map_nodes.size():  
		map_nodes[current_node_id].set_state(MapNode.NodeState.CURRENT)  
		map_nodes[current_node_id].set_visibility(true)  
	else:  
		# 如果没有当前节点，使用起点  
		for node in map_nodes:  
			if node.node_type == MapNode.NodeType.START:  
				node.set_state(MapNode.NodeState.CURRENT)  
				current_node_id = node.node_id  
				node.set_visibility(true)  
				break  
	
	# 更新可用节点和路径可见性  
	update_available_nodes()  
	update_visuals()  

func update_available_nodes():  
	var MapNode = load("res://scripts/map/map_node.gd")  
	available_nodes.clear()  
	
	# 如果有当前节点  
	if current_node_id >= 0 && current_node_id < map_nodes.size():  
		var current_node = map_nodes[current_node_id]  
		
		# 检查连接的节点  
		for connected_id in current_node.connected_nodes:  
			if connected_id >= 0 && connected_id < map_nodes.size():  
				var connected_node = map_nodes[connected_id]  
				
				# 如果是下一层的节点且未访问，标记为可用  
				if connected_node.floor_level > current_node.floor_level && connected_node.node_state == MapNode.NodeState.LOCKED:  
					connected_node.set_state(MapNode.NodeState.AVAILABLE)  
					available_nodes.append(connected_id)  
					connected_node.set_visibility(true)  

func update_visuals():  
	# 更新节点可见性  
	for node in map_nodes:  
		# 确定节点可见范围 - 当前节点、可用节点和已访问节点都可见  
		var should_be_visible = (  
			node.node_id == current_node_id ||   
			available_nodes.has(node.node_id) ||   
			node.node_state == load("res://scripts/map/map_node.gd").NodeState.VISITED  
		)  
		
		node.set_visibility(should_be_visible)  
	
	# 可以在这里添加其他视觉更新，如路径动画等  

#------------------------------------------------------------------------------  
# 节点交互  
#------------------------------------------------------------------------------  
func _on_node_clicked(node):  
	var MapNode = load("res://scripts/map/map_node.gd")  
	
	# 验证节点  
	if !node:  
		print_debug("点击的节点无效")  
		return  
	
	var node_id = node.node_id  
	
	# 检查节点是否可用  
	if !available_nodes.has(node_id):  
		# 提供反馈，节点不可用  
		return  
	
	# 更新当前节点状态  
	if current_node_id >= 0 && current_node_id < map_nodes.size():  
		map_nodes[current_node_id].set_state(MapNode.NodeState.VISITED)  
	
	# 设置新的当前节点  
	current_node_id = node_id  
	node.set_state(MapNode.NodeState.CURRENT)  
	
	# 更新地图状态  
	update_available_nodes()  
	update_visuals()  
	
	# 检查是否到达Boss  
	if node.node_type == MapNode.NodeType.BOSS:  
		emit_signal("map_completed")  
	
	# 获取节点数据并打印调试信息
	var node_data = _get_node_data(node.node_type)  
	print("节点", node_id, "被点击 (类型:", MapNode.get_node_type_name(node.node_type), ")")
	
	# 发送节点选择信号  
	emit_signal("node_selected", node.node_type, node_data)  
	
	# 保存当前地图状态  
	save_map_state()  
	
	# 直接调用GameManager处理地图节点，不仅仅依赖信号连接
	var game_manager = get_node("/root/GameManager")  
	if game_manager:  
		# 先处理节点事件
		game_manager.handle_map_node_event(node.node_type, node_data)  
		
		# 再直接调用_on_map_node_selected确保场景切换逻辑执行
		game_manager._on_map_node_selected(node.node_type, node_data)

func _get_node_data(node_type):  
	# 根据节点类型创建相应的数据  
	var MapNode = load("res://scripts/map/map_node.gd")  
	
	match node_type:  
		MapNode.NodeType.ENEMY:  
			return null  # 由GameManager决定具体敌人  
		MapNode.NodeType.ELITE:  
			return null  # 由GameManager决定具体精英敌人  
		MapNode.NodeType.BOSS:  
			return null  # 由GameManager决定具体Boss  
		MapNode.NodeType.SHOP:  
			return {"shop_level": current_floor}  
		MapNode.NodeType.REST:  
			return {"healing_amount": 20 + current_floor * 5}  
		MapNode.NodeType.TREASURE:  
			return {"min_gold": 20, "max_gold": 30 + current_floor * 10}  
		MapNode.NodeType.EVENT:  
			return {"event_level": current_floor}  
		_:  
			return {}  

func _on_return_button_pressed():  
	var game_manager = get_node("/root/GameManager")  
	if game_manager:  
		# 使用GameManager中的场景切换功能，而不是直接调用场景变换  
		var main_menu_scene = preload("res://scenes/MainMenu.tscn")  
		game_manager.switch_to_scene(main_menu_scene)  
	else:  
		# 如果找不到GameManager，使用备用方法  
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")  

#------------------------------------------------------------------------------  
# 状态保存和加载  
#------------------------------------------------------------------------------  
func save_map_state():  
	var game_manager = get_node("/root/GameManager")  
	if game_manager:  
		var map_state = {  
			"current_floor": current_floor,  
			"current_node_id": current_node_id,  
			"nodes_state": [],  
			"connections": node_connections.duplicate()  
		}  
		
		# 保存每个节点的状态  
		for node in map_nodes:  
			map_state.nodes_state.append({  
				"id": node.node_id,  
				"type": node.node_type,  
				"state": node.node_state,  
				"position": {"x": node.position.x, "y": node.position.y},  
				"floor_level": node.floor_level,  
				"connections": node.connected_nodes.duplicate()  
			})  
		
		game_manager.save_map_state(map_state)  

func load_map_state():  
	var game_manager = get_node("/root/GameManager")  
	if !game_manager:  
		return false  
	
	var map_state = game_manager.get_map_state()  
	if !map_state:  
		return false  
	
	# 设置地图状态  
	current_floor = map_state.current_floor  
	current_node_id = map_state.current_node_id  
	map_title.text = "地下城 - 第%s层" % current_floor  
	
	# 清除已有地图  
	clear_map()  
	
	# 重建地图节点  
	var MapNode = load("res://scripts/map/map_node.gd")  
	
	# 首先创建所有节点  
	for saved_node in map_state.nodes_state:  
		var node_pos = Vector2(saved_node.position.x, saved_node.position.y)  
		var node_instance = map_node_scene.instantiate()  
		
		nodes_container.add_child(node_instance)  
		node_instance.initialize(  
			saved_node.id,   
			saved_node.type,   
			node_pos,   
			saved_node.floor_level  
		)  
		node_instance.position = node_pos  
		node_instance.set_state(saved_node.state)  
		node_instance.node_clicked.connect(_on_node_clicked)  
		
		map_nodes.append(node_instance)  
	
	# 然后恢复节点连接  
	for i in range(map_nodes.size()):  
		if i < map_state.nodes_state.size():  
			var saved_connections = map_state.nodes_state[i].connections  
			for connected_id in saved_connections:  
				if connected_id >= 0 && connected_id < map_nodes.size():  
					var direction = _calculate_direction(  
						map_nodes[i].position,   
						map_nodes[connected_id].position  
					)  
					map_nodes[i].add_connection(connected_id, direction)  
	
	# 恢复连接记录  
	if map_state.has("connections"):  
		node_connections = map_state.connections.duplicate()  
	
	# 更新节点状态  
	update_node_states()  
	
	return true  

func ensure_current_node_selected():  
	var MapNode = load("res://scripts/map/map_node.gd")  
	
	# 验证当前节点ID是否有效  
	if current_node_id < 0 || current_node_id >= map_nodes.size():  
		# 寻找合适的节点作为当前节点  
		var highest_visited_layer = -1  
		var best_node_id = -1  
		
		for i in range(map_nodes.size()):  
			var node = map_nodes[i]  
			
			# 如果是起点且没有已访问节点，选择起点  
			if node.node_type == MapNode.NodeType.START && best_node_id == -1:  
				best_node_id = i  
			
			# 寻找最高层的已访问节点  
			if node.node_state == MapNode.NodeState.VISITED && node.floor_level > highest_visited_layer:  
				highest_visited_layer = node.floor_level  
				best_node_id = i  
		
		# 更新当前节点ID  
		if best_node_id >= 0:  
			current_node_id = best_node_id  
	
	# 更新节点状态  
	update_node_states()  

# 在加载状态后更新地图
func update_after_state_load():
	print("NodeMapScene: 在加载状态后更新地图")
	
	# 获取MapNode类
	var MapNode = load("res://scripts/map/map_node.gd")
	
	# 确保地图可见
	visible = true
	
	# 刷新节点状态
	for node in map_nodes:
		if node.node_id == current_node_id:
			node.set_state(MapNode.NodeState.CURRENT)
		
		# 更新节点连接和可见性
		node.set_visibility(true)
	
	# 更新地图标题
	if map_title:
		map_title.text = "地下城 - 第%s层" % current_floor
	
	# 更新可用节点和路径
	update_available_nodes()
	update_visuals()
	
	print("NodeMapScene: 地图状态加载后更新完成")

# 在处理地图节点事件后更新
func update_after_node_event(node_type):
	print("NodeMapScene: 在节点事件后更新地图")
	
	# 获取MapNode类
	var MapNode = load("res://scripts/map/map_node.gd")
	
	# 确保地图可见
	visible = true
	
	# 检查并更新节点状态
	for node in map_nodes:
		if node.node_id == current_node_id:
			node.set_state(MapNode.NodeState.VISITED)
			
			# 更新连接节点状态
			for connected_id in node.connected_nodes:
				if connected_id >= 0 && connected_id < map_nodes.size():
					var connected_node = map_nodes[connected_id]
					if connected_node.node_state == MapNode.NodeState.LOCKED:
						connected_node.set_state(MapNode.NodeState.AVAILABLE)
	
	# 更新可用节点和视觉效果
	update_available_nodes()
	update_visuals()
	
	print("NodeMapScene: 节点事件后地图更新完成")
