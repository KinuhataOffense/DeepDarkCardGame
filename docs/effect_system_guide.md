# 《无火的牌局》效果系统使用指南

## 目录
1. [系统概述](#系统概述)
2. [安装与配置](#安装与配置)
3. [视觉效果管理器](#视觉效果管理器)
4. [卡牌效果系统](#卡牌效果系统)
5. [UI效果系统](#ui效果系统)
6. [最佳实践](#最佳实践)
7. [故障排除](#故障排除)

## 系统概述

《无火的牌局》效果系统是一套完整的视觉效果管理工具，用于为游戏增添哥特式暗黑风格的视觉效果。系统包含三个主要组件：

1. **视觉效果管理器（VisualEffectsManager）** - 全局后处理效果管理
2. **卡牌效果管理器（CardEffectManager）** - 卡牌视觉效果管理
3. **UI效果管理器（UIEffectManager）** - 界面元素效果管理

这些组件共同工作，为游戏提供一致的视觉风格和氛围。

## 安装与配置

### 自动加载配置

为确保视觉效果系统在整个游戏中可用，需要将`VisualEffectsManager`添加为自动加载脚本：

1. 打开Godot编辑器
2. 进入"项目 > 项目设置 > 自动加载"
3. 添加新的自动加载项：
   - 路径：`res://scripts/core/visual_effects_manager.gd`
   - 名称：`VisualEffectsManager`
   - 作用域：Global

或者，可以使用提供的自动加载脚本：

```gdscript
# 在项目的入口脚本中添加
var effect_autoload = load("res://scripts/autoload/effect_system_autoload.gd").new()
add_child(effect_autoload)
```

### 文件结构

效果系统的核心文件：

```
scripts/
  ├── core/
  │   ├── post_processing_manager.gd
  │   └── visual_effects_manager.gd
  ├── effects/
  │   ├── card_effect_manager.gd
  │   └── ui_effect_manager.gd
  └── autoload/
      └── effect_system_autoload.gd

assets/
  ├── shaders/
  │   ├── card_aged.gdshader
  │   ├── card_glow.gdshader
  │   ├── card_burn.gdshader
  │   ├── card_soulfire.gdshader
  │   ├── post_processing.gdshader
  │   ├── ui_button.gdshader
  │   └── ui_panel.gdshader
  └── materials/
      └── cards/
          ├── card_worn.tres
          ├── card_worn_light.tres
          └── card_worn_heavy.tres
```

## 视觉效果管理器

视觉效果管理器提供游戏全局的后处理效果，如暗角、胶片颗粒、色调映射等。

### 基本用法

```gdscript
# 应用预设效果
VisualEffectsManager.apply_preset(VisualEffectsManager.VisualPreset.CINEMATIC)

# 设置场景类型（自动调整效果参数）
VisualEffectsManager.set_scene_type(PostProcessingManager.SceneType.BATTLE)

# 启用/禁用特定效果
VisualEffectsManager.set_effect_enabled(PostProcessingManager.EffectType.FILM_GRAIN, false)

# 全局启用/禁用所有效果
VisualEffectsManager.set_enabled(false)
```

### 预设效果

系统提供五种预设效果：

1. **DEFAULT** - 默认设置，平衡的效果
2. **CINEMATIC** - 电影风格，强调氛围和色彩
3. **PERFORMANCE** - 性能优先，减少效果复杂度
4. **HORROR** - 恐怖风格，增强暗角和扭曲效果
5. **CLASSIC** - 经典风格，复古色彩和噪点

### 场景类型

系统根据不同场景类型自动调整参数：

1. **MENU** - 主菜单，强调氛围
2. **MAP** - 地图界面，提高可读性
3. **BATTLE** - 战斗场景，保持紧张感
4. **SHOP** - 商店界面，更为明亮
5. **REST** - 休息点，温暖舒适的效果

## 卡牌效果系统

卡牌效果系统为游戏中的卡牌添加视觉效果，如磨损纹理、发光、黑火等效果。

### 基本用法

```gdscript
# 创建卡牌效果管理器
var card_effect_manager = CardEffectManager.new()
add_child(card_effect_manager)

# 设置目标卡牌
card_effect_manager.set_target(your_card_node)

# 应用磨损效果
card_effect_manager.apply_worn_effect(CardEffectManager.WornLevel.LIGHT)

# 应用特殊效果
card_effect_manager.apply_special_effect(CardEffectManager.EffectType.GLOW)

# 根据卡牌稀有度应用效果
card_effect_manager.apply_rarity_effect(card_rarity)

# 清除效果
card_effect_manager.clear_effects()
```

### 磨损等级

系统支持四种磨损等级：

1. **NONE** - 无磨损
2. **LIGHT** - 轻微磨损，适合稀有卡牌
3. **NORMAL** - 普通磨损，适合常见卡牌
4. **HEAVY** - 严重磨损，适合古老或特殊卡牌

### 特殊效果

系统支持多种特殊效果：

1. **NONE** - 无特效
2. **GLOW** - 基础发光效果
3. **BURN** - 黑火燃烧效果
4. **SOULFIRE** - 灵魂火焰效果
5. **ENHANCED_GLOW** - 增强型发光效果

## UI效果系统

UI效果系统为游戏界面元素添加视觉效果，如石质纹理、老旧效果等。

### 基本用法

```gdscript
# 创建UI效果管理器
var ui_effect_manager = UIEffectManager.new()
add_child(ui_effect_manager)

# 应用按钮效果
ui_effect_manager.apply_button_effect(your_button, 0.7, 0.4)

# 应用面板效果
ui_effect_manager.apply_panel_effect(your_panel, 0.7, 0.5)

# 应用菜单框架效果
ui_effect_manager.apply_menu_frame_effect(your_frame, 0.6, 0.2)

# 批量应用哥特式主题
ui_effect_manager.apply_gothic_theme({
    "buttons": [button1, button2],
    "panels": [panel1, panel2],
    "frames": [frame1, frame2]
})

# 清除效果
ui_effect_manager.clear_effect(your_control)
```

### 效果类型

系统支持多种UI效果：

1. **NONE** - 无效果
2. **STONE_BUTTON** - 石质按钮效果
3. **DARK_PANEL** - 暗色面板效果
4. **SCROLL_PANEL** - 卷轴面板效果（计划中）

## 最佳实践

### 性能考虑

1. 在移动设备上使用`PERFORMANCE`预设
2. 减少同时使用的特效数量
3. 对非关键UI元素使用简单效果

### 样式一致性

1. 为相同类型的元素使用一致的效果
2. 根据游戏区域统一调整效果参数
3. 使用预设而非单独设置参数

### 集成流程

1. 在场景脚本中尽早设置场景类型：
   ```gdscript
   func _ready():
       VisualEffectsManager.set_scene_type(PostProcessingManager.SceneType.BATTLE)
   ```

2. 为卡牌类添加效果支持：
   ```gdscript
   class Card:
       var effect_manager = CardEffectManager.new()
       
       func _ready():
           add_child(effect_manager)
           effect_manager.set_target(self)
           apply_card_effect()
       
       func apply_card_effect():
           effect_manager.apply_rarity_effect(rarity)
   ```

3. 重用UI效果管理器：
   ```gdscript
   # 在主UI脚本中
   var ui_manager = UIEffectManager.new()
   
   func _ready():
       add_child(ui_manager)
       apply_effects_to_all_ui()
   ```

## 故障排除

### 常见问题

1. **效果没有显示**
   - 检查VisualEffectsManager是否正确自动加载
   - 确认后处理效果已启用(`set_enabled(true)`)
   - 检查目标节点是否被其他节点遮挡

2. **卡牌效果不显示**
   - 确认卡牌节点是Control类型
   - 检查着色器是否正确加载
   - 确认目标节点可见且未被遮挡

3. **UI效果应用后视觉异常**
   - 尝试调低效果强度参数
   - 确认UI主题与shader参数不冲突
   - 对特定按钮组使用自定义参数

### 调试方法

使用提供的效果系统演示场景(`effect_system_demo.tscn`)测试不同效果组合，通过控制台输出诊断信息：

```gdscript
# 诊断视觉效果管理器
func debug_visual_effects():
    var manager = get_node_or_null("/root/VisualEffectsManager")
    if manager:
        print("当前预设: ", manager.get_current_preset())
        print("场景类型: ", manager.get_post_processor().get_current_scene_type())
        print("效果状态: ", {
            "vignette": manager.is_effect_enabled(PostProcessingManager.EffectType.VIGNETTE),
            "film_grain": manager.is_effect_enabled(PostProcessingManager.EffectType.FILM_GRAIN),
            "color_shift": manager.is_effect_enabled(PostProcessingManager.EffectType.COLOR_SHIFT)
        })
    else:
        push_error("VisualEffectsManager未找到")
```

若需进一步帮助，请联系开发团队。 