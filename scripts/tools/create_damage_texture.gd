#!/usr/bin/env -S godot --headless --script
extends SceneTree

# 命令行工具脚本，用于生成损坏纹理
# 使用方法: godot --headless --script scripts/tools/create_damage_texture.gd

func _init():
	print("开始生成损坏效果纹理...")
	var texture = generate_damage_texture()
	var save_path = "res://assets/textures/noise/noise_damage.png"
	save_texture(texture, save_path)
	print("损坏效果纹理已生成并保存到 " + save_path)
	quit()

# 创建损坏效果纹理
func generate_damage_texture():
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.fractal_octaves = 4
	noise.frequency = 0.04
	
	var image = Image.create(512, 512, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 1)) # 开始时整个图像为白色
	
	# 创建基础圆角矩形形状
	var center_x = 256
	var center_y = 256
	var width = 430
	var height = 430
	var corner_radius = 40
	
	# 绘制圆角矩形 (外部为黑色，内部保持白色)
	for x in range(512):
		for y in range(512):
			var dx = abs(x - center_x)
			var dy = abs(y - center_y)
			
			# 检查是否在圆角矩形外部
			if dx > width / 2 or dy > height / 2:
				image.set_pixel(x, y, Color(0, 0, 0, 1))
			elif dx > width / 2 - corner_radius and dy > height / 2 - corner_radius:
				# 在角落区域，检查是否超出圆角
				var corner_dx = dx - (width / 2 - corner_radius)
				var corner_dy = dy - (height / 2 - corner_radius)
				if corner_dx * corner_dx + corner_dy * corner_dy > corner_radius * corner_radius:
					image.set_pixel(x, y, Color(0, 0, 0, 1))
	
	# 为边缘添加不规则撕裂和磨损效果
	var border_size = 60 # 边缘效果区域宽度
	for x in range(512):
		for y in range(512):
			var pixel_color = image.get_pixel(x, y)
			
			# 只对接近边缘的区域应用效果
			var dx = abs(x - center_x)
			var dy = abs(y - center_y)
			var distance_from_center = sqrt(dx * dx + dy * dy)
			var distance_from_edge = min(width/2 - dx, height/2 - dy)
			
			# 对接近边缘的区域应用噪声
			if pixel_color.r > 0.5 and distance_from_edge < border_size:
				# 计算噪声值，用于不规则磨损
				var noise_value = noise.get_noise_2d(x * 1.5, y * 1.5) * 0.5 + 0.5
				var edge_noise = noise.get_noise_2d(x * 0.8, y * 0.8) * 0.5 + 0.5
				
				# 边缘接近度因子 (0表示离边缘很远，1表示在边缘)
				var edge_factor = 1.0 - (distance_from_edge / float(border_size))
				edge_factor = pow(edge_factor, 1.5) # 使边缘效果更加明显
				
				# 应用噪声和边缘效果
				var damage_amount = edge_factor * 1.2 * (noise_value * 0.7 + edge_noise * 0.3)
				
				# 创建从边缘向内部逐渐消失的锯齿状和不规则效果
				if damage_amount > 0.4 + 0.3 * edge_noise:
					var alpha = min(1.0, damage_amount * 1.5)
					image.set_pixel(x, y, Color(0, 0, 0, alpha))
				else:
					# 创建轻微磨损效果
					var gray_value = max(0.0, 1.0 - damage_amount * 0.7)
					image.set_pixel(x, y, Color(gray_value, gray_value, gray_value, 1))
	
	# 添加一些随机的内部磨损斑点
	for i in range(20):
		var spot_x = randi() % 412 + 50
		var spot_y = randi() % 412 + 50
		var spot_size = randi() % 20 + 10
		
		# 只有当斑点不太接近边缘时才添加
		var dx = abs(spot_x - center_x)
		var dy = abs(spot_y - center_y)
		if dx < width/2 - border_size * 0.7 and dy < height/2 - border_size * 0.7:
			for x in range(spot_x - spot_size, spot_x + spot_size):
				for y in range(spot_y - spot_size, spot_y + spot_size):
					if x >= 0 and x < 512 and y >= 0 and y < 512:
						var dist = sqrt(pow(x - spot_x, 2) + pow(y - spot_y, 2))
						if dist < spot_size:
							var spot_intensity = 1.0 - dist / spot_size
							var current = image.get_pixel(x, y)
							var gray_value = max(0.4, current.r - spot_intensity * 0.3)
							image.set_pixel(x, y, Color(gray_value, gray_value, gray_value, 1))
	
	# 添加一些细小的折痕线条
	for i in range(15):
		var line_start_x = randi() % 412 + 50
		var line_start_y = randi() % 412 + 50
		var line_length = randi() % 100 + 50
		var angle = randf() * 2 * PI
		
		var dx = cos(angle) * line_length
		var dy = sin(angle) * line_length
		var line_end_x = line_start_x + dx
		var line_end_y = line_start_y + dy
		
		for t in range(100):
			var t_normalized = float(t) / 100.0
			var x = int(line_start_x + dx * t_normalized)
			var y = int(line_start_y + dy * t_normalized)
			
			if x >= 0 and x < 512 and y >= 0 and y < 512:
				# 使线条更加自然随机
				var line_noise = noise.get_noise_2d(t * 0.2, 0) * 0.5 + 0.5
				var width_variation = int(line_noise * 3)
				
				for w in range(-width_variation, width_variation + 1):
					var nx = x + w
					var ny = y + int(noise.get_noise_2d(t * 0.5, w * 0.5) * 2)
					
					if nx >= 0 and nx < 512 and ny >= 0 and ny < 512:
						var current = image.get_pixel(nx, ny)
						if current.r > 0.4: # 只在非黑区域绘制
							var intensity = (1.0 - abs(float(w) / float(width_variation + 1))) * 0.3
							var gray_value = max(0.6, current.r - intensity)
							image.set_pixel(nx, ny, Color(gray_value, gray_value, gray_value, 1))
	
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