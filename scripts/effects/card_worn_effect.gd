extends Node2D

# 卡牌老旧效果控制脚本
# 应当附加到卡牌节点上，用于控制卡牌的老旧程度

# 老旧效果的预设
enum WornPreset {
	NONE,        # 无老旧效果
	LIGHT,       # 轻微老旧
	MEDIUM,      # 中等老旧
	HEAVY        # 严重老旧
}

# 检查表用于记录需要处理老旧效果的节点
var _worn_sprites = []

# 当前预设
@export var preset: WornPreset = WornPreset.MEDIUM:
	set(value):
		preset = value
		_update_preset()

# 自定义老旧程度参数
@export_group("自定义老旧参数")
@export_range(0.0, 1.0) var worn_amount: float = 0.4:
	set(value):
		worn_amount = value
		_update_custom_parameters()
		
@export_range(0.0, 1.0) var edge_worn: float = 0.6:
	set(value):
		edge_worn = value
		_update_custom_parameters()
		
@export_range(0.0, 1.0) var stain_amount: float = 0.3:
	set(value):
		stain_amount = value
		_update_custom_parameters()
		
@export_range(0.0, 1.0) var dust_amount: float = 0.15:
	set(value):
		dust_amount = value
		_update_custom_parameters()
		
@export_range(0.0, 1.0) var crease_amount: float = 0.25:
	set(value):
		crease_amount = value
		_update_custom_parameters()
		
@export_range(0.0, 1.0) var color_fade: float = 0.35:
	set(value):
		color_fade = value
		_update_custom_parameters()
		
@export_range(0.0, 1.0) var yellowing: float = 0.3:
	set(value):
		yellowing = value
		_update_custom_parameters()
		
@export var stain_color: Color = Color(0.27, 0.19, 0.12, 1.0):
	set(value):
		stain_color = value
		_update_custom_parameters()
		
@export var dust_color: Color = Color(0.15, 0.13, 0.1, 1.0):
	set(value):
		dust_color = value
		_update_custom_parameters()
		
@export_range(0.0, 1.0) var edge_darkness: float = 0.6:
	set(value):
		edge_darkness = value
		_update_custom_parameters()
		
@export_range(0.0, 1.0) var randomness: float = 0.7:
	set(value):
		randomness = value
		_update_custom_parameters()
		
@export var unique_seed: float = 12.345:
	set(value):
		unique_seed = value
		_update_custom_parameters()

# 引用材质资源
var _worn_material: ShaderMaterial
var _worn_light_material: ShaderMaterial
var _worn_heavy_material: ShaderMaterial

# 当节点准备好时调用
func _ready():
	# 加载材质资源
	_worn_material = load("res://assets/materials/cards/card_worn.tres")
	_worn_light_material = load("res://assets/materials/cards/card_worn_light.tres")
	_worn_heavy_material = load("res://assets/materials/cards/card_worn_heavy.tres")
	
	# 查找所有需要应用老旧效果的精灵节点
	_find_worn_sprites(self)
	
	# 应用当前预设的效果
	_update_preset()

# 递归查找所有Sprite2D节点，添加到处理列表中
func _find_worn_sprites(node):
	if node is Sprite2D or node is TextureRect:
		_worn_sprites.append(node)
	
	for child in node.get_children():
		_find_worn_sprites(child)

# 根据当前预设更新效果
func _update_preset():
	match preset:
		WornPreset.NONE:
			_apply_no_worn_effect()
		WornPreset.LIGHT:
			_apply_light_worn_effect()
		WornPreset.MEDIUM:
			_apply_medium_worn_effect()
		WornPreset.HEAVY:
			_apply_heavy_worn_effect()

# 根据自定义参数更新效果
func _update_custom_parameters():
	# 只有在选择自定义预设或中等预设时才应用自定义参数
	if preset == WornPreset.MEDIUM:
		for sprite in _worn_sprites:
			if sprite.material != _worn_material:
				sprite.material = _worn_material.duplicate()
			
			_apply_parameters_to_material(sprite.material)

# 将自定义参数应用到材质
func _apply_parameters_to_material(material):
	if material:
		material.set_shader_parameter("worn_amount", worn_amount)
		material.set_shader_parameter("edge_worn", edge_worn)
		material.set_shader_parameter("stain_amount", stain_amount)
		material.set_shader_parameter("dust_amount", dust_amount)
		material.set_shader_parameter("crease_amount", crease_amount)
		material.set_shader_parameter("color_fade", color_fade)
		material.set_shader_parameter("yellowing", yellowing)
		material.set_shader_parameter("stain_color", stain_color)
		material.set_shader_parameter("dust_color", dust_color)
		material.set_shader_parameter("edge_darkness", edge_darkness)
		material.set_shader_parameter("randomness", randomness)
		material.set_shader_parameter("unique_seed", unique_seed)

# 应用无老旧效果
func _apply_no_worn_effect():
	for sprite in _worn_sprites:
		sprite.material = null

# 应用轻微老旧效果
func _apply_light_worn_effect():
	for sprite in _worn_sprites:
		sprite.material = _worn_light_material

# 应用中等老旧效果
func _apply_medium_worn_effect():
	for sprite in _worn_sprites:
		if sprite.material != _worn_material:
			sprite.material = _worn_material.duplicate()
		
		_apply_parameters_to_material(sprite.material)

# 应用严重老旧效果
func _apply_heavy_worn_effect():
	for sprite in _worn_sprites:
		sprite.material = _worn_heavy_material

# 公开方法：设置老旧效果预设
func set_worn_preset(new_preset: WornPreset):
	preset = new_preset

# 公开方法：随机化老旧效果参数
func randomize_worn_parameters(min_intensity := 0.1, max_intensity := 0.7):
	var intensity = randf_range(min_intensity, max_intensity)
	
	worn_amount = randf_range(intensity * 0.8, intensity)
	edge_worn = randf_range(intensity, intensity * 1.2)
	stain_amount = randf_range(intensity * 0.5, intensity)
	dust_amount = randf_range(intensity * 0.3, intensity * 0.8)
	crease_amount = randf_range(intensity * 0.5, intensity)
	color_fade = randf_range(intensity * 0.7, intensity)
	yellowing = randf_range(intensity * 0.5, intensity)
	
	# 为每张卡牌生成唯一的种子值
	unique_seed = randf_range(1.0, 100.0)
	
	# 更新自定义参数
	_update_custom_parameters() 

# 公开方法：强制更新着色器参数
func update_shader_parameters():
	_update_custom_parameters()

# 公开方法：重新应用当前效果
func apply_effect():
	# 首先重新查找所有需要应用效果的精灵节点
	_worn_sprites.clear()
	_find_worn_sprites(self)
	
	# 强制刷新父节点下的所有卡牌精灵
	var parent = get_parent()
	if parent:
		_find_worn_sprites(parent)
	
	# 然后根据当前预设重新应用效果
	_update_preset()
	print("应用老旧效果: %d个节点, 预设=%d" % [_worn_sprites.size(), preset])

# 公开方法：获取各种参数值
func get_worn_amount():
	return worn_amount

func get_edge_worn():
	return edge_worn

func get_stain_amount():
	return stain_amount

func get_dust_amount():
	return dust_amount

func get_crease_amount():
	return crease_amount

func get_color_fade():
	return color_fade

func get_yellowing():
	return yellowing

func get_edge_darkness():
	return edge_darkness

func get_randomness():
	return randomness 
