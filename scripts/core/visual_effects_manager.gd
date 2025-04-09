extends Node

# 视觉效果管理器 - 管理游戏中的所有视觉效果
# 作为单例使用，可在项目设置的自动加载列表中添加

# 预设选项
enum VisualPreset {
	DEFAULT,    # 默认设置
	CINEMATIC,  # 电影风格，强调氛围
	PERFORMANCE, # 性能优先，减少特效
	HORROR,     # 恐怖风格，暗角和噪点加强
	CLASSIC     # 经典风格，复古色彩
}

# 引用后处理管理器
var post_processing_manager: PostProcessingManager = null

# 当前预设
var _current_preset: VisualPreset = VisualPreset.DEFAULT

# 上次使用的场景类型
var _last_scene_type: PostProcessingManager.SceneType = PostProcessingManager.SceneType.MENU

# 预设参数配置
var _preset_configs = {
	VisualPreset.DEFAULT: {
		"vignette_intensity": 0.4,
		"vignette_opacity": 0.5,
		"grain_amount": 0.05,
		"dust_amount": 0.2, 
		"enable_color_shift": true,
		"color_depth": 32.0
	},
	VisualPreset.CINEMATIC: {
		"vignette_intensity": 0.5,
		"vignette_opacity": 0.6,
		"grain_amount": 0.08,
		"dust_amount": 0.25,
		"enable_color_shift": true,
		"color_depth": 24.0
	},
	VisualPreset.PERFORMANCE: {
		"vignette_intensity": 0.3,
		"vignette_opacity": 0.4,
		"grain_amount": 0.03,
		"dust_amount": 0.1,
		"enable_color_shift": false,
		"color_depth": 16.0
	},
	VisualPreset.HORROR: {
		"vignette_intensity": 0.6,
		"vignette_opacity": 0.7,
		"grain_amount": 0.1,
		"dust_amount": 0.3,
		"enable_color_shift": true,
		"color_depth": 16.0
	},
	VisualPreset.CLASSIC: {
		"vignette_intensity": 0.35,
		"vignette_opacity": 0.4,
		"grain_amount": 0.15,
		"dust_amount": 0.15,
		"enable_color_shift": true,
		"color_depth": 8.0
	}
}

func _ready():
	# 查找或创建后处理管理器
	post_processing_manager = _find_or_create_post_processor()
	
	# 应用默认预设
	apply_preset(VisualPreset.DEFAULT)

# 查找或创建后处理管理器实例
func _find_or_create_post_processor() -> PostProcessingManager:
	# 首先尝试查找已有实例
	var existing = get_node_or_null("/root/PostProcessingManager")
	if existing != null:
		return existing
	
	# 如果不存在，创建一个新实例
	var manager = PostProcessingManager.new()
	manager.name = "PostProcessingManager"
	add_child(manager)
	return manager

# 应用预设
func apply_preset(preset: VisualPreset):
	if post_processing_manager == null:
		return
	
	# 保存当前预设
	_current_preset = preset
	
	# 获取预设配置
	var config = _preset_configs[preset]
	
	# 应用参数
	post_processing_manager.set_vignette_intensity(config.vignette_intensity)
	post_processing_manager.set_vignette_opacity(config.vignette_opacity)
	post_processing_manager.set_grain_amount(config.grain_amount)
	post_processing_manager.set_dust_amount(config.dust_amount)
	post_processing_manager.set_color_shift_enabled(config.enable_color_shift)
	post_processing_manager.set_color_depth(config.color_depth)
	
	# 重新应用场景类型，确保效果一致性
	if _last_scene_type:
		post_processing_manager.set_scene_type(_last_scene_type)

# 设置场景类型
func set_scene_type(type: PostProcessingManager.SceneType):
	if post_processing_manager == null:
		return
	
	_last_scene_type = type
	post_processing_manager.set_scene_type(type)

# 获取当前预设
func get_current_preset() -> VisualPreset:
	return _current_preset

# 启用/禁用后处理效果
func set_enabled(enabled: bool):
	if post_processing_manager == null:
		return
	
	post_processing_manager.set_enabled(enabled)

# 获取后处理管理器实例
func get_post_processor() -> PostProcessingManager:
	return post_processing_manager

# 启用/禁用特定效果
func set_effect_enabled(effect_type: PostProcessingManager.EffectType, enabled: bool):
	if post_processing_manager == null:
		return
	
	post_processing_manager.set_effect_enabled(effect_type, enabled)

# 检查效果是否启用
func is_effect_enabled(effect_type: PostProcessingManager.EffectType) -> bool:
	if post_processing_manager == null:
		return false
	
	return post_processing_manager.is_effect_enabled(effect_type)

# 设置自定义参数 (高级用户)
func set_custom_parameters(params: Dictionary):
	if post_processing_manager == null:
		return
	
	# 应用提供的参数
	if params.has("vignette_intensity"):
		post_processing_manager.set_vignette_intensity(params.vignette_intensity)
	
	if params.has("vignette_opacity"):
		post_processing_manager.set_vignette_opacity(params.vignette_opacity)
	
	if params.has("vignette_color"):
		post_processing_manager.set_vignette_color(params.vignette_color)
	
	if params.has("grain_amount"):
		post_processing_manager.set_grain_amount(params.grain_amount)
	
	if params.has("dust_amount"):
		post_processing_manager.set_dust_amount(params.dust_amount)
	
	if params.has("enable_color_shift"):
		post_processing_manager.set_color_shift_enabled(params.enable_color_shift)
	
	if params.has("color_depth"):
		post_processing_manager.set_color_depth(params.color_depth) 
