@tool
extends EditorScript

# 生成并保存灰尘纹理工具脚本
# 用法：在Godot编辑器中选择此脚本，然后点击"运行"按钮

func _run():
	print("开始生成灰尘纹理...")
	var texture = generate_dust_texture()
	save_texture(texture, "res://assets/textures/noise/noise_dust.png")
	print("灰尘纹理已生成并保存到 res://assets/textures/noise/noise_dust.png")

# 创建灰尘纹理
func generate_dust_texture():
	# 优化的灰尘纹理生成方法
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.fractal_octaves = 4
	noise.frequency = 0.01  # 降低频率以获得更大的噪点
	
	var image = Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	
	# 使用批处理处理像素，每16x16像素块为一组
	for x_block in range(0, 1024, 16):
		for y_block in range(0, 1024, 16):
			# 为每个块生成随机值
			var block_noise = noise.get_noise_2d(x_block, y_block) * 0.5 + 0.5
			var dust_density = clamp(block_noise * 1.2, 0, 1)  # 控制每个块内灰尘的密度
			
			# 为每个块内的像素设置值
			for x_offset in range(16):
				var x = x_block + x_offset
				if x >= 1024:
					continue
					
				for y_offset in range(16):
					var y = y_block + y_offset
					if y >= 1024:
						continue
					
					# 为块内每个像素添加细节噪点
					var detail_noise = noise.get_noise_2d(x * 0.2, y * 0.2) * 0.5 + 0.5
					
					# 只有当噪点值高于阈值时才显示灰尘
					var threshold = 0.85 - dust_density * 0.15  # 块密度会影响阈值
					var dust_visible = detail_noise > threshold
					
					if dust_visible:
						# 随机设置灰尘的强度和大小
						var intensity = randf_range(0.5, 1.0)
						
						# 添加光晕效果，使灰尘看起来更自然
						var distance_from_center = sqrt(pow(x_offset - 8, 2) + pow(y_offset - 8, 2)) / 11.0
						var alpha = clamp(1.0 - distance_from_center, 0.0, 1.0)
						
						if alpha > 0.1:  # 忽略太小的alpha值
							image.set_pixel(x, y, Color(intensity, intensity, intensity, alpha))
					else:
						image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	# 对图像应用轻微模糊，使灰尘看起来更自然
	image.resize(512, 512, Image.INTERPOLATE_BILINEAR)  # 缩小
	image.resize(1024, 1024, Image.INTERPOLATE_BILINEAR)  # 放大，产生模糊效果
	
	var texture = ImageTexture.create_from_image(image)
	return texture

# 保存纹理到文件
func save_texture(texture: ImageTexture, path: String):
	var image = texture.get_image()
	# 确保目录存在
	var dir = path.get_base_dir()
	var dir_access = DirAccess.open("res://")
	if not dir_access.dir_exists(dir.trim_prefix("res://")):
		dir_access.make_dir_recursive(dir.trim_prefix("res://"))
		
	var err = image.save_png(path)
	if err != OK:
		push_error("无法保存纹理到 " + path + "，错误码：" + str(err))
		return false
	return true 