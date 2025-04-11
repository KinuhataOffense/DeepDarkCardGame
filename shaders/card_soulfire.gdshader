shader_type canvas_item;

// 魂火效果着色器 - 《无火的牌局》特效
// 模拟黑暗之魂风格的微妙火焰/魂火效果

// 参数设置
uniform vec4 fire_color_1 : source_color = vec4(0.1, 0.3, 0.7, 1.0); // 火焰主色调（蓝色魂火）
uniform vec4 fire_color_2 : source_color = vec4(0.0, 0.1, 0.3, 1.0); // 火焰次色调（深蓝色）
uniform vec4 fire_color_3 : source_color = vec4(0.7, 0.8, 1.0, 1.0); // 高光色调（亮蓝色）
uniform float fire_intensity : hint_range(0.0, 2.0) = 1.0; // 火焰强度
uniform float fire_speed : hint_range(0.1, 5.0) = 1.0; // 火焰速度
uniform float fire_scale : hint_range(1.0, 10.0) = 3.0; // 火焰细节缩放
uniform float edge_intensity : hint_range(0.0, 1.0) = 0.8; // 边缘火焰强度
uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable; // 噪声纹理
uniform bool preserve_alpha = true; // 是否保留原始透明度
uniform float distortion : hint_range(0.0, 0.1) = 0.02; // 扭曲强度
uniform bool invert_mask = false; // 反转遮罩，内部火焰还是外部火焰
uniform float flicker_speed : hint_range(0.0, 10.0) = 3.0; // 闪烁速度
uniform float smoke_amount : hint_range(0.0, 1.0) = 0.2; // 烟雾数量

// 噪声函数
float noise(vec2 p, float time) {
    // 添加时间因素的扭曲噪声
    vec2 uv = p * fire_scale + vec2(time * 0.1, time * -0.1);
    return texture(noise_texture, uv).r;
}

// FBM（分形布朗运动）- 用于生成自然的火焰形状
float fbm(vec2 uv, float time) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    // 叠加多层噪声，创建分形效果
    for (int i = 0; i < 5; ++i) {
        value += amplitude * noise(uv * frequency, time);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

// 火焰形状函数
float fire_shape(vec2 uv, float time, float edge_size) {
    // 基础火焰形状 - 梯形
    float base_height = 1.0 - uv.y; // 底部更强
    
    // 添加横向变化
    float x_falloff = 1.0 - 2.0 * abs(uv.x - 0.5); // 中心更强
    
    // 结合基础形状
    float base_shape = base_height * pow(x_falloff, 2.0);
    
    // 添加噪声扰动
    float noise_val = fbm(uv * vec2(1.0, 2.0) + vec2(0.0, time * 0.5), time);
    
    // 应用噪声扰动到基础形状
    float fire = base_shape + noise_val * 0.2 - 0.1;
    
    // 边缘处理
    if (edge_size > 0.0) {
        float edge_mask = smoothstep(edge_size, 0.0, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
        fire = mix(fire, fire * edge_mask, edge_intensity);
    }
    
    return clamp(fire, 0.0, 1.0);
}

// 扭曲函数
vec2 distort_uv(vec2 uv, float time) {
    // 使用噪声图来创建扭曲向量
    vec2 noise_uv = uv * 2.0 + time * 0.1;
    float noise_val_x = texture(noise_texture, noise_uv + vec2(0.0, time * 0.1)).r * 2.0 - 1.0;
    float noise_val_y = texture(noise_texture, noise_uv + vec2(time * 0.1, 0.0)).r * 2.0 - 1.0;
    
    // 创建扭曲向量
    vec2 distort_vec = vec2(noise_val_x, noise_val_y) * distortion;
    
    return uv + distort_vec;
}

void fragment() {
    // 获取原始颜色
    vec4 original_color = texture(TEXTURE, UV);
    
    // 时间变量
    float time = TIME * fire_speed;
    
    // 扭曲UV坐标
    vec2 distorted_uv = distort_uv(UV, time);
    
    // 计算火焰形状
    float mask = invert_mask ? (1.0 - original_color.a) : original_color.a;
    float fire_val = fire_shape(distorted_uv, time, 0.1) * mask;
    
    // 添加闪烁效果
    float flicker = sin(time * flicker_speed) * 0.1 + 0.9;
    fire_val *= flicker;
    
    // 颜色渐变 - 从深色到亮色
    vec3 fire_color;
    if (fire_val < 0.3) {
        fire_color = mix(fire_color_2.rgb, fire_color_1.rgb, fire_val / 0.3);
    } else if (fire_val < 0.6) {
        fire_color = mix(fire_color_1.rgb, fire_color_3.rgb, (fire_val - 0.3) / 0.3);
    } else {
        fire_color = fire_color_3.rgb;
    }
    
    // 烟雾效果 - 在火焰上方添加淡灰色
    if (smoke_amount > 0.0) {
        float smoke_y = distorted_uv.y - 0.2; // 烟雾位置偏上
        float smoke_mask = smoothstep(0.0, 0.3, smoke_y) * smoothstep(1.0, 0.7, smoke_y);
        float smoke_val = fbm(distorted_uv * vec2(1.0, 0.5) + vec2(time * 0.05, 0.0), time) * smoke_mask * smoke_amount;
        vec3 smoke_color = vec3(0.2, 0.2, 0.25); // 深灰色烟雾
        fire_color = mix(fire_color, smoke_color, smoke_val);
    }
    
    // 应用火焰颜色
    vec4 final_color = vec4(fire_color * fire_intensity * fire_val, fire_val);
    
    // 保留原始透明度或使用火焰透明度
    if (preserve_alpha) {
        final_color.a = original_color.a;
    }
    
    // 混合原始颜色和火焰
    COLOR = original_color + final_color;
} 