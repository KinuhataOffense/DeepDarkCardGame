extends Control

# 边缘属性
var from_node_id: int = -1
var to_node_id: int = -1
var is_available: bool = false
var is_traversed: bool = false

# 常量
const COLOR_UNAVAILABLE: Color = Color(0.4, 0.4, 0.4, 1)  # 灰色
const COLOR_AVAILABLE: Color = Color(0.8, 0.8, 1.0, 1)    # 亮蓝色
const COLOR_TRAVERSED: Color = Color(0.4, 0.8, 0.4, 1)    # 绿色

# 对Line2D的引用
@onready var line = $Line2D

# 初始化边缘
func initialize(from_id: int, to_id: int, start_pos: Vector2, end_pos: Vector2):
    from_node_id = from_id
    to_node_id = to_id
    
    # 设置线段的点
    line.clear_points()
    line.add_point(start_pos)
    line.add_point(end_pos)
    
    # 默认不可用状态
    set_availability(false)
    set_traversed(false)

# 设置边缘可用性
func set_availability(available: bool):
    is_available = available
    update_appearance()

# 设置边缘是否已经被走过
func set_traversed(traversed: bool):
    is_traversed = traversed
    update_appearance()

# 更新边缘外观
func update_appearance():
    if is_traversed:
        line.default_color = COLOR_TRAVERSED
    elif is_available:
        line.default_color = COLOR_AVAILABLE
    else:
        line.default_color = COLOR_UNAVAILABLE 