@tool
class_name UIEffectManager extends Node

# UI效果管理器 - 用于管理和应用UI特效
# 负责为界面元素应用各种视觉效果，如石质纹理、老旧效果等

# 枚举：UI效果类型
enum EffectType {
	NONE,           # 无特效
	STONE_BUTTON,   # 石质按钮效果
	DARK_PANEL,     # 暗色面板效果
	SCROLL_PANEL    # 卷轴效果
}

# 着色器路径
const SHADER_PATHS = {
	EffectType.STONE_BUTTON: "res://assets/shaders/ui_button.gdshader",
	EffectType.DARK_PANEL: "res://assets/shaders/ui_panel.gdshader"
}

# 缓存的着色器
var _effect_shaders = {}

# 已应用效果的UI元素
var _affected_controls = {}

func _ready():
	# 预加载所有着色器
	_preload_resources()

# 预加载资源
func _preload_resources():
	for effect in SHADER_PATHS:
		if ResourceLoader.exists(SHADER_PATHS[effect]):
			_effect_shaders[effect] = load(SHADER_PATHS[effect])

# 应用按钮效果
func apply_button_effect(button: Button, stone_intensity: float = 0.7, wear_amount: float = 0.4):
	if button == null or not _effect_shaders.has(EffectType.STONE_BUTTON):
		return
	
	# 创建材质
	var material = ShaderMaterial.new()
	material.shader = _effect_shaders[EffectType.STONE_BUTTON]
	
	# 设置参数
	material.set_shader_parameter("stone_intensity", stone_intensity)
	material.set_shader_parameter("wear_amount", wear_amount)
	material.set_shader_parameter("edge_darkness", 0.3)
	material.set_shader_parameter("bevel_amount", 0.4)
	material.set_shader_parameter("stone_color", Color(0.6, 0.6, 0.6, 1.0))
	
	# 应用材质
	button.material = material
	
	# 记录已应用效果的控件
	_affected_controls[button.get_instance_id()] = EffectType.STONE_BUTTON

# 应用面板效果
func apply_panel_effect(panel: Panel, darkness: float = 0.7, texture_intensity: float = 0.5):
	if panel == null or not _effect_shaders.has(EffectType.DARK_PANEL):
		return
	
	# 创建材质
	var material = ShaderMaterial.new()
	material.shader = _effect_shaders[EffectType.DARK_PANEL]
	
	# 设置参数
	material.set_shader_parameter("darkness", darkness)
	material.set_shader_parameter("texture_intensity", texture_intensity)
	material.set_shader_parameter("edge_wear", 0.3)
	material.set_shader_parameter("panel_color", Color(0.2, 0.2, 0.25, 1.0))
	
	# 应用材质
	panel.material = material
	
	# 记录已应用效果的控件
	_affected_controls[panel.get_instance_id()] = EffectType.DARK_PANEL

# 应用菜单框架效果
func apply_menu_frame_effect(control: Control, stone_intensity: float = 0.6, edge_glow: float = 0.2):
	if control == null or not _effect_shaders.has(EffectType.STONE_BUTTON):
		return
	
	# 创建材质
	var material = ShaderMaterial.new()
	material.shader = _effect_shaders[EffectType.STONE_BUTTON]
	
	# 设置参数 - 修改为适合菜单框架的效果
	material.set_shader_parameter("stone_intensity", stone_intensity)
	material.set_shader_parameter("wear_amount", 0.3)
	material.set_shader_parameter("edge_darkness", 0.2)
	material.set_shader_parameter("bevel_amount", 0.5)
	material.set_shader_parameter("stone_color", Color(0.5, 0.48, 0.45, 1.0))
	material.set_shader_parameter("edge_glow", edge_glow)
	material.set_shader_parameter("glow_color", Color(0.9, 0.8, 0.6, 0.5))
	
	# 应用材质
	control.material = material
	
	# 记录已应用效果的控件
	_affected_controls[control.get_instance_id()] = EffectType.STONE_BUTTON

# 清除效果
func clear_effect(control: Control):
	if control == null:
		return
	
	# 移除材质
	control.material = null
	
	# 从记录中移除
	var id = control.get_instance_id()
	if _affected_controls.has(id):
		_affected_controls.erase(id)

# 应用哥特式界面主题 - 为一组控件批量应用效果
func apply_gothic_theme(controls: Dictionary):
	"""
	批量应用哥特式界面主题
	参数 controls 格式: {
		"buttons": [按钮列表],
		"panels": [面板列表],
		"frames": [框架列表]
	}
	"""
	
	# 应用按钮效果
	if controls.has("buttons"):
		for button in controls["buttons"]:
			apply_button_effect(button)
	
	# 应用面板效果
	if controls.has("panels"):
		for panel in controls["panels"]:
			apply_panel_effect(panel)
	
	# 应用框架效果
	if controls.has("frames"):
		for frame in controls["frames"]:
			apply_menu_frame_effect(frame)

# 当节点从场景中移除时，清理资源
func _exit_tree():
	_effect_shaders.clear()
	_affected_controls.clear() 