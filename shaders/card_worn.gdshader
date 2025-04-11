shader_type canvas_item;

uniform sampler2D card_texture : source_color; // 卡牌纹理
uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable; // 噪声纹理（用于折痕和磨损）
uniform sampler2D dust_texture : filter_linear_mipmap, repeat_enable; // 灰尘纹理

// 老旧效果参数
uniform float worn_amount : hint_range(0.0, 1.0) = 0.5; // 磨损程度
uniform float edge_worn : hint_range(0.0, 1.0) = 0.7; // 边缘磨损强度
uniform float stain_amount : hint_range(0.0, 1.0) = 0.3; // 污渍数量
uniform float dust_amount : hint_range(0.0, 1.0) = 0.2; // 灰尘数量
uniform float crease_amount : hint_range(0.0, 1.0) = 0.4; // 折痕数量
uniform float color_fade : hint_range(0.0, 1.0) = 0.3; // 颜色褪色程度
uniform float yellowing : hint_range(0.0, 1.0) = 0.2; // 泛黄程度
uniform vec4 stain_color : source_color = vec4(0.3, 0.2, 0.1, 1.0); // 污渍颜色
uniform vec4 dust_color : source_color = vec4(0.8, 0.8, 0.7, 1.0); // 灰尘颜色
uniform float edge_darkness : hint_range(0.0, 1.0) = 0.3; // 边缘暗化
uniform float randomness : hint_range(0.0, 1.0) = 0.5; // 随机性（每张卡的变化）
uniform vec2 unique_seed = vec2(0.0, 0.0); // 每张卡的唯一种子

// 噪声函数
float get_noise(vec2 uv, float scale) {
    return texture(noise_texture, uv * scale + unique_seed).r;
}

// 分形布朗运动噪声（更自然的纹理）
float fbm(vec2 uv, float scale) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    for (int i = 0; i < 5; i++) {
        value += amplitude * get_noise(uv, scale * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    // 基本UV坐标
    vec2 uv = UV;
    
    // 获取原始卡牌纹理
    vec4 original = texture(card_texture, uv);
    
    // 生成各种噪声纹理用于不同的老旧效果
    float edge_noise = smoothstep(0.4, 0.9, fbm(uv * 3.0 + unique_seed, 2.0)); // 边缘磨损
    float wear_noise = fbm(uv * 4.0 + unique_seed * 2.0, 3.0); // 整体磨损
    float stain_noise = smoothstep(0.4, 0.8, fbm(uv * 2.0 + unique_seed * 3.0, 1.5)); // 污渍
    float crease_noise = pow(fbm(uv * 5.0 + unique_seed * 4.0, 3.0), 3.0); // 折痕（更锐利）
    float dust_pattern = texture(dust_texture, uv * 3.0 + unique_seed).r; // 灰尘模式

    // 计算边缘系数（边缘更容易磨损）
    float edge_factor = 1.0 - smoothstep(0.0, 0.3, min(
        min(uv.x, 1.0 - uv.x),
        min(uv.y, 1.0 - uv.y)
    ));
    edge_factor = pow(edge_factor, 2.0) * edge_worn;
    
    // 计算磨损效果（边缘更严重）
    float worn_factor = wear_noise * worn_amount + edge_factor;
    
    // 添加褪色效果
    vec3 faded_color = mix(original.rgb, vec3(
        original.r * (1.0 + yellowing * 0.4),
        original.g * (1.0 + yellowing * 0.2),
        original.b * (1.0 - yellowing * 0.2)
    ), color_fade);
    
    // 添加污渍
    vec3 with_stains = mix(faded_color, stain_color.rgb, stain_noise * stain_amount);
    
    // 添加边缘暗化
    with_stains *= 1.0 - edge_factor * edge_darkness;
    
    // 添加折痕（使颜色变暗）
    with_stains *= 1.0 - crease_noise * crease_amount * 0.5;
    
    // 添加灰尘（混合灰尘颜色）
    vec3 with_dust = mix(with_stains, dust_color.rgb, dust_pattern * dust_amount);
    
    // 最终颜色
    vec4 result = vec4(with_dust, original.a);
    
    // 边缘轻微透明度降低（模拟磨损导致的边缘损坏）
    result.a *= 1.0 - edge_factor * worn_amount * 0.3;
    
    COLOR = result;
} 