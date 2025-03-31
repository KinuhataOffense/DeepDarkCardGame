extends RefCounted
class_name HandCardLayout

# 手牌布局参数
var card_spacing: float = 80.0  # 基础卡牌间距
var max_spacing: float = 150.0  # 最大卡牌间距
var min_spacing: float = 40.0   # 最小卡牌间距
var curve_radius: float = 1000.0  # 弧线半径
var curve_angle: float = 40.0    # 弧线角度（度）
var vertical_offset: float = 0.0  # 垂直偏移
var hover_raise: float = 50.0    # 悬浮时上升高度
var rotation_factor: float = 1.0  # 卡牌旋转因子

# 调整手牌布局
func arrange_cards(cards: Array, base_position: Vector2):
    # 如果没有卡牌，直接返回
    if cards.size() == 0:
        return
    
    # 动态调整卡牌间距，基于卡牌数量
    var actual_spacing = clamp(
        card_spacing - (cards.size() - 5) * (card_spacing * 0.1),
        min_spacing,
        max_spacing
    )
    
    # 计算手牌总宽度
    var total_width = (cards.size() - 1) * actual_spacing
    
    # 计算手牌弧线参数
    var angle_per_card = curve_angle / max(1, cards.size() - 1)
    if cards.size() == 1:
        angle_per_card = 0
    
    # 计算起始角度
    var start_angle = 90 - (curve_angle / 2)
    
    # 计算每张卡牌的位置和旋转
    for i in range(cards.size()):
        var card = cards[i]
        
        # 计算当前卡牌在弧线上的角度
        var current_angle = start_angle + (i * angle_per_card)
        
        # 将角度转换为弧度
        var radians = deg_to_rad(current_angle)
        
        # 计算卡牌在弧线上的位置
        var offset_x = cos(radians) * curve_radius
        var offset_y = sin(radians) * curve_radius
        
        # 计算卡牌基础位置（水平排列部分）
        var base_x = base_position.x - (total_width / 2) + (i * actual_spacing)
        
        # 结合弧线效果和基础位置
        var card_position = Vector2(
            base_x,
            base_position.y + vertical_offset - offset_y + curve_radius
        )
        
        # 设置卡牌位置
        card.target_position = card_position
        card.original_position = card_position
        
        # 设置卡牌旋转角度，使其略微倾斜，指向中心点
        var rotation_angle = (i - (cards.size() - 1) / 2.0) * -2.0 * rotation_factor
        card.rotation_degrees = rotation_angle
        
        # 设置卡牌悬浮距离
        card.hover_distance = hover_raise

# 获取卡牌在手牌中的索引（基于水平位置）
func get_card_index_at_position(cards: Array, position: Vector2) -> int:
    # 如果没有卡牌，返回-1
    if cards.size() == 0:
        return -1
    
    # 获取卡牌的水平位置列表
    var card_positions = []
    for card in cards:
        card_positions.append(card.position.x)
    
    # 处理边界情况
    if position.x <= card_positions[0]:
        return 0
    elif position.x >= card_positions[cards.size() - 1]:
        return cards.size() - 1
    
    # 查找位置最接近的两张卡牌
    for i in range(cards.size() - 1):
        if position.x >= card_positions[i] and position.x < card_positions[i + 1]:
            # 确定是更接近左侧还是右侧的卡牌
            var dist_to_left = abs(position.x - card_positions[i])
            var dist_to_right = abs(position.x - card_positions[i + 1])
            
            return i if dist_to_left < dist_to_right else i + 1
    
    # 默认返回
    return 0

# 平滑手牌布局
func smooth_arrange_cards(cards: Array, base_position: Vector2, animation_time: float = 0.3):
    # 如果没有卡牌，直接返回
    if cards.size() == 0:
        return
    
    # 保存原始位置，用于动画
    var original_positions = []
    var original_rotations = []
    
    for card in cards:
        original_positions.append(card.position)
        original_rotations.append(card.rotation_degrees)
    
    # 计算新位置
    arrange_cards(cards, base_position)
    
    # 保存目标位置和旋转，用于动画
    var target_positions = []
    var target_rotations = []
    
    for card in cards:
        target_positions.append(card.target_position)
        target_rotations.append(card.rotation_degrees)
    
    # 使用动画逐步更新位置
    var time_elapsed = 0.0
    while time_elapsed < animation_time:
        # 计算动画进度
        var progress = min(time_elapsed / animation_time, 1.0)
        
        # 使用平滑插值
        progress = ease_out_cubic(progress)
        
        # 更新卡牌位置和旋转
        for i in range(cards.size()):
            var card = cards[i]
            var original_pos = original_positions[i]
            var target_pos = target_positions[i]
            var original_rot = original_rotations[i]
            var target_rot = target_rotations[i]
            
            # 插值计算当前位置和旋转
            card.position = original_pos.lerp(target_pos, progress)
            card.rotation_degrees = lerp(original_rot, target_rot, progress)
        
        # 增加时间
        time_elapsed += get_process_delta_time()
        await get_tree().process_frame
    
    # 确保最终位置正确
    for i in range(cards.size()):
        var card = cards[i]
        card.position = target_positions[i]
        card.rotation_degrees = target_rotations[i]

# 三次方缓出函数
func ease_out_cubic(x: float) -> float:
    return 1.0 - pow(1.0 - x, 3)

# 获取当前帧时间间隔
func get_process_delta_time() -> float:
    return Engine.get_process_delta_time()

# 播放卡牌抽取动画
func play_draw_animation(card: Control, draw_pile_position: Vector2, hand_position: Vector2, animation_time: float = 0.5):
    # 设置初始位置
    card.position = draw_pile_position
    card.scale = Vector2(0.8, 0.8)
    card.modulate.a = 0.5
    
    # 创建动画路径点
    var control_point = Vector2(
        (draw_pile_position.x + hand_position.x) / 2,
        min(draw_pile_position.y, hand_position.y) - 100
    )
    
    # 使用动画逐步更新位置
    var time_elapsed = 0.0
    while time_elapsed < animation_time:
        # 计算动画进度
        var progress = min(time_elapsed / animation_time, 1.0)
        
        # 使用缓动函数使动画更自然
        progress = ease_out_cubic(progress)
        
        # 使用二次贝塞尔曲线计算当前位置
        var p0 = draw_pile_position.lerp(control_point, progress)
        var p1 = control_point.lerp(hand_position, progress)
        var current_pos = p0.lerp(p1, progress)
        
        # 更新卡牌位置和视觉属性
        card.position = current_pos
        card.scale = Vector2(0.8, 0.8).lerp(Vector2(1.0, 1.0), progress)
        card.modulate.a = 0.5 + (0.5 * progress)
        card.rotation_degrees = -10 + (progress * 10)
        
        # 增加时间
        time_elapsed += get_process_delta_time()
        await get_tree().process_frame
    
    # 确保最终位置正确
    card.position = hand_position
    card.scale = Vector2(1.0, 1.0)
    card.modulate.a = 1.0
    card.rotation_degrees = 0

# 播放卡牌打出动画
func play_play_animation(card: Control, play_position: Vector2, animation_time: float = 0.3):
    # 保存原始值
    var original_position = card.position
    var original_scale = card.scale
    var original_rotation = card.rotation_degrees
    
    # 使用动画逐步更新位置
    var time_elapsed = 0.0
    while time_elapsed < animation_time:
        # 计算动画进度
        var progress = min(time_elapsed / animation_time, 1.0)
        
        # 使用缓动函数使动画更自然
        progress = ease_out_cubic(progress)
        
        # 更新卡牌位置和视觉属性
        card.position = original_position.lerp(play_position, progress)
        card.scale = original_scale.lerp(Vector2(1.2, 1.2), progress)
        card.rotation_degrees = original_rotation * (1 - progress)
        
        # 增加时间
        time_elapsed += get_process_delta_time()
        await get_tree().process_frame
    
    # 缩小淡出效果
    time_elapsed = 0.0
    while time_elapsed < animation_time * 0.5:
        # 计算动画进度
        var progress = min(time_elapsed / (animation_time * 0.5), 1.0)
        
        # 更新卡牌视觉属性
        card.scale = Vector2(1.2, 1.2).lerp(Vector2(0.8, 0.8), progress)
        card.modulate.a = 1.0 - progress
        
        # 增加时间
        time_elapsed += get_process_delta_time()
        await get_tree().process_frame
    
    # 重置卡牌属性
    card.scale = original_scale
    card.modulate.a = 1.0 