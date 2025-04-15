extends Panel

# 引用到UI元素
@onready var enemy_icon = $EnemyIcon
@onready var enemy_name = $EnemyName
@onready var enemy_type = $EnemyType
@onready var enemy_description = $EnemyDescription

# 存储敌人数据
var enemy_data = null

# 初始化敌人项目
func setup(data):
	enemy_data = data
	
	# 设置敌人名称
	enemy_name.text = data.name if data.has("name") else "未知敌人"
	
	# 设置敌人描述
	enemy_description.text = data.description if data.has("description") else "无可用描述"
	
	# 设置敌人类型标签
	if data.has("is_boss") and data.is_boss:
		enemy_type.text = "[BOSS]"
		enemy_type.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	elif data.has("is_elite") and data.is_elite:
		enemy_type.text = "[精英]"
		enemy_type.add_theme_color_override("font_color", Color(0.9, 0.6, 0.1))
	else:
		enemy_type.text = "[普通]"
		enemy_type.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	# 设置敌人图标
	if data.has("image") and data.image != "":
		var image_path = data.image
		var texture = load(image_path)
		if texture:
			enemy_icon.texture = texture
		else:
			print("无法加载敌人图标: ", image_path) 
