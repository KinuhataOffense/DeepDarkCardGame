func _on_return_button_pressed():
	print("奖励场景: 返回按钮被点击")
	
	# 尝试从GameManager获取返回方法
	var game_manager = get_node("/root/GameManager")
	if not game_manager:
		push_error("奖励场景: 无法找到GameManager")
		return
	
	# 检查是否来自Rogue模式
	var from_rogue = false
	if game_manager.has_meta("reward_from_rogue_mode"):
		from_rogue = game_manager.get_meta("reward_from_rogue_mode")
		print("奖励场景: 从GameManager元数据中获取from_rogue_mode=", from_rogue)
	
	# 如果来自Rogue模式，尝试调用返回Rogue模式的方法
	if from_rogue:
		print("奖励场景: 尝试返回Rogue模式")
		# 尝试多种可能的返回方法
		if game_manager.has_method("return_to_rogue_mode"):
			game_manager.return_to_rogue_mode()
		elif game_manager.has_method("return_to_rogue"):
			game_manager.return_to_rogue()
		elif game_manager.has_method("switch_to_rogue_mode"):
			game_manager.switch_to_rogue_mode()
		else:
			push_error("奖励场景: GameManager没有实现返回Rogue模式的方法")
			# 如果找不到返回方法，尝试返回地图
			game_manager.return_to_map()
	else:
		# 如果不是Rogue模式，返回地图
		print("奖励场景: 返回地图")
		game_manager.return_to_map() 