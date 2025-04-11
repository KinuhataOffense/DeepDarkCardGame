extends Control

# 视觉效果演示场景控制脚本

var effects_manager = null
@onready var vignette_toggle = $DemoUI/EffectsContainer/VignetteToggle
@onready var film_grain_toggle = $DemoUI/EffectsContainer/FilmGrainToggle
@onready var tone_mapping_toggle = $DemoUI/EffectsContainer/ToneMappingToggle
@onready var color_shift_toggle = $DemoUI/EffectsContainer/ColorShiftToggle
@onready var dust_toggle = $DemoUI/EffectsContainer/DustToggle
@onready var enabled_toggle = $DemoUI/EnabledContainer/EnabledToggle

func _ready():
	# 获取效果管理器引用
	effects_manager = get_node_or_null("/root/VisualEffectsManager")
	if effects_manager == null:
		effects_manager = $VisualEffectsManager
	
	# 连接切换按钮信号
	vignette_toggle.toggled.connect(_on_vignette_toggled)
	film_grain_toggle.toggled.connect(_on_film_grain_toggled)
	tone_mapping_toggle.toggled.connect(_on_tone_mapping_toggled)
	color_shift_toggle.toggled.connect(_on_color_shift_toggled)
	dust_toggle.toggled.connect(_on_dust_toggled)
	enabled_toggle.toggled.connect(_on_enabled_toggled)
	
	# 更新UI状态以匹配当前效果状态
	_update_ui_state()

# 更新UI状态
func _update_ui_state():
	if effects_manager == null or effects_manager.post_processing_manager == null:
		return
	
	vignette_toggle.button_pressed = effects_manager.is_effect_enabled(effects_manager.post_processing_manager.EffectType.VIGNETTE)
	film_grain_toggle.button_pressed = effects_manager.is_effect_enabled(effects_manager.post_processing_manager.EffectType.FILM_GRAIN)
	tone_mapping_toggle.button_pressed = effects_manager.is_effect_enabled(effects_manager.post_processing_manager.EffectType.TONE_MAPPING)
	color_shift_toggle.button_pressed = effects_manager.is_effect_enabled(effects_manager.post_processing_manager.EffectType.COLOR_SHIFT)
	dust_toggle.button_pressed = effects_manager.is_effect_enabled(effects_manager.post_processing_manager.EffectType.DUST)

# 切换暗角效果
func _on_vignette_toggled(enabled):
	if effects_manager:
		effects_manager.set_effect_enabled(effects_manager.post_processing_manager.EffectType.VIGNETTE, enabled)

# 切换胶片颗粒效果
func _on_film_grain_toggled(enabled):
	if effects_manager:
		effects_manager.set_effect_enabled(effects_manager.post_processing_manager.EffectType.FILM_GRAIN, enabled)

# 切换色调映射效果
func _on_tone_mapping_toggled(enabled):
	if effects_manager:
		effects_manager.set_effect_enabled(effects_manager.post_processing_manager.EffectType.TONE_MAPPING, enabled)

# 切换色彩偏移效果
func _on_color_shift_toggled(enabled):
	if effects_manager:
		effects_manager.set_effect_enabled(effects_manager.post_processing_manager.EffectType.COLOR_SHIFT, enabled)

# 切换灰尘效果
func _on_dust_toggled(enabled):
	if effects_manager:
		effects_manager.set_effect_enabled(effects_manager.post_processing_manager.EffectType.DUST, enabled)

# 启用/禁用所有后处理效果
func _on_enabled_toggled(enabled):
	if effects_manager:
		effects_manager.set_enabled(enabled) 
