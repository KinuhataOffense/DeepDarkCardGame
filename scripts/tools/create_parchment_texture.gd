#!/usr/bin/env -S godot --headless --script
extends SceneTree

# 命令行工具脚本，用于生成羊皮纸纹理
# 使用方法: godot --headless --script scripts/tools/create_parchment_texture.gd

func _init():
	print("开始生成羊皮纸纹理...")
	var texture = generate_parchment_texture()
	var save_path = "res://assets/textures/card/parchment_texture.png"
	save_texture(texture, save_path)
	print("羊皮纸纹理已生成并保存到 " + save_path)
	quit()

# 创建羊皮纸纹理
func generate_parchment_texture():
	var base_noise = FastNoiseLite.new()
	base_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	base_noise.seed = randi()
	base_noise.fractal_octaves = 5
	base_noise.frequency = 0.01
	
	var detail_noise = FastNoiseLite.new()
	detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	detail_noise.seed = randi()
	detail_noise.fractal_octaves = 3
	detail_noise.frequency = 0.04
	
	var fiber_noise = FastNoiseLite.new()
	fiber_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	fiber_noise.seed = randi()
	fiber_noise.fractal_octaves = 2
	fiber_noise.frequency = 0.1
	
	var image = Image.create(512, 512, false, Image.FORMAT_RGBA8)
	
	# 定义羊皮纸的基础颜色范围（从暖米色到浅黄褐色）
	var base_color_light = Color(0.96, 0.94, 0.84)  # 浅米色
	var base_color_dark = Color(0.92, 0.88, 0.74)   # 暖黄褐色
	
	# 添加一些老化变色斑点的颜色
	var aged_spot_color = Color(0.84, 0.78, 0.65)   # 深一点的黄褐色
	
	for x in range(512):
		for y in range(512):
			# 基础羊皮纸颜色变化
			var base_value = base_noise.get_noise_2d(x, y) * 0.5 + 0.5
			
			# 添加详细纹理
			var detail_value = detail_noise.get_noise_2d(x * 2, y * 2) * 0.5 + 0.5
			
			# 添加纤维方向纹理（模拟羊皮纸的纤维结构）
			var fiber_value = fiber_noise.get_noise_2d(x, y * 5) * 0.5 + 0.5  # y方向拉伸，模拟横向纤维
			
			# 合并所有纹理层
			var combined_value = base_value * 0.6 + detail_value * 0.3 + fiber_value * 0.1
			
			# 计算最终颜色 - 在基础颜色范围内插值
			var final_color = base_color_light.lerp(base_color_dark, combined_value)
			
			# 随机添加一些老化斑点
			var spot_noise = detail_noise.get_noise_2d(x * 3, y * 3) * 0.5 + 0.5
			if spot_noise > 0.85:
				var spot_intensity = (spot_noise - 0.85) * 6  # 放大斑点效果
				final_color = final_color.lerp(aged_spot_color, spot_intensity * 0.7)
			
			# 为边缘添加轻微的暗淡效果（使纹理看起来更自然平铺）
			var edge_distance = min(min(x, 512 - x), min(y, 512 - y)) / 30.0
			var edge_factor = clamp(edge_distance, 0, 1)
			final_color = final_color.lerp(base_color_dark, (1 - edge_factor) * 0.1)
			
			image.set_pixel(x, y, final_color)
	
	# 添加细微的折痕和皱纹
	for i in range(10):
		var crease_start_x = randi() % 512
		var crease_start_y = randi() % 512
		var crease_length = randi() % 200 + 100
		var angle = randf() * 2 * PI
		
		var dx = cos(angle) * crease_length
		var dy = sin(angle) * crease_length
		
		for t in range(crease_length):
			var t_normalized = float(t) / crease_length
			var x = int(crease_start_x + dx * t_normalized)
			var y = int(crease_start_y + dy * t_normalized)
			
			if x >= 0 and x < 512 and y >= 0 and y < 512:
				var crease_noise = base_noise.get_noise_2d(t * 0.2, 0) * 0.5 + 0.5
				var width_variation = int(crease_noise * 2) + 1
				var crease_intensity = 0.08 * (1.0 - abs(t_normalized * 2 - 1))  # 中间强，两端弱
				
				for w in range(-width_variation, width_variation + 1):
					var nx = x + w
					var ny = y + int(detail_noise.get_noise_2d(t * 0.5, w * 0.5) * 2)
					
					if nx >= 0 and nx < 512 and ny >= 0 and ny < 512:
						var current_color = image.get_pixel(nx, ny)
						var darkened_color = current_color.darkened(crease_intensity * (1.0 - float(abs(w)) / width_variation))
						image.set_pixel(nx, ny, darkened_color)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

# 保存纹理到文件
func save_texture(texture: ImageTexture, path: String):
	var image = texture.get_image()
	var dir = path.get_base_dir()
	
	# 确保目录存在
	var dir_access = DirAccess.open("res://")
	if not dir_access.dir_exists(dir.trim_prefix("res://")):
		dir_access.make_dir_recursive(dir.trim_prefix("res://"))
	
	var err = image.save_png(path)
	if err != OK:
		push_error("无法保存纹理到 " + path + "，错误码：" + str(err))
		return false
	
	return true 