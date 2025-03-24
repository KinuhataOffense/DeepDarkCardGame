extends Node  
class_name PlayerStats  

var health: int = 100  
var max_health: int = 100  
var current_score: int = 0  
var currency: int = 0  

# 道具和被动效果  
var items: Array = []  
var passive_effects: Dictionary = {}  

# 初始化  
func reset():  
	health = max_health  
	current_score = 0  
	
# 得分管理  
func add_score(amount: int):  
	current_score += amount  
	
# 受伤和治疗  
func take_damage(amount: int):  
	health = max(0, health - amount)  
	if health <= 0:  
		emit_signal("player_died")  
		
func heal(amount: int):  
	health = min(max_health, health + amount)  
	
# 道具管理  
func add_item(item_data: Dictionary):  
	items.append(item_data)  
	apply_item_effects(item_data)  
	
func apply_item_effects(item_data: Dictionary):  
	match item_data.type:  
		"permanent_upgrade":  
			match item_data.effect_id:  
				"imprint_mastery":  
					# 提升刻印组合能力  
					passive_effects["imprint_bonus_score"] = 5  
					passive_effects["imprint_multiplier"] = 0.3  
					
				"max_health_up":  
					# 增加最大生命值  
					max_health += item_data.value  
					health += item_data.value  
					
		"consumable":  
			# 临时消耗品  
			var duration = item_data.duration  
			var temp_effect = {  
				"effect_id": item_data.effect_id,  
				"duration": duration,  
				"value": item_data.value  
			}  
			passive_effects["temp_effects"].append(temp_effect)  
			
# 更新临时效果持续时间  
func update_temp_effects():  
	var temp_effects = passive_effects.get("temp_effects", [])  
	var i = 0  
	while i < temp_effects.size():  
		temp_effects[i].duration -= 1  
		if temp_effects[i].duration <= 0:  
			temp_effects.remove_at(i)  
		else:  
			i += 1  
