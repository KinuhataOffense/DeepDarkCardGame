#!/usr/bin/env -S godot --headless --script
extends SceneTree

# 命令行工具脚本，用于生成哥特式卡牌边框
# 使用方法: godot --headless --script scripts/tools/create_gothic_frame.gd

func _init():
	print("开始生成哥特式卡牌边框...")
	var texture = generate_gothic_frame()
	var save_path = "res://assets/textures/card/gothic_frame.png"
	save_texture(texture, save_path)
	print("哥特式卡牌边框已生成并保存到 " + save_path)
	quit()

# 创建哥特式卡牌边框
func generate_gothic_frame():
	var width = 1024
	var height = 1024
	var image = Image.create(width, height, true, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0)) # 透明背景
	
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.fractal_octaves = 4
	noise.frequency = 0.05
	
	# 边框参数
	var border_width = int(width * 0.1) # 边框宽度为图像宽度的10%
	var inner_width = width - 2 * border_width
	var inner_height = height - 2 * border_width
	
	# 边框颜色
	var border_color = Color(0.25, 0.22, 0.2, 1.0) # 暗褐色边框
	var border_highlight = Color(0.35, 0.32, 0.28, 1.0) # 边框高光
	var shadow_color = Color(0.15, 0.12, 0.1, 1.0) # 边框阴影
	
	# 绘制边框的基本形状
	for y in range(height):
		for x in range(width):
			# 检查是否在边框区域
			var in_border = (x < border_width or x >= width - border_width or 
							y < border_width or y >= height - border_width)
			
			if in_border:
				# 边框内添加一些纹理变化
				var noise_value = noise.get_noise_2d(x * 1.5, y * 1.5) * 0.5 + 0.5
				
				# 边框内部向中心渐变
				var distance_from_edge = min(
					min(x, width - 1 - x),
					min(y, height - 1 - y)
				)
				var edge_factor = float(distance_from_edge) / float(border_width)
				edge_factor = clamp(edge_factor, 0.0, 1.0)
				
				# 获取接近边缘或角落的影响
				var is_near_corner = (x < border_width * 1.5 and y < border_width * 1.5) or \
									(x < border_width * 1.5 and y >= height - border_width * 1.5) or \
									(x >= width - border_width * 1.5 and y < border_width * 1.5) or \
									(x >= width - border_width * 1.5 and y >= height - border_width * 1.5)
				
				var is_edge = (x < border_width * 0.3) or (x >= width - border_width * 0.3) or \
							(y < border_width * 0.3) or (y >= height - border_width * 0.3)
				
				# 根据位置混合颜色
				var final_color = border_color
				if is_edge:
					final_color = final_color.lerp(shadow_color, 0.7 - noise_value * 0.3)
				elif is_near_corner:
					final_color = final_color.lerp(border_highlight, noise_value * 0.5)
				else:
					final_color = final_color.lerp(border_highlight, edge_factor * 0.4 * noise_value)
				
				# 添加细微的随机色调变化
				final_color.r += (noise_value - 0.5) * 0.05
				final_color.g += (noise_value - 0.5) * 0.03
				final_color.b += (noise_value - 0.5) * 0.02
				
				image.set_pixel(x, y, final_color)
	
	# 添加哥特式装饰元素
	add_gothic_decorations(image, border_width, width, height)
	
	# 添加角落的装饰元素
	add_corner_decorations(image, border_width, width, height)
	
	# 添加磨损和老化效果
	add_wear_effect(image, noise, width, height)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

# 添加哥特式装饰
func add_gothic_decorations(image, border_width, width, height):
	# 中心点
	var center_x = width / 2
	var center_y = height / 2
	
	# 在四条边添加装饰
	# 顶部边缘装饰
	for x in range(border_width * 2, width - border_width * 2, border_width):
		draw_gothic_arch(image, x, border_width * 0.5, border_width * 0.8, border_width * 0.6, true)
	
	# 底部边缘装饰
	for x in range(border_width * 2, width - border_width * 2, border_width):
		draw_gothic_arch(image, x, height - border_width * 0.5, border_width * 0.8, border_width * 0.6, false)
	
	# 左侧边缘装饰
	for y in range(border_width * 2, height - border_width * 2, border_width):
		draw_gothic_arch(image, border_width * 0.5, y, border_width * 0.6, border_width * 0.8, true, true)
	
	# 右侧边缘装饰
	for y in range(border_width * 2, height - border_width * 2, border_width):
		draw_gothic_arch(image, width - border_width * 0.5, y, border_width * 0.6, border_width * 0.8, false, true)

# 绘制哥特式拱门装饰
func draw_gothic_arch(image, center_x, center_y, width, height, pointing_up = true, is_sideways = false):
	# 装饰元素的颜色
	var decoration_color = Color(0.5, 0.45, 0.4, 1.0) # 稍亮的褐色
	var highlight_color = Color(0.65, 0.6, 0.55, 1.0) # 高光色
	
	if is_sideways:
		# 水平方向的拱门装饰
		var direction = 1 if pointing_up else -1
		for x in range(int(center_x - width/2), int(center_x + width/2)):
			for y in range(int(center_y - height/2), int(center_y + height/2)):
				var dx = abs(x - center_x)
				var dy = abs(y - center_y)
				
				# 创建尖拱形状
				var arch_value = dx / (width/2)
				var arch_y = height/2 * arch_value * arch_value * 0.8
				
				if dy < arch_y and dx < width/2:
					# 计算到边缘的距离
					var distance_to_edge = min(arch_y - dy, width/2 - dx)
					var edge_factor = clamp(distance_to_edge / 5.0, 0.0, 1.0)
					
					# 混合颜色
					var color = decoration_color.lerp(highlight_color, edge_factor * 0.5)
					
					# 确保在图像边界内
					if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
						image.set_pixel(x, y, color)
	else:
		# 垂直方向的拱门装饰
		var direction = 1 if pointing_up else -1
		for x in range(int(center_x - width/2), int(center_x + width/2)):
			for y in range(int(center_y - height/2), int(center_y + height/2)):
				var dx = abs(x - center_x)
				var dy = abs(y - center_y)
				
				# 创建尖拱形状
				var arch_value = dx / (width/2)
				var arch_y = height/2 * arch_value * arch_value * 0.8
				
				if dy < arch_y and dx < width/2:
					# 计算到边缘的距离
					var distance_to_edge = min(arch_y - dy, width/2 - dx)
					var edge_factor = clamp(distance_to_edge / 5.0, 0.0, 1.0)
					
					# 混合颜色
					var color = decoration_color.lerp(highlight_color, edge_factor * 0.5)
					
					# 确保在图像边界内
					if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
						var target_y = center_y + direction * (dy) if pointing_up else center_y - direction * (dy)
						image.set_pixel(x, target_y, color)

# 添加角落装饰
func add_corner_decorations(image, border_width, width, height):
	var corner_size = border_width * 2
	
	# 左上角
	draw_corner_ornament(image, border_width, border_width, corner_size, corner_size)
	
	# 右上角
	draw_corner_ornament(image, width - border_width, border_width, corner_size, corner_size, true)
	
	# 左下角
	draw_corner_ornament(image, border_width, height - border_width, corner_size, corner_size, false, true)
	
	# 右下角
	draw_corner_ornament(image, width - border_width, height - border_width, corner_size, corner_size, true, true)

# 绘制角落装饰
func draw_corner_ornament(image, center_x, center_y, width, height, flip_x = false, flip_y = false):
	var ornament_color = Color(0.4, 0.35, 0.3, 1.0) # 装饰颜色
	var highlight_color = Color(0.55, 0.5, 0.45, 1.0) # 高光色
	
	# 绘制花纹装饰
	for dx in range(-width, width):
		for dy in range(-height, height):
			var x = center_x + (dx if not flip_x else -dx)
			var y = center_y + (dy if not flip_y else -dy)
			
			# 确保在图像边界内
			if x < 0 or x >= image.get_width() or y < 0 or y >= image.get_height():
				continue
			
			# 创建放射状花纹
			var angle = atan2(dy, dx)
			var distance = sqrt(dx*dx + dy*dy)
			
			# 角落花纹图案
			var pattern_value = 0.0
			
			# 放射状装饰
			var ray_count = 5
			var ray_width = 0.2
			var ray_angle = (angle + PI) % (2 * PI / ray_count)
			var ray_pattern = max(0, 1.0 - abs(ray_angle - PI / ray_count) / ray_width)
			
			# 圆形衰减
			var radial_decay = max(0, 1.0 - distance / width)
			
			# 综合图案
			pattern_value = ray_pattern * radial_decay
			
			if pattern_value > 0.1 and distance < width * 0.8:
				var color = ornament_color.lerp(highlight_color, pattern_value * 0.7)
				image.set_pixel(x, y, color)

# 添加磨损和老化效果
func add_wear_effect(image, noise, width, height):
	for y in range(height):
		for x in range(width):
			var current_color = image.get_pixel(x, y)
			
			# 只处理非透明像素
			if current_color.a > 0:
				# 添加随机磨损
				var wear_noise = noise.get_noise_2d(x * 3, y * 3) * 0.5 + 0.5
				
				# 随机划痕和磨损
				if wear_noise > 0.92:
					var scratch_intensity = (wear_noise - 0.92) * 5 # 划痕强度
					current_color = current_color.darkened(scratch_intensity * 0.4)
				
				# 边缘随机磨损
				var edge_distance = min(
					min(x, width - 1 - x),
					min(y, height - 1 - y)
				)
				if edge_distance < 10 and wear_noise > 0.6:
					var edge_wear = (1.0 - edge_distance / 10.0) * 0.8
					current_color.a = max(current_color.a - edge_wear * wear_noise, 0)
				
				# 轻微的颜色变化，使边框看起来更自然
				current_color.r += (noise.get_noise_2d(x * 0.2, y * 0.5) * 0.5 + 0.5) * 0.02 - 0.01
				current_color.g += (noise.get_noise_2d(x * 0.3, y * 0.4) * 0.5 + 0.5) * 0.02 - 0.01
				current_color.b += (noise.get_noise_2d(x * 0.4, y * 0.3) * 0.5 + 0.5) * 0.02 - 0.01
				
				image.set_pixel(x, y, current_color)

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
