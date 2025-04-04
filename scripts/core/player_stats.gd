extends Node  
class_name PlayerStats  

var health: int = 100  
var max_health: int = 100  
var current_score: int = 0  
var currency: int = 0  

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
		# 游戏结束处理  
		var game_manager = get_parent()  
		if game_manager.has_method("emit_signal"):  
			game_manager.emit_signal("game_over", false)  
		
func heal(amount: int):  
	health = min(max_health, health + amount)  

func get_player_stats():  
	return { "health": health, "max_health": max_health, "current_score": current_score, "currency": currency }

func set_player_stats(stats):  
	health = stats["health"]  	
	max_health = stats["max_health"]  
	current_score = stats["current_score"]  	
	currency = stats["currency"]
