extends CardUI  

@onready var label = $Frontface/Label  

func _ready():  
	super()
	label.text = card_data.nice_name
	# 设置卡牌文本  
	if card_data:  
		# 根据卡牌类型设置样式  
		if card_data is DarkCardData:  
			var dark_data = card_data as DarkCardData  
			
			# 设置花色图标/文本  
			match dark_data.suit:  
				"hearts":  
					label.text = "♥" + label.text  
					label.add_theme_color_override("font_color", Color.RED)  
				"diamonds":  
					label.text = "♦" + label.text  
					label.add_theme_color_override("font_color", Color.RED)  
				"clubs":  
					label.text = "♣" + label.text  
				"spades":  
					label.text = "♠" + label.text  
				"special":  
					label.text = "✦" + label.text  
					label.add_theme_color_override("font_color", Color.PURPLE)  
					
			# 特殊卡牌的视觉效果  
			if dark_data.card_type == DarkCardData.CardType.ENHANCED:  
				var overlay = TextureRect.new()  
				overlay.texture = preload("res://assets/ui/enhanced_overlay.png")  
				$Frontface.add_child(overlay)  
				
			elif dark_data.card_type == DarkCardData.CardType.SPECIAL:  
				var overlay = TextureRect.new()  
				overlay.texture = preload("res://assets/ui/special_overlay.png")  
				$Frontface.add_child(overlay)  
