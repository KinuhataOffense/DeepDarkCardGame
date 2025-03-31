extends RefCounted
class_name GridCardLayout

# 网格布局参数
var horizontal_spacing: float = 120.0  # 卡牌水平间距
var vertical_spacing: float = 160.0  # 卡牌垂直间距
var columns: int = 5  # 网格列数
var hover_distance: float = 20.0  # 悬浮距离
var animation_speed: float = 0.2  # 动画速度

# 调整网格布局
func arrange_cards(cards: Array, base_position: Vector2):
    # 如果没有卡牌，直接返回
    if cards.size() == 0:
        return
    
    # 计算网格起始位置（使整个网格居中）
    var rows = ceil(float(cards.size()) / columns)
    var grid_width = (columns - 1) * horizontal_spacing
    var grid_height = (rows - 1) * vertical_spacing
    var start_x = base_position.x - (grid_width / 2)
    var start_y = base_position.y - (grid_height / 2)
    
    # 计算每张卡牌的位置
    for i in range(cards.size()):
        var card = cards[i]
        
        # 计算网格位置
        var col = i % columns
        var row = i / columns
        
        # 计算卡牌位置
        var card_position = Vector2(
            start_x + (col * horizontal_spacing),
            start_y + (row * vertical_spacing)
        )
        
        # 设置卡牌位置
        card.target_position = card_position
        card.original_position = card_position
        
        # 设置悬浮距离
        card.hover_distance = hover_distance

# 调整卡牌为透视网格布局（3D效果）
func arrange_cards_perspective(cards: Array, base_position: Vector2, perspective_strength: float = 0.5):
    # 如果没有卡牌，直接返回
    if cards.size() == 0:
        return
    
    # 计算网格起始位置（使整个网格居中）
    var rows = ceil(float(cards.size()) / columns)
    var grid_width = (columns - 1) * horizontal_spacing
    var grid_height = (rows - 1) * vertical_spacing
    var start_x = base_position.x - (grid_width / 2)
    var start_y = base_position.y - (grid_height / 2)
    
    # 计算中心点
    var center_col = (columns - 1) / 2.0
    var center_row = (rows - 1) / 2.0
    
    # 计算每张卡牌的位置和旋转
    for i in range(cards.size()):
        var card = cards[i]
        
        # 计算网格位置
        var col = i % columns
        var row = i / columns
        
        # 计算透视缩放和旋转因子
        var dist_from_center_x = (col - center_col) / center_col
        var dist_from_center_y = (row - center_row) / center_row
        var dist_factor = sqrt(dist_from_center_x * dist_from_center_x + dist_from_center_y * dist_from_center_y)
        
        # 应用透视效果
        var perspective_scale = 1.0 - (dist_factor * perspective_strength * 0.3)
        var perspective_x = dist_from_center_x * perspective_strength * 15.0
        var perspective_y = dist_from_center_y * perspective_strength * 15.0
        
        # 计算卡牌位置
        var card_position = Vector2(
            start_x + (col * horizontal_spacing) + perspective_x,
            start_y + (row * vertical_spacing) + perspective_y
        )
        
        # 设置卡牌位置和缩放
        card.target_position = card_position
        card.original_position = card_position
        card.scale = Vector2(perspective_scale, perspective_scale)
        
        # 设置卡牌旋转
        card.rotation_degrees = dist_from_center_x * 5.0
        
        # 设置悬浮距离
        card.hover_distance = hover_distance

# 平滑网格布局
func smooth_arrange_cards(cards: Array, base_position: Vector2, animation_time: float = 0.5):
    # 如果没有卡牌，直接返回
    if cards.size() == 0:
        return
    
    # 保存原始位置，用于动画
    var original_positions = []
    var original_scales = []
    var original_rotations = []
    
    for card in cards:
        original_positions.append(card.position)
        original_scales.append(card.scale)
        original_rotations.append(card.rotation_degrees)
    
    # 计算新位置
    arrange_cards(cards, base_position)
    
    # 保存目标位置，用于动画
    var target_positions = []
    var target_scales = []
    var target_rotations = []
    
    for card in cards:
        target_positions.append(card.target_position)
        target_scales.append(Vector2(1, 1))  # 默认缩放为1
        target_rotations.append(0)  # 默认旋转为0
    
    # 使用动画逐步更新位置
    var time_elapsed = 0.0
    while time_elapsed < animation_time:
        # 计算动画进度
        var progress = min(time_elapsed / animation_time, 1.0)
        
        # 使用缓动函数使动画更自然
        progress = ease_out_quad(progress)
        
        # 更新卡牌位置和外观
        for i in range(cards.size()):
            var card = cards[i]
            var original_pos = original_positions[i]
            var target_pos = target_positions[i]
            var original_scale = original_scales[i]
            var target_scale = target_scales[i]
            var original_rot = original_rotations[i]
            var target_rot = target_rotations[i]
            
            # 插值计算当前位置和外观
            card.position = original_pos.lerp(target_pos, progress)
            card.scale = original_scale.lerp(target_scale, progress)
            card.rotation_degrees = lerp(original_rot, target_rot, progress)
        
        # 增加时间
        time_elapsed += get_process_delta_time()
        await get_tree().process_frame
    
    # 确保最终位置正确
    for i in range(cards.size()):
        var card = cards[i]
        card.position = target_positions[i]
        card.scale = target_scales[i]
        card.rotation_degrees = target_rotations[i]

# 二次方缓出函数
func ease_out_quad(x: float) -> float:
    return 1 - (1 - x) * (1 - x)

# 获取当前帧时间间隔
func get_process_delta_time() -> float:
    return Engine.get_process_delta_time()

# 从网格中移除卡牌并重新排列
func remove_card_and_rearrange(cards: Array, card_to_remove, base_position: Vector2):
    # 如果没有卡牌或者要移除的卡牌不在列表中，直接返回
    if cards.size() == 0 or not cards.has(card_to_remove):
        return
    
    # 移除卡牌
    cards.erase(card_to_remove)
    
    # 重新排列剩余卡牌
    smooth_arrange_cards(cards, base_position)
    
    return cards

# 添加卡牌到网格并重新排列
func add_card_and_rearrange(cards: Array, new_card, base_position: Vector2, entry_position: Vector2 = Vector2.ZERO):
    # 设置新卡牌的初始位置
    if entry_position != Vector2.ZERO:
        new_card.position = entry_position
    else:
        new_card.position = base_position
    
    # 添加卡牌到列表
    cards.append(new_card)
    
    # 重新排列所有卡牌
    smooth_arrange_cards(cards, base_position)
    
    return cards

# 查找指定点最近的卡牌
func find_nearest_card(cards: Array, point: Vector2) -> int:
    # 如果没有卡牌，返回-1
    if cards.size() == 0:
        return -1
    
    var nearest_index = -1
    var min_distance = INF
    
    # 查找最近的卡牌
    for i in range(cards.size()):
        var card = cards[i]
        var distance = card.position.distance_to(point)
        
        if distance < min_distance:
            min_distance = distance
            nearest_index = i
    
    return nearest_index

# 应用卡牌排序并重新布局
func sort_and_rearrange(cards: Array, base_position: Vector2, sort_func = null):
    # 如果没有卡牌，直接返回
    if cards.size() == 0:
        return
    
    # 如果提供了排序函数，则使用它排序
    if sort_func != null:
        cards.sort_custom(sort_func)
    
    # 重新排列卡牌
    smooth_arrange_cards(cards, base_position)
    
    return cards 