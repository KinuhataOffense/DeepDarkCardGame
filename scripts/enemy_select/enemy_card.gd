extends Panel

@onready var enemy_image = $EnemyImage
@onready var enemy_name = $EnemyName
@onready var difficulty_stars = $DifficultyStars
@onready var score_required_label = $ScoreRequiredLabel
@onready var button = $Button

var enemy_data = null

# 信号
signal enemy_card_clicked(enemy_data)

func _ready():
	# 连接按钮信号
	button.pressed.connect(_on_button_pressed)

# 设置敌人数据
func setup(data):
	enemy_data = data
	
	# 更新UI
	enemy_name.text = data.name
	
	# 设置图像
	if data.has("image") and ResourceLoader.exists(data.image):
		var texture = load(data.image)
		if texture:
			enemy_image.texture = texture
	
	# 设置难度星级
	var stars_text = ""
	if data.has("difficulty"):
		for i in range(data.difficulty):
			stars_text += "★"
		for i in range(4 - data.difficulty):
			stars_text += "☆"
	difficulty_stars.text = stars_text
	
	# 设置所需分数和奖励信息
	var info_text = "所需分数: " + str(data.get("required_score", 0))
	if data.has("rewards") and data.rewards.has("currency"):
		info_text += " | 奖励: " + str(data.rewards.currency) + "魂"
	score_required_label.text = info_text

# 点击按钮
func _on_button_pressed():
	# 打印选择的敌人数据用于调试
	print("选择敌人:", enemy_data.name)
	# 传递敌人数据
	emit_signal("enemy_card_clicked", enemy_data) 