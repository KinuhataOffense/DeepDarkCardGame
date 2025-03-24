extends Control  

@onready var shop_system = $ShopSystem  
@onready var item_container = $ItemContainer  
@onready var player_currency = $PlayerCurrency  
@onready var leave_button = $LeaveShopButton  

var game_manager = null  
var item_card_scene = preload("res://scenes/shop/item_card.tscn")  

func _ready():  
	# 连接按钮信号  
	leave_button.pressed.connect(_on_leave_shop_pressed)  
	
	# 等待游戏管理器引用  
	await get_tree().process_frame  
	refresh_shop_display()  

func initialize(new_game_manager):  
	game_manager = new_game_manager  
	shop_system.game_manager = game_manager  
	
func refresh_shop_display():  
	# 清空现有物品显示  
	for child in item_container.get_children():  
		child.queue_free()  
	
	# 更新货币显示  
	player_currency.text = "货币: " + str(game_manager.player_stats.currency)  
	
	# 刷新商店物品  
	shop_system.initialize_shop()  
	
	# 为每个可用物品创建卡片  
	for item in shop_system.available_items:  
		var item_card = item_card_scene.instantiate()  
		item_container.add_child(item_card)  
		item_card.setup(item)  
		item_card.purchased.connect(_on_item_purchased.bind(item_card))  

func _on_item_purchased(item_card):  
	var result = shop_system.purchase_item(item_card.item_index)  
	if result:  
		# 更新显示  
		refresh_shop_display()  
		
func _on_leave_shop_pressed():  
	# 离开商店，返回主游戏  
	game_manager.leave_shop()  
	queue_free()  
