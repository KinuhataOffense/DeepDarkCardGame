# 《无火的牌局》视觉效果系统使用指南

## 目录
1. [系统概述](#系统概述)
2. [后处理效果说明](#后处理效果说明)
3. [使用方法](#使用方法)
4. [视觉效果预设](#视觉效果预设)
5. [场景类型设置](#场景类型设置)
6. [API文档](#api文档)
7. [性能优化](#性能优化)
8. [故障排除](#故障排除)

## 系统概述

《无火的牌局》视觉效果系统是一套完整的后处理效果管理工具，用于为游戏增添黑暗之魂风格的视觉氛围。系统包含两个主要组件：

1. **PostProcessingManager** - 核心后处理效果实现和管理类
2. **VisualEffectsManager** - 高级接口，提供各种视觉预设和简化的API

系统支持暗角、胶片颗粒、色调映射、色彩偏移和灰尘粒子等效果，可根据不同场景类型自动调整效果参数，营造合适的氛围。

## 后处理效果说明

### 暗角效果 (Vignette)
在屏幕边缘周围形成一个渐变的黑色边框，增强场景中心的关注度，营造压抑感或营造画面焦点。

### 胶片颗粒 (Film Grain)
添加轻微的噪点，模拟老式胶片放映的质感，增加游戏的复古感和氛围。

### 色调映射 (Tone Mapping)
调整场景的色调和对比度，使画面更加暗沉或突出，符合黑暗之魂风格的视觉表现。

### 色彩偏移 (Color Shift)
轻微改变颜色平衡，营造特定氛围，如偏向棕褐色调以增强老旧感。

### 灰尘效果 (Dust)
屏幕上漂浮的微小灰尘粒子，随时间缓慢移动，增强场景的深度感和氛围。

## 使用方法

### 系统集成

1. **自动加载VisualEffectsManager**
   
   在项目设置中将`visual_effects_manager.gd`添加为自动加载脚本：
   - 打开项目设置 -> 自动加载
   - 添加新的自动加载脚本，路径为`res://scripts/core/visual_effects_manager.gd`
   - 名称设为`VisualEffectsManager`

2. **在场景中直接使用**

   如果不想使用自动加载，也可以在需要后处理效果的场景中添加组件：
   ```gdscript
   var effects_manager = load("res://scripts/core/visual_effects_manager.gd").new()
   add_child(effects_manager)
   ```

### 基本用法

1. **应用预设效果**
   ```gdscript
   # 使用预设
   VisualEffectsManager.apply_preset(VisualEffectsManager.VisualPreset.CINEMATIC)
   ```

2. **设置场景类型**
   ```gdscript
   # 设置为战斗场景
   VisualEffectsManager.set_scene_type(PostProcessingManager.SceneType.BATTLE)
   ```

3. **切换单个效果**
   ```gdscript
   # 禁用胶片颗粒效果
   VisualEffectsManager.set_effect_enabled(PostProcessingManager.EffectType.FILM_GRAIN, false)
   ```

4. **全局启用/禁用**
   ```gdscript
   # 禁用所有后处理效果
   VisualEffectsManager.set_enabled(false)
   ```

## 视觉效果预设

系统提供以下预设：

### DEFAULT (默认)
平衡的后处理效果，适合大多数场景。

### CINEMATIC (电影风格)
强调氛围，增强的暗角和颗粒效果，适合过场动画和重要场景。

### PERFORMANCE (性能优先)
简化的效果设置，适合在低性能设备上运行，或者需要清晰视觉反馈的游戏阶段。

### HORROR (恐怖风格)
强烈的暗角和扭曲效果，适合紧张或恐怖的游戏场景。

### CLASSIC (经典风格)
复古风格，强调胶片颗粒和色彩量化，适合怀旧场景。

## 场景类型设置

系统会根据不同场景类型自动调整参数：

### MENU (主菜单)
强调氛围，较重的效果，适合展示游戏主题和风格。

### MAP (地图)
略微减轻效果，提高可读性，便于玩家查看地图信息。

### BATTLE (战斗)
适中效果，保持紧张感，同时不干扰游戏玩法。

### SHOP (商店)
较轻效果，更为明亮，方便玩家查看商品。

### REST (休息点)
温暖的效果，营造舒适感和安全感。

## API文档

### VisualEffectsManager

#### 方法
- `apply_preset(preset: VisualPreset)` - 应用视觉效果预设
- `set_scene_type(type: PostProcessingManager.SceneType)` - 设置场景类型
- `get_current_preset() -> VisualPreset` - 获取当前使用的预设
- `set_enabled(enabled: bool)` - 启用或禁用后处理效果
- `set_effect_enabled(effect_type: PostProcessingManager.EffectType, enabled: bool)` - 启用或禁用特定效果
- `is_effect_enabled(effect_type: PostProcessingManager.EffectType) -> bool` - 检查特定效果是否启用
- `set_custom_parameters(params: Dictionary)` - 设置自定义参数

### PostProcessingManager

#### 方法
- `set_vignette_intensity(value: float)` - 设置暗角效果强度
- `set_vignette_opacity(value: float)` - 设置暗角效果不透明度
- `set_vignette_color(color: Color)` - 设置暗角效果颜色
- `set_dust_amount(value: float)` - 设置灰尘效果强度
- `set_grain_amount(value: float)` - 设置胶片颗粒效果强度
- `set_color_shift_enabled(enabled: bool)` - 启用或禁用颜色偏移效果
- `set_color_depth(value: int)` - 设置颜色深度（用于颜色量化）
- `set_scene_type(scene_type: SceneType)` - 设置场景类型
- `set_effect_enabled(effect: EffectType, enabled: bool)` - 启用或禁用特定效果

## 性能优化

为保持良好的性能，请注意以下几点：

1. **移动平台**
   - 在移动平台上使用`PERFORMANCE`预设
   - 禁用灰尘效果，因为它对GPU较为消耗

2. **较弱设备**
   - 降低灰尘纹理分辨率
   - 考虑禁用部分后处理效果

3. **批量操作**
   - 使用预设批量设置参数，而不是逐个设置

## 故障排除

### 常见问题

1. **效果不显示**
   - 检查是否正确初始化了效果管理器
   - 确认后处理效果已启用(`set_enabled(true)`)
   - 检查是否有较高层级的Canvas层覆盖了效果

2. **灰尘纹理缺失**
   - 系统会自动生成并保存灰尘纹理
   - 如果想手动创建，使用`scripts/tools/create_dust_texture.gd`

3. **性能问题**
   - 使用`PERFORMANCE`预设
   - 调低灰尘数量或禁用灰尘效果
   - 禁用不必要的效果

### 调试方法

- 使用`VisualEffectsDemo`场景测试各种效果组合
- 检查Godot控制台是否有纹理加载或生成相关的错误消息

---

若需进一步帮助，请联系开发团队。 