extends Node

# 效果系统自动加载脚本 - 为项目添加全局视觉效果管理

func _ready():
	# 检查VisualEffectsManager是否已在自动加载中配置
	var visual_manager = get_node_or_null("/root/VisualEffectsManager")
	
	if visual_manager == null:
		# 如果未配置，则手动创建实例
		print("VisualEffectsManager未在自动加载中配置，正在手动创建...")
		
		# 创建VisualEffectsManager实例
		var manager_script = load("res://scripts/core/visual_effects_manager.gd")
		if manager_script:
			var manager_instance = manager_script.new()
			manager_instance.name = "VisualEffectsManager"
			get_tree().root.add_child(manager_instance)
			print("成功创建VisualEffectsManager实例")
		else:
			push_error("无法加载视觉效果管理器脚本")
	else:
		print("找到已配置的VisualEffectsManager自动加载实例")
	
	# 输出提示信息
	print("效果系统初始化完成，可通过VisualEffectsManager使用视觉效果")
	print("使用示例：")
	print("VisualEffectsManager.apply_preset(VisualEffectsManager.VisualPreset.DEFAULT)")
	print("VisualEffectsManager.set_scene_type(PostProcessingManager.SceneType.BATTLE)")
	
	# 初始化自动加载后不再需要该节点
	queue_free() 