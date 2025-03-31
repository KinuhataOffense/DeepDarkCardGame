extends Control
class_name CustomCardPileManager

signal draw_pile_updated(count: int)
signal discard_pile_updated(count: int)
signal hand_updated(cards: Array)
signal card_selected(card: CustomCardUI)
signal card_played(card: CustomCardUI)

# 预载体
var card_ui_scene = preload("res://scenes/cards/card_ui.tscn")

# 节点引用
@onready var draw_pile_zone = $DrawPileZone
@onready var discard_pile_zone = $DiscardPileZone
@onready var hand_zone = $HandZone
@onready var play_zone = $PlayZone
@onready var animation_layer = $AnimationLayer
@onready var draw_pile_count = $DrawPileZone/Count
@onready var discard_pile_count = $DiscardPileZone/Count

# 配置
@export var max_hand_size: int = 7
@export var starting_hand_size: int = 5
@export var card_spacing: float = 10.0
@export var card_fan_angle: float = 5.0
@export var auto_sort_hand: bool = true

# 牌堆状态
var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []
var hand: Array[CustomCardUI] = []
var played_cards: Array[CustomCardUI] = []
var all_card_uis: Array[CustomCardUI] = []
var active_dropzones: Array[CustomCardDropzone] = []

# 交互状态
var selected_card: CustomCardUI = null
var is_busy: bool = false
var can_draw_cards: bool = true
var can_discard_cards: bool = true
var can_play_cards: bool = true

func _ready():
    # 初始化放置区域
    _init_dropzones()
    
    # 更新显示
    _update_pile_counters()

# 初始化放置区域
func _init_dropzones():
    active_dropzones.clear()
    
    if draw_pile_zone:
        draw_pile_zone.card_pile_manager = self
        draw_pile_zone.zone_type = "draw"
        active_dropzones.append(draw_pile_zone)
    
    if discard_pile_zone:
        discard_pile_zone.card_pile_manager = self
        discard_pile_zone.zone_type = "discard"
        active_dropzones.append(discard_pile_zone)
    
    if hand_zone:
        hand_zone.card_pile_manager = self
        hand_zone.zone_type = "hand"
        active_dropzones.append(hand_zone)
    
    if play_zone:
        play_zone.card_pile_manager = self
        play_zone.zone_type = "play"
        active_dropzones.append(play_zone)
    
    # 连接信号
    for zone in active_dropzones:
        if not zone.is_connected("card_dropped_in_zone", _on_card_dropped_in_zone):
            zone.connect("card_dropped_in_zone", _on_card_dropped_in_zone)
        if not zone.is_connected("card_hovered_over_zone", _on_card_hovered_over_zone):
            zone.connect("card_hovered_over_zone", _on_card_hovered_over_zone)
        if not zone.is_connected("card_exited_zone", _on_card_exited_zone):
            zone.connect("card_exited_zone", _on_card_exited_zone)

# 初始化牌堆
func initialize_deck(deck_cards: Array[CardData]):
    # 清空现有牌堆
    clear_all()
    
    # 深拷贝卡牌数据到抽牌堆
    for card_data in deck_cards:
        draw_pile.append(card_data.duplicate())
    
    # 洗牌
    shuffle_draw_pile()
    
    # 更新计数器
    _update_pile_counters()
    
    # 抽初始手牌
    draw_cards(starting_hand_size)

# 洗牌(抽牌堆)
func shuffle_draw_pile():
    if draw_pile.size() <= 1:
        return
    
    # 随机排序抽牌堆
    randomize()
    draw_pile.shuffle()
    
    # 更新计数器
    _update_pile_counters()
    
    # 发送信号
    emit_signal("draw_pile_updated", draw_pile.size())

# 洗牌(弃牌堆)
func shuffle_discard_to_draw():
    if discard_pile.size() == 0:
        return
    
    # 将弃牌堆所有卡牌移到抽牌堆
    for card in discard_pile:
        draw_pile.append(card)
    
    # 清空弃牌堆
    discard_pile.clear()
    
    # 洗牌
    shuffle_draw_pile()

# 抽牌
func draw_cards(count: int) -> Array[CustomCardUI]:
    # 检查是否可以抽牌
    if not can_draw_cards or is_busy:
        return []
    
    # 检查手牌是否已满
    if hand.size() >= max_hand_size:
        print("手牌已满，无法抽牌")
        return []
    
    # 设置繁忙标志
    is_busy = true
    
    # 实际可抽牌数量(考虑手牌上限)
    var actual_draw_count = min(count, max_hand_size - hand.size())
    
    # 如果抽牌堆不够，需要先洗入弃牌堆
    if draw_pile.size() < actual_draw_count and discard_pile.size() > 0:
        shuffle_discard_to_draw()
    
    # 实际可抽牌数量(考虑抽牌堆卡牌数量)
    actual_draw_count = min(actual_draw_count, draw_pile.size())
    
    var drawn_cards: Array[CustomCardUI] = []
    
    # 抽牌
    for i in range(actual_draw_count):
        if draw_pile.size() > 0:
            # 从抽牌堆顶取一张卡牌
            var card_data = draw_pile.pop_back()
            
            # 创建卡牌UI
            var card_ui = create_card_ui(card_data)
            
            # 将卡牌添加到手牌中
            add_card_to_hand(card_ui)
            
            # 添加到已抽取卡牌列表
            drawn_cards.append(card_ui)
            
            # 动画延迟
            await get_tree().create_timer(0.1).timeout
    
    # 重置繁忙标志
    is_busy = false
    
    # 更新显示
    _update_pile_counters()
    update_hand_layout()
    
    # 发送信号
    emit_signal("draw_pile_updated", draw_pile.size())
    emit_signal("hand_updated", hand)
    
    return drawn_cards

# 弃牌
func discard_card(card_ui: CustomCardUI) -> bool:
    # 检查是否可以弃牌
    if not can_discard_cards or is_busy:
        return false
    
    # 检查卡牌是否在手牌中
    if not hand.has(card_ui):
        return false
    
    # 设置繁忙标志
    is_busy = true
    
    # 从手牌中移除卡牌
    hand.erase(card_ui)
    
    # 将卡牌数据添加到弃牌堆
    discard_pile.append(card_ui.card_data)
    
    # 重新排列手牌
    update_hand_layout()
    
    # 销毁卡牌UI对象
    all_card_uis.erase(card_ui)
    card_ui.queue_free()
    
    # 重置繁忙标志
    is_busy = false
    
    # 更新显示
    _update_pile_counters()
    
    # 发送信号
    emit_signal("discard_pile_updated", discard_pile.size())
    emit_signal("hand_updated", hand)
    
    return true

# 弃置所有手牌
func discard_hand() -> int:
    if hand.size() == 0 or is_busy:
        return 0
    
    # 设置繁忙标志
    is_busy = true
    
    # 记录弃置数量
    var discard_count = hand.size()
    
    # 复制手牌数组，因为我们会在循环中修改它
    var hand_copy = hand.duplicate()
    
    # 依次弃置每张手牌
    for card in hand_copy:
        discard_card(card)
        await get_tree().create_timer(0.05).timeout
    
    # 重置繁忙标志
    is_busy = false
    
    return discard_count

# 创建卡牌UI
func create_card_ui(card_data: CardData) -> CustomCardUI:
    var card_instance = card_ui_scene.instantiate()
    animation_layer.add_child(card_instance)
    
    # 设置卡牌数据
    card_instance.card_data = card_data
    card_instance.update_card_appearance()
    
    # 连接卡牌信号
    _connect_card_signals(card_instance)
    
    # 初始位置(抽牌堆位置)
    if draw_pile_zone:
        card_instance.position = draw_pile_zone.global_position
        card_instance.target_position = draw_pile_zone.global_position
    
    # 添加到卡牌UI列表
    all_card_uis.append(card_instance)
    
    return card_instance

# 连接卡牌信号
func _connect_card_signals(card: CustomCardUI):
    if not card.is_connected("card_clicked", _on_card_clicked):
        card.connect("card_clicked", _on_card_clicked)
    if not card.is_connected("card_hovered", _on_card_hovered):
        card.connect("card_hovered", _on_card_hovered)
    if not card.is_connected("card_unhovered", _on_card_unhovered):
        card.connect("card_unhovered", _on_card_unhovered)
    if not card.is_connected("card_dropped", _on_card_dropped):
        card.connect("card_dropped", _on_card_dropped)
    if not card.is_connected("card_dragging_started", _on_card_dragging_started):
        card.connect("card_dragging_started", _on_card_dragging_started)
    if not card.is_connected("card_dragging_ended", _on_card_dragging_ended):
        card.connect("card_dragging_ended", _on_card_dragging_ended)

# 将卡牌添加到手牌
func add_card_to_hand(card_ui: CustomCardUI) -> bool:
    # 检查是否已在手牌中
    if hand.has(card_ui):
        return false
    
    # 检查手牌是否已满
    if hand.size() >= max_hand_size:
        print("手牌已满，无法添加更多卡牌")
        return false
    
    # 添加到手牌
    hand.append(card_ui)
    
    # 设置卡牌朝向为正面朝上
    card_ui.set_direction(Vector2.UP)
    
    # 更新手牌布局
    update_hand_layout()
    
    # 发送信号
    emit_signal("hand_updated", hand)
    
    return true

# 更新手牌布局
func update_hand_layout():
    if hand.size() == 0:
        return
    
    # 如果启用自动排序，根据牌值排序手牌
    if auto_sort_hand:
        hand.sort_custom(func(a, b): return a.card_data.value < b.card_data.value)
    
    # 计算手牌布局参数
    var card_width = hand[0].custom_minimum_size.x
    var total_width = (hand.size() - 1) * card_spacing + card_width
    var start_x = hand_zone.global_position.x - total_width * 0.5 + card_width * 0.5
    var hand_y = hand_zone.global_position.y
    
    # 设置每张卡牌的目标位置
    for i in range(hand.size()):
        var card = hand[i]
        var target_x = start_x + i * card_spacing
        card.target_position = Vector2(target_x, hand_y)
        card.original_position = Vector2(target_x, hand_y)
        
        # 设置卡牌的旋转角度(扇形布局)
        var angle = (i - hand.size() * 0.5) * card_fan_angle
        card.rotation_degrees = angle

# 打出卡牌
func play_card(card_ui: CustomCardUI) -> bool:
    # 检查是否可以打出卡牌
    if not can_play_cards or is_busy:
        return false
    
    # 检查卡牌是否在手牌中
    if not hand.has(card_ui):
        return false
    
    # 设置繁忙标志
    is_busy = true
    
    # 从手牌中移除卡牌
    hand.erase(card_ui)
    
    # 添加到已打出卡牌列表
    played_cards.append(card_ui)
    
    # 移动卡牌到打出区域
    card_ui.target_position = play_zone.global_position
    card_ui.rotation_degrees = 0
    
    # 更新手牌布局
    update_hand_layout()
    
    # 发送信号
    emit_signal("card_played", card_ui)
    emit_signal("hand_updated", hand)
    
    # 重置繁忙标志
    await get_tree().create_timer(0.3).timeout
    is_busy = false
    
    # 如果卡牌设置为使用后销毁
    if card_ui.card_data.burn_after_use:
        # 直接销毁卡牌而不进入弃牌堆
        all_card_uis.erase(card_ui)
        card_ui.queue_free()
    else:
        # 将卡牌移到弃牌堆
        played_cards.erase(card_ui)
        discard_pile.append(card_ui.card_data)
        all_card_uis.erase(card_ui)
        card_ui.queue_free()
    
    # 更新显示
    _update_pile_counters()
    
    # 发送弃牌堆更新信号
    emit_signal("discard_pile_updated", discard_pile.size())
    
    return true

# 清空所有牌堆和手牌
func clear_all():
    # 清空数据
    draw_pile.clear()
    discard_pile.clear()
    
    # 销毁所有卡牌UI
    for card in all_card_uis:
        card.queue_free()
    
    # 清空列表
    hand.clear()
    played_cards.clear()
    all_card_uis.clear()
    selected_card = null
    
    # 更新计数器和手牌布局
    _update_pile_counters()
    
    # 发送信号
    emit_signal("draw_pile_updated", 0)
    emit_signal("discard_pile_updated", 0)
    emit_signal("hand_updated", [])

# 更新牌堆计数器显示
func _update_pile_counters():
    if draw_pile_count:
        draw_pile_count.text = str(draw_pile.size())
    
    if discard_pile_count:
        discard_pile_count.text = str(discard_pile.size())

# 获取指定位置下的放置区域
func get_dropzone_at_position(position: Vector2) -> CustomCardDropzone:
    for zone in active_dropzones:
        if zone.is_point_in_zone(position):
            return zone
    return null

# 选择一张卡牌
func select_card(card: CustomCardUI):
    # 取消之前的选择
    if selected_card and selected_card != card:
        selected_card.set_selected(false)
    
    # 设置新选择
    selected_card = card
    if selected_card:
        selected_card.set_selected(true)
        emit_signal("card_selected", selected_card)

#------------------------ 信号处理 ------------------------#

# 卡牌被点击
func _on_card_clicked(card: CustomCardUI):
    select_card(card)

# 卡牌被悬浮
func _on_card_hovered(card: CustomCardUI):
    # 可以添加卡牌悬浮时的效果
    pass

# 卡牌取消悬浮
func _on_card_unhovered(card: CustomCardUI):
    # 可以添加卡牌取消悬浮时的效果
    pass

# 卡牌开始拖动
func _on_card_dragging_started(card: CustomCardUI):
    # 将拖动的卡牌移到最上层
    animation_layer.move_child(card, -1)
    
    # 检测鼠标下方的放置区域
    var current_zone = get_dropzone_at_position(card.global_position)
    if current_zone:
        current_zone.on_card_hover_enter(card)

# 卡牌结束拖动
func _on_card_dragging_ended(card: CustomCardUI):
    # 检查卡牌下方是否有放置区域
    var dropzone = get_dropzone_at_position(card.global_position)
    
    # 如果没有有效的放置区域，卡牌返回原位
    if not dropzone or not dropzone.can_accept_card(card):
        card.target_position = card.original_position
        card.rotation_degrees = 0
        
        # 更新手牌布局
        if hand.has(card):
            update_hand_layout()
    # 否则，处理卡牌放置到区域的逻辑
    else:
        for zone in active_dropzones:
            if zone.hovering_cards.has(card):
                zone.on_card_hover_exit(card)

# 卡牌被放下
func _on_card_dropped(card: CustomCardUI):
    # 检查卡牌下方是否有放置区域
    var dropzone = get_dropzone_at_position(card.global_position)
    
    # 如果有有效的放置区域，处理相应逻辑
    if dropzone and dropzone.can_accept_card(card):
        # 处理不同区域的逻辑
        match dropzone.zone_type:
            "play":
                # 打出卡牌
                if hand.has(card):
                    play_card(card)
            "discard":
                # 弃置卡牌
                if hand.has(card):
                    discard_card(card)
            "draw":
                # 抽牌操作通常不通过拖放触发
                pass
            "hand":
                # 确保卡牌在手牌中正确显示
                if not hand.has(card) and played_cards.has(card):
                    played_cards.erase(card)
                    add_card_to_hand(card)
        
        # 通知区域卡牌已放置
        dropzone.on_card_dropped(card)
    else:
        # 卡牌返回原位
        card.target_position = card.original_position
        
        # 更新手牌布局
        if hand.has(card):
            update_hand_layout()

# 卡牌放置到区域
func _on_card_dropped_in_zone(card: CustomCardUI, zone: CustomCardDropzone):
    # 可以添加额外的区域特定逻辑
    pass

# 卡牌悬浮在放置区域上
func _on_card_hovered_over_zone(card: CustomCardUI, zone: CustomCardDropzone):
    # 可以添加额外的交互反馈
    pass

# 卡牌离开放置区域
func _on_card_exited_zone(card: CustomCardUI, zone: CustomCardDropzone):
    # 可以添加额外的交互反馈
    pass 