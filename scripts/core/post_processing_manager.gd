@tool
class_name	PostProcessingManager	extends	Node

#	全局后处理效果管理器	-	管理游戏的整体视觉效果
#	用于黑暗之魂风格的卡牌游戏《无火的牌局》

signal	effect_toggled(effect_name:	String,	enabled:	bool)

#	后处理效果类型枚举
enum	EffectType	{
				VIGNETTE,						#	暗角效果
				FILM_GRAIN,				#	胶片颗粒
				TONE_MAPPING,		#	色调映射
				COLOR_SHIFT,			#	色彩偏移
				DUST											#	灰尘颗粒
}

#	全局后处理着色器
const POST_PROCESSING_SHADER_PATH	=	"res://assets/shaders/post_processing.gdshader"

#	噪点纹理路径
const	NOISE_DUST_PATH	=	"res://assets/textures/noise/noise_dust.png"

#	默认参数值
const	DEFAULT_VIGNETTE_INTENSITY	=	0.4
const	DEFAULT_VIGNETTE_OPACITY	=	0.5
const	DEFAULT_DUST_AMOUNT	=	0.2
const	DEFAULT_GRAIN_AMOUNT	=	0.05
const	DEFAULT_COLOR_DEPTH	=	32.0

#	场景类型枚举
enum	SceneType	{
				MENU,					#	主菜单
				MAP,						#	地图
				BATTLE,			#	战斗
				SHOP,					#	商店
				REST						#	休息点
}

#	后处理效果状态
var	_effects_state:	Dictionary	=	{
				EffectType.VIGNETTE:	true,
				EffectType.FILM_GRAIN:	true,
				EffectType.TONE_MAPPING:	true,
				EffectType.COLOR_SHIFT:	true,
				EffectType.DUST:	true
}

#	后处理材质
var	_post_material:	ShaderMaterial	=	null

#	当前场景类型
var	_current_scene_type:	SceneType	=	SceneType.MENU

#	后处理覆盖层
var	_post_canvas:	CanvasLayer	=	null
var	_post_rect:	ColorRect	=	null

#	灰尘噪点纹理
var	_dust_texture:	Texture2D	=	null

#	后处理效果的控制参数
@export_range(0.0,	1.0)	var	vignette_intensity:	float	=	0.4
@export_range(0.0,	1.0)	var	vignette_opacity:	float	=	0.5
var	vignette_rgb:	Color	=	Color(0.1,	0.05,	0.05)
@export_range(0.0,	1.0)	var	dust_amount:	float	=	0.2
@export	var	dust_texture:	Texture2D
@export_range(0.0,	1.0)	var	grain_amount:	float	=	0.1
@export	var	enable_color_shift:	bool	=	true
@export_range(1,	32)	var	color_depth:	int	=	16

#	初始化后处理效果
func	_ready():
	#	创建CanvasLayer并设置层级
	_post_canvas	=	CanvasLayer.new()
	_post_canvas.layer	=	100
	add_child(_post_canvas)
	
	#	创建后处理使用的材质
	_post_material	=	_create_post_material()
	
	#	创建用于显示着色器的矩形
	_post_rect	=	_create_post_rect()
	_post_canvas.add_child(_post_rect)
	
	#	加载灰尘纹理
	if	ResourceLoader.exists(NOISE_DUST_PATH):
		_dust_texture	=	load(NOISE_DUST_PATH)
	else:
		#	如果灰尘纹理不存在，则生成一个
		print("没有找到灰尘纹理，正在生成...")
		_dust_texture	=	generate_dust_texture()
		#	保存到文件以便后续使用
		var	dir_access	=	DirAccess.open("res://")
		var	dir_path	=	NOISE_DUST_PATH.get_base_dir().trim_prefix("res://")
		if	not	dir_access.dir_exists(dir_path):
			dir_access.make_dir_recursive(dir_path)
		var	image	=	_dust_texture.get_image()
		var	err	=	image.save_png(NOISE_DUST_PATH)
		if	err	!=	OK:
			push_error("无法保存灰尘纹理到	"	+	NOISE_DUST_PATH	+	"，错误码："	+	str(err))
	
	#	初始化默认参数
	if	_dust_texture	!=	null:
		_post_material.set_shader_parameter("dust_texture",	_dust_texture)
	
	#	应用默认参数
	_update_post_process_effects()
	
	#	默认启用后处理
	set_enabled(true)

#	创建后处理材质
func	_create_post_material():
	if ResourceLoader.exists(POST_PROCESSING_SHADER_PATH):
		#	创建材质
		var material = ShaderMaterial.new()
		material.shader = load(POST_PROCESSING_SHADER_PATH)
		
		#	设置基础参数
		material.set_shader_parameter("vignette_intensity", DEFAULT_VIGNETTE_INTENSITY)
		material.set_shader_parameter("vignette_opacity", DEFAULT_VIGNETTE_OPACITY)
		material.set_shader_parameter("vignette_rgb", Color(0.1, 0.1, 0.1, 1.0))
		material.set_shader_parameter("dust_amount", DEFAULT_DUST_AMOUNT)
		
		if _dust_texture != null:
			material.set_shader_parameter("dust_texture", _dust_texture)
			
		material.set_shader_parameter("grain_amount", DEFAULT_GRAIN_AMOUNT)
		material.set_shader_parameter("enable_color_shift", true)
		material.set_shader_parameter("color_depth", DEFAULT_COLOR_DEPTH)
		
		return material
	
	return null

#	创建后处理覆盖层
func	_create_post_overlay():
				#	创建Canvas层
				_post_canvas	=	CanvasLayer.new()
				_post_canvas.layer	=	100		#	确保在最顶层
				add_child(_post_canvas)
				
				#	创建覆盖整个屏幕的ColorRect
				_post_rect	=	ColorRect.new()
				_post_rect.material	=	_post_material
				_post_rect.mouse_filter	=	Control.MOUSE_FILTER_IGNORE		#	不拦截鼠标事件
				_post_canvas.add_child(_post_rect)
				
				#	确保ColorRect覆盖整个视口
				get_tree().get_root().connect("size_changed",	_update_rect_size)
				_update_rect_size()

#	更新覆盖层大小
func	_update_rect_size():
				if	_post_rect	!=	null:
								var	viewport_size	=	get_viewport().get_visible_rect().size
								_post_rect.size	=	viewport_size
								_post_rect.position	=	Vector2.ZERO

#	设置效果状态
func	set_effect_enabled(effect:	EffectType,	enabled:	bool):
				if	_post_material	==	null:
								return
				
				_effects_state[effect]	=	enabled
				
				match	effect:
								EffectType.VIGNETTE:
												_post_material.set_shader_parameter("vignette_opacity",	DEFAULT_VIGNETTE_OPACITY	if	enabled	else	0.0)
								EffectType.FILM_GRAIN:
												_post_material.set_shader_parameter("grain_amount",	DEFAULT_GRAIN_AMOUNT	if	enabled	else	0.0)
								EffectType.TONE_MAPPING:
												#	特殊处理，需要在调整色调时在片段着色器中处理
												pass
								EffectType.COLOR_SHIFT:
												_post_material.set_shader_parameter("enable_color_shift",	enabled)
								EffectType.DUST:
												_post_material.set_shader_parameter("dust_amount",	DEFAULT_DUST_AMOUNT	if	enabled	else	0.0)
				
				emit_signal("effect_toggled",	EffectType.keys()[effect].to_lower(),	enabled)

#	是否启用效果
func	is_effect_enabled(effect:	EffectType)	->	bool:
				return	_effects_state.get(effect,	false)

#	设置场景类型，自动调整后处理效果
func	set_scene_type(scene_type:	SceneType):
				_current_scene_type	=	scene_type
				
				#	根据场景类型应用不同的效果设置
				match	scene_type:
								SceneType.MENU:
												#	主菜单：强调氛围，较重的效果
												_post_material.set_shader_parameter("vignette_intensity",	0.5)
												_post_material.set_shader_parameter("vignette_opacity",	0.6)
												_post_material.set_shader_parameter("dust_amount",	0.25)
												_post_material.set_shader_parameter("grain_amount",	0.07)
												_post_material.set_shader_parameter("vignette_rgb",	Color(0.08,	0.08,	0.1,	1.0))
												
								SceneType.MAP:
												#	地图：略微减轻效果，提高可读性
												_post_material.set_shader_parameter("vignette_intensity",	0.4)
												_post_material.set_shader_parameter("vignette_opacity",	0.5)
												_post_material.set_shader_parameter("dust_amount",	0.15)
												_post_material.set_shader_parameter("grain_amount",	0.04)
												_post_material.set_shader_parameter("vignette_rgb",	Color(0.1,	0.1,	0.12,	1.0))
												
								SceneType.BATTLE:
												#
												#	战斗：适中效果，保持紧张感
												_post_material.set_shader_parameter("vignette_intensity",	0.45)
												_post_material.set_shader_parameter("vignette_opacity",	0.55)
												_post_material.set_shader_parameter("dust_amount",	0.2)
												_post_material.set_shader_parameter("grain_amount",	0.05)
												_post_material.set_shader_parameter("vignette_rgb",	Color(0.12,	0.1,	0.1,	1.0))
												
								SceneType.SHOP:
												#	商店：较轻效果，更为明亮
												_post_material.set_shader_parameter("vignette_intensity",	0.35)
												_post_material.set_shader_parameter("vignette_opacity",	0.45)
												_post_material.set_shader_parameter("dust_amount",	0.15)
												_post_material.set_shader_parameter("grain_amount",	0.04)
												_post_material.set_shader_parameter("vignette_rgb",	Color(0.14,	0.12,	0.1,	1.0))
												
								SceneType.REST:
												#	休息点：温暖的效果，舒适感
												_post_material.set_shader_parameter("vignette_intensity",	0.4)
												_post_material.set_shader_parameter("vignette_opacity",	0.5)
												_post_material.set_shader_parameter("dust_amount",	0.18)
												_post_material.set_shader_parameter("grain_amount",	0.04)
												_post_material.set_shader_parameter("vignette_rgb",	Color(0.14,	0.1,	0.08,	1.0))
				
				#	应用状态
				for	effect	in	_effects_state.keys():
								set_effect_enabled(effect,	_effects_state[effect])

#	获取当前场景类型
func	get_current_scene_type()	->	SceneType:
				return	_current_scene_type

#	销毁后处理效果
func	_exit_tree():
				if	_post_canvas	!=	null:
								_post_canvas.queue_free()
								_post_canvas	=	null	

#	更新着色器参数
func	_update_shader_parameters():
				if	_post_material:
								_post_material.set_shader_parameter("vignette_intensity",	vignette_intensity)
								_post_material.set_shader_parameter("vignette_opacity",	vignette_opacity)		
								_post_material.set_shader_parameter("vignette_rgb",	vignette_rgb)
								_post_material.set_shader_parameter("dust_amount",	dust_amount)
								_post_material.set_shader_parameter("dust_texture",	dust_texture)
								_post_material.set_shader_parameter("grain_amount",	grain_amount)
								_post_material.set_shader_parameter("enable_color_shift",	enable_color_shift)
								_post_material.set_shader_parameter("color_depth",	color_depth)

#	设置暗角效果强度
func	set_vignette_intensity(value:	float):
				vignette_intensity	=	value
				_post_material.set_shader_parameter("vignette_intensity",	vignette_intensity)

#	设置暗角效果不透明度
func	set_vignette_opacity(value:	float):
				vignette_opacity	=	value
				_post_material.set_shader_parameter("vignette_opacity",	vignette_opacity)

#	设置暗角效果颜色
func	set_vignette_color(color:	Color):
				vignette_rgb	=	color
				_post_material.set_shader_parameter("vignette_rgb",	vignette_rgb)

#	设置灰尘效果强度
func	set_dust_amount(value:	float):
				dust_amount	=	value
				_post_material.set_shader_parameter("dust_amount",	dust_amount)

#	设置胶片颗粒效果强度
func	set_grain_amount(value:	float):
				grain_amount	=	value
				_post_material.set_shader_parameter("grain_amount",	grain_amount)

#	启用或禁用颜色偏移效果
func	set_color_shift_enabled(enabled:	bool):
				enable_color_shift	=	enabled
				_post_material.set_shader_parameter("enable_color_shift",	enable_color_shift)

#	设置颜色深度（用于颜色量化）
func	set_color_depth(value:	int):
				color_depth	=	value
				_post_material.set_shader_parameter("color_depth",	color_depth)

#	创建灰尘纹理（如果没有提供）
func	generate_dust_texture():
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
	dust_texture = texture
	if _post_material:
		_post_material.set_shader_parameter("dust_texture", dust_texture)
	return texture

#	启用/禁用后处理效果
func	set_enabled(enabled:	bool):
				if	_post_rect:
								_post_rect.visible	=	enabled	

#	创建用于显示着色器的矩形
func	_create_post_rect():
	var	rect	=	ColorRect.new()
	rect.material	=	_post_material
	rect.mouse_filter	=	Control.MOUSE_FILTER_IGNORE		#	不拦截鼠标事件
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)		#	铺满整个父节点
	
	#	确保ColorRect覆盖整个视口
	get_viewport().connect("size_changed",	_on_viewport_size_changed.bind(rect))
	update_rect_size(rect)
	
	return	rect

#	视口大小改变时更新矩形大小
func	_on_viewport_size_changed(rect):
	update_rect_size(rect)

#	更新矩形大小以匹配视口
func	update_rect_size(rect):
	if	rect	!=	null:
		var	viewport_size	=	get_viewport().get_visible_rect().size
		rect.size	=	viewport_size
		rect.position	=	Vector2.ZERO	

#	更新后处理效果参数
func	_update_post_process_effects():
	if	_post_material	==	null:
		return
		
	#	更新着色器参数
	_post_material.set_shader_parameter("vignette_intensity",	vignette_intensity)
	_post_material.set_shader_parameter("vignette_opacity",	vignette_opacity)
	_post_material.set_shader_parameter("vignette_rgb",	vignette_rgb)
	_post_material.set_shader_parameter("dust_amount",	dust_amount)
	_post_material.set_shader_parameter("grain_amount",	grain_amount)
	_post_material.set_shader_parameter("enable_color_shift",	enable_color_shift)
	_post_material.set_shader_parameter("color_depth",	color_depth)
	
	#	设置初始场景类型
	set_scene_type(SceneType.MENU)	
