@tool
class_name StyledCardUI extends CardUI

@onready var card_name := $Frontface/CardName
@onready var card_value := $Frontface/CardValue
# 扩展卡牌UI类 - 添加黑暗之魂风格的视觉效果
# 使用卡牌材质管理器应用着色器和视觉效果

# 材质管理器引用
var material_manager: CardMaterialManager = null

# 卡牌类型
var card_type: CardMaterialManager.CardMaterialType = CardMaterialManager.CardMaterialType.NORMAL

# 是否启用发光效果
@export var enable_glow: bool = false:
	set(value):
		enable_glow = value
		_update_materials()

# 是否是特殊卡牌
@export var is_special_card: bool = false:
	set(value):
		is_special_card = value
		if value:
			card_type = CardMaterialManager.CardMaterialType.SPECIAL
		else:
			card_type = CardMaterialManager.CardMaterialType.NORMAL
		_update_materials()

# 卡牌特殊类型（如果是特殊卡牌）
@export_enum("普通", "黑火", "混沌", "暗月", "龙契", "初火") var special_type: int = 0:
	set(value):
		special_type = value
		if is_special_card:
			match value:
				0: card_type = CardMaterialManager.CardMaterialType.SPECIAL
				1: card_type = CardMaterialManager.CardMaterialType.BLACKFIRE
				2: card_type = CardMaterialManager.CardMaterialType.CHAOS
				3: card_type = CardMaterialManager.CardMaterialType.DARKMOON
				4: card_type = CardMaterialManager.CardMaterialType.DRAGON
				5: card_type = CardMaterialManager.CardMaterialType.FIRSTFLAME
			_update_materials()

# 覆盖基类的_ready方法
func _ready():
	super()
	card_name.text = card_data.nice_name
	card_value.text = str(card_data.value)
	if Engine.is_editor_hint():
		set_disabled(true)
		update_configuration_warnings()
		return
	
	# 查找或创建材质管理器
	material_manager = _find_or_create_material_manager()
	
	# 从卡牌名称自动检测类型
	if is_special_card and card_data != null and card_data.name != "":
		card_type = material_manager.get_material_type_from_card_name(card_data.name)
		
		# 更新special_type属性以匹配card_type
		match card_type:
			CardMaterialManager.CardMaterialType.NORMAL: special_type = 0
			CardMaterialManager.CardMaterialType.SPECIAL: special_type = 0
			CardMaterialManager.CardMaterialType.BLACKFIRE: special_type = 1
			CardMaterialManager.CardMaterialType.CHAOS: special_type = 2
			CardMaterialManager.CardMaterialType.DARKMOON: special_type = 3
			CardMaterialManager.CardMaterialType.DRAGON: special_type = 4
			CardMaterialManager.CardMaterialType.FIRSTFLAME: special_type = 5
	
	# 应用材质
	_update_materials()
	
	# 连接信号
	connect("card_hovered", _on_card_hover)
	connect("card_unhovered", _on_card_unhover)

# 查找或创建材质管理器
func _find_or_create_material_manager() -> CardMaterialManager:
	# 首先在场景树中查找现有的材质管理器
	var existing_manager = get_node_or_null("/root/CardMaterialManager")
	if existing_manager != null:
		return existing_manager
	
	# 如果找不到，则创建一个新的材质管理器
	var manager = CardMaterialManager.new()
	manager.name = "CardMaterialManager"
	
	# 将其添加为自动加载的单例
	var root = get_tree().get_root()
	root.add_child(manager)
	
	return manager

# 更新卡牌材质
func _update_materials():
	if material_manager == null or not is_inside_tree():
		return
	
	# 应用材质到卡牌
	material_manager.apply_material_to_card(self, card_type, enable_glow)

# 当卡牌被悬停时增强发光效果
func _on_card_hover(_card):
	if material_manager == null or not is_special_card:
		return
	
	# 增强发光效果
	var light = get_node_or_null("CardGlow")
	if light != null:
		light.energy = 1.5  # 增强发光强度
		
		# 创建发光动画
		var tween = create_tween()
		tween.tween_property(light, "energy", 1.2, 0.3)
		tween.tween_property(light, "energy", 1.5, 0.3)
		tween.set_loops()

# 当卡牌悬停结束时恢复正常发光效果
func _on_card_unhover(_card):
	if material_manager == null:
		return
	
	# 恢复普通发光效果
	var light = get_node_or_null("CardGlow")
	if light != null:
		# 停止任何正在进行的动画
		var tweens = get_tree().get_tweens()
		for tween in tweens:
			if tween.is_valid() and tween.get_object() == light:
				tween.kill()
		
		# 恢复正常亮度
		light.energy = 0.8

# 设置卡牌类型
func set_card_type(type_name: String):
	if material_manager == null:
		material_manager = _find_or_create_material_manager()
	
	# 设置卡牌类型
	card_type = material_manager.get_material_type_from_card_name(type_name)
	is_special_card = (card_type != CardMaterialManager.CardMaterialType.NORMAL)
	
	# 更新special_type属性以匹配card_type
	match card_type:
		CardMaterialManager.CardMaterialType.NORMAL: special_type = 0
		CardMaterialManager.CardMaterialType.SPECIAL: special_type = 0
		CardMaterialManager.CardMaterialType.BLACKFIRE: special_type = 1
		CardMaterialManager.CardMaterialType.CHAOS: special_type = 2
		CardMaterialManager.CardMaterialType.DARKMOON: special_type = 3
		CardMaterialManager.CardMaterialType.DRAGON: special_type = 4
		CardMaterialManager.CardMaterialType.FIRSTFLAME: special_type = 5
	
	# 应用材质
	_update_materials()

# 覆盖基类的_process方法以处理卡牌特效
func _process(delta):
	super._process(delta)
	
	# 处理特殊卡牌效果
	if is_special_card and not Engine.is_editor_hint():
		match card_type:
			CardMaterialManager.CardMaterialType.CHAOS:
				# 混沌卡牌效果：轻微抖动
				if is_clicked or mouse_is_hovering:
					rotation = sin(Time.get_ticks_msec() * 0.01) * 0.02
			CardMaterialManager.CardMaterialType.BLACKFIRE:
				# 黑火卡牌效果：随时间变化的黑暗光晕
				var light = get_node_or_null("CardGlow")
				if light != null:
					light.color.a = 0.7 + sin(Time.get_ticks_msec() * 0.003) * 0.3 
