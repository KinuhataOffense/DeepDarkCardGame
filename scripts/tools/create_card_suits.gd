#!/usr/bin/env -S godot --headless --script
extends SceneTree

# 命令行工具脚本，用于生成哥特式花色符号
# 使用方法: godot --headless --script scripts/tools/create_card_suits.gd

func _init():
	print("开始生成哥特式花色符号...")
	
	# 创建各个花色
	var suits = ["spades", "hearts", "diamonds", "clubs"]
	var resolutions = [256, 256] # 花色图标的分辨率
	
	for suit in suits:
		var texture = generate_card_suit(suit, resolutions[0], resolutions[1])
		var save_path = "res://assets/textures/card/suit_" + suit + ".png"
		save_texture(texture, save_path)
		print("已生成并保存 " + suit + " 花色到 " + save_path)
	
	print("所有花色符号生成完成!")
	quit()

# 生成指定花色的纹理
func generate_card_suit(suit: String, width: int, height: int) -> ImageTexture:
	var image = Image.create(width, height, true, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0)) # 透明背景
	
	var center_x = width / 2
	var center_y = height / 2
	var size = min(width, height) * 0.8 # 花色大小为图像尺寸的80%
	
	# 噪声生成器用于添加纹理效果
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.fractal_octaves = 4
	noise.frequency = 0.1
	
	# 花色颜色定义
	var colors = {
		"spades": Color(0.15, 0.15, 0.2, 1.0), # 黑桃 - 深蓝黑色
		"hearts": Color(0.5, 0.15, 0.15, 1.0), # 红心 - 深红色
		"diamonds": Color(0.5, 0.2, 0.1, 1.0), # 方块 - 深橙红色
		"clubs": Color(0.12, 0.15, 0.12, 1.0)  # 梅花 - 深绿黑色
	}
	
	# 高光颜色
	var highlight_colors = {
		"spades": Color(0.3, 0.3, 0.4, 1.0),
		"hearts": Color(0.7, 0.3, 0.3, 1.0),
		"diamonds": Color(0.7, 0.4, 0.2, 1.0),
		"clubs": Color(0.25, 0.3, 0.25, 1.0)
	}
	
	# 绘制对应的花色
	match suit:
		"spades":
			draw_gothic_spade(image, center_x, center_y, size, colors[suit], highlight_colors[suit], noise)
		"hearts":
			draw_gothic_heart(image, center_x, center_y, size, colors[suit], highlight_colors[suit], noise)
		"diamonds":
			draw_gothic_diamond(image, center_x, center_y, size, colors[suit], highlight_colors[suit], noise)
		"clubs":
			draw_gothic_club(image, center_x, center_y, size, colors[suit], highlight_colors[suit], noise)
	
	# 添加花色的装饰效果和纹理
	add_gothic_decorations(image, suit, noise)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

# 绘制哥特式黑桃
func draw_gothic_spade(image: Image, center_x: int, center_y: int, size: float, color: Color, highlight_color: Color, noise: FastNoiseLite):
	var spade_width = size * 0.7
	var spade_height = size * 0.8
	var handle_width = size * 0.15
	var handle_height = size * 0.4
	
	# 遍历每个像素，检查是否在黑桃形状内
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var dx = float(x - center_x) / (spade_width / 2.0)
			var dy = float(y - center_y) / (spade_height / 2.0)
			var dy_adjusted = dy + 0.5 # 上移黑桃尖端
			
			# 黑桃的顶部是倒置的心形
			var top_shape = 0.0
			
			# 尖锐的哥特式黑桃顶部
			if dy_adjusted < 0: 
				# 计算心形方程，但更尖锐
				var heart_x = abs(dx) * 1.2
				var heart_y = -dy_adjusted * 1.2
				top_shape = pow(heart_x, 2) + pow(heart_y - sqrt(abs(heart_x)), 2) - 1
			
			# 黑桃的柄部
			var handle_shape = 0.0
			if dy_adjusted >= 0:
				var handle_dx = abs(x - center_x) / (handle_width / 2.0)
				var handle_dy = (y - (center_y - spade_height * 0.25)) / handle_height
				handle_shape = max(handle_dx - 1.0, handle_dy - 1.0)
			
			# 判断点是否在黑桃形状内
			var in_shape = (dy_adjusted < 0 and top_shape <= 0) or (dy_adjusted >= 0 and handle_shape <= 0)
			
			if in_shape:
				# 添加纹理和阴影效果
				var noise_val = noise.get_noise_2d(x * 0.1, y * 0.1) * 0.5 + 0.5
				var edge_distance = min(1.0, min(abs(top_shape), abs(handle_shape)) * 20.0)
				var edge_factor = pow(edge_distance, 0.5) * 0.6
				
				# 混合颜色
				var pixel_color = color.lerp(highlight_color, edge_factor * noise_val)
				
				# 增加细微的纹理变化
				pixel_color.r += (noise_val - 0.5) * 0.05
				pixel_color.g += (noise_val - 0.5) * 0.05
				pixel_color.b += (noise_val - 0.5) * 0.05
				
				image.set_pixel(x, y, pixel_color)

# 绘制哥特式红心
func draw_gothic_heart(image: Image, center_x: int, center_y: int, size: float, color: Color, highlight_color: Color, noise: FastNoiseLite):
	var heart_width = size * 0.8
	var heart_height = size * 0.7
	
	# 遍历每个像素，检查是否在心形内
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var dx = float(x - center_x) / (heart_width / 2.0)
			var dy = float(y - center_y) / (heart_height / 2.0)
			var dy_adjusted = dy - 0.2 # 下移心形
			
			# 哥特式风格的心形，更尖锐、更有棱角
			var heart_shape = 0.0
			
			# 计算一个更尖锐的心形方程
			var heart_x = abs(dx) * 1.05
			var heart_y = dy_adjusted * 1.1
			heart_shape = pow(heart_x, 2) + pow(heart_y - 0.7 * sqrt(abs(heart_x)), 2) - 1
			
			# 判断点是否在心形内
			var in_shape = heart_shape <= 0
			
			if in_shape:
				# 添加纹理和阴影效果
				var noise_val = noise.get_noise_2d(x * 0.1, y * 0.1) * 0.5 + 0.5
				var edge_distance = min(1.0, abs(heart_shape) * 15.0)
				var edge_factor = pow(edge_distance, 0.5) * 0.7
				
				# 混合颜色
				var pixel_color = color.lerp(highlight_color, edge_factor * noise_val)
				
				# 增加细微的纹理变化
				pixel_color.r += (noise_val - 0.5) * 0.1
				pixel_color.g += (noise_val - 0.5) * 0.05
				pixel_color.b += (noise_val - 0.5) * 0.05
				
				image.set_pixel(x, y, pixel_color)

# 绘制哥特式方块
func draw_gothic_diamond(image: Image, center_x: int, center_y: int, size: float, color: Color, highlight_color: Color, noise: FastNoiseLite):
	var diamond_width = size * 0.65
	var diamond_height = size * 0.9
	
	# 遍历每个像素，检查是否在方块形状内
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var dx = float(x - center_x) / (diamond_width / 2.0)
			var dy = float(y - center_y) / (diamond_height / 2.0)
			
			# 哥特式风格的方块，使菱形更加尖锐
			var diamond_value = abs(dx) + abs(dy)
			
			# 判断点是否在方块内
			var in_shape = diamond_value <= 1.0
			
			if in_shape:
				# 添加纹理和阴影效果
				var noise_val = noise.get_noise_2d(x * 0.1, y * 0.1) * 0.5 + 0.5
				var edge_distance = min(1.0, (1.0 - diamond_value) * 5.0)
				var edge_factor = pow(edge_distance, 0.4) * 0.8
				
				# 创建辐射状的明暗变化
				var radial_factor = 1.0 - abs(dx * dy) * 1.5
				radial_factor = clamp(radial_factor, 0.0, 1.0)
				
				# 混合颜色
				var pixel_color = color.lerp(highlight_color, edge_factor * noise_val * radial_factor)
				
				# 增加细微的纹理变化
				pixel_color.r += (noise_val - 0.5) * 0.1
				pixel_color.g += (noise_val - 0.5) * 0.05
				pixel_color.b += (noise_val - 0.5) * 0.05
				
				image.set_pixel(x, y, pixel_color)

# 绘制哥特式梅花
func draw_gothic_club(image: Image, center_x: int, center_y: int, size: float, color: Color, highlight_color: Color, noise: FastNoiseLite):
	var leaf_radius = size * 0.25
	var stem_width = size * 0.15
	var stem_height = size * 0.35
	
	# 确定三个叶子的中心位置
	var centers = [
		Vector2(center_x, center_y - leaf_radius * 1.2), # 顶部叶子
		Vector2(center_x - leaf_radius * 1.2, center_y + leaf_radius * 0.2), # 左侧叶子
		Vector2(center_x + leaf_radius * 1.2, center_y + leaf_radius * 0.2)  # 右侧叶子
	]
	
	# 遍历每个像素
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			# 检查是否在任一叶子内部
			var in_leaf = false
			for center_pos in centers:
				var dist_squared = pow(x - center_pos.x, 2) + pow(y - center_pos.y, 2)
				if dist_squared <= pow(leaf_radius, 2):
					in_leaf = true
					break
			
			# 检查是否在梅花柄部
			var stem_dx = abs(x - center_x) / (stem_width / 2.0)
			var stem_dy = (y - (center_y + leaf_radius * 0.2)) / stem_height
			var in_stem = stem_dx <= 1.0 and stem_dy >= 0.0 and stem_dy <= 1.0
			
			# 判断点是否在梅花形状内
			var in_shape = in_leaf or in_stem
			
			if in_shape:
				# 添加纹理和阴影效果
				var noise_val = noise.get_noise_2d(x * 0.1, y * 0.1) * 0.5 + 0.5
				
				# 计算到形状边缘的距离
				var edge_distance = 1.0
				if in_leaf:
					for center_pos in centers:
						var dist = sqrt(pow(x - center_pos.x, 2) + pow(y - center_pos.y, 2))
						var leaf_edge_dist = 1.0 - dist / leaf_radius
						edge_distance = min(edge_distance, leaf_edge_dist)
				else: # in_stem
					edge_distance = min(1.0 - stem_dx, min(stem_dy, 1.0 - stem_dy))
				
				var edge_factor = pow(clamp(edge_distance * 3.0, 0.0, 1.0), 0.5) * 0.7
				
				# 混合颜色
				var pixel_color = color.lerp(highlight_color, edge_factor * noise_val)
				
				# 增加细微的纹理变化
				pixel_color.r += (noise_val - 0.5) * 0.05
				pixel_color.g += (noise_val - 0.5) * 0.05
				pixel_color.b += (noise_val - 0.5) * 0.05
				
				image.set_pixel(x, y, pixel_color)

# 添加哥特式装饰
func add_gothic_decorations(image: Image, suit: String, noise: FastNoiseLite):
	# 获取图像尺寸
	var width = image.get_width()
	var height = image.get_height()
	
	# 为花色添加装饰性的刻痕、划痕和细节
	for y in range(height):
		for x in range(width):
			var current_color = image.get_pixel(x, y)
			
			# 只处理花色内部的像素（非透明像素）
			if current_color.a > 0:
				# 添加随机划痕和刻痕
				var scratch_noise = noise.get_noise_2d(x * 2, y * 2) * 0.5 + 0.5
				if scratch_noise > 0.9:
					var scratch_intensity = (scratch_noise - 0.9) * 10
					current_color = current_color.darkened(scratch_intensity * 0.3)
				
				# 添加细小的随机光点，模拟灰尘或光反射
				var highlight_noise = noise.get_noise_2d(x * 5, y * 5) * 0.5 + 0.5
				if highlight_noise > 0.95:
					var highlight_intensity = (highlight_noise - 0.95) * 20
					current_color = current_color.lightened(highlight_intensity * 0.5)
				
				# 根据不同花色添加不同的装饰元素
				match suit:
					"spades":
						# 黑桃添加一些垂直的流线纹理
						var streak_noise = noise.get_noise_2d(x * 0.5, y * 0.1) * 0.5 + 0.5
						if streak_noise > 0.7:
							current_color = current_color.darkened((streak_noise - 0.7) * 0.3)
					"hearts":
						# 红心添加一些辐射状的装饰线条
						var radial_noise = noise.get_noise_2d(x * 0.2, y * 0.2) * 0.5 + 0.5
						if radial_noise > 0.8:
							current_color = current_color.lightened((radial_noise - 0.8) * 0.4)
					"diamonds":
						# 方块添加十字形状的细节
						var cross_x = abs(x - width/2) / float(width/2)
						var cross_y = abs(y - height/2) / float(height/2)
						if min(cross_x, cross_y) < 0.05:
							current_color = current_color.lightened(0.1 * (1.0 - min(cross_x, cross_y) / 0.05))
					"clubs":
						# 梅花添加螺旋状的装饰
						var angle = atan2(y - height/2, x - width/2)
						var spiral = (sqrt(pow(x - width/2, 2) + pow(y - height/2, 2)) * 0.05 + angle * 5.0) % (PI * 2)
						if abs(sin(spiral)) > 0.95:
							current_color = current_color.darkened(0.1)
				
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