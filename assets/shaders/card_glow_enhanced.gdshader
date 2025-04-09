shader_type canvas_item;

// 卡牌发光效果增强版 - 适用于《无火的牌局》的奇幻效果

// 参数设置
uniform vec4 glow_color : source_color = vec4(1.0, 0.7, 0.3, 1.0); // 发光颜色
uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0; // 发光强度
uniform float glow_size : hint_range(0.0, 0.5) = 0.15; // 发光尺寸
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.0; // 脉冲速度
uniform float distortion_amount : hint_range(0.0, 0.1) = 0.02; // 扭曲强度
uniform sampler2D distortion_noise : filter_linear_mipmap, repeat_enable; // 扭曲噪声纹理
uniform float inner_intensity : hint_range(0.0, 2.0) = 0.3; // 内部光晕强度
uniform bool enable_aura = true; // 启用光环效果
uniform vec4 secondary_color : source_color = vec4(0.3, 0.5, 1.0, 1.0); // 次要颜色，用于颜色混合
uniform float color_mix_rate : hint_range(0.0, 1.0) = 0.2; // 颜色混合速率
uniform bool enable_sparkles = true; // 启用闪光粒子
uniform float sparkle_amount : hint_range(0.0, 1.0) = 0.3; // 闪光数量
uniform float sparkle_speed : hint_range(0.0, 5.0) = 2.0; // 闪光速度

// 随机函数
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// 杂乱噪声函数
float noise(vec2 p) {
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);
    
    float res = mix(
        mix(rand(ip), rand(ip+vec2(1.0, 0.0)), u.x),
        mix(rand(ip+vec2(0.0, 1.0)), rand(ip+vec2(1.0, 1.0)), u.x), u.y);
    return res*res;
}

// 闪光效果生成
float generate_sparkle(vec2 uv, float time, float amount, float speed) {
    // 为每个闪光生成随机位置和时机
    float sparkle = 0.0;
    for(int i = 0; i < 10; i++) {
        // 随机位置
        vec2 pos = vec2(
            rand(vec2(float(i), 1.0)),
            rand(vec2(float(i), 2.0))
        );
        
        // 随机时间偏移
        float time_offset = rand(vec2(float(i), 3.0)) * 6.28;
        
        // 计算闪光强度（随时间变化）
        float sparkle_time = sin(time * speed + time_offset) * 0.5 + 0.5;
        sparkle_time = pow(sparkle_time, 4.0); // 使闪烁更加尖锐
        
        // 计算到中心的距离
        float dist = distance(uv, pos);
        
        // 随距离和时间添加闪光
        sparkle += smoothstep(0.02 * amount, 0.0, dist) * sparkle_time;
    }
    
    return min(sparkle, 1.0); // 限制最大值为1
}

void fragment() {
    // 获取原始纹理
    vec4 original_color = texture(TEXTURE, UV);
    
    // 时间变量，用于动画效果
    float time = TIME;
    
    // 扭曲效果 - 使用噪声纹理
    vec2 distorted_uv = UV;
    if (distortion_amount > 0.0) {
        // 获取噪声纹理并创建扭曲向量
        vec2 noise_uv = UV + vec2(time * 0.1, time * -0.1) * 0.2;
        vec4 noise_texture = texture(distortion_noise, noise_uv);
        
        // 应用扭曲
        distorted_uv += (noise_texture.rg - 0.5) * distortion_amount;
    }
    
    // 重新获取扭曲后的颜色
    vec4 color = texture(TEXTURE, distorted_uv);
    
    // 计算到边缘的距离，用于边缘发光
    float distance_to_edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
    
    // 脉冲效果 - 随时间变化的发光强度
    float pulse = sin(time * pulse_speed) * 0.5 + 1.0;
    
    // 边缘发光计算
    float edge_glow = smoothstep(glow_size, 0.0, distance_to_edge) * glow_intensity * pulse;
    
    // 创建光环效果 - 在卡牌周围形成柔和的光环
    float aura = 0.0;
    if (enable_aura) {
        // 在较大范围内创建柔和的光环
        aura = smoothstep(glow_size * 2.0, glow_size * 0.5, distance_to_edge) * 0.5 * glow_intensity;
    }
    
    // 内部光晕 - 在卡牌内部创建光晕效果
    float inner_glow = smoothstep(0.4, 0.0, length(UV - vec2(0.5))) * inner_intensity;
    
    // 颜色混合效果 - 在主要和次要颜色之间平滑过渡
    vec4 current_glow_color = glow_color;
    if (color_mix_rate > 0.0) {
        float mix_factor = sin(time * color_mix_rate) * 0.5 + 0.5;
        current_glow_color = mix(glow_color, secondary_color, mix_factor);
    }
    
    // 添加闪光粒子效果
    float sparkle = 0.0;
    if (enable_sparkles) {
        sparkle = generate_sparkle(UV, time, sparkle_amount, sparkle_speed);
    }
    
    // 合并所有光效并应用到原始颜色
    vec3 glow = current_glow_color.rgb * (edge_glow + aura + inner_glow + sparkle * 2.0);
    
    // 最终颜色为原始颜色加上发光效果
    color.rgb += glow;
    
    // 确保透明度正确
    color.a = original_color.a;
    
    // 输出最终颜色
    COLOR = color;
} 