extends Control
class_name CustomCardDropzone

signal card_dropped_in_zone(card: CustomCardUI, zone: CustomCardDropzone)
signal card_hovered_over_zone(card: CustomCardUI, zone: CustomCardDropzone)
signal card_exited_zone(card: CustomCardUI, zone: CustomCardDropzone)

# 配置
@export var can_accept_cards: bool = true
@export var highlight_on_hover: bool = true
@export var card_pile_manager: Node = null  # 引用卡牌管理器
@export var max_cards: int = -1  # -1表示无限制
@export var zone_type: String = "default"  # 可扩展为枚举类型

# 样式
@export var highlight_color: Color = Color(0.3, 0.7, 0.3, 0.5)
@export var invalid_highlight_color: Color = Color(0.7, 0.3, 0.3, 0.5)

# 节点引用
@onready var highlight = $Highlight
@onready var background = $Background
@onready var label = $Label

# 内部状态
var cards: Array[CustomCardUI] = []
var hovering_cards: Array[CustomCardUI] = []
var is_valid_target: bool = true

func _ready():
	# 初始化
	if highlight:
		highlight.visible = false
	
	# 设置区域名称
	if label:
		label.text = zone_type
	
	# 设置自定义尺寸
	if background and background.texture:
		custom_minimum_size = background.texture.get_size()

# 检查是否可以接受指定的卡牌
func can_accept_card(card: CustomCardUI) -> bool:
	# 如果区域不接受卡牌，直接返回false
	if not can_accept_cards:
		return false
		
	# 检查卡牌数量限制
	if max_cards > 0 and cards.size() >= max_cards:
		return false
	
	# 基础实现，子类可以重写这个方法加入更多逻辑
	return true

# 当卡牌放置到此区域时调用
func on_card_dropped(card: CustomCardUI):
	# 如果不能接受该卡牌，直接返回
	if not can_accept_card(card):
		return
	
	# 将卡牌添加到区域中
	if not cards.has(card):
		cards.append(card)
	
	# 移除卡牌从悬浮列表
	if hovering_cards.has(card):
		hovering_cards.erase(card)
	
	# 更新卡牌显示位置
	update_card_positions()
	
	# 发出信号
	emit_signal("card_dropped_in_zone", card, self)

# 当卡牌悬浮在此区域上方时调用
func on_card_hover_enter(card: CustomCardUI):
	# 如果卡牌已经在悬浮列表中，直接返回
	if hovering_cards.has(card):
		return
	
	# 添加卡牌到悬浮列表
	hovering_cards.append(card)
	
	# 检查并更新高亮显示
	is_valid_target = can_accept_card(card)
	if highlight and highlight_on_hover:
		highlight.visible = true
		highlight.modulate = highlight_color if is_valid_target else invalid_highlight_color
	
	# 发出信号
	emit_signal("card_hovered_over_zone", card, self)

# 当卡牌离开此区域上方时调用
func on_card_hover_exit(card: CustomCardUI):
	# 如果卡牌不在悬浮列表中，直接返回
	if not hovering_cards.has(card):
		return
	
	# 从悬浮列表中移除卡牌
	hovering_cards.erase(card)
	
	# 如果悬浮列表为空，隐藏高亮
	if hovering_cards.size() == 0 and highlight:
		highlight.visible = false
	
	# 发出信号
	emit_signal("card_exited_zone", card, self)

# 从区域中移除指定卡牌
func remove_card(card: CustomCardUI):
	if cards.has(card):
		cards.erase(card)
		update_card_positions()
		return true
	return false

# 获取区域中的所有卡牌
func get_cards() -> Array[CustomCardUI]:
	return cards

# 清空区域
func clear_cards():
	cards.clear()
	hovering_cards.clear()
	if highlight:
		highlight.visible = false

# 更新区域中所有卡牌的位置
func update_card_positions():
	# 基础实现
	# 这是一个占位实现，具体的布局逻辑应该在子类中实现
	# 例如扇形布局、网格布局等
	pass

# 检查某个点是否在当前区域内
func is_point_in_zone(point: Vector2) -> bool:
	return get_global_rect().has_point(point)

# 处理输入事件
func _gui_input(event):
	# 这里可以添加与区域直接交互的逻辑
	# 例如右键点击查看区域内所有卡牌等
	pass 
