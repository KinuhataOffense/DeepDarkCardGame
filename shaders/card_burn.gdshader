shader_type canvas_item;

uniform sampler2D card_texture : source_color; // 卡牌纹理
uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable; // 噪声纹理
uniform sampler2D burn_mask : filter_linear_mipmap; // 燃烧掩码纹理，控制燃烧方向

// 燃烧参数
uniform float burn_position : hint_range(0.0, 1.0) = 0.0; // 燃烧位置 (0.0-1.0)
uniform float burn_edge_width : hint_range(0.0, 0.5) = 0.1; // 燃烧边缘宽度
uniform vec4 burn_color : source_color = vec4(1.0, 0.3, 0.0, 1.0); // 燃烧颜色
uniform vec4 ember_color : source_color = vec4(1.0, 0.5, 0.0, 1.0); // 余烬颜色
uniform float ember_width : hint_range(0.0, 0.5) = 0.05; // 余烬宽度
uniform float flame_speed : hint_range(0.1, 5.0) = 1.0; // 火焰移动速度
uniform float flame_intensity : hint_range(0.0, 2.0) = 1.0; // 火焰强度
uniform float ash_amount : hint_range(0.0, 1.0) = 0.2; // 灰烬数量
uniform vec4 ash_color : source_color = vec4(0.1, 0.1, 0.1, 1.0); // 灰烬颜色
uniform float ash_tex_scale : hint_range(1.0, 10.0) = 5.0; // 灰烬纹理缩放
uniform bool use_distortion = true; // 是否使用热扭曲
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.02; // 热扭曲强度
uniform float distortion_scale : hint_range(1.0, 10.0) = 3.0; // 热扭曲缩放

// 噪声函数
float noise(vec2 p) {
    return texture(noise_texture, p).r;
}

// 分形布朗运动噪声
float fbm(vec2 p) {
    float f = 0.0;
    float w = 0.5;
    for (int i = 0; i < 5; i++) {
        f += w * noise(p);
        p *= 2.0;
        w *= 0.5;
    }
    return f;
}

void fragment() {
    // 基本UV坐标
    vec2 uv = UV;
    
    // 获取燃烧掩码值，控制燃烧形状
    float burn_mask_value = texture(burn_mask, uv).r;
    
    // 计算燃烧阈值 - 添加噪声使边缘不规则
    float noise_value = fbm(uv * 4.0 + vec2(0.0, TIME * 0.1));
    float burn_threshold = burn_position - noise_value * 0.2;
    
    // 热扭曲效果（仅应用于未燃烧区域）
    if (use_distortion && burn_mask_value > burn_threshold + burn_edge_width) {
        float heat_distortion = fbm(uv * distortion_scale + vec2(-TIME * flame_speed * 0.2, 0.0)) * 2.0 - 1.0;
        float distortion_factor = smoothstep(burn_threshold + burn_edge_width, burn_threshold + burn_edge_width * 2.0, burn_mask_value);
        uv += vec2(heat_distortion, heat_distortion) * distortion_strength * distortion_factor;
    }
    
    // 原始卡牌纹理
    vec4 card = texture(card_texture, uv);
    
    // 已燃烧区域（完全透明）
    float burnt_area = step(burn_mask_value, burn_threshold);
    
    // 燃烧边缘（火焰）
    float edge_area = smoothstep(burn_threshold, burn_threshold + burn_edge_width, burn_mask_value);
    
    // 余烬区域
    float ember_area = smoothstep(burn_threshold + burn_edge_width, burn_threshold + burn_edge_width + ember_width, burn_mask_value);
    
    // 火焰动画（使用噪声纹理和时间）
    float flame_noise1 = noise(uv * 3.0 + vec2(-TIME * flame_speed, 0.0));
    float flame_noise2 = noise(uv * 5.0 + vec2(-TIME * flame_speed * 1.2, TIME * flame_speed * 0.3));
    float flame_noise = mix(flame_noise1, flame_noise2, 0.5) * flame_intensity;
    
    // 火焰效果
    vec4 flame = burn_color * (1.0 - edge_area) * flame_noise;
    
    // 余烬效果（边缘微弱发光）
    vec4 embers = ember_color * ember_area * (0.5 + 0.5 * sin(TIME * 3.0 + uv.y * 10.0));
    
    // 灰烬效果（已燃烧区域）
    float ash_noise = fbm(uv * ash_tex_scale);
    vec4 ash = ash_color * burnt_area * ash_amount * ash_noise;
    
    // 组合所有效果
    vec4 result = card * edge_area; // 原始卡牌（仅在未燃烧区域）
    result += flame * (1.0 - edge_area); // 添加火焰
    result += embers * ember_area; // 添加余烬
    result += ash; // 添加灰烬
    
    // 更新透明度 - 完全燃烧的区域变透明
    result.a = card.a * max(edge_area, ash_amount * burnt_area * ash_noise);
    
    // 输出最终颜色
    COLOR = result;
} 