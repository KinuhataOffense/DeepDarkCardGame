shader_type canvas_item;
render_mode blend_add;

// 灵魂粒子着色器
// 用于实现游戏中灵魂、幽灵、魂火等超自然效果

// 基础颜色
uniform vec4 base_color : source_color = vec4(0.5, 0.8, 1.0, 0.8);
// 边缘颜色
uniform vec4 edge_color : source_color = vec4(0.1, 0.4, 0.8, 0.0);
// 核心颜色
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// 灵魂类型：0=普通灵魂, 1=深渊灵魂, 2=神圣灵魂, 3=元素灵魂
uniform int soul_type : hint_range(0, 3) = 0;
// 自定义元素颜色（用于元素灵魂）
uniform vec4 element_color : source_color = vec4(0.2, 0.9, 0.4, 0.7);
// 粒子噪声纹理
uniform sampler2D noise_texture;
// 扭曲强度
uniform float distortion : hint_range(0.0, 1.0) = 0.3;
// 能量强度
uniform float energy : hint_range(0.0, 2.0) = 1.0;
// 脉动速度
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.0;
// 脉动强度
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.3;
// 流动速度
uniform float flow_speed : hint_range(0.0, 2.0) = 0.5;
// 流动方向
uniform vec2 flow_direction = vec2(0.0, 1.0);
// 扭曲速度
uniform float distortion_speed : hint_range(0.0, 2.0) = 0.5;
// 灵魂轮廓软度
uniform float edge_softness : hint_range(0.0, 1.0) = 0.2;
// 灵魂核心大小
uniform float core_size : hint_range(0.0, 0.5) = 0.15;
// 灵魂核心亮度
uniform float core_brightness : hint_range(1.0, 5.0) = 2.0;
// 纹理旋转速度
uniform float rotation_speed : hint_range(-2.0, 2.0) = 0.2;
// 扭曲噪声缩放
uniform float noise_scale : hint_range(0.1, 10.0) = 3.0;
// 层噪声影响
uniform float layered_noise : hint_range(0.0, 1.0) = 0.5;
// 随机闪烁
uniform float flicker : hint_range(0.0, 1.0) = 0.2;
// 闪烁速度
uniform float flicker_speed : hint_range(0.0, 10.0) = 5.0;
// UV扭曲
uniform float uv_distortion : hint_range(0.0, 1.0) = 0.2;
// 粒子拖尾长度
uniform float trail_length : hint_range(0.0, 1.0) = 0.5;
// 粒子大小随机变化
uniform float size_variation : hint_range(0.0, 1.0) = 0.3;
// 大小变化速度
uniform float size_speed : hint_range(0.0, 2.0) = 0.5;
// 是否启用三维旋转效果
uniform bool enable_3d_rotation = true;
// 是否启用灵魂轨迹
uniform bool enable_trail = true;
// 是否启用色彩变化
uniform bool enable_color_shift = true;
// 色彩变化速度
uniform float color_shift_speed : hint_range(0.0, 2.0) = 0.3;
// 对外部光照的反应强度
uniform float light_sensitivity : hint_range(0.0, 1.0) = 0.5;

// 生成2D旋转矩阵
mat2 get_rotation_matrix(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

// 生成噪声
float generate_noise(sampler2D noise_tex, vec2 uv, float time, float scale) {
    // 多层噪声混合
    vec2 uv1 = uv * scale + time * 0.1;
    vec2 uv2 = uv * scale * 1.5 + time * -0.15;
    vec2 uv3 = uv * scale * 0.7 + time * 0.2;
    
    float noise1 = texture(noise_tex, uv1).r;
    float noise2 = texture(noise_tex, uv2).r;
    float noise3 = texture(noise_tex, uv3).r;
    
    return mix(noise1, 0.5 * (noise2 + noise3), layered_noise);
}

// 生成流动扭曲
vec2 get_flow_distortion(vec2 uv, float time) {
    // 计算多层噪声扭曲
    vec2 distort_uv1 = uv * noise_scale + time * distortion_speed * 0.2;
    vec2 distort_uv2 = uv * noise_scale * 1.7 + time * distortion_speed * -0.15;
    
    vec2 noise1 = texture(noise_texture, distort_uv1).rg * 2.0 - 1.0;
    vec2 noise2 = texture(noise_texture, distort_uv2).rg * 2.0 - 1.0;
    
    // 混合多层噪声
    vec2 final_distortion = mix(noise1, noise2, 0.5) * distortion;
    
    // 添加定向流动
    final_distortion += normalize(flow_direction) * time * flow_speed * 0.05;
    
    return final_distortion;
}

// 生成灵魂拖尾效果
float get_soul_trail(vec2 uv, float time, float shape) {
    if (!enable_trail) return 0.0;
    
    // 基于原始形状创建拖尾
    float trail = 0.0;
    vec2 trail_dir = normalize(flow_direction);
    
    // 多个拖尾采样点
    for (int i = 1; i <= 5; i++) {
        float strength = float(6 - i) / 5.0;
        vec2 offset = -trail_dir * float(i) * 0.02 * trail_length;
        
        // 计算当前采样点的形状值
        vec2 trail_uv = uv + offset;
        
        // 确保尾迹在UV范围内
        if (trail_uv.x >= 0.0 && trail_uv.x <= 1.0 && trail_uv.y >= 0.0 && trail_uv.y <= 1.0) {
            // 计算基础形状的偏移版本
            float trail_shape = length(trail_uv - 0.5) * 2.0;
            trail_shape = 1.0 - smoothstep(0.0, 0.9 + 0.1 * sin(time * 2.0), trail_shape);
            
            // 累加拖尾贡献
            trail += trail_shape * strength * 0.2;
        }
    }
    
    return trail;
}

// 应用闪烁效果
float apply_flicker(float time) {
    if (flicker <= 0.0) return 1.0;
    
    // 使用多个不同频率的正弦波创建不规则闪烁
    float flick1 = sin(time * flicker_speed) * 0.5 + 0.5;
    float flick2 = sin(time * flicker_speed * 1.3 + 1.5) * 0.5 + 0.5;
    float flick3 = sin(time * flicker_speed * 0.7 + 2.8) * 0.5 + 0.5;
    
    // 混合多个闪烁值
    float combined_flicker = flick1 * 0.5 + flick2 * 0.3 + flick3 * 0.2;
    
    // 应用闪烁强度
    return 1.0 - flicker * 0.5 * combined_flicker;
}

// 根据粒子类型调整颜色
vec4 adjust_soul_color(vec4 base, vec4 edge, vec4 core, int type, float time, float shape) {
    vec4 result;
    
    // 获取基础渐变色
    result = mix(edge, base, shape);
    
    // 应用类型特定的颜色调整
    if (type == 1) {  // 深渊灵魂
        // 深紫/黑色调
        vec3 abyss_core = vec3(0.6, 0.0, 0.8);
        vec3 abyss_base = vec3(0.2, 0.0, 0.4);
        vec3 abyss_edge = vec3(0.0, 0.0, 0.1);
        
        // 混合基础颜色与深渊颜色
        result.rgb = mix(mix(abyss_edge, abyss_base, shape), abyss_core, pow(shape, 3.0));
        
        // 添加深渊脉动
        float abyss_pulse = sin(time * pulse_speed * 0.7) * 0.5 + 0.5;
        result.rgb += vec3(0.1, 0.0, 0.2) * abyss_pulse * pulse_intensity;
        
        // 深渊灵魂有独特的不透明度处理
        result.a = base.a * (shape * 0.8 + 0.2);
    }
    else if (type == 2) {  // 神圣灵魂
        // 金色/白色调
        vec3 divine_core = vec3(1.0, 1.0, 0.9);
        vec3 divine_base = vec3(1.0, 0.9, 0.6);
        vec3 divine_edge = vec3(0.8, 0.7, 0.3);
        
        // 混合基础颜色与神圣颜色
        result.rgb = mix(mix(divine_edge, divine_base, shape), divine_core, pow(shape, 2.0));
        
        // 添加神圣光芒
        float divine_glow = sin(time * pulse_speed * 1.2) * 0.5 + 0.5;
        result.rgb += vec3(0.2, 0.2, 0.1) * divine_glow * pulse_intensity;
        
        // 神圣灵魂更加明亮
        result.rgb *= 1.2;
    }
    else if (type == 3) {  // 元素灵魂
        // 使用提供的元素颜色
        vec3 element_base = element_color.rgb;
        vec3 element_edge = element_base * 0.5;
        vec3 element_core = mix(element_base, vec3(1.0), 0.7);
        
        // 混合颜色
        result.rgb = mix(mix(element_edge, element_base, shape), element_core, pow(shape, 2.0));
        
        // 应用随时间变化的元素律动
        if (enable_color_shift) {
            float time_offset = time * color_shift_speed;
            float r_shift = sin(time_offset) * 0.5 + 0.5;
            float g_shift = sin(time_offset + 2.0) * 0.5 + 0.5;
            float b_shift = sin(time_offset + 4.0) * 0.5 + 0.5;
            
            vec3 color_shift = vec3(r_shift, g_shift, b_shift) * 0.3;
            result.rgb = mix(result.rgb, result.rgb + color_shift, 0.3);
        }
    }
    
    // 对所有类型应用核心高亮
    if (shape > (1.0 - core_size)) {
        float core_factor = smoothstep(1.0 - core_size, 1.0, shape);
        result.rgb = mix(result.rgb, core.rgb * core_brightness, core_factor);
    }
    
    return result;
}

void fragment() {
    // 计算时间
    float time = TIME;
    
    // 中心坐标系
    vec2 centered_uv = UV - 0.5;
    
    // 应用旋转
    centered_uv = get_rotation_matrix(time * rotation_speed) * centered_uv;
    
    // 计算大小变化
    float size_mod = 1.0;
    if (size_variation > 0.0) {
        size_mod = 1.0 + sin(time * size_speed) * size_variation * 0.3;
        centered_uv /= size_mod;
    }
    
    // 计算3D旋转效果（透视变形）
    if (enable_3d_rotation) {
        float x_rot = sin(time * 0.5) * 0.2;
        float y_rot = cos(time * 0.3) * 0.15;
        
        // 简化的3D透视效果
        centered_uv.x *= 1.0 + x_rot * centered_uv.y;
        centered_uv.y *= 1.0 + y_rot * centered_uv.x;
    }
    
    // 恢复回0-1范围的UV
    vec2 uv = centered_uv + 0.5;
    
    // 计算流动扭曲
    vec2 distortion_offset = get_flow_distortion(uv, time);
    vec2 distorted_uv = uv + distortion_offset * uv_distortion;
    
    // 计算基础形状（圆形渐变）
    float base_shape = length(centered_uv);
    base_shape = 1.0 - smoothstep(0.0, 0.5 - edge_softness * 0.1, base_shape);
    
    // 应用噪声修改形状
    float noise = generate_noise(noise_texture, distorted_uv, time, noise_scale);
    float shape = base_shape * (1.0 - distortion * 0.5) + noise * distortion;
    
    // 应用能量因子
    shape = pow(shape, 1.0 / (0.5 + energy * 0.5));
    
    // 脉动效果
    float pulse_factor = 1.0;
    if (pulse_intensity > 0.0) {
        pulse_factor = 1.0 + sin(time * pulse_speed) * pulse_intensity * 0.3;
        shape *= pulse_factor;
    }
    
    // 计算拖尾效果
    float trail = get_soul_trail(uv, time, base_shape);
    
    // 应用闪烁
    float flicker_factor = apply_flicker(time);
    
    // 调整灵魂颜色
    vec4 color = adjust_soul_color(base_color, edge_color, core_color, soul_type, time, shape);
    
    // 应用拖尾
    color.rgb += edge_color.rgb * trail * energy;
    
    // 应用闪烁
    color.rgb *= flicker_factor;
    
    // 确保透明度基于形状
    color.a *= shape;
    
    // 对灵魂拖尾应用额外不透明度
    color.a += trail * 0.5 * energy;
    
    // 限制最大透明度
    color.a = min(color.a, 1.0);
    
    // 能量强度整体调整
    color.rgb *= 0.8 + energy * 0.4;
    
    COLOR = color;
} 