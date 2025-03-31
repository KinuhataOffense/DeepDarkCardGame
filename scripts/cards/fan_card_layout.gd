extends RefCounted
class_name FanCardLayout

# 扇形布局参数
var horizontal_spacing: float = 60.0  # 卡牌水平间距
var radius: float = 800.0  # 扇形半径
var min_angle: float = 5.0  # 扇形最小角度（度）
var max_angle: float = 30.0  # 扇形最大角度（度）
var vertical_offset: float = -100.0  # 卡牌垂直偏移
var hover_distance: float = 30.0  # 悬浮距离
var center_position: Vector2 = Vector2.ZERO  # 扇形中心点

# 调整扇形布局
func arrange_cards(cards: Array, base_position: Vector2):
    # 如果没有卡牌，直接返回
    if cards.size() == 0:
        return
    
    # 设置中心点
    center_position = base_position + Vector2(0, radius + vertical_offset)
    
    # 计算扇形角度，基于卡牌数量进行调整
    var total_angle = min(max_angle, max(min_angle, cards.size() * 5.0))
    
    # 计算每张卡牌之间的角度
    var angle_per_card = total_angle / max(1, cards.size() - 1)
    if cards.size() == 1:
        angle_per_card = 0
    
    # 计算起始角度
    var start_angle = 270 - (total_angle / 2)
    
    # 计算每张卡牌的位置和旋转角度
    for i in range(cards.size()):
        var card = cards[i]
        
        # 计算当前卡牌的角度
        var current_angle = start_angle + (i * angle_per_card)
        
        # 将角度转换为弧度
        var radians = deg_to_rad(current_angle)
        
        # 计算卡牌位置
        var offset_x = cos(radians) * radius
        var offset_y = sin(radians) * radius
        
        # 设置卡牌位置
        var card_position = center_position + Vector2(offset_x, offset_y)
        card.target_position = card_position
        card.original_position = card_position
        
        # 设置卡牌旋转角度，使其指向圆心
        card.rotation_degrees = current_angle - 90
        
        # 设置卡牌悬浮距离（沿着卡牌的朝向方向）
        card.hover_distance = hover_distance
        
        # 设置卡牌层级，使中间的卡牌在最上层
        var z_index = abs(i - (cards.size() / 2))
        card.z_index = -z_index

# 平滑扇形布局
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
        progress = smooth_step(0.0, 1.0, progress)
        
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

# 扇形布局下的卡牌收集动画
func collect_cards_to_point(cards: Array, target_position: Vector2, animation_time: float = 0.5):
    # 如果没有卡牌，直接返回
    if cards.size() == 0:
        return
    
    # 保存原始位置和旋转
    var original_positions = []
    var original_rotations = []
    
    for card in cards:
        original_positions.append(card.position)
        original_rotations.append(card.rotation_degrees)
    
    # 使用动画逐步更新位置
    var time_elapsed = 0.0
    while time_elapsed < animation_time:
        # 计算动画进度（使用缓动函数使动画更自然）
        var progress = ease_out_cubic(min(time_elapsed / animation_time, 1.0))
        
        # 更新卡牌位置和旋转
        for i in range(cards.size()):
            var card = cards[i]
            var original_pos = original_positions[i]
            
            # 插值计算当前位置和旋转
            card.position = original_pos.lerp(target_position, progress)
            card.rotation_degrees = lerp(original_rotations[i], 0, progress)
            
            # 随着进度缩小卡牌
            var scale_factor = 1.0 - (progress * 0.5)
            card.scale = Vector2(scale_factor, scale_factor)
        
        # 增加时间
        time_elapsed += get_process_delta_time()
        await get_tree().process_frame
    
    # 确保最终位置正确
    for card in cards:
        card.position = target_position
        card.rotation_degrees = 0
        card.scale = Vector2(0.5, 0.5) # 缩小到最终大小

# 三次方缓出函数
func ease_out_cubic(x: float) -> float:
    return 1.0 - pow(1.0 - x, 3)

# 获取当前帧时间间隔
func get_process_delta_time() -> float:
    return Engine.get_process_delta_time()

# 在扇形布局中查找最接近指定角度的卡牌索引
func find_card_at_angle(cards: Array, angle_degrees: float) -> int:
    # 如果没有卡牌，返回-1
    if cards.size() == 0:
        return -1
    
    # 计算扇形角度
    var total_angle = min(max_angle, max(min_angle, cards.size() * 5.0))
    
    # 计算每张卡牌之间的角度
    var angle_per_card = total_angle / max(1, cards.size() - 1)
    if cards.size() == 1:
        angle_per_card = 0
    
    # 计算起始角度
    var start_angle = 270 - (total_angle / 2)
    
    # 使角度在0-360范围内
    while angle_degrees < 0:
        angle_degrees += 360
    while angle_degrees >= 360:
        angle_degrees -= 360
    
    # 如果角度不在扇形范围内，返回-1
    if angle_degrees < start_angle or angle_degrees > start_angle + total_angle:
        return -1
    
    # 计算最接近的卡牌索引
    var index = round((angle_degrees - start_angle) / angle_per_card)
    
    # 确保索引在有效范围内
    index = clamp(index, 0, cards.size() - 1)
    
    return index 