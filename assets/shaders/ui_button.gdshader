shader_type canvas_item;

// 按钮状态参数
uniform bool hovered = false; // 鼠标悬停状态
uniform bool pressed = false; // 按下状态
uniform bool disabled = false; // 禁用状态

// 外观参数
uniform vec4 normal_color : source_color = vec4(0.25, 0.22, 0.18, 1.0); // 正常状态颜色
uniform vec4 hover_color : source_color = vec4(0.35, 0.30, 0.22, 1.0); // 悬停状态颜色
uniform vec4 pressed_color : source_color = vec4(0.18, 0.16, 0.12, 1.0); // 按下状态颜色
uniform vec4 disabled_color : source_color = vec4(0.15, 0.15, 0.15, 0.7); // 禁用状态颜色
uniform vec4 border_color : source_color = vec4(0.6, 0.5, 0.3, 1.0); // 边框颜色
uniform float border_width : hint_range(0.0, 0.1) = 0.02; // 边框宽度
uniform float corner_radius : hint_range(0.0, 0.5) = 0.1; // 圆角半径
uniform float glow_strength : hint_range(0.0, 1.0) = 0.3; // 发光强度
uniform vec4 glow_color : source_color = vec4(0.8, 0.6, 0.2, 1.0); // 发光颜色
uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable; // 噪声纹理，用于添加细节
uniform float noise_amount : hint_range(0.0, 0.5) = 0.05; // 噪声强度
uniform bool use_wear_effect = true; // 使用磨损效果
uniform float wear_amount : hint_range(0.0, 1.0) = 0.2; // 磨损程度

// 距离场函数 - 圆角矩形
float sdf_rounded_rect(vec2 uv, vec2 size, float radius) {
    vec2 d = abs(uv - vec2(0.5)) - size * 0.5 + radius;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - radius;
}

// 随机函数
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

// 噪声函数
float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// 磨损效果
float wear_effect(vec2 uv, float amount) {
    float n = noise(uv * 15.0) * noise(uv * 7.5);
    return smoothstep(0.5 - amount, 0.5 + amount, n);
}

void fragment() {
    // 基础按钮形状
    vec2 uv = UV;
    float distance_field = sdf_rounded_rect(uv, vec2(0.95, 0.9), corner_radius);
    
    // 选择当前状态的颜色
    vec4 current_color;
    if (disabled) {
        current_color = disabled_color;
    } else if (pressed) {
        current_color = pressed_color;
    } else if (hovered) {
        current_color = hover_color;
    } else {
        current_color = normal_color;
    }
    
    // 计算边框
    float border = smoothstep(0.0, 0.005, border_width - abs(distance_field));
    
    // 计算磨损效果
    float wear = 0.0;
    if (use_wear_effect) {
        wear = wear_effect(uv, wear_amount);
        // 只在边缘应用磨损
        wear *= smoothstep(0.0, 0.1, abs(distance_field) + 0.05);
    }
    
    // 噪声细节
    float noise_detail = texture(noise_texture, uv * 3.0).r * noise_amount;
    
    // 计算发光效果（仅在悬停时）
    float glow = 0.0;
    if (hovered && !disabled && !pressed) {
        glow = smoothstep(0.1, 0.5, abs(sin(TIME * 1.5))) * glow_strength;
    }
    
    // 应用磨损到边框
    vec4 border_with_wear = mix(border_color, vec4(0.0), wear * 0.7);
    
    // 组合所有效果
    vec4 final_color = current_color;
    
    // 添加噪声细节
    final_color.rgb = mix(final_color.rgb, final_color.rgb * (1.0 - noise_detail), 0.5);
    
    // 添加边框
    final_color = mix(final_color, border_with_wear, border);
    
    // 添加发光
    if (distance_field < 0.0) {
        final_color.rgb += glow_color.rgb * glow;
    }
    
    // 应用阴影和外发光
    float shadow = smoothstep(-0.05, 0.05, distance_field);
    final_color.a = mix(current_color.a, 0.0, shadow);
    
    // 在禁用状态下降低按钮对比度
    if (disabled) {
        final_color.rgb = mix(final_color.rgb, vec3(0.2), 0.5);
    }
    
    // 应用按下效果（轻微压扁）
    if (pressed && !disabled) {
        // 压扁效果 - 使用暗色并添加微小的阴影
        final_color.rgb *= 0.9;
    }
    
    // 最终输出
    COLOR = final_color;
} 