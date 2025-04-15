extends Node  

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

# 添加奖励到玩家状态
func add_rewards(reward_data: Dictionary):
	if reward_data.has("currency"):
		currency += reward_data.currency
		print("PlayerStats: 添加", reward_data.currency, "金币，当前总金币:", currency)
	
	if reward_data.has("items"):
		for item in reward_data.items:
			# 处理物品奖励，如果需要可以扩展该部分
			print("PlayerStats: 获得物品:", item.name, "x", item.quantity)
	
	if reward_data.has("exp"):
		# 处理经验值，后续可以添加升级逻辑
		print("PlayerStats: 获得经验:", reward_data.exp)
	
	if reward_data.has("health"):
		heal(reward_data.health)
		print("PlayerStats: 恢复生命值:", reward_data.health, "，当前生命值:", health)
