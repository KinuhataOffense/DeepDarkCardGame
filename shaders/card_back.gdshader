shader_type canvas_item;

// 纹理参数
uniform sampler2D card_texture : source_color; // 卡牌基础纹理
uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable; // 噪声纹理，用于添加颗粒感
uniform sampler2D symbol_texture : source_color; // 符号纹理，例如徽章或印记

// 颜色参数
uniform vec4 base_color : source_color = vec4(0.31, 0.27, 0.20, 1.0); // 基础颜色
uniform vec4 edge_color : source_color = vec4(0.17, 0.12, 0.07, 1.0); // 边缘颜色
uniform vec4 highlight_color : source_color = vec4(0.65, 0.55, 0.35, 1.0); // 符号高亮颜色

// 效果参数
uniform float edge_width : hint_range(0.0, 0.5) = 0.15; // 边缘渐变宽度
uniform float edge_burn : hint_range(0.0, 1.0) = 0.3; // 边缘烧焦效果
uniform float symbol_opacity : hint_range(0.0, 1.0) = 0.8; // 符号不透明度
uniform float symbol_scale : hint_range(0.1, 2.0) = 0.8; // 符号缩放
uniform float symbol_rotation : hint_range(0.0, 6.28) = 0.0; // 符号旋转(弧度)
uniform float noise_strength : hint_range(0.0, 1.0) = 0.15; // 噪声强度
uniform float worn_effect : hint_range(0.0, 1.0) = 0.3; // 磨损效果
uniform bool animate_glow = true; // 是否使符号轻微闪烁
uniform float glow_speed : hint_range(0.1, 5.0) = 1.0; // 闪烁速度
uniform float dirt_amount : hint_range(0.0, 1.0) = 0.4; // 污渍程度
uniform float corner_damage : hint_range(0.0, 1.0) = 0.3; // 角落损坏程度

// 旋转UV坐标
vec2 rotate_uv(vec2 uv, float rotation, vec2 center) {
    vec2 uv_centered = uv - center;
    float sin_rot = sin(rotation);
    float cos_rot = cos(rotation);
    mat2 rotation_matrix = mat2(
        vec2(cos_rot, -sin_rot),
        vec2(sin_rot, cos_rot)
    );
    return rotation_matrix * uv_centered + center;
}

// 计算距边缘的距离
float edge_distance(vec2 uv) {
    vec2 centered = abs(uv - 0.5) * 2.0;
    return max(centered.x, centered.y);
}

// Perlin噪声
float perlin_noise(vec2 uv) {
    return texture(noise_texture, uv).r;
}

// 分形布朗运动 - 用于创建更自然的纸张纹理
float fbm(vec2 uv, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 3.0;
    
    for (int i = 0; i < octaves; i++) {
        value += amplitude * perlin_noise(uv * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

// 污渍和损坏效果
float damage_effect(vec2 uv, float amount) {
    // 创建角落和边缘的损坏
    float corner_dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
    float edge_dist = 1.0 - edge_distance(uv);
    
    // 使用噪声创建不规则的损坏形状
    float noise1 = fbm(uv * 5.0, 3);
    float noise2 = fbm(uv * 2.5 + vec2(57.2, 13.7), 3);
    
    float corner_mask = smoothstep(0.0, 0.25, corner_dist + noise1 * 0.1);
    float edge_mask = smoothstep(0.0, edge_width * 2.0, edge_dist + noise2 * 0.15);
    
    return mix(1.0, min(corner_mask, edge_mask), amount);
}

void fragment() {
    vec2 uv = UV;
    
    // 基础纸张纹理
    vec4 base_texture = texture(card_texture, uv);
    
    // 创建纸张纹理噪声
    float paper_noise = fbm(uv * 4.0, 4);
    float fine_noise = perlin_noise(uv * 20.0);
    
    // 计算边缘效果
    float edge = smoothstep(1.0 - edge_width, 1.0, edge_distance(uv));
    
    // 添加角落磨损和损坏
    float damage = damage_effect(uv, corner_damage);
    
    // 计算中心符号
    vec2 symbol_uv = rotate_uv(uv, symbol_rotation, vec2(0.5));
    symbol_uv = (symbol_uv - 0.5) / symbol_scale + 0.5; // 缩放
    vec4 symbol = texture(symbol_texture, symbol_uv);
    
    // 为符号添加闪烁效果
    float glow_amount = 1.0;
    if (animate_glow) {
        glow_amount = 0.8 + 0.2 * sin(TIME * glow_speed);
    }
    
    // 添加老旧感和污渍
    float dirt = mix(1.0, perlin_noise(uv * 8.0 + vec2(123.4, 567.8)), dirt_amount);
    
    // 组合所有效果
    vec4 final_color = mix(base_color, edge_color, edge * edge_burn);
    
    // 添加纸张纹理
    final_color.rgb *= mix(0.9, 1.1, paper_noise);
    
    // 添加细节噪声
    final_color.rgb *= 1.0 - (fine_noise * noise_strength);
    
    // 叠加符号
    float symbol_mask = symbol.a * symbol_opacity * glow_amount;
    final_color.rgb = mix(final_color.rgb, highlight_color.rgb, symbol_mask);
    
    // 添加边缘磨损效果
    final_color.rgb *= mix(1.0, 0.7, edge * worn_effect);
    
    // 添加污渍和损坏
    final_color.rgb *= dirt;
    final_color.rgb *= damage;
    
    // 使用基础纹理的alpha通道
    final_color.a = base_texture.a;
    
    // 输出最终颜色
    COLOR = final_color;
} 