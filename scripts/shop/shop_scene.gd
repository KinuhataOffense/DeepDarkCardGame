extends Control

@onready var item_container = $ItemContainer  
@onready var player_currency = $PlayerCurrency  
@onready var leave_button = $LeaveShopButton  

var game_manager = null  
var item_card_scene = preload("res://scenes/item_card.tscn")  

# 添加离开商店信号
signal leave_shop_requested

func _ready():  
	# 连接按钮信号  
	leave_button.pressed.connect(_on_leave_shop_pressed)  
	game_manager = get_node("/root/Main/GameManager")
	# 等待游戏管理器引用  
	await get_tree().process_frame  
	refresh_shop_display()  

func initialize(new_game_manager):  
	game_manager = new_game_manager
	
func refresh_shop_display():  
	# 清空现有物品显示  
	for child in item_container.get_children():  
		child.queue_free()  
	
	# 更新货币显示
	if game_manager:
		player_currency.text = "货币: " + str(game_manager.get_player_currency())  
	else:
		player_currency.text = "货币: 0"
	
	# 为每个可用物品创建卡片  
	var shop_items = game_manager.get_shop_items()
	for index in shop_items.size():  
		var item = shop_items[index]
		var item_card = item_card_scene.instantiate()  
		item_container.add_child(item_card)  
		item_card.setup(item, index)  
		item_card.purchased.connect(_on_item_purchased.bind(index))  

func _on_item_purchased(item_index: int):  
	if game_manager.purchase_shop_item(item_index):  
		# 更新显示  
		refresh_shop_display()  
		
func _on_leave_shop_pressed():  
	# 发出离开商店信号
	emit_signal("leave_shop_requested")
