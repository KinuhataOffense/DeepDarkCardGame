# 卡牌老旧效果使用指南

本文档介绍如何在游戏中使用卡牌老旧效果着色器，为卡牌添加中世纪手抄本风格的视觉效果。

## 概述

卡牌老旧效果是一组通过着色器实现的视觉效果，可以为卡牌添加以下特性：

- 边缘磨损和撕裂
- 纸张泛黄和褪色
- 随机污渍和水渍
- 微小折痕和皱纹
- 纸面灰尘和微粒
- 色彩变化

这些效果的组合可以创造出各种程度的老旧感，从几乎全新到严重磨损的古老卡牌，非常适合中世纪风格的卡牌游戏。

## 可用资源

本系统包含以下资源：

1. **着色器文件**：
   - `assets/shaders/card_worn.gdshader`: 卡牌老旧效果的主着色器文件

2. **材质预设**：
   - `assets/materials/cards/card_worn_light.tres`: 轻微老旧效果
   - `assets/materials/cards/card_worn.tres`: 中等老旧效果
   - `assets/materials/cards/card_worn_heavy.tres`: 严重老旧效果

3. **纹理资源**：
   - `assets/textures/noise/noise_damage.png`: 边缘损坏纹理

4. **脚本文件**：
   - `scripts/effects/card_worn_effect.gd`: 控制卡牌老旧效果的脚本
   - `scripts/tools/create_damage_texture.gd`: 生成损坏纹理的工具脚本

5. **演示场景**：
   - `scenes/debug/card_worn_effect_demo.tscn`: 展示不同老旧效果的演示场景

## 基本用法

### 方法一：使用 CardManager 自动添加效果

最简单的方法是使用 `CardManager` 中的 `apply_worn_effect` 方法，它会自动根据卡牌稀有度添加适当的老旧效果：

```gdscript
# 在创建卡牌后应用老旧效果
var card_instance = card_scene.instantiate()
# ... 设置卡牌属性 ...

# 应用老旧效果，参数为卡牌稀有度 (0-普通, 1-稀有, 2-史诗, 3-传说)
CardManager.apply_worn_effect(card_instance, rarity)
```

### 方法二：手动添加效果组件

你也可以手动添加和控制老旧效果：

```gdscript
# 创建卡牌
var card_instance = card_scene.instantiate()
add_child(card_instance)

# 添加老旧效果组件
var worn_effect = load("res://scripts/effects/card_worn_effect.gd").new()
worn_effect.name = "WornEffect"
card_instance.add_child(worn_effect)

# 设置老旧程度 (NONE, LIGHT, MEDIUM, HEAVY)
worn_effect.preset = worn_effect.WornPreset.MEDIUM

# 可选：随机化参数
worn_effect.randomize_worn_parameters(0.3, 0.6)
```

### 方法三：直接应用材质

如果只需要简单应用预设材质，可以直接设置 Sprite 节点的材质：

```gdscript
# 获取卡牌精灵节点
var card_sprite = card_instance.get_node("Sprite2D")

# 应用老旧效果材质
card_sprite.material = load("res://assets/materials/cards/card_worn.tres")
```

## 自定义效果参数

卡牌老旧效果提供了多个参数，可以精细控制卡牌的视觉表现：

| 参数名 | 范围 | 描述 |
|-------|------|------|
| worn_amount | 0.0-1.0 | 总体磨损程度 |
| edge_worn | 0.0-1.0 | 边缘撕裂和磨损程度 |
| stain_amount | 0.0-1.0 | 污渍和水渍程度 |
| dust_amount | 0.0-1.0 | 表面灰尘程度 |
| crease_amount | 0.0-1.0 | 折痕和皱纹程度 |
| color_fade | 0.0-1.0 | 颜色褪色程度 |
| yellowing | 0.0-1.0 | 纸张泛黄程度 |
| stain_color | Color | 污渍颜色 |
| dust_color | Color | 灰尘颜色 |
| edge_darkness | 0.0-1.0 | 边缘暗化程度 |
| randomness | 0.0-1.0 | 效果随机变化程度 |
| unique_seed | 浮点数 | 每张卡牌的唯一随机种子 |

要修改这些参数，可以使用以下方法：

```gdscript
# 获取老旧效果组件
var worn_effect = card_instance.get_node("WornEffect")

# 设置参数
worn_effect.worn_amount = 0.5
worn_effect.edge_worn = 0.7
worn_effect.stain_amount = 0.3
# ...设置其他参数...

# 或者使用随机化功能
worn_effect.randomize_worn_parameters(0.4, 0.8)
```

## 按稀有度应用效果

推荐为不同稀有度的卡牌应用不同程度的老旧效果：

- **普通卡牌**：中等老旧 (磨损明显)
- **稀有卡牌**：轻微老旧 (保存较好)
- **史诗卡牌**：几乎无老旧 (保存完好)
- **传说卡牌**：无老旧效果 (崭新状态)
- **古老特殊卡牌**：严重老旧 (年代久远)

这种设计既符合游戏世界观，又能通过视觉效果直观地表达卡牌稀有度。

## 生成自定义纹理

如果需要自定义损坏纹理，可以使用提供的工具脚本：

1. 在编辑器中：选择脚本 `scripts/core/generate_damage_texture.gd` 然后点击"运行"
2. 通过命令行：`godot --headless --script scripts/tools/create_damage_texture.gd`

## 故障排除

### 常见问题

1. **效果不显示**：
   - 确保纹理文件 `noise_damage.png` 存在
   - 检查卡牌节点是否有老旧效果组件
   - 验证材质已正确应用到精灵节点

2. **效果过强或过弱**：
   - 调整各个参数值，特别是 `worn_amount` 和 `edge_worn`
   - 使用预设 (LIGHT, MEDIUM, HEAVY) 作为起点

3. **效果在所有卡牌上相同**：
   - 确保每张卡牌有不同的 `unique_seed` 值
   - 使用 `randomize_worn_parameters()` 方法为每张卡牌生成随机参数

## 性能考虑

卡牌老旧效果着色器经过优化，适合同时在多张卡牌上使用，但在低性能设备上，应注意以下几点：

1. 当场景中显示大量卡牌时，可以降低效果复杂度
2. 考虑为非关键卡牌禁用部分效果参数
3. 在菜单中添加选项，允许玩家调整或禁用卡牌视觉效果

## 演示场景

可以运行 `scenes/debug/card_worn_effect_demo.tscn` 场景，体验不同级别的老旧效果，并使用UI控件实时调整各个参数。 