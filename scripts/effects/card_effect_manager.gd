@tool
class_name CardEffectManager extends Node

# 卡牌效果管理器 - 用于管理和应用卡牌特效
# 负责为卡牌应用各种视觉效果，如磨损、发光、黑火等

# 枚举：卡牌磨损程度
enum WornLevel {
	NONE,    # 无磨损
	LIGHT,   # 轻微磨损
	NORMAL,  # 普通磨损
	HEAVY    # 严重磨损
}

# 枚举：卡牌特效类型
enum EffectType {
	NONE,           # 无特效
	GLOW,           # 发光效果
	BURN,           # 黑火效果
	SOULFIRE,       # 灵魂火效果
	ENHANCED_GLOW   # 增强发光效果
}

# 材质路径
const WORN_MATERIAL_PATHS = {
	WornLevel.LIGHT: "res://assets/materials/cards/card_worn_light.tres",
	WornLevel.NORMAL: "res://assets/materials/cards/card_worn.tres",
	WornLevel.HEAVY: "res://assets/materials/cards/card_worn_heavy.tres"
}

# 着色器路径
const SHADER_PATHS = {
	EffectType.GLOW: "res://assets/shaders/card_glow.gdshader",
	EffectType.BURN: "res://assets/shaders/card_burn.gdshader",
	EffectType.SOULFIRE: "res://assets/shaders/card_soulfire.gdshader",
	EffectType.ENHANCED_GLOW: "res://assets/shaders/card_glow_enhanced.gdshader"
}

# 缓存的材质
var _worn_materials = {}
var _effect_shaders = {}

# 当前目标
var _current_target: Control = null

# 当前效果
var _current_worn_level = WornLevel.NONE
var _current_effect_type = EffectType.NONE

func _ready():
	# 预加载所有材质和着色器
	_preload_resources()

# 预加载资源
func _preload_resources():
	# 加载磨损材质
	for level in WORN_MATERIAL_PATHS:
		if ResourceLoader.exists(WORN_MATERIAL_PATHS[level]):
			_worn_materials[level] = load(WORN_MATERIAL_PATHS[level])
	
	# 加载效果着色器
	for effect in SHADER_PATHS:
		if ResourceLoader.exists(SHADER_PATHS[effect]):
			var shader = load(SHADER_PATHS[effect])
			_effect_shaders[effect] = shader

# 设置目标控件（卡牌）
func set_target(target: Control):
	_current_target = target
	
	# 重置效果
	_current_worn_level = WornLevel.NONE
	_current_effect_type = EffectType.NONE
	
	# 清除材质
	if target != null:
		target.material = null

# 应用磨损效果
func apply_worn_effect(worn_level: WornLevel):
	if _current_target == null or worn_level == WornLevel.NONE:
		return
	
	_current_worn_level = worn_level
	
	# 应用磨损材质
	if _worn_materials.has(worn_level):
		_current_target.material = _worn_materials[worn_level]
	
	# 如果已有特效，则需要重新应用
	if _current_effect_type != EffectType.NONE:
		apply_special_effect(_current_effect_type)

# 应用特殊效果
func apply_special_effect(effect_type: EffectType):
	if _current_target == null or effect_type == EffectType.NONE:
		return
	
	_current_effect_type = effect_type
	
	# 创建新的材质
	var material = ShaderMaterial.new()
	
	# 设置着色器
	if _effect_shaders.has(effect_type):
		material.shader = _effect_shaders[effect_type]
		
		# 根据效果类型设置默认参数
		match effect_type:
			EffectType.GLOW:
				material.set_shader_parameter("glow_color", Color(1.0, 0.7, 0.3, 0.7))
				material.set_shader_parameter("glow_intensity", 0.4)
			EffectType.BURN:
				material.set_shader_parameter("burn_color", Color(0.3, 0.0, 0.0, 1.0))
				material.set_shader_parameter("burn_amount", 0.2)
				material.set_shader_parameter("burn_speed", 1.0)
			EffectType.SOULFIRE:
				material.set_shader_parameter("soul_color", Color(0.2, 0.4, 0.8, 0.7))
				material.set_shader_parameter("fire_speed", 1.5)
				material.set_shader_parameter("fire_intensity", 0.5)
			EffectType.ENHANCED_GLOW:
				material.set_shader_parameter("glow_color", Color(1.0, 0.9, 0.5, 0.8))
				material.set_shader_parameter("pulse_speed", 1.0)
				material.set_shader_parameter("glow_intensity", 0.6)
		
		_current_target.material = material

# 移除所有效果
func clear_effects():
	if _current_target != null:
		_current_target.material = null
	
	_current_worn_level = WornLevel.NONE
	_current_effect_type = EffectType.NONE

# 根据卡牌稀有度自动设置效果
func apply_rarity_effect(rarity: int):
	# 根据稀有度设置磨损程度和特效
	match rarity:
		0: # 普通卡
			apply_worn_effect(WornLevel.NORMAL)
		1: # 稀有卡
			apply_worn_effect(WornLevel.LIGHT)
			apply_special_effect(EffectType.GLOW)
		2: # 史诗卡
			apply_worn_effect(WornLevel.LIGHT)
			apply_special_effect(EffectType.ENHANCED_GLOW)
		3: # 传说卡
			apply_worn_effect(WornLevel.LIGHT)
			apply_special_effect(EffectType.SOULFIRE)
		4: # 黑火卡
			apply_worn_effect(WornLevel.HEAVY)
			apply_special_effect(EffectType.BURN) 