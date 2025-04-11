shader_type canvas_item;

// 火焰粒子效果着色器 - 用于篝火和火焰特效
// 参数定义
uniform vec4 color_low : source_color = vec4(1.0, 0.7, 0.0, 1.0);  // 火焰底部颜色
uniform vec4 color_high : source_color = vec4(1.0, 0.2, 0.0, 1.0); // 火焰顶部颜色
uniform float speed : hint_range(0.1, 10.0) = 3.0;  // 火焰上升速度
uniform float noise_scale : hint_range(0.5, 10.0) = 2.0;  // 噪声纹理比例
uniform float distortion : hint_range(0.0, 1.0) = 0.3;  // 火焰扭曲程度
uniform sampler2D noise_texture;  // 噪声纹理

// 噪声函数
float noise(vec2 uv) {
    return texture(noise_texture, uv).r;
}

void fragment() {
    // 获取原始颜色
    vec4 original_color = texture(TEXTURE, UV);
    
    // 使用时间让火焰上升
    vec2 moving_uv = vec2(UV.x, UV.y + TIME * speed * 0.1);
    
    // 第一层噪声，基础火焰形状
    float noise1 = noise(moving_uv * noise_scale);
    
    // 第二层噪声，添加扭曲效果
    float noise2 = noise(moving_uv * noise_scale * 2.0 + vec2(0.0, TIME * speed * 0.05));
    
    // 扭曲基础UV
    vec2 distorted_uv = UV;
    distorted_uv.x += (noise2 - 0.5) * distortion * (1.0 - UV.y);  // 底部扭曲更强
    
    // 重新采样噪声
    float final_noise = noise(distorted_uv * noise_scale + vec2(0.0, TIME * speed * 0.1));
    
    // 创建火焰高度蒙版 (底部更强)
    float height_mask = 1.0 - UV.y;
    
    // 火焰形状，底部实心，顶部飘散
    float fire_shape = smoothstep(0.1, 0.6, final_noise + height_mask * 0.5 - 0.3);
    
    // 根据高度混合颜色
    vec4 fire_color = mix(color_high, color_low, height_mask);
    
    // 设置透明度
    fire_color.a = fire_shape * original_color.a;
    
    // 添加内部亮度变化
    float brightness = noise(moving_uv * 1.5 + vec2(TIME * 0.2, 0.0));
    fire_color.rgb = mix(fire_color.rgb, fire_color.rgb * 1.5, brightness * height_mask);
    
    // 输出最终颜色
    COLOR = fire_color;
} 