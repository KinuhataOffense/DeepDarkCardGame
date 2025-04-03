extends Control
class_name MapNode

# 节点类型枚举
enum NodeType {
	START,      # 起点
	ENEMY,      # 普通敌人
	ELITE,      # 精英敌人
	SHOP,       # 商店
	REST,       # 休息处
	TREASURE,   # 宝箱
	EVENT,      # 随机事件
	BOSS,       # Boss
	END         # 本层终点
}

# 节点状态枚举
enum NodeState {
	LOCKED,     # 锁定状态
	AVAILABLE,  # 可访问
	VISITED,    # 已访问
	CURRENT     # 当前位置
}

# 门的方向枚举
enum DoorDirection {
	TOP,
	RIGHT,
	BOTTOM,
	LEFT
}

# 节点属性
var node_id: int = 0                       # 节点唯一ID
var node_type: NodeType = NodeType.ENEMY   # 节点类型
var node_state: NodeState = NodeState.LOCKED # 节点状态
var node_position: Vector2 = Vector2.ZERO  # 节点在地图中的位置
var connected_nodes: Array[int] = []       # 连接到的节点ID列表
var connected_directions: Dictionary = {}  # 连接方向 {节点ID: 方向枚举}
var floor_level: int = 0                   # 节点所在的层级（从下往上）
var node_data: Dictionary = {}             # 节点特定数据（如：敌人ID、商店物品等）

# 是否可见

var is_fogged: bool = false                 # 节点是否处于迷雾状态（模糊）

# 信号
signal node_clicked(node)

# 节点UI引用
@onready var background = $Background
@onready var icon = $Icon
@onready var label = $Label
@onready var visited_overlay = $VisitedOverlay
@onready var highlight_border = $HighlightBorder
@onready var fog_overlay = $FogOverlay
@onready var button = $Button
@onready var doors = $Doors
@onready var door_top = $Doors/DoorTop
@onready var door_right = $Doors/DoorRight
@onready var door_bottom = $Doors/DoorBottom
@onready var door_left = $Doors/DoorLeft

# 节点图标资源
var node_icons = {
	NodeType.START: null,    # 起点图标
	NodeType.ENEMY: null,    # 敌人图标
	NodeType.ELITE: null,    # 精英敌人图标
	NodeType.SHOP: null,     # 商店图标
	NodeType.REST: null,     # 休息处图标
	NodeType.TREASURE: null, # 宝箱图标
	NodeType.EVENT: null,    # 随机事件图标
	NodeType.BOSS: null,     # Boss图标
	NodeType.END: null       # 终点图标
}

# 节点类型的背景颜色
var node_colors = {
	NodeType.START: Color(0.2, 0.6, 0.2),   # 绿色
	NodeType.ENEMY: Color(0.6, 0.2, 0.2),   # 红色
	NodeType.ELITE: Color(0.8, 0.2, 0.2),   # 深红色
	NodeType.SHOP: Color(0.2, 0.2, 0.6),    # 蓝色
	NodeType.REST: Color(0.2, 0.6, 0.6),    # 青色
	NodeType.TREASURE: Color(0.8, 0.6, 0.2), # 金色
	NodeType.EVENT: Color(0.6, 0.4, 0.6),   # 紫色
	NodeType.BOSS: Color(0.4, 0.0, 0.0),    # 暗红色
	NodeType.END: Color(0.2, 0.2, 0.2)      # 灰色
}

func _ready():
	# 连接按钮信号
	button.pressed.connect(_on_button_pressed)
	
	# 加载图标资源
	_load_icons()
	
	# 初始化节点外观
	update_appearance()

# 加载图标资源
func _load_icons():
	# 这里可以使用项目中已有的图标资源
	# 如果不存在对应资源，可以后续添加
	var icon_paths = {
		NodeType.START: "res://assets/ui/node_start.png",
		NodeType.ENEMY: "res://assets/ui/node_enemy.png",
		NodeType.ELITE: "res://assets/ui/node_elite.png",
		NodeType.SHOP: "res://assets/ui/node_shop.png",
		NodeType.REST: "res://assets/ui/node_rest.png",
		NodeType.TREASURE: "res://assets/ui/node_treasure.png",
		NodeType.EVENT: "res://assets/ui/node_event.png",
		NodeType.BOSS: "res://assets/ui/node_boss.png",
		NodeType.END: "res://assets/ui/node_end.png"
	}
	
	# 尝试加载图标，如果失败则使用默认图标
	for type in icon_paths:
		var path = icon_paths[type]
		if ResourceLoader.exists(path):
			node_icons[type] = load(path)

# 初始化节点
func initialize(id: int, type: NodeType, pos: Vector2, level: int = 0, data: Dictionary = {}):
	node_id = id
	node_type = type
	node_position = pos
	floor_level = level
	node_data = data
	position = pos
	
	# 设置标签文字
	label.text = get_node_type_string()
	
	# 如果是起点，直接设为当前状态
	if node_type == NodeType.START:
		node_state = NodeState.CURRENT
	
	update_appearance()

# 更新节点外观
func update_appearance():
	# 设置背景颜色
	if node_colors.has(node_type):
		var style_box = background.get_theme_stylebox("panel").duplicate()
		style_box.bg_color = node_colors[node_type]
		background.add_theme_stylebox_override("panel", style_box)
	
	# 设置图标
	if node_icons.has(node_type):
		icon.texture = node_icons[node_type]
	
	# 根据状态调整外观
	match node_state:
		NodeState.LOCKED:
			modulate = Color(0.5, 0.5, 0.5)
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_update_doors(false)
		NodeState.AVAILABLE:
			modulate = Color(1, 1, 1)
			button.mouse_filter = Control.MOUSE_FILTER_STOP
			_update_doors(true)
		NodeState.VISITED:
			modulate = Color(0.7, 0.7, 0.7)
			visited_overlay.visible = true
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_update_doors(true)
		NodeState.CURRENT:
			modulate = Color(1, 1, 1)
			highlight_border.visible = true
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_update_doors(true)
	
	# 设置可见性
	if !is_visible:
		# 完全隐藏
		modulate.a = 0.0
		button.disabled = true
	elif is_fogged:
		# 模糊显示
		modulate.a = 0.5
		if fog_overlay:
			fog_overlay.visible = true
		button.disabled = true
	else:
		# 正常显示
		modulate.a = 1.0
		if fog_overlay:
			fog_overlay.visible = false
		button.disabled = false

# 更新门的显示
func _update_doors(visible_state: bool):
	# 隐藏所有门
	door_top.visible = false
	door_right.visible = false
	door_bottom.visible = false
	door_left.visible = false
	
	if not visible_state:
		return
	
	# 根据连接方向显示对应的门
	for target_id in connected_nodes:
		if connected_directions.has(target_id):
			var direction = connected_directions[target_id]
			match direction:
				DoorDirection.TOP:
					door_top.visible = true
				DoorDirection.RIGHT:
					door_right.visible = true
				DoorDirection.BOTTOM:
					door_bottom.visible = true
				DoorDirection.LEFT:
					door_left.visible = true

# 设置节点状态
func set_state(new_state: NodeState):
	node_state = new_state
	update_appearance()

# 设置节点可见性
func set_visibility(visible_state: bool, fogged_state: bool = false):
	self.visible = visible_state
	is_fogged = fogged_state
	
	# 更新节点外观
	if !is_visible:
		# 完全隐藏
		modulate.a = 0.0
		button.disabled = true
	elif is_fogged:
		# 模糊显示
		modulate.a = 0.5
		if fog_overlay:
			fog_overlay.visible = true
		button.disabled = true
	else:
		# 正常显示
		modulate.a = 1.0
		if fog_overlay:
			fog_overlay.visible = false
		button.disabled = false

# 添加连接的节点
func add_connection(target_id: int, direction: DoorDirection = DoorDirection.BOTTOM):
	if not connected_nodes.has(target_id):
		connected_nodes.append(target_id)
		connected_directions[target_id] = direction
		update_appearance()

func is_connected_to(target_id: int) -> bool:
	if (connected_nodes.has(target_id)):
		return true
	else:
		return false
	
# 按钮点击处理
func _on_button_pressed():
	# 只有当节点状态为可用时才发出信号
	if node_state == NodeState.AVAILABLE:
		print("节点 %d 被点击 (类型: %s)" % [node_id, get_node_type_string()])
		emit_signal("node_clicked", self)

# 获取节点类型的字符串表示
func get_node_type_string() -> String:
	match node_type:
		NodeType.START:
			return "起点"
		NodeType.ENEMY:
			return "敌人"
		NodeType.ELITE:
			return "精英"
		NodeType.SHOP:
			return "商店"
		NodeType.REST:
			return "休息"
		NodeType.TREASURE:
			return "宝箱"
		NodeType.EVENT:
			return "事件"
		NodeType.BOSS:
			return "Boss"
		NodeType.END:
			return "终点"
		_:
			return "未知" 

# 静态函数：获取节点类型的字符串表示
static func get_node_type_name(type_value: int) -> String:
	match type_value:
		NodeType.START:
			return "起点"
		NodeType.ENEMY:
			return "敌人"
		NodeType.ELITE:
			return "精英"
		NodeType.SHOP:
			return "商店"
		NodeType.REST:
			return "休息"
		NodeType.TREASURE:
			return "宝箱"
		NodeType.EVENT:
			return "事件"
		NodeType.BOSS:
			return "Boss"
		NodeType.END:
			return "终点"
		_:
			return "未知" 
