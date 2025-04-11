shader_type canvas_item;
render_mode blend_mix;

// 水晶效果着色器
// 用于实现游戏中各种水晶、宝石和晶体的视觉效果

// 基础参数
uniform vec4 crystal_color : source_color = vec4(0.3, 0.5, 0.9, 0.9);
uniform vec4 highlight_color : source_color = vec4(0.9, 0.95, 1.0, 0.95);
uniform vec4 shadow_color : source_color = vec4(0.1, 0.2, 0.4, 0.9);
// 水晶类型：0=普通水晶, 1=火焰水晶, 2=暗影水晶, 3=元素水晶
uniform int crystal_type : hint_range(0, 3) = 0;
// 自定义元素颜色（用于元素水晶）
uniform vec4 element_color : source_color = vec4(0.2, 0.9, 0.4, 0.7);
// 折射强度
uniform float refraction : hint_range(0.0, 1.0) = 0.5;
// 反射强度
uniform float reflection : hint_range(0.0, 1.0) = 0.3;
// 内部光照强度
uniform float inner_light : hint_range(0.0, 2.0) = 1.0;
// 表面光泽
uniform float shininess : hint_range(0.0, 1.0) = 0.7;
// 亮点强度
uniform float highlight_intensity : hint_range(0.0, 2.0) = 1.0;
// 亮点大小
uniform float highlight_size : hint_range(0.0, 0.5) = 0.1;
// 边缘发光强度
uniform float edge_glow : hint_range(0.0, 1.0) = 0.4;
// 晶面数量
uniform float facet_count : hint_range(3.0, 24.0) = 6.0;
// 晶面清晰度
uniform float facet_clarity : hint_range(0.0, 1.0) = 0.5;
// 内部纹理缩放
uniform float inner_texture_scale : hint_range(0.1, 10.0) = 3.0;
// 纹理旋转速度
uniform float rotation_speed : hint_range(-2.0, 2.0) = 0.1;
// 波纹强度
uniform float ripple_intensity : hint_range(0.0, 1.0) = 0.3;
// 波纹速度
uniform float ripple_speed : hint_range(0.0, 5.0) = 1.0;
// 水晶杂质
uniform float impurity : hint_range(0.0, 1.0) = 0.1;
// 杂质尺寸
uniform float impurity_scale : hint_range(1.0, 20.0) = 10.0;
// 水晶形状（0.0为圆形，1.0为晶体形状）
uniform float crystal_shape : hint_range(0.0, 1.0) = 0.7;
// 噪声纹理
uniform sampler2D noise_texture;

// 用于折射效果的场景纹理
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
// 水晶纹理
uniform sampler2D crystal_texture;
// 是否使用自定义晶体贴图
uniform bool use_custom_texture = false;
// 内部闪光效果
uniform float sparkle : hint_range(0.0, 1.0) = 0.3;
// 闪光速度
uniform float sparkle_speed : hint_range(0.0, 5.0) = 2.0;
// 水晶透明度
uniform float crystal_alpha : hint_range(0.0, 1.0) = 0.9;
// 色散效果（光分离为彩虹）
uniform float dispersion : hint_range(0.0, 1.0) = 0.2;
// 脉动效果
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.1;
// 脉动速度
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.0;
// 视差深度
uniform float parallax_depth : hint_range(0.0, 1.0) = 0.3;
// 视差层数
uniform float parallax_layers : hint_range(1.0, 10.0) = 5.0;
// 是否启用裂纹效果
uniform bool enable_cracks = false;
// 裂纹数量
uniform float crack_amount : hint_range(0.0, 1.0) = 0.2;
// 裂纹宽度
uniform float crack_width : hint_range(0.01, 0.1) = 0.03;

// 2D旋转矩阵
mat2 get_rotation_matrix(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

// 生成随机值
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// 生成噪声
float generate_noise(sampler2D noise_tex, vec2 uv, float scale) {
    return texture(noise_tex, uv * scale).r;
}

// 生成分形噪声
float fractal_noise(sampler2D noise_tex, vec2 uv, float scale, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < octaves; i++) {
        value += amplitude * generate_noise(noise_tex, uv * frequency, scale);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

// 计算晶面图案
float facet_pattern(vec2 uv, float facets, float clarity) {
    // 转换到极坐标
    float dist = length(uv - 0.5) * 2.0;
    float angle = atan(uv.y - 0.5, uv.x - 0.5);
    
    // 计算晶面角度分割
    float facet_angle = 3.14159 * 2.0 / facets;
    float facet_value = mod(angle, facet_angle) / facet_angle;
    
    // 应用晶面清晰度
    facet_value = smoothstep(0.5 - clarity * 0.5, 0.5 + clarity * 0.5, facet_value);
    
    // 混合径向梯度
    float radial = 1.0 - dist;
    return mix(radial, facet_value, clarity * crystal_shape);
}

// 生成水晶形状
float crystal_mask(vec2 uv, float edges, float shape_factor) {
    // 基础圆形
    float circle = 1.0 - smoothstep(0.4, 0.5, length(uv - 0.5));
    
    // 晶体多边形
    float angle = atan(uv.y - 0.5, uv.x - 0.5);
    float r = length(uv - 0.5);
    
    // 根据边数创建多边形
    float a = 3.14159 * 2.0 / edges;
    float polygon = cos(floor(0.5 + angle / a) * a - angle) * r;
    polygon = 1.0 - smoothstep(0.4, 0.5, polygon);
    
    // 混合圆和多边形
    return mix(circle, polygon, shape_factor);
}

// 计算水晶亮点
float calculate_highlight(vec2 uv, float time) {
    // 主亮点位置（随时间轻微移动）
    vec2 highlight_pos = vec2(0.35, 0.35) + vec2(sin(time * 0.2), cos(time * 0.3)) * 0.05;
    float d1 = distance(uv, highlight_pos);
    float highlight1 = 1.0 - smoothstep(0.0, highlight_size, d1);
    
    // 第二个小亮点
    vec2 highlight_pos2 = vec2(0.6, 0.35) + vec2(cos(time * 0.2), sin(time * 0.3)) * 0.05;
    float d2 = distance(uv, highlight_pos2);
    float highlight2 = (1.0 - smoothstep(0.0, highlight_size * 0.7, d2)) * 0.7;
    
    // 组合亮点
    return highlight1 + highlight2;
}

// 计算内部光照
vec3 calculate_inner_light(vec2 uv, float time, int type, vec4 base_color) {
    // 计算内部光照基础值
    float inner_glow = facet_pattern(uv, facet_count, facet_clarity * 0.5);
    
    // 应用波纹效果
    if (ripple_intensity > 0.0) {
        float ripple = sin((length(uv - 0.5) * 10.0 - time * ripple_speed) * 3.14159);
        ripple = ripple * 0.5 + 0.5;
        inner_glow = mix(inner_glow, ripple, ripple_intensity * 0.3);
    }
    
    // 根据类型调整内部光照
    vec3 glow_color = base_color.rgb;
    
    if (type == 1) {  // 火焰水晶
        // 内部火焰效果
        float fire_noise = fractal_noise(noise_texture, uv * 1.5 + time * 0.1, 2.0, 3);
        float fire_intensity = fire_noise * (1.0 - length(uv - 0.5) * 1.5);
        fire_intensity = max(0.0, fire_intensity * 2.0);
        
        vec3 fire_color = mix(vec3(1.0, 0.5, 0.0), vec3(1.0, 0.8, 0.0), fire_noise);
        glow_color = mix(glow_color, fire_color, fire_intensity * 0.7);
        
        // 添加火焰脉动
        float fire_pulse = sin(time * pulse_speed * 1.5) * 0.5 + 0.5;
        glow_color *= 1.0 + fire_pulse * pulse_intensity * 0.5;
    }
    else if (type == 2) {  // 暗影水晶
        // 内部暗影漩涡效果
        vec2 vortex_uv = uv - 0.5;
        float angle = atan(vortex_uv.y, vortex_uv.x);
        float r = length(vortex_uv);
        
        // 扭曲角度创建漩涡
        vec2 swirl_uv = vec2(
            cos(angle + r * 5.0 - time * 0.2),
            sin(angle + r * 5.0 - time * 0.2)
        ) * r;
        
        float shadow_noise = texture(noise_texture, swirl_uv + 0.5).r;
        
        // 暗影颜色
        vec3 shadow_base = vec3(0.1, 0.0, 0.2);
        vec3 shadow_accent = vec3(0.3, 0.0, 0.4);
        
        glow_color = mix(shadow_base, shadow_accent, shadow_noise);
        
        // 添加脉动
        float shadow_pulse = sin(time * pulse_speed * 0.7) * 0.5 + 0.5;
        glow_color = mix(glow_color, vec3(0.4, 0.0, 0.5), shadow_pulse * pulse_intensity * 0.3);
    }
    else if (type == 3) {  // 元素水晶
        // 使用元素颜色
        glow_color = element_color.rgb;
        
        // 创建动态元素花纹
        float element_pattern = fractal_noise(noise_texture, 
            uv * 2.0 + time * 0.05, 3.0, 2);
        
        // 添加颜色变化
        float time_var = time * 0.2;
        vec3 element_accent = vec3(
            sin(time_var) * 0.5 + 0.5,
            sin(time_var + 2.0) * 0.5 + 0.5,
            sin(time_var + 4.0) * 0.5 + 0.5
        );
        
        glow_color = mix(glow_color, element_accent, element_pattern * 0.3);
    }
    
    // 应用内部光照强度
    return glow_color * inner_light * inner_glow;
}

// 计算闪光效果
float calculate_sparkle(vec2 uv, float time) {
    if (sparkle <= 0.0) return 0.0;
    
    // 创建多个闪光点
    float total_sparkle = 0.0;
    
    for (int i = 0; i < 5; i++) {
        // 为每个闪光点创建独特的种子
        float seed = float(i) * 1234.5678;
        
        // 随机位置
        vec2 pos = vec2(
            fract(sin(seed) * 43758.5453),
            fract(sin(seed + 1.0) * 22578.1459)
        );
        
        // 随机时间偏移
        float time_offset = fract(sin(seed + 2.0) * 19281.5837);
        
        // 随机大小
        float size = fract(sin(seed + 3.0) * 32187.2471) * 0.02 + 0.01;
        
        // 闪烁频率
        float freq = fract(sin(seed + 4.0) * 27518.9743) * 3.0 + 2.0;
        
        // 计算闪光点亮度
        float brightness = pow(sin(time * sparkle_speed * freq + time_offset * 6.28) * 0.5 + 0.5, 2.0);
        
        // 计算到闪光点的距离
        float dist = distance(uv, pos);
        
        // 添加闪光点贡献
        total_sparkle += brightness * (1.0 - smoothstep(0.0, size, dist));
    }
    
    return total_sparkle * sparkle;
}

// 计算裂纹效果
float calculate_cracks(sampler2D noise_tex, vec2 uv, float amount, float width) {
    if (!enable_cracks || amount <= 0.0) return 0.0;
    
    // 使用噪声生成裂纹图案
    float noise = fractal_noise(noise_tex, uv * 3.0, 4.0, 3);
    
    // 阈值化噪声创建裂纹
    float crack_threshold = 1.0 - amount * 0.3;
    float crack_value = smoothstep(crack_threshold - width, crack_threshold, noise) * 
                       (1.0 - smoothstep(crack_threshold, crack_threshold + width, noise));
    
    return crack_value;
}

// 色散效果（将光分离为彩虹色）
vec3 apply_dispersion(sampler2D screen_tex, vec2 uv, float strength, float refract_value) {
    if (strength <= 0.0 || refract_value <= 0.0) return texture(screen_tex, uv).rgb;
    
    // 计算色散偏移
    float offset = strength * 0.01 * refract_value;
    
    // RGB各通道分别采样
    float r = texture(screen_tex, uv + vec2(offset, 0.0)).r;
    float g = texture(screen_tex, uv).g;
    float b = texture(screen_tex, uv - vec2(offset, 0.0)).b;
    
    return vec3(r, g, b);
}

void fragment() {
    // 计算时间
    float time = TIME;
    
    // 脉动时间因子
    float pulse_factor = 1.0;
    if (pulse_intensity > 0.0) {
        pulse_factor = sin(time * pulse_speed) * pulse_intensity * 0.2 + 1.0;
    }
    
    // 中心坐标系
    vec2 centered_uv = UV - 0.5;
    
    // 旋转UV
    centered_uv = get_rotation_matrix(time * rotation_speed) * centered_uv;
    vec2 uv = centered_uv + 0.5;
    
    // 视差效果 - 创建多层次的深度
    vec3 parallax_color = vec3(0.0);
    if (parallax_depth > 0.0) {
        for (float i = 0.0; i < parallax_layers; i++) {
            // 计算当前层的深度
            float depth = i / parallax_layers;
            float depth_influence = depth * parallax_depth;
            
            // 调整UV基于深度
            vec2 parallax_uv = uv - (uv - 0.5) * depth_influence;
            
            // 旋转内部层
            parallax_uv = 0.5 + get_rotation_matrix(time * rotation_speed * 0.2 * (depth + 0.5)) * (parallax_uv - 0.5);
            
            // 当前层的水晶效果
            float layer_facet = facet_pattern(parallax_uv, facet_count, facet_clarity * (1.0 - depth * 0.5));
            
            // 添加到总颜色
            float layer_weight = (1.0 - depth) / parallax_layers;
            parallax_color += crystal_color.rgb * layer_facet * layer_weight;
        }
    }
    
    // 计算水晶蒙版
    float crystal_mask_value = crystal_mask(uv, facet_count, crystal_shape);
    
    // 内部纹理
    vec3 inner_texture;
    if (use_custom_texture) {
        // 使用自定义水晶纹理
        vec2 texture_uv = uv * inner_texture_scale;
        inner_texture = texture(crystal_texture, texture_uv).rgb;
    } else {
        // 使用程序生成的纹理
        float pattern = facet_pattern(uv, facet_count, facet_clarity);
        inner_texture = crystal_color.rgb * pattern;
    }
    
    // 应用杂质
    if (impurity > 0.0) {
        float impurity_noise = texture(noise_texture, uv * impurity_scale).r;
        impurity_noise = smoothstep(1.0 - impurity, 1.0, impurity_noise);
        inner_texture = mix(inner_texture, shadow_color.rgb, impurity_noise * 0.5);
    }
    
    // 计算内部光照
    vec3 inner_light_color = calculate_inner_light(uv, time, crystal_type, crystal_color);
    
    // 应用视差效果如果启用
    if (parallax_depth > 0.0) {
        inner_texture = mix(inner_texture, parallax_color, parallax_depth);
    }
    
    // 计算折射效果
    vec3 refraction_color;
    if (refraction > 0.0) {
        // 获取噪声图案用于扭曲
        float refract_noise = texture(noise_texture, uv * 2.0 + time * 0.1).r;
        
        // 创建折射偏移
        vec2 refract_offset = centered_uv * refract_noise * refraction * 0.1;
        vec2 refract_uv = SCREEN_UV + refract_offset;
        
        // 应用色散效果
        refraction_color = apply_dispersion(screen_texture, refract_uv, dispersion, refraction);
    } else {
        refraction_color = texture(screen_texture, SCREEN_UV).rgb;
    }
    
    // 边缘发光
    float edge = 1.0 - crystal_mask_value;
    edge = 1.0 - smoothstep(0.0, 0.2, edge);
    edge *= edge_glow * pulse_factor;
    
    // 计算高光
    float highlight = calculate_highlight(uv, time) * highlight_intensity * shininess;
    
    // 计算闪光效果
    float sparkle_value = calculate_sparkle(uv, time);
    
    // 计算裂纹
    float cracks = calculate_cracks(noise_texture, uv, crack_amount, crack_width);
    
    // 混合所有效果
    vec3 final_color = mix(refraction_color, inner_texture, crystal_mask_value * crystal_alpha * 0.7);
    final_color += inner_light_color * crystal_mask_value;
    final_color += highlight_color.rgb * highlight * crystal_mask_value;
    final_color += crystal_color.rgb * edge * edge_glow;
    final_color += highlight_color.rgb * sparkle_value;
    
    // 应用裂纹效果
    if (enable_cracks) {
        final_color = mix(final_color, highlight_color.rgb, cracks * 0.5);
    }
    
    // 最终透明度
    float final_alpha = crystal_mask_value * crystal_alpha;
    final_alpha = max(final_alpha, edge * edge_glow * 0.5);
    final_alpha = max(final_alpha, sparkle_value * 0.7);
    
    COLOR = vec4(final_color, final_alpha);
} 