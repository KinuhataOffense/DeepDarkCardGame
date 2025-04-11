#!/usr/bin/env -S godot --headless --script
extends SceneTree

# 命令行工具脚本，用于生成灵魂粒子纹理
# 使用方法: godot --headless --script scripts/tools/create_soul_particles.gd

func _init():
	print("开始生成灵魂粒子纹理...")
	
	# 生成基础灵魂粒子纹理
	var particle_texture = generate_soul_particle(256, 256)
	var particle_path = "res://assets/textures/particles/soul_particle.png"
	save_texture(particle_texture, particle_path)
	print("灵魂粒子纹理已保存到 " + particle_path)
	
	# 生成灵魂轨迹纹理
	var trail_texture = generate_soul_trail(256, 64)
	var trail_path = "res://assets/textures/particles/soul_trail.png"
	save_texture(trail_texture, trail_path)
	print("灵魂轨迹纹理已保存到 " + trail_path)
	
	# 生成灵魂光芒纹理
	var glow_texture = generate_soul_glow(512, 512)
	var glow_path = "res://assets/textures/particles/soul_glow.png"
	save_texture(glow_texture, glow_path)
	print("灵魂光芒纹理已保存到 " + glow_path)
	
	print("所有灵魂粒子纹理生成完成!")
	quit()

# 生成灵魂粒子主纹理
func generate_soul_particle(width: int, height: int) -> ImageTexture:
	var image = Image.create(width, height, true, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0)) # 透明背景
	
	var center_x = width / 2
	var center_y = height / 2
	var max_radius = min(width, height) / 2.0 * 0.8 # 最大半径为图像尺寸的40%
	
	# 噪声生成器用于添加不规则形状
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.fractal_octaves = 3
	noise.frequency = 0.1
	
	# 灵魂粒子的颜色设置
	var inner_color = Color(0.7, 0.9, 1.0, 0.9) # 内部亮蓝色
	var outer_color = Color(0.3, 0.5, 0.9, 0.0) # 外部深蓝色，透明
	
	# 绘制粒子
	for y in range(height):
		for x in range(width):
			var dx = x - center_x
			var dy = y - center_y
			var distance = sqrt(dx * dx + dy * dy)
			
			if distance <= max_radius:
				# 加入噪声扰动，使粒子形状不规则
				var angle = atan2(dy, dx)
				var noise_val = noise.get_noise_2d(cos(angle) * 5, sin(angle) * 5) * 0.5 + 0.5
				var adjusted_distance = distance * (1.0 + noise_val * 0.3 - 0.15)
				
				# 计算不透明度，从中心向外渐变
				var opacity_factor = 1.0 - adjusted_distance / max_radius
				opacity_factor = pow(opacity_factor, 1.5) # 使边缘更柔和
				
				if opacity_factor > 0:
					# 计算颜色渐变
					var color = inner_color.lerp(outer_color, 1.0 - opacity_factor)
					
					# 添加一些细微的颜色变化
					var detail_noise = noise.get_noise_2d(x * 0.2, y * 0.2) * 0.5 + 0.5
					color.r += (detail_noise - 0.5) * 0.1
					color.g += (detail_noise - 0.5) * 0.1
					color.b += (detail_noise - 0.5) * 0.1
					
					# 设置最终颜色
					color.a *= opacity_factor
					image.set_pixel(x, y, color)
	
	# 添加内部的细节
	add_inner_details(image, center_x, center_y, max_radius * 0.7, noise)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

# 添加灵魂粒子内部的细节
func add_inner_details(image: Image, center_x: int, center_y: int, radius: float, noise: FastNoiseLite):
	var width = image.get_width()
	var height = image.get_height()
	
	# 添加螺旋状的能量线
	for angle_deg in range(0, 360, 15): # 每15度一条线
		var angle = deg_to_rad(angle_deg)
		var spiral_tightness = 0.15
		
		for t in range(50): # 50个点组成一条线
			var r = t / 50.0 * radius
			var spiral_angle = angle + r * spiral_tightness
			
			var x = center_x + cos(spiral_angle) * r
			var y = center_y + sin(spiral_angle) * r
			
			if x >= 0 and x < width and y >= 0 and y < height:
				var current_color = image.get_pixel(int(x), int(y))
				
				# 增加线条亮度
				var line_brightness = 0.3 * (1.0 - t / 50.0)
				var highlight_color = current_color.lightened(line_brightness)
				
				# 调整颜色使其略带青色
				highlight_color.g = min(highlight_color.g + 0.1, 1.0)
				highlight_color.b = min(highlight_color.b + 0.05, 1.0)
				
				image.set_pixel(int(x), int(y), highlight_color)

# 生成灵魂轨迹纹理
func generate_soul_trail(width: int, height: int) -> ImageTexture:
	var image = Image.create(width, height, true, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0)) # 透明背景
	
	# 噪声生成器
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.fractal_octaves = 2
	noise.frequency = 0.05
	
	# 轨迹颜色设置
	var trail_color_start = Color(0.5, 0.8, 1.0, 0.8) # 起始蓝色
	var trail_color_end = Color(0.2, 0.4, 0.8, 0.0)   # 结束深蓝色，透明
	
	# 绘制水平渐变轨迹
	for y in range(height):
		for x in range(width):
			var gradient_factor = float(x) / width # 从左到右的渐变
			var y_center_factor = 1.0 - abs(y - height/2) / (height/2) # 垂直方向中间最亮
			
			# 加入噪声，让轨迹看起来不那么整齐
			var noise_val = noise.get_noise_2d(x * 0.1, y * 0.2) * 0.5 + 0.5
			var adjusted_y_factor = y_center_factor * (0.7 + noise_val * 0.6)
			
			# 淡出效果
			var opacity = adjusted_y_factor * (1.0 - pow(gradient_factor, 0.7))
			
			if opacity > 0.01:
				var color = trail_color_start.lerp(trail_color_end, gradient_factor)
				color.a *= opacity
				image.set_pixel(x, y, color)
	
	# 添加一些亮点
	for i in range(20):
		var spark_x = randi() % int(width * 0.7) # 只在前70%的区域添加亮点
		var spark_y = height/2 + (randi() % int(height * 0.6) - height * 0.3) # 在中心区域上下浮动
		
		var spark_size = randi() % 5 + 2
		var spark_brightness = randf() * 0.5 + 0.5
		
		for y in range(spark_y - spark_size, spark_y + spark_size):
			for x in range(spark_x - spark_size, spark_x + spark_size):
				if x >= 0 and x < width and y >= 0 and y < height:
					var distance = sqrt(pow(x - spark_x, 2) + pow(y - spark_y, 2))
					if distance <= spark_size:
						var current_color = image.get_pixel(x, y)
						var spark_intensity = (1.0 - distance / spark_size) * spark_brightness
						var spark_color = current_color.lightened(spark_intensity)
						spark_color.a = min(spark_color.a + spark_intensity * 0.5, 1.0)
						image.set_pixel(x, y, spark_color)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

# 生成灵魂光芒纹理
func generate_soul_glow(width: int, height: int) -> ImageTexture:
	var image = Image.create(width, height, true, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0)) # 透明背景
	
	var center_x = width / 2
	var center_y = height / 2
	var max_radius = min(width, height) / 2.0
	
	# 噪声生成器
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.fractal_octaves = 4
	noise.frequency = 0.01
	
	# 光芒颜色设置
	var inner_glow = Color(0.9, 0.95, 1.0, 0.5) # 内部白光
	var middle_glow = Color(0.6, 0.85, 1.0, 0.3) # 中间蓝光
	var outer_glow = Color(0.2, 0.5, 0.9, 0.0) # 外部深蓝光，透明
	
	# 绘制径向渐变光芒
	for y in range(height):
		for x in range(width):
			var dx = x - center_x
			var dy = y - center_y
			var distance = sqrt(dx * dx + dy * dy)
			
			if distance <= max_radius:
				# 基于距离的径向渐变
				var gradient_factor = distance / max_radius
				
				# 加入噪声，使光芒看起来更自然
				var angle = atan2(dy, dx)
				var noise_val = noise.get_noise_2d(cos(angle) * 10, sin(angle) * 10) * 0.5 + 0.5
				var detail_noise = noise.get_noise_2d(x * 0.05, y * 0.05) * 0.5 + 0.5
				
				# 结合噪声和梯度调整不透明度
				var opacity = (1.0 - gradient_factor) * (0.8 + noise_val * 0.4) * (0.9 + detail_noise * 0.2)
				opacity = pow(opacity, 1.2) # 使边缘更柔和
				
				if opacity > 0.01:
					var color
					if gradient_factor < 0.3:
						# 内部的颜色过渡
						color = inner_glow.lerp(middle_glow, gradient_factor / 0.3)
					else:
						# 外部的颜色过渡
						color = middle_glow.lerp(outer_glow, (gradient_factor - 0.3) / 0.7)
					
					# 添加细微的颜色变化
					color.r += (detail_noise - 0.5) * 0.05
					color.g += (detail_noise - 0.5) * 0.05
					color.b += (detail_noise - 0.5) * 0.05
					
					# 设置最终不透明度
					color.a *= opacity
					image.set_pixel(x, y, color)
	
	# 添加辐射状的光线
	add_radial_rays(image, center_x, center_y, max_radius)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

# 添加辐射状的光线
func add_radial_rays(image: Image, center_x: int, center_y: int, max_radius: float):
	var width = image.get_width()
	var height = image.get_height()
	
	# 随机生成一些光线
	for i in range(12): # 12条光线
		var angle = randf() * 2.0 * PI
		var ray_width = randf() * 0.1 + 0.02 # 0.02到0.12弧度宽度
		var ray_intensity = randf() * 0.3 + 0.2 # 光线强度
		
		for r in range(int(max_radius)):
			var ray_opacity = (1.0 - r / max_radius) * ray_intensity
			
			for a in range(-10, 11):
				var ray_angle = angle + a * 0.01 * ray_width
				var x = center_x + cos(ray_angle) * r
				var y = center_y + sin(ray_angle) * r
				
				if x >= 0 and x < width and y >= 0 and y < height:
					var current_color = image.get_pixel(int(x), int(y))
					var ray_factor = (1.0 - abs(a) / 10.0) * ray_opacity
					
					var ray_color = current_color.lightened(ray_factor)
					ray_color.a = min(ray_color.a + ray_factor * 0.3, 1.0)
					
					image.set_pixel(int(x), int(y), ray_color)

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