# 无火的牌局

## 出牌得分系统

- 出牌组合得分
  - **灰烬**：一张孤立的牌 (10筹码)
  - **魂组**：两张相同的牌 (15筹码)
  - **魂链**：三张连续同花色牌 (25筹码)
  - **刻印**：三张相同的牌 (40筹码)
  - **王印**：四张相同的牌 (60筹码)
  - 其他非法组合不能打出。
- 结算机制
  - 打出的牌移出手牌，计算初火碎片 = 筹码 × 倍率
  - 摸回对应数量的牌

## 敌人挑战系统

开始游戏后，玩家逐个遭遇敌人，敌人分为"小怪"和"BOSS"。要击败敌人需要在限制的出牌次数内达到要求的初火碎片。

BOSS还有特殊debuff。例子：

- 每三轮会使用"祈祷"，使你下一轮无法使用魔法牌
- 每轮开始时，随机一张手牌被标记，若未在该轮使用则受到10点伤害
- 每第五轮，所有手牌倍率减半
- 每次打出王印后，手牌区域暂时被封印一轮
- 随机改变牌的数值，增加组合难度

## 商店道具系统

击败一个敌人后，获得一定灵魂，然后进入商店。从商店离开后遭遇下一个敌人。

### 牌堆修改

例子：

- **锻造**：将几张普通牌升级为强化牌
- **星宿**：加入一张特殊卡牌
- **黑矢**：删除几张不需要的牌

### 消耗型道具

例子：

- **火焰卷轴**：临时增加顺子组合50%倍率，持续3轮
- **日光皂石**：预见接下来将摸到的3张牌
- **人性碎片**：一次重新排列所有手牌的机会
- **净化宝珠**：移除一张带有负面效果的牌

### 永久升级

例子：

- **刻印精通**：永久提升刻子组合的筹码值(+5)和倍率(+0.3)
- **灵魂链接**：每完成3次魂链，获得一次额外行动
- **火之传承**：每回合首次组合获得额外25%得分
- **魂之容器**：增加最大生命值上限，提升生存能力

### 被动效果道具

例子：

- **守护之戒**：每回合一次，可以保护一张牌不被敌人效果影响
- **猎龙戒指**：增加10%对龙系敌人的得分
- **咒缚戒指**：可以将一张牌暂时锁定，延迟其效果到下一轮触发
- **混沌戒指**：每轮牌组中随机加入两张混沌牌
- **深渊戒指**：允许进入隐藏深渊区域而不受伤害，但得分降低25%

## 特殊牌效果

### 强化牌效果

例子：

- **锻造石牌**：打出后此牌不移除，可再次使用，但每次使用后降低1点筹码值
- **魂之牌**：可以吸收相邻牌的特性，但每回合结束时会消耗1点生命
- **黑火牌**：使包含它的组合分数翻倍，但结算后永久烧毁，并对玩家造成5点伤害

### 特殊卡牌效果

例子：

- **人性牌**：可作为任意牌参与组合，但使用后会触发随机事件
- **混沌牌**：每回合开始时变为此牌左侧的牌，结算时有20%几率产生额外收益
- **龙契牌**：打出后行动次数+1，但下回合开始时手牌上限-1
- **暗月牌**：可同时参与两个不同组合的结算，但使用后永久离场

## 剧情

玩家作为一名不死人，必须通过牌局挑战来收集足够的初火碎片，最终面对葛温王，决定是延续火之时代还是迎来黑暗时代。

## 待办

- [ ] 完成README.md
- [x] 修复MainMenu的bug
- [ ] 修复GameManager的bug
- [ ] godot引擎调整场景ui
- [ ] ...

2025.3.25 MainMenu前所有bug已修复。已生成占位.png资源文件。MainMenu的bug已修复，牌堆和手牌正常运行。出牌bug未修复。

# 深渊卡牌游戏 (DeepDarkCardGame)

一个使用Godot 4引擎开发的卡牌roguelike游戏。

## 主要功能

- 基于节点的地图系统，支持随机生成的关卡
- 回合制战斗系统，具有丰富的卡牌效果
- 角色进度系统，可以解锁新的能力和卡牌
- 敌人AI系统，提供各种不同的挑战
- 卡牌收集系统，支持不同类型和稀有度的卡牌

## GameManager 功能说明

### 核心功能
- 管理游戏全局状态(玩家回合、敌人回合、商店等)
- 处理玩家数据(生命值、货币等)
- 管理敌人系统
- 处理商店系统
- 管理地图进度

### 主要接口

#### 商店系统
```gdscript
# 进入商店
func enter_shop()

# 离开商店  
func leave_shop()

# 加载商店物品(从JSON)
func load_shop_items()

# 购买商店物品
func purchase_shop_item(item_index: int) -> bool

# 获取当前商店物品
func get_shop_items() -> Array

# 获取玩家货币
func get_player_currency() -> int
```

#### 游戏流程控制
```gdscript
# 进入游戏
func initialize_game()

# 生成敌人
func spawn_next_enemy()

# 处理胜利奖励
func process_victory_rewards()

# 处理失败
func process_defeat()
```

#### 地图系统
```gdscript
# 保存地图状态
func save_map_state(map_state)

# 获取地图状态
func get_map_state()

# 处理地图节点事件
func handle_map_node_event(node_type, node_data)
```

### 数据管理
- 玩家数据存储在`player_data`字典中
- 商店物品数据从`res://data/shop_items.json`加载
- 敌人数据从`res://data/enemies.json`加载

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

# 地图系统

## 核心组件

1. **节点地图场景（node_map_scene）**:
   - 管理整个地图的显示和交互
   - 生成随机地图布局
   - 处理玩家在地图上的进度

2. **地图节点（map_node）**:
   - 表示地图上的各种地点（敌人、商店、休息点等）
   - 管理节点状态（锁定、可用、已访问、当前）
   - 处理玩家交互

3. **地图连接线（map_edge）**:
   - 显示节点之间的连接关系
   - 根据可用性和访问状态改变外观

## 数据结构

1. **节点类型枚举（NodeType）**:
   - START: 起点节点
   - ENEMY: 普通敌人节点
   - ELITE: 精英敌人节点
   - SHOP: 商店节点
   - REST: 休息节点
   - TREASURE: 宝箱节点
   - EVENT: 事件节点
   - BOSS: Boss节点
   - END: 终点节点

2. **节点状态枚举（NodeState）**:
   - LOCKED: 锁定状态，玩家无法访问
   - AVAILABLE: 可用状态，玩家可以访问
   - VISITED: 已访问状态
   - CURRENT: 当前位置

3. **地图状态数据**:
   - current_floor: 当前楼层
   - current_node_id: 当前节点ID
   - nodes_state: 所有节点的状态信息

## 主要功能

1. **地图生成**:
   - 分层生成节点，每层有预定数量的节点
   - 随机决定每个节点的类型
   - 创建节点间的连接关系，确保路径合理性

2. **地图导航**:
   - 玩家只能访问从当前节点可达的节点
   - 访问节点后更新状态，并解锁新的可访问节点
   - 显示路径可用性（高亮或变暗）

3. **节点交互**:
   - 不同节点类型触发不同的游戏内容（战斗、商店、事件等）
   - 完成节点内容后返回地图继续探索
   - 到达Boss节点并击败后完成当前楼层

4. **状态保存**:
   - 保存玩家在地图上的进度
   - 在不同场景（战斗、商店）间切换时保持地图状态
   - 在完成楼层后重置地图状态，进入新楼层

## 集成方式

1. **与游戏管理器的集成**:
   - 在GameManager中添加地图状态保存和获取功能
   - 添加处理地图节点事件的方法
   - 管理楼层进度和玩家数据

2. **与场景管理器的集成**:
   - 添加地图模式入口
   - 处理在地图和其他场景（战斗、商店）之间的切换
   - 管理地图完成和楼层转换

## 使用流程

1. 玩家从主菜单选择"地图模式"
2. 显示地图场景，初始只有起点是当前节点
3. 玩家选择可用节点，触发相应内容（战斗、商店等）
4. 完成节点内容后返回地图，继续探索
5. 到达并击败Boss后，进入下一楼层，重新生成地图
6. 游戏进度存储在GameManager中，允许玩家退出并继续游戏

## 可扩展性考虑

1. **节点类型扩展**:
   - 可以轻松添加新的节点类型，如特殊事件、挑战等
   - 每种节点类型可以有多种变体

2. **地图生成算法改进**:
   - 可以实现不同的地图生成策略（更随机、更线性等）
   - 可以根据游戏进度增加难度

3. **UI优化**:
   - 添加缩放和平移功能
   - 实现小地图或全局视图
   - 添加更多视觉效果提升游戏体验 

## 安装与使用

1. 克隆仓库到本地
2. 使用Godot 4.x版本打开项目
3. 运行游戏，开始新的冒险!

## 贡献

欢迎所有形式的贡献，包括问题报告、功能请求和代码贡献。

## 游戏特点

- **卡牌战斗系统**：收集各种卡牌，利用组合效果击败敌人
- **地下城探索**：通过节点地图系统，探索不同路径和遭遇
- **多样敌人**：面对普通敌人、精英怪物和强大的Boss
- **资源管理**：管理生命值、金币等资源，在商店购买新卡牌和道具
- **决策影响**：地图路径的选择将影响游戏难度和获得的奖励

## 游戏模式

游戏提供两种主要模式：

1. **战斗模式**：直接选择敌人进行战斗
2. **地图模式**：通过节点地图探索地下城，面对不同类型的遭遇

## 节点地图系统

地图系统是游戏的核心玩法之一，灵感来源于《杀戮尖塔》。地图具有以下特点：

- **分层结构**：每个地下城由多个层级组成，玩家从底层向上层进行探索
- **节点类型**：
  - **战斗节点**：与普通敌人战斗
  - **精英节点**：与精英敌人战斗，难度更高但奖励更丰富
  - **商店节点**：购买卡牌、道具或恢复生命
  - **休息节点**：恢复生命值
  - **事件节点**：随机事件，可能带来好处或挑战
  - **宝箱节点**：获得随机奖励
  - **Boss节点**：每层的最终挑战
- **路径选择**：玩家可以选择不同的路径，影响游戏难度和获得的奖励
- **进度保存**：地图状态会被保存，允许玩家在不同遭遇间切换

## 操作指南

1. **主菜单**：
   - **开始战斗**：进入战斗模式，选择敌人进行战斗
   - **地图模式**：进入地下城探索模式
   - **退出**：退出游戏

2. **地图界面**：
   - 点击可用节点前进
   - 查看当前状态（生命值、金币等）
   - 返回按钮可返回主菜单

3. **战斗界面**：
   - 使用卡牌进行战斗
   - 结束回合按钮
   - 查看敌人信息和战斗进度

4. **商店界面**：
   - 购买卡牌和道具
   - 升级现有卡牌
   - 返回地图

## 开发说明

本项目使用Godot引擎开发，主要文件结构：

- **scenes/**：游戏场景文件
  - **map/**：地图相关场景
- **scripts/**：游戏脚本
  - **core/**：核心系统脚本
  - **map/**：地图系统脚本
- **assets/**：游戏资源
- **data/**：游戏数据（卡牌、敌人等）
