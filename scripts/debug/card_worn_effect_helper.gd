extends Node

# 卡牌老旧效果辅助脚本
# 此脚本用于协助将老旧效果应用到复杂结构的卡牌UI上

@onready var parent_card = get_parent()

func _ready():
	# 延迟一帧执行，确保卡牌节点已完全初始化
	call_deferred("_apply_worn_effect")

func _apply_worn_effect():
	# 查找该卡牌上的老旧效果节点
	var worn_effect = parent_card.get_node_or_null("WornEffect")
	if not worn_effect:
		push_error("无法找到WornEffect节点")
		return
	
	# 手动找到卡牌的所有纹理组件并添加到老旧效果的处理列表中
	var texture_nodes = []
	_find_texture_nodes(parent_card, texture_nodes)
	
	print("找到 %d 个纹理节点可应用老旧效果" % texture_nodes.size())
	
	# 将这些节点添加到老旧效果的_worn_sprites数组中
	if "_worn_sprites" in worn_effect:
		worn_effect._worn_sprites.clear()
		worn_effect._worn_sprites.append_array(texture_nodes)
		
		# 应用效果
		if worn_effect.has_method("apply_effect"):
			worn_effect.apply_effect()

# 递归查找所有纹理节点
func _find_texture_nodes(node, result_array):
	if node is TextureRect or node is Sprite2D:
		result_array.append(node)
	
	for child in node.get_children():
		_find_texture_nodes(child, result_array) 
