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

## GameManager 功能说明

### 核心功能
- 管理游戏全局状态(玩家回合、敌人回合、商店等)
- 处理玩家数据(生命值、货币等)
- 管理敌人系统
- 处理商店系统
- 管理地图进度

### 主要接口

#### 场景管理系统
```gdscript
# 切换到新主场景
func switch_to_scene(scene_resource)

# 添加子场景
func add_subscene(parent_node, scene_resource, scene_name)

# 移除场景
func remove_scene(scene_name)

# 获取活动场景
func get_scene(scene_name)

# 显示/隐藏场景
func set_scene_visibility(scene_name, visible_state)
```

#### 敌人数据管理
```gdscript
# 设置敌人数据
func set_enemy_data(enemy_data)

# 更新敌人UI
func update_enemy_ui()

# 加载敌人数据
func load_enemy_by_id(enemy_id: String)

# 获取随机敌人
func get_random_enemy(is_elite: bool)

# 获取随机Boss
func get_random_boss()
```

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

### 信号系统
```gdscript
# 敌人被击败时触发
signal enemy_defeated

# 游戏结束时触发(参数win表示是否胜利)
signal game_over(win)

# 请求进入商店时触发
signal enter_shop_requested

# 请求返回游戏时触发
signal return_to_game_requested
```

### 游戏状态枚举
```gdscript
enum GameState {
	PLAYER_TURN,    # 玩家回合
	ENEMY_TURN,     # 敌人回合
	SHOP,           # 商店状态
	GAME_OVER       # 游戏结束
}
```
### 关于切换场景

```gdscript
	# 使用统一的添加子场景方法  
	var parent = get_tree().current_scene  
	var enemy_select_instance = add_subscene(parent, enemy_select_scene, "EnemySelectScene")  
	if not enemy_select_instance:  
		push_error("无法创建敌人选择场景")  
		return 
```
- 由于项目把Main作为root下的主节点，所以需要使用get_tree().current_scene获取当前场景，然后使用add_subscene方法添加子场景。
- 由于add_subscene方法返回的是一个引用，所以可以判断是否创建成功。
- 由于add_subscene方法是异步的，所以需要在下一帧调用get_tree().change_scene方法切换场景。

## 地图系统

### 核心组件

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

### 数据结构

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

### 主要功能

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

### 集成方式

1. **与游戏管理器的集成**:
   - 在GameManager中添加地图状态保存和获取功能
   - 添加处理地图节点事件的方法
   - 管理楼层进度和玩家数据
   - 添加地图模式入口
   - 处理在地图和其他场景（战斗、商店）之间的切换
   - 管理地图完成和楼层转换

### 使用流程

1. 玩家从主菜单选择"地图模式"
2. 显示地图场景，初始只有起点是当前节点
3. 玩家选择可用节点，触发相应内容（战斗、商店等）
4. 完成节点内容后返回地图，继续探索
5. 到达并击败Boss后，进入下一楼层，重新生成地图
6. 游戏进度存储在GameManager中，允许玩家退出并继续游戏

### 可扩展性考虑

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

### 开发说明

本项目使用Godot引擎开发，主要文件结构：

- **scenes/**：游戏场景文件
- **scripts/**：游戏脚本
- **assets/**：游戏资源
- **data/**：游戏数据（卡牌、敌人等）

## 贡献

欢迎所有形式的贡献，包括问题报告、功能请求和代码贡献。

## 待办

- [ ] 完成README.md
- [x] 修复MainMenu的bug
- [x] 修复GameManager的bug
- [x] 创建地图系统
- [ ] 修复BattleManager的bug
- [ ] godot引擎调整场景ui
- [ ] ...

2025.3.25 MainMenu前所有bug已修复。已生成占位.png资源文件。MainMenu的bug已修复，牌堆和手牌正常运行。出牌bug未修复。

2025.4.5 完成地图系统的基本功能，包括节点生成、节点交互、节点状态保存、节点类型扩展等。已完成地图系统的基本功能。
