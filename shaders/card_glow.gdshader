shader_type canvas_item;

// 基础参数
uniform sampler2D card_texture : source_color; // 卡牌基础纹理
uniform vec4 glow_color : source_color = vec4(0.4, 0.7, 1.0, 1.0); // 发光颜色，默认蓝色
uniform vec4 inner_glow_color : source_color = vec4(0.2, 0.5, 1.0, 1.0); // 内发光颜色
uniform float glow_intensity : hint_range(0.0, 3.0) = 1.5; // 发光强度
uniform float inner_glow_power : hint_range(0.0, 5.0) = 2.0; // 内发光强度
uniform float outer_glow_power : hint_range(0.0, 5.0) = 1.0; // 外发光强度
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.0; // 脉冲速度
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.2; // 脉冲强度
uniform bool use_fire_effect = false; // 是否使用火焰效果
uniform vec4 fire_color_1 : source_color = vec4(1.0, 0.6, 0.0, 1.0); // 火焰颜色1
uniform vec4 fire_color_2 : source_color = vec4(1.0, 0.2, 0.0, 1.0); // 火焰颜色2
uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable; // 噪声纹理
uniform float fire_speed : hint_range(0.1, 3.0) = 1.0; // 火焰动画速度
uniform float fire_scale : hint_range(0.1, 5.0) = 2.0; // 火焰纹理缩放
uniform float distortion_amount : hint_range(0.0, 0.1) = 0.02; // 扭曲强度
uniform float glow_sharpness : hint_range(0.0, 10.0) = 3.0; // 发光边缘锐利度

// 计算随机值
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// 扭曲UV
vec2 warp_uv(vec2 uv, float time, float strength) {
    vec2 noise_uv = uv * 2.0 + time * 0.1;
    float angle = texture(noise_texture, noise_uv).r * 2.0 * 3.14159;
    vec2 offset = vec2(cos(angle), sin(angle)) * strength;
    return uv + offset;
}

void fragment() {
    // 基础UV
    vec2 uv = UV;
    
    // 获取卡牌基础纹理
    vec4 card = texture(card_texture, uv);
    
    // 计算到卡牌边缘的距离（基于alpha通道）
    float edge_distance = 1.0 - card.a;
    
    // 脉冲效果
    float pulse = 1.0 + pulse_intensity * sin(TIME * pulse_speed);
    
    // 内发光
    float inner_glow = pow(1.0 - edge_distance, inner_glow_power) * card.a;
    
    // 外发光
    float outer_glow = pow(smoothstep(0.0, 0.2, 1.0 - edge_distance), outer_glow_power) * 
                       (1.0 - smoothstep(0.0, 0.5, edge_distance));
    
    // 组合内外发光
    float glow_mask = (inner_glow + outer_glow) * glow_intensity * pulse;
    
    // 锐化发光边缘
    glow_mask = pow(glow_mask, glow_sharpness);
    
    // 基础发光颜色
    vec4 result = vec4(0.0);
    
    // 如果使用火焰效果
    if (use_fire_effect) {
        // 扭曲UV来创建火焰
        vec2 warped_uv = warp_uv(uv, TIME * fire_speed, distortion_amount);
        
        // 对噪声纹理进行采样以创建火焰效果
        float noise1 = texture(noise_texture, warped_uv * fire_scale + vec2(-TIME * fire_speed, 0.0)).r;
        float noise2 = texture(noise_texture, warped_uv * fire_scale * 0.8 + vec2(-TIME * fire_speed * 1.5, TIME * fire_speed * 0.5)).r;
        
        // 创建火焰形状
        float flame_shape = max(0.0, 1.0 - abs(warped_uv.y - 0.5) * 2.0);
        flame_shape = pow(flame_shape, 2.0);
        
        // 组合噪声以创建自然的火焰移动
        float fire_noise = mix(noise1, noise2, 0.5) * flame_shape;
        
        // 在两种火焰颜色之间混合
        vec4 fire_color = mix(fire_color_1, fire_color_2, fire_noise);
        
        // 应用火焰效果到卡牌周围
        result = fire_color * glow_mask;
    } else {
        // 标准发光效果
        result = mix(inner_glow_color, glow_color, outer_glow / (inner_glow + outer_glow + 0.0001)) * glow_mask;
    }
    
    // 添加微小的闪烁
    float flicker = 1.0 + 0.05 * random(vec2(TIME * 0.01, 0.0));
    result.rgb *= flicker;
    
    // 保持原始纹理的alpha
    result.a = min(glow_mask, 1.0) * card.a;
    
    // 输出最终颜色
    COLOR = result;
} 