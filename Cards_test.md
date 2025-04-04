
## 自定义卡牌系统

游戏使用自定义的卡牌系统，而不是依赖第三方插件。该系统包含以下组件：

### 核心组件

#### CardManager (scripts/cards/card_manager.gd)

`CardManager`是卡牌系统的核心接口，负责：
- 加载和管理卡牌数据
- 处理玩家牌组
- 提供对卡牌操作的简化API
- 连接卡牌系统与游戏逻辑

使用示例：
```gdscript
# 初始化卡牌管理器
var card_manager = CardManager.new()
card_manager.initialize($CardPileManager)

# 加载卡牌数据并初始化玩家牌组
card_manager.load_cards_from_file("res://data/cards.json")
card_manager.initialize_player_deck(["card_1", "card_2", "card_3"])

# 游戏中使用
card_manager.draw_cards(5)  # 抽5张牌
card_manager.shuffle_draw_pile()  # 洗牌
```

#### CardData (scripts/cards/card_data.gd)

`CardData`类是所有卡牌的基础数据结构，包含：
- 基本属性：id, 名称, 描述, 数值, 花色, 卡牌类型, 稀有度
- 视觉属性：纹理路径, 背面纹理路径
- 特殊效果：使用后销毁, 效果数组
- 自定义属性：可以通过自定义属性字典扩展功能

#### CardEffect (scripts/cards/card_effect.gd)

`CardEffect`类定义了卡牌可以产生的各种效果：
- 效果类型：伤害、格挡、治疗、增益、减益等
- 效果目标：自身、敌人、所有敌人等
- 效果值：数值大小
- 效果应用：处理效果作用于目标的逻辑

#### CardUtils (scripts/cards/card_utils.gd)

`CardUtils`提供了一系列静态工具函数：
- 从JSON加载/保存卡牌数据
- 卡牌筛选和查找功能
- 颜色和视觉效果辅助函数
- 卡牌数据转换工具

### 视觉和交互组件

#### CustomCardUI (scripts/cards/card_ui.gd)

`CustomCardUI`类负责卡牌的视觉呈现和交互：
- 信号系统：悬浮, 点击, 拖放等交互事件
- 视觉状态：选中, 标记, 禁用等状态的视觉反馈
- 动画效果：平滑移动, 缩放, 旋转等动画
- 交互处理：处理鼠标事件，实现拖放功能

#### CustomCardDropzone (scripts/cards/card_dropzone.gd)

`CustomCardDropzone`类定义了卡牌可以放置的区域：
- 放置验证：检查是否可以接受特定卡牌
- 视觉反馈：区域高亮、有效/无效状态显示
- 信号系统：卡牌放置、悬浮、离开的事件处理

#### CustomCardPileManager (scripts/cards/card_pile_manager.gd)

`CustomCardPileManager`类负责管理所有牌堆：
- 牌堆管理：抽牌堆、弃牌堆、手牌等
- 卡牌操作：抽牌、弃牌、打出等基本操作
- 布局管理：自动排列手牌，处理卡牌位置
- 交互处理：处理卡牌与放置区域的交互

### 布局管理器

为了实现不同的卡牌排列方式，系统提供了三种布局管理器：

#### FanCardLayout (scripts/cards/fan_card_layout.gd)

扇形布局管理器，适用于展示卡牌收藏或奖励选择：
- 扇形排列：卡牌呈扇形展开
- 平滑动画：卡牌移动时平滑过渡
- 收集动画：将卡牌收集到一个点

#### GridCardLayout (scripts/cards/grid_card_layout.gd)

网格布局管理器，适用于卡组编辑或商店：
- 网格排列：卡牌按行列排列
- 透视效果：可选的3D透视效果
- 操作函数：添加/移除卡牌并重新排列

#### HandCardLayout (scripts/cards/hand_card_layout.gd)

手牌布局管理器，专门用于游戏中的手牌：
- 弧线排列：卡牌沿弧线排列，模拟真实手持效果
- 动态间距：基于卡牌数量动态调整间距
- 动画效果：抽牌和打出卡牌的特殊动画

## 调用关系

卡牌系统的调用关系如下：

1. **游戏逻辑** -> **CardManager**：游戏代码通过CardManager与卡牌系统交互
2. **CardManager** -> **CustomCardPileManager**：CardManager将操作委托给CustomCardPileManager执行
3. **CustomCardPileManager** -> **CustomCardUI**：管理卡牌UI实例的创建、布局和交互
4. **CustomCardUI** <-> **CustomCardDropzone**：处理卡牌与放置区域的交互
5. **手牌布局**：CustomCardPileManager使用HandCardLayout管理手牌布局
6. **卡牌效果**：卡牌打出时，通过CardEffect处理效果应用

## 卡牌数据格式

卡牌数据保存为JSON格式，示例如下：

```json
[
  {
	"id": "strike",
	"name": "打击",
	"description": "造成6点伤害",
	"value": 6,
	"type": "attack",
	"rarity": "common",
	"texture": "res://assets/cards/strike.png",
	"effects": [
	  {
		"type": "damage",
		"target": "enemy",
		"value": 6
	  }
	]
  },
  {
	"id": "defend",
	"name": "防御",
	"description": "获得5点格挡",
	"value": 5,
	"type": "defense",
	"rarity": "common",
	"texture": "res://assets/cards/defend.png",
	"effects": [
	  {
		"type": "block",
		"target": "self",
		"value": 5
	  }
	]
  }
]
```

## 使用示例

### 初始化卡牌系统

```gdscript
# 获取节点引用
@onready var pile_manager = $CardPileManager

# 创建卡牌管理器
var card_manager = CardManager.new()
add_child(card_manager)

# 初始化
card_manager.initialize(pile_manager)

# 加载卡牌数据
card_manager.load_cards_from_file("res://data/cards.json")

# 初始化玩家牌组
var starter_deck = ["strike", "strike", "defend", "defend", "special_card"]
card_manager.initialize_player_deck(starter_deck)
```

### 游戏中使用

```gdscript
# 回合开始时抽牌
func start_turn():
	card_manager.draw_cards(5)
	
# 回合结束时弃牌
func end_turn():
	card_manager.discard_hand()
	
# 添加新卡牌到牌组
func add_card_reward(card_id):
	card_manager.add_card_to_deck(card_id)
	
# 打出卡牌
func play_selected_card():
	var selected = card_manager.selected_card
	if selected:
		var result = card_manager.play_card(selected)
		# 处理卡牌效果结果
```