extends Node
class_name CardManager

# 子组件引用
var pile_manager: CustomCardPileManager
var layout_manager: HandCardLayout

# 卡牌数据缓存
var all_cards: Dictionary = {}  # 所有可用卡牌的字典 {id: CardData}
var player_deck: Array[CardData] = []  # 玩家当前牌组
var available_cards: Array[CardData] = []  # 可获取的卡牌池

# 初始化
func initialize(pile_manager_node: CustomCardPileManager):
    pile_manager = pile_manager_node
    layout_manager = HandCardLayout.new()
    
    # 配置手牌布局参数
    layout_manager.card_spacing = 80.0
    layout_manager.curve_radius = 1000.0
    layout_manager.curve_angle = 40.0
    layout_manager.hover_raise = 50.0
    
    # 配置卡牌管理器
    pile_manager.auto_sort_hand = true
    
    # 连接信号
    pile_manager.connect("hand_updated", _on_hand_updated)
    pile_manager.connect("card_played", _on_card_played)
    pile_manager.connect("draw_pile_updated", _on_draw_pile_updated)
    pile_manager.connect("discard_pile_updated", _on_discard_pile_updated)

# 加载卡牌数据
func load_cards_from_file(file_path: String) -> bool:
    if not FileAccess.file_exists(file_path):
        print("卡牌数据文件不存在: " + file_path)
        return false
    
    var file = FileAccess.open(file_path, FileAccess.READ)
    var json_text = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var error = json.parse(json_text)
    if error != OK:
        print("解析卡牌数据失败: " + json.get_error_message())
        return false
    
    var card_data = json.get_data()
    if typeof(card_data) != TYPE_ARRAY:
        print("卡牌数据格式错误，应为数组")
        return false
    
    # 清空现有卡牌数据
    all_cards.clear()
    
    # 解析并创建卡牌数据
    for card_info in card_data:
        var card = CardData.new()
        card.id = card_info.id
        card.name = card_info.name
        card.description = card_info.description
        card.value = card_info.value if "value" in card_info else 0
        
        # 设置花色
        if "suit" in card_info:
            match card_info.suit:
                "spades": card.suit = CardData.CardSuit.SPADES
                "hearts": card.suit = CardData.CardSuit.HEARTS
                "clubs": card.suit = CardData.CardSuit.CLUBS
                "diamonds": card.suit = CardData.CardSuit.DIAMONDS
                "special": card.suit = CardData.CardSuit.SPECIAL
        
        # 设置类型
        if "type" in card_info:
            match card_info.type:
                "attack": card.card_type = CardData.CardType.ATTACK
                "defense": card.card_type = CardData.CardType.DEFENSE
                "skill": card.card_type = CardData.CardType.SKILL
                "power": card.card_type = CardData.CardType.POWER
                "status": card.card_type = CardData.CardType.STATUS
                "curse": card.card_type = CardData.CardType.CURSE
        
        # 设置稀有度
        if "rarity" in card_info:
            match card_info.rarity:
                "common": card.rarity = CardData.CardRarity.COMMON
                "uncommon": card.rarity = CardData.CardRarity.UNCOMMON
                "rare": card.rarity = CardData.CardRarity.RARE
                "legendary": card.rarity = CardData.CardRarity.LEGENDARY
        
        # 设置纹理路径
        if "texture" in card_info:
            card.texture_path = card_info.texture
        
        # 设置背面纹理路径
        if "backface" in card_info:
            card.backface_texture_path = card_info.backface
        
        # 设置使用后销毁
        if "burn_after_use" in card_info:
            card.burn_after_use = card_info.burn_after_use
        
        # 设置效果
        if "effects" in card_info:
            card.effects = card_info.effects
        
        # 添加自定义属性
        if "custom_properties" in card_info:
            card.custom_properties = card_info.custom_properties
        
        # 将卡牌添加到字典
        all_cards[card.id] = card
    
    print("成功加载 " + str(all_cards.size()) + " 张卡牌")
    return true

# 初始化玩家牌组
func initialize_player_deck(card_ids: Array[String]):
    player_deck.clear()
    
    for card_id in card_ids:
        if card_id in all_cards:
            player_deck.append(all_cards[card_id].duplicate())
    
    print("玩家牌组初始化完成，共 " + str(player_deck.size()) + " 张卡牌")
    
    # 初始化卡牌管理器
    pile_manager.initialize_deck(player_deck)

# 添加卡牌到玩家牌组
func add_card_to_deck(card_id: String):
    if card_id in all_cards:
        var card = all_cards[card_id].duplicate()
        player_deck.append(card)
        
        # 如果当前战斗中，则添加到抽牌堆
        if pile_manager:
            pile_manager.draw_pile.append(card)
            pile_manager.shuffle_draw_pile()
            pile_manager._update_pile_counters()
        
        return true
    
    return false

# 从玩家牌组移除卡牌
func remove_card_from_deck(card_id: String, count: int = 1):
    var removed = 0
    
    for i in range(player_deck.size() - 1, -1, -1):
        if removed >= count:
            break
        
        if player_deck[i].id == card_id:
            player_deck.remove_at(i)
            removed += 1
    
    return removed

# 抽牌
func draw_cards(count: int = 1):
    if pile_manager:
        pile_manager.draw_cards(count)

# 弃牌
func discard_hand():
    if pile_manager:
        pile_manager.discard_hand()

# 洗牌
func shuffle_draw_pile():
    if pile_manager:
        pile_manager.shuffle_draw_pile()

# 重置牌组
func reset_deck():
    if pile_manager:
        pile_manager.clear_all()
        pile_manager.initialize_deck(player_deck)

# 获取玩家牌组副本
func get_player_deck() -> Array[CardData]:
    var deck_copy: Array[CardData] = []
    for card in player_deck:
        deck_copy.append(card.duplicate())
    return deck_copy

# 获取当前手牌
func get_hand() -> Array[CustomCardUI]:
    if pile_manager:
        return pile_manager.hand
    return []

# 获取抽牌堆大小
func get_draw_pile_size() -> int:
    if pile_manager:
        return pile_manager.draw_pile.size()
    return 0

# 获取弃牌堆大小
func get_discard_pile_size() -> int:
    if pile_manager:
        return pile_manager.discard_pile.size()
    return 0

# 信号处理函数
func _on_hand_updated(cards: Array):
    # 使用布局管理器重新布局
    if pile_manager and pile_manager.hand_zone:
        layout_manager.arrange_cards(cards, pile_manager.hand_zone.global_position)

func _on_card_played(card: CustomCardUI):
    print("卡牌已打出: " + card.card_data.name)
    # 在这里可以处理卡牌效果

func _on_draw_pile_updated(count: int):
    print("抽牌堆更新: " + str(count) + " 张卡牌")

func _on_discard_pile_updated(count: int):
    print("弃牌堆更新: " + str(count) + " 张卡牌") 