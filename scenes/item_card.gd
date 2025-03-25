extends Control  
class_name ItemCard  

signal purchased  

var item_data = null  
var item_index = -1  

@onready var item_name = $ItemName  
@onready var item_description = $ItemDescription  
@onready var item_price = $ItemPrice  
@onready var buy_button = $BuyButton  

func _ready():  
	buy_button.pressed.connect(_on_buy_button_pressed)  

func setup(data, index = -1):  
	item_data = data  
	item_index = index  
	
	# 更新UI  
	item_name.text = data.get("name", "未知物品")  
	item_description.text = data.get("description", "")  
	item_price.text = str(data.get("price", 0)) + " 金币"  

func _on_buy_button_pressed():  
	emit_signal("purchased")  
