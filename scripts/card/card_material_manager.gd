@tool
class_name CardMaterialManager extends Node

# 卡牌材质管理器 - 管理卡牌的各种着色器和材质效果
# 用于黑暗之魂风格的卡牌游戏《无火的牌局》

signal material_loaded(material_name: String)

# 卡牌材质类型枚举
enum CardMaterialType {
    NORMAL,     # 普通卡牌材质
    SPECIAL,    # 特殊卡牌材质
    BLACKFIRE,  # 黑火卡牌材质
    CHAOS,      # 混沌卡牌材质
    DARKMOON,   # 暗月卡牌材质
    DRAGON,     # 龙契卡牌材质
    FIRSTFLAME  # 初火卡牌材质
}

# 材质缓存
var _materials: Dictionary = {}
var _noise_textures: Dictionary = {}

# 着色器路径
const AGED_SHADER_PATH = "res://assets/shaders/card_aged.gdshader"
const GLOW_SHADER_PATH = "res://assets/shaders/card_glow.gdshader"

# 噪点纹理路径
const NOISE_BASIC_PATH = "res://assets/textures/noise/noise_basic.png"
const NOISE_DISTORTION_PATH = "res://assets/textures/noise/noise_distortion.png"
const NOISE_DAMAGE_PATH = "res://assets/textures/noise/noise_damage.png"

# 默认参数值
const DEFAULT_WEAR_AMOUNT = 0.3
const DEFAULT_EDGE_DARKNESS = 0.4
const DEFAULT_VIGNETTE_INTENSITY = 0.3

# 特殊卡牌发光颜色
const BLACKFIRE_COLOR = Color(0.3, 0.1, 0.6, 1.0)  # 暗紫色
const CHAOS_COLOR = Color(0.1, 0.6, 0.8, 1.0)      # 青蓝色
const DARKMOON_COLOR = Color(0.15, 0.2, 0.4, 1.0)  # 深蓝色
const DRAGON_COLOR = Color(0.8, 0.3, 0.1, 1.0)     # 橙红色
const FIRSTFLAME_COLOR = Color(1.0, 0.6, 0.1, 1.0) # 火焰色

func _ready():
    # 预加载噪点纹理(暂不加载，等资产准备好后再加载)
    # _preload_noise_textures()
    pass

# 预加载噪点纹理
func _preload_noise_textures():
    if ResourceLoader.exists(NOISE_BASIC_PATH):
        _noise_textures["basic"] = load(NOISE_BASIC_PATH)
    if ResourceLoader.exists(NOISE_DISTORTION_PATH):
        _noise_textures["distortion"] = load(NOISE_DISTORTION_PATH)
    if ResourceLoader.exists(NOISE_DAMAGE_PATH):
        _noise_textures["damage"] = load(NOISE_DAMAGE_PATH)

# 获取卡牌材质
func get_card_material(type: CardMaterialType) -> ShaderMaterial:
    var material_name = CardMaterialType.keys()[type].to_lower()
    
    # 如果材质已经缓存，直接返回
    if _materials.has(material_name):
        return _materials[material_name]
    
    # 创建新材质
    var material = ShaderMaterial.new()
    
    # 设置基础老旧效果着色器
    if ResourceLoader.exists(AGED_SHADER_PATH):
        material.shader = load(AGED_SHADER_PATH)
        
        # 设置噪点纹理
        if _noise_textures.has("basic"):
            material.set_shader_parameter("noise_texture", _noise_textures["basic"])
        
        # 设置基础参数
        material.set_shader_parameter("wear_amount", DEFAULT_WEAR_AMOUNT)
        material.set_shader_parameter("edge_darkness", DEFAULT_EDGE_DARKNESS)
        material.set_shader_parameter("vignette_intensity", DEFAULT_VIGNETTE_INTENSITY)
        
        # 根据类型设置特定颜色
        match type:
            CardMaterialType.NORMAL:
                material.set_shader_parameter("tint_color", Color(0.9, 0.8, 0.6, 1.0)) # 默认羊皮纸色
            CardMaterialType.SPECIAL:
                material.set_shader_parameter("tint_color", Color(0.85, 0.75, 0.55, 1.0)) # 略浅色
            CardMaterialType.BLACKFIRE:
                material.set_shader_parameter("tint_color", Color(0.7, 0.65, 0.5, 1.0)) # 偏灰色
                material.set_shader_parameter("wear_amount", 0.5) # 更多磨损
            CardMaterialType.CHAOS:
                material.set_shader_parameter("tint_color", Color(0.8, 0.75, 0.85, 1.0)) # 略带紫色
                material.set_shader_parameter("wear_amount", 0.4)
            CardMaterialType.DARKMOON:
                material.set_shader_parameter("tint_color", Color(0.7, 0.7, 0.8, 1.0)) # 略带蓝色
                material.set_shader_parameter("edge_darkness", 0.6) # 更暗的边缘
            CardMaterialType.DRAGON:
                material.set_shader_parameter("tint_color", Color(0.95, 0.85, 0.65, 1.0)) # 偏黄色
                material.set_shader_parameter("wear_amount", 0.25) # 更少磨损
            CardMaterialType.FIRSTFLAME:
                material.set_shader_parameter("tint_color", Color(0.95, 0.8, 0.6, 1.0)) # 偏暖色
    
    # 缓存材质
    _materials[material_name] = material
    emit_signal("material_loaded", material_name)
    
    return material

# 获取特殊卡牌发光材质
func get_glow_material(type: CardMaterialType) -> ShaderMaterial:
    var material_name = "glow_" + CardMaterialType.keys()[type].to_lower()
    
    # 如果材质已经缓存，直接返回
    if _materials.has(material_name):
        return _materials[material_name]
    
    # 创建新材质
    var material = ShaderMaterial.new()
    
    # 设置发光效果着色器
    if ResourceLoader.exists(GLOW_SHADER_PATH):
        material.shader = load(GLOW_SHADER_PATH)
        
        # 设置噪点纹理
        if _noise_textures.has("distortion"):
            material.set_shader_parameter("noise_texture", _noise_textures["distortion"])
        
        # 设置基础参数
        material.set_shader_parameter("glow_width", 0.1)
        material.set_shader_parameter("glow_intensity", 1.0)
        material.set_shader_parameter("pulse_speed", 1.0)
        
        # 根据卡牌类型设置发光颜色
        match type:
            CardMaterialType.BLACKFIRE:
                material.set_shader_parameter("glow_color", BLACKFIRE_COLOR)
                material.set_shader_parameter("enable_distortion", true)
                material.set_shader_parameter("distortion_amount", 0.03)
            CardMaterialType.CHAOS:
                material.set_shader_parameter("glow_color", CHAOS_COLOR)
                material.set_shader_parameter("enable_distortion", true)
                material.set_shader_parameter("pulse_speed", 2.0)
            CardMaterialType.DARKMOON:
                material.set_shader_parameter("glow_color", DARKMOON_COLOR)
                material.set_shader_parameter("glow_width", 0.15)
            CardMaterialType.DRAGON:
                material.set_shader_parameter("glow_color", DRAGON_COLOR)
                material.set_shader_parameter("glow_intensity", 1.2)
            CardMaterialType.FIRSTFLAME:
                material.set_shader_parameter("glow_color", FIRSTFLAME_COLOR)
                material.set_shader_parameter("pulse_speed", 1.5)
            _:
                # 默认发光颜色
                material.set_shader_parameter("glow_color", Color(1.0, 0.7, 0.3, 1.0))
    
    # 缓存材质
    _materials[material_name] = material
    emit_signal("material_loaded", material_name)
    
    return material

# 根据卡牌名称获取合适的材质类型
func get_material_type_from_card_name(card_name: String) -> CardMaterialType:
    card_name = card_name.to_lower()
    
    if "black_fire" in card_name or "blackfire" in card_name:
        return CardMaterialType.BLACKFIRE
    elif "chaos" in card_name:
        return CardMaterialType.CHAOS
    elif "dark_moon" in card_name or "darkmoon" in card_name:
        return CardMaterialType.DARKMOON
    elif "dragon" in card_name:
        return CardMaterialType.DRAGON
    elif "first_flame" in card_name or "firstflame" in card_name:
        return CardMaterialType.FIRSTFLAME
    elif card_name.begins_with("special_") or "special" in card_name:
        return CardMaterialType.SPECIAL
    else:
        return CardMaterialType.NORMAL

# 应用材质到卡牌
func apply_material_to_card(card_ui: Control, material_type: CardMaterialType = CardMaterialType.NORMAL, enable_glow: bool = false):
    if card_ui == null:
        return
    
    # 获取卡牌正面
    var frontface = card_ui.get_node_or_null("Frontface")
    if frontface == null or not frontface is TextureRect:
        return
    
    # 应用基础老旧效果材质
    frontface.material = get_card_material(material_type)
    
    # 如果是特殊卡牌，添加发光效果
    if enable_glow and material_type != CardMaterialType.NORMAL:
        # 获取或创建光效节点
        var light = card_ui.get_node_or_null("CardGlow")
        if light == null:
            light = PointLight2D.new()
            light.name = "CardGlow"
            card_ui.add_child(light)
            
            # 设置光效位置和大小
            var card_size = frontface.get_rect().size
            light.position = card_size / 2
            light.scale = card_size / 100 # 缩放因子，可以根据需要调整
        
        # 设置光效属性
        light.enabled = true
        light.energy = 0.8
        light.texture = frontface.texture
        
        # 根据卡牌类型设置光效颜色
        match material_type:
            CardMaterialType.BLACKFIRE:
                light.color = BLACKFIRE_COLOR
            CardMaterialType.CHAOS:
                light.color = CHAOS_COLOR
            CardMaterialType.DARKMOON:
                light.color = DARKMOON_COLOR
            CardMaterialType.DRAGON:
                light.color = DRAGON_COLOR
            CardMaterialType.FIRSTFLAME:
                light.color = FIRSTFLAME_COLOR
    else:
        # 移除光效
        var light = card_ui.get_node_or_null("CardGlow")
        if light != null:
            light.queue_free()

# 清除材质缓存
func clear_materials_cache():
    _materials.clear()
    emit_signal("material_loaded", "cache_cleared") 