extends Control
class_name CustomCardUI

signal card_hovered(card: CustomCardUI)
signal card_unhovered(card: CustomCardUI)
signal card_clicked(card: CustomCardUI)
signal card_dropped(card: CustomCardUI)
signal card_dragging_started(card: CustomCardUI)
signal card_dragging_ended(card: CustomCardUI)

# 节点引用
@onready var frontface = $Frontface
@onready var backface = $Backface
@onready var highlight = $Highlight
@onready var glow_effect = $GlowEffect
@onready var card_name_label = $CardInfo/NameLabel
@onready var card_description_label = $CardInfo/DescriptionLabel
@onready var card_value_label = $CardInfo/ValueLabel

# 卡牌数据
var card_data: CardData

# 交互状态
var is_clicked: bool = false
var is_hovered: bool = false
var is_dragging: bool = false
var is_disabled: bool = false
var is_selected: bool = false
var is_marked: bool = false  # 被标记的卡牌(例如敌人技能效果)

# 动画与位置
var target_position := Vector2.ZERO
var original_position := Vector2.ZERO
var return_speed := 0.2
var hover_distance := 30
var drag_when_clicked := true
var face_direction := Vector2.UP  # UP表示正面朝上，DOWN表示背面朝上

# 视觉效果
var original_scale := Vector2(1, 1)
var hover_scale := Vector2(1.1, 1.1)

func _ready():
    connect("mouse_entered", _on_mouse_enter)
    connect("mouse_exited", _on_mouse_exit)
    connect("gui_input", _on_gui_input)
    
    # 初始化默认值
    original_scale = scale
    original_position = position
    highlight.visible = false
    glow_effect.visible = false
    
    # 初始化卡牌外观
    update_card_appearance()

# 更新卡牌外观显示
func update_card_appearance():
    if card_data:
        # 设置卡牌纹理
        if card_data.texture_path and card_data.texture_path != "":
            frontface.texture = load(card_data.texture_path)
        
        if card_data.backface_texture_path and card_data.backface_texture_path != "":
            backface.texture = load(card_data.backface_texture_path)
        
        # 设置卡牌信息
        card_name_label.text = card_data.get_full_name()
        card_description_label.text = card_data.description
        card_value_label.text = str(card_data.value)
        
        # 根据稀有度设置卡牌边框颜色
        match card_data.rarity:
            0:  # 普通
                highlight.modulate = Color(0.7, 0.7, 0.7)
            1:  # 稀有
                highlight.modulate = Color(0.2, 0.5, 1.0)
            2:  # 史诗
                highlight.modulate = Color(0.7, 0.2, 1.0)
            3:  # 传说
                highlight.modulate = Color(1.0, 0.8, 0.0)
        
        # 根据花色设置卡牌文字颜色
        card_name_label.add_theme_color_override("font_color", card_data.get_color())
        card_value_label.add_theme_color_override("font_color", card_data.get_color())
        
        # 设置卡牌尺寸
        custom_minimum_size = frontface.texture.get_size()
        pivot_offset = frontface.texture.get_size() / 2

# 设置卡牌朝向(正面/背面)
func set_direction(direction: Vector2):
    face_direction = direction
    backface.visible = direction == Vector2.DOWN
    frontface.visible = direction == Vector2.UP
    
    # 当卡牌面朝下时隐藏详细信息
    var info_visible = direction == Vector2.UP
    if card_name_label:
        card_name_label.visible = info_visible
    if card_description_label:
        card_description_label.visible = info_visible
    if card_value_label:
        card_value_label.visible = info_visible

# 设置卡牌是否被选中
func set_selected(selected: bool):
    is_selected = selected
    if highlight:
        highlight.visible = selected
    
    # 触发外观更新
    update_visual_state()

# 设置卡牌是否被标记
func set_marked(marked: bool):
    is_marked = marked
    if glow_effect:
        glow_effect.visible = marked
        glow_effect.modulate = Color(1, 0, 0)  # 红色标记
    
    # 触发外观更新
    update_visual_state()

# 设置卡牌是否禁用
func set_disabled(disabled: bool):
    is_disabled = disabled
    
    if disabled:
        # 重置所有交互状态
        is_clicked = false
        is_dragging = false
        is_hovered = false
        
        # 重置位置和旋转
        rotation = 0
        
        # 更新显示
        modulate = Color(0.5, 0.5, 0.5)  # 灰色显示禁用状态
    else:
        modulate = Color(1, 1, 1)  # 恢复正常颜色
    
    # 触发外观更新
    update_visual_state()

# 更新卡牌视觉状态
func update_visual_state():
    # 优先级: 禁用 > 标记 > 选中 > 悬浮
    if is_disabled:
        modulate = Color(0.5, 0.5, 0.5)
    elif is_marked:
        modulate = Color(1, 0.8, 0.8)  # 轻微红色
    elif is_selected:
        modulate = Color(1, 1, 1)
        highlight.visible = true
    elif is_hovered:
        modulate = Color(1, 1, 1)
        highlight.visible = false
    else:
        modulate = Color(1, 1, 1)
        highlight.visible = false

# 鼠标进入事件
func _on_mouse_enter():
    if is_disabled:
        return
        
    is_hovered = true
    target_position.y -= hover_distance
    
    # 触发卡牌悬浮事件
    emit_signal("card_hovered", self)
    
    # 更新视觉状态
    update_visual_state()

# 鼠标离开事件
func _on_mouse_exit():
    if is_disabled or is_dragging:
        return
        
    is_hovered = false
    target_position.y += hover_distance
    
    # 触发卡牌取消悬浮事件
    emit_signal("card_unhovered", self)
    
    # 更新视觉状态
    update_visual_state()

# 输入事件处理
func _on_gui_input(event):
    if is_disabled:
        return
    
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:  # 按下左键
            is_clicked = true
            is_dragging = drag_when_clicked
            
            # 重置旋转以便拖动
            rotation = 0
            
            # 触发卡牌点击事件
            emit_signal("card_clicked", self)
            
            # 如果开始拖动，触发拖动开始事件
            if is_dragging:
                emit_signal("card_dragging_started", self)
        else:  # 释放左键
            if is_clicked:
                is_clicked = false
                
                # 如果之前在拖动，则触发拖动结束和放下事件
                if is_dragging:
                    is_dragging = false
                    emit_signal("card_dragging_ended", self)
                    emit_signal("card_dropped", self)
                
                # 如果鼠标不再悬浮在卡牌上，触发取消悬浮事件
                if not get_global_rect().has_point(get_global_mouse_position()):
                    is_hovered = false
                    emit_signal("card_unhovered", self)
                
                # 更新视觉状态
                update_visual_state()

# 处理帧更新
func _process(delta):
    # 处理拖动逻辑
    if is_dragging and drag_when_clicked:
        target_position = get_global_mouse_position() - custom_minimum_size * 0.5
        position = target_position
    # 处理平滑移动到目标位置
    elif position != target_position:
        position = position.lerp(target_position, return_speed)
    
    # 处理悬浮缩放效果
    if is_hovered and not is_dragging:
        scale = scale.lerp(hover_scale, 0.1)
    else:
        scale = scale.lerp(original_scale, 0.1)

# 获取卡牌的放置目标(检测鼠标悬浮在哪个放置区域)
func get_dropzone_at_position():
    # 这个函数需要在卡牌管理器中实现
    return null
    
# 重置卡牌状态
func reset_state():
    is_clicked = false
    is_dragging = false
    is_hovered = false
    is_selected = false
    is_marked = false
    
    # 重置位置和旋转
    position = original_position
    target_position = original_position
    rotation = 0
    scale = original_scale
    
    # 更新视觉状态
    update_visual_state() 