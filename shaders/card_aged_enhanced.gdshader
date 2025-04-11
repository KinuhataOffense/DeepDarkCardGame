shader_type canvas_item;

// 卡牌老旧效果增强版 - 适用于《无火的牌局》的暗黑风格

// 参数设置
uniform float age_amount : hint_range(0.0, 1.0) = 0.7; // 老化程度
uniform float edge_wear : hint_range(0.0, 1.0) = 0.6; // 边缘磨损程度
uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable; // 噪点纹理
uniform float noise_influence : hint_range(0.0, 1.0) = 0.4; // 噪点影响程度
uniform vec4 age_tint : source_color = vec4(0.8, 0.72, 0.62, 1.0); // 老化色调
uniform float parchment_effect : hint_range(0.0, 1.0) = 0.3; // 羊皮纸效果程度
uniform float dust_amount : hint_range(0.0, 1.0) = 0.2; // 灰尘效果程度
uniform sampler2D dust_texture : filter_linear_mipmap, repeat_enable; // 灰尘纹理
uniform bool enable_animate = true; // 是否启用微妙的动画效果
uniform float time_scale = 0.1; // 时间比例，控制动画速度

// 随机函数
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// 扰动函数
vec2 distort(vec2 uv, float time, float strength) {
    vec2 distorted_uv = uv;
    distorted_uv.x += sin(uv.y * 10.0 + time) * 0.01 * strength;
    distorted_uv.y += cos(uv.x * 10.0 + time) * 0.01 * strength;
    return distorted_uv;
}

// 羊皮纸效果
vec3 apply_parchment(vec3 color, vec2 uv, float amount) {
    // 生成羊皮纸的不规则纹理
    float pattern = rand(uv * 100.0) * 0.1 * amount;
    vec3 parchment_color = vec3(0.9, 0.85, 0.7);
    return mix(color, color * (1.0 - pattern) + parchment_color * pattern, amount);
}

// 边缘磨损效果
float edge_wear_effect(vec2 uv, float amount) {
    // 计算到卡牌边缘的距离
    float distance_to_edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
    // 应用非线性函数使边缘更明显
    float edge_mask = smoothstep(0.0, 0.15, distance_to_edge);
    // 添加随机性使边缘更自然
    float random_edge = rand(uv * 50.0) * 0.5 + 0.5;
    // 合并效果
    return mix(edge_mask, edge_mask * random_edge, amount);
}

void fragment() {
    // 获取时间变量，用于动画
    float time = enable_animate ? TIME * time_scale : 0.0;
    
    // 应用微小扰动，模拟轻微的老旧卡牌变形
    vec2 distorted_uv = distort(UV, time, age_amount * 0.5);
    
    // 获取原始颜色
    vec4 color = texture(TEXTURE, distorted_uv);
    
    // 应用噪点纹理，增加老旧感
    vec2 noise_uv = UV + vec2(sin(time * 0.1), cos(time * 0.1)) * 0.01 * age_amount;
    vec4 noise = texture(noise_texture, noise_uv * 3.0);
    
    // 混合原始颜色和噪点
    color.rgb = mix(color.rgb, color.rgb * noise.rgb, noise_influence * age_amount);
    
    // 应用羊皮纸效果
    color.rgb = apply_parchment(color.rgb, UV, parchment_effect * age_amount);
    
    // 应用边缘磨损
    float edge = edge_wear_effect(UV, edge_wear);
    color.a *= edge;
    
    // 灰尘效果
    if (dust_amount > 0.0) {
        vec2 dust_uv = UV + vec2(sin(time * 0.2), cos(time * 0.3)) * 0.02;
        vec4 dust = texture(dust_texture, dust_uv * 2.0);
        float dust_factor = dust.r * dust_amount * age_amount;
        color.rgb = mix(color.rgb, color.rgb * (1.0 - dust_factor) + dust.rgb, dust_factor * 0.7);
    }
    
    // 应用老化色调，整体偏黄偏褐
    color.rgb = mix(color.rgb, color.rgb * age_tint.rgb, age_amount * 0.5);
    
    // 应用轻微的暗角效果
    float vignette = 1.0 - smoothstep(0.5, 1.2, length(UV - vec2(0.5)));
    color.rgb *= mix(1.0, vignette, age_amount * 0.3);
    
    // 输出最终颜色
    COLOR = color;
} 