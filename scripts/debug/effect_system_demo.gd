@tool
extends Node

# 效果系统示例 - 演示如何在游戏中使用视觉效果系统

# 引用管理器
var card_effect_manager: CardEffectManager
var ui_effect_manager: UIEffectManager

# 当前场景类型
var current_scene_type = PostProcessingManager.SceneType.MENU

# 示例卡牌
@export var example_card: Control
# 示例按钮
@export var example_buttons: Array[Button]
# 示例面板
@export var example_panels: Array[Panel]

func _ready():
	# 设置视觉效果目标
	example_card = $CardContainer/Card1
	example_buttons = [
		$UIControlsContainer/EffectControls/SceneTypePanel/ButtonContainer/MenuButton,
		$UIControlsContainer/EffectControls/SceneTypePanel/ButtonContainer/BattleButton,
		$UIControlsContainer/EffectControls/SceneTypePanel/ButtonContainer/ShopButton,
		$UIControlsContainer/EffectControls/EffectTypePanel/ButtonContainer/GlowButton,
		$UIControlsContainer/EffectControls/EffectTypePanel/ButtonContainer/BurnButton,
		$UIControlsContainer/EffectControls/EffectTypePanel/ButtonContainer/SoulfireButton
	]
	example_panels = [
		$UIControlsContainer/EffectControls/SceneTypePanel,
		$UIControlsContainer/EffectControls/EffectTypePanel,
		$UIControlsContainer/PresetPanel
	]
	
	# 初始化效果管理器
	_initialize_managers()
	
	# 演示应用视觉效果
	_demo_visual_effects()
	
	# 演示应用卡牌效果
	if example_card:
		_demo_card_effects(example_card)
	
	# 演示应用UI效果
	_demo_ui_effects()

# 初始化效果管理器
func _initialize_managers():
	# 检查是否已有VisualEffectsManager实例
	var visual_manager = get_node_or_null("/root/VisualEffectsManager")
	if visual_manager == null:
		print("注意：VisualEffectsManager未在自动加载中配置，效果可能无法正确应用")
	else:
		# 应用默认预设
		visual_manager.apply_preset(visual_manager.VisualPreset.DEFAULT)
		visual_manager.set_scene_type(current_scene_type)
	
	# 创建卡牌效果管理器
	card_effect_manager = CardEffectManager.new()
	add_child(card_effect_manager)
	
	# 创建UI效果管理器
	ui_effect_manager = UIEffectManager.new()
	add_child(ui_effect_manager)

# 演示视觉效果
func _demo_visual_effects():
	var visual_manager = get_node_or_null("/root/VisualEffectsManager")
	if visual_manager == null:
		return
	
	# 启用所有效果
	visual_manager.set_enabled(true)
	
	# 设置场景类型
	visual_manager.set_scene_type(current_scene_type)
	
	print("已应用场景类型: " + str(PostProcessingManager.SceneType.keys()[current_scene_type]))

# 演示卡牌效果
func _demo_card_effects(card: Control):
	# 设置目标卡牌
	card_effect_manager.set_target(card)
	
	# 应用磨损效果
	card_effect_manager.apply_worn_effect(CardEffectManager.WornLevel.LIGHT)
	
	# 应用发光效果（可以根据卡牌类型选择不同效果）
	card_effect_manager.apply_special_effect(CardEffectManager.EffectType.GLOW)
	
	print("已应用卡牌效果: 轻微磨损 + 发光效果")

# 演示UI效果
func _demo_ui_effects():
	# 应用按钮效果
	for button in example_buttons:
		if button:
			ui_effect_manager.apply_button_effect(button)
	
	# 应用面板效果
	for panel in example_panels:
		if panel:
			ui_effect_manager.apply_panel_effect(panel)
	
	print("已应用UI效果到 " + str(example_buttons.size()) + " 个按钮和 " + str(example_panels.size()) + " 个面板")

# 切换场景类型 - 可以连接到UI按钮
func change_scene_type(type: int):
	current_scene_type = type
	
	var visual_manager = get_node_or_null("/root/VisualEffectsManager")
	if visual_manager:
		visual_manager.set_scene_type(type)
	
	print("已切换场景类型: " + str(PostProcessingManager.SceneType.keys()[type]))

# 切换卡牌效果 - 可以连接到UI按钮
func change_card_effect(effect_type: int):
	if not example_card:
		return
	
	card_effect_manager.apply_special_effect(effect_type)
	print("已切换卡牌效果: " + str(CardEffectManager.EffectType.keys()[effect_type]))

# 切换预设 - 连接到预设按钮
func _on_preset_pressed(preset: int):
	var visual_manager = get_node_or_null("/root/VisualEffectsManager")
	if visual_manager:
		visual_manager.apply_preset(preset)
		print("已应用预设: " + str(VisualEffectsManager.VisualPreset.keys()[preset])) 
