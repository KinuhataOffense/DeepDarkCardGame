shader_type canvas_item;
render_mode blend_mix;

// 雾气效果着色器
// 用于实现游戏中的环境氛围和雾气效果

// 基础参数
uniform vec4 fog_color : source_color = vec4(0.5, 0.5, 0.5, 0.5);
uniform vec4 deep_fog_color : source_color = vec4(0.3, 0.3, 0.3, 0.7);
// 雾气密度
uniform float density : hint_range(0.0, 1.0) = 0.5;
// 雾气类型：0=普通雾, 1=暗能雾, 2=魔法雾, 3=迷幻雾
uniform int fog_type : hint_range(0, 3) = 0;
// 特殊雾气颜色
uniform vec4 special_fog_color : source_color = vec4(0.2, 0.0, 0.3, 0.6);
// 雾气速度
uniform float speed : hint_range(0.0, 2.0) = 0.1;
// 雾气方向 (弧度)
uniform float direction : hint_range(0.0, 6.28) = 0.0;
// 涡流强度
uniform float swirl : hint_range(0.0, 2.0) = 0.3;
// 涡流大小
uniform float swirl_size : hint_range(0.1, 10.0) = 3.0;
// 涡流速度
uniform float swirl_speed : hint_range(0.0, 2.0) = 0.5;
// 噪声缩放
uniform float noise_scale : hint_range(0.1, 10.0) = 2.0;
// 细节层级
uniform int detail_levels : hint_range(1, 5) = 3;
// 雾气抖动
uniform float jitter : hint_range(0.0, 1.0) = 0.1;
// 闪烁效果
uniform float flicker : hint_range(0.0, 1.0) = 0.0;
// 闪烁速度
uniform float flicker_speed : hint_range(0.1, 5.0) = 1.0;
// 亮点效果
uniform float bright_spots : hint_range(0.0, 1.0) = 0.0;
// 亮点大小
uniform float bright_spot_size : hint_range(0.01, 0.5) = 0.1;
// 亮点数量
uniform float bright_spot_amount : hint_range(0, 20) = 5.0;
// 深度影响
uniform float depth_influence : hint_range(0.0, 1.0) = 0.5;
// 视差强度
uniform float parallax : hint_range(0.0, 1.0) = 0.2;
// 视差层数
uniform int parallax_layers : hint_range(1, 5) = 2;
// 高度影响
uniform float height_influence : hint_range(0.0, 1.0) = 0.3;
// 漩涡点
uniform int vortex_count : hint_range(0, 10) = 0;
// 漩涡强度
uniform float vortex_strength : hint_range(0.0, 2.0) = 1.0;
// 漩涡尺寸
uniform float vortex_size : hint_range(0.1, 1.0) = 0.3;
// 漩涡旋转速度
uniform float vortex_rotation : hint_range(0.0, 5.0) = 1.0;
// 雾气颗粒度
uniform float graininess : hint_range(0.0, 1.0) = 0.1;
// 脉动效果
uniform float pulse : hint_range(0.0, 1.0) = 0.0;
// 脉动速度
uniform float pulse_speed : hint_range(0.1, 3.0) = 1.0;
// 是否使用遮罩
uniform bool use_mask = false;
// 遮罩纹理
uniform sampler2D mask_texture;
// 反转遮罩
uniform bool invert_mask = false;
// 扭曲屏幕内容
uniform float distortion : hint_range(0.0, 0.1) = 0.0;
// 扭曲速度
uniform float distortion_speed : hint_range(0.0, 2.0) = 0.5;
// 是否使用纹理
uniform bool use_texture = false;
// 雾气纹理
uniform sampler2D fog_texture;
// 边缘柔和度
uniform float edge_softness : hint_range(0.0, 1.0) = 0.2;
// 自定义时间流逝
uniform float time_factor : hint_range(0.0, 2.0) = 1.0;
// 场景深度纹理
uniform sampler2D depth_texture : hint_depth_texture;
// 是否使用深度贴图
uniform bool use_depth = false;
// 深度系数
uniform float depth_factor : hint_range(0.0, 5.0) = 1.0;
// 雾气光照效果
uniform float light_influence : hint_range(0.0, 1.0) = 0.2;
// 光源位置
uniform vec2 light_position = vec2(0.5, 0.5);
// 光强度
uniform float light_intensity : hint_range(0.0, 2.0) = 1.0;
// 光半径
uniform float light_radius : hint_range(0.0, 1.0) = 0.3;
// 阴影投射强度
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.3;

// 随机函数
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

// 简单噪声函数
float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    // 四角随机值
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    // 平滑插值
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    // 混合四角
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// 分形噪声 (FBM)
float fbm(vec2 uv, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise(uv * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

// 旋涡效果
vec2 swirl_effect(vec2 uv, float t, float strength, float sz, float spd) {
    vec2 center = vec2(0.5);
    vec2 tc = uv - center;
    float dist = length(tc);
    
    // 计算旋转角度
    float angle = atan(tc.y, tc.x);
    float swirl_factor = strength * sin(dist * sz - t * spd);
    
    // 应用旋转
    float s = sin(swirl_factor);
    float c = cos(swirl_factor);
    
    tc = vec2(
        tc.x * c - tc.y * s,
        tc.x * s + tc.y * c
    );
    
    return tc + center;
}

// 计算涡旋点
vec2 vortex_points(vec2 uv, float t, int count, float strength, float size, float rot_speed) {
    if (count <= 0 || strength <= 0.0) return uv;
    
    vec2 result = uv;
    
    for (int i = 0; i < count; i++) {
        if (i >= 10) break; // 安全保障
        
        // 为每个涡旋生成一个种子
        float seed = float(i) * 1234.5678;
        
        // 随机位置
        vec2 center = vec2(
            random(vec2(seed, 0.0)),
            random(vec2(seed, 1.0))
        );
        
        // 随机旋转速度
        float rot = (random(vec2(seed, 2.0)) * 0.5 + 0.5) * rot_speed;
        
        // 计算到涡旋中心的距离
        vec2 offset = result - center;
        float dist = length(offset);
        
        if (dist < size) {
            // 计算归一化影响因子 (边缘较弱)
            float factor = (1.0 - dist / size) * strength;
            
            // 计算旋转角度
            float angle = t * rot;
            
            // 应用旋转
            float s = sin(angle * factor);
            float c = cos(angle * factor);
            
            offset = vec2(
                offset.x * c - offset.y * s,
                offset.x * s + offset.y * c
            );
            
            result = center + offset;
        }
    }
    
    return result;
}

// 计算亮点
float calculate_bright_spots(vec2 uv, float t, float amount, float spot_size) {
    if (bright_spots <= 0.0 || amount <= 0.0) return 0.0;
    
    float total_spots = 0.0;
    
    for (int i = 0; i < int(amount); i++) {
        // 为每个亮点生成种子
        float seed = float(i) * 5678.1234;
        
        // 随机位置
        vec2 center = vec2(
            random(vec2(seed, 0.0)),
            random(vec2(seed, 1.0))
        );
        
        // 随机移动
        center.x += sin(t * (random(vec2(seed, 2.0)) * 0.5 + 0.3)) * 0.1;
        center.y += cos(t * (random(vec2(seed, 3.0)) * 0.5 + 0.3)) * 0.1;
        
        // 随机大小
        float size = (random(vec2(seed, 4.0)) * 0.8 + 0.2) * spot_size;
        
        // 随机亮度和闪烁
        float brightness = (random(vec2(seed, 5.0)) * 0.5 + 0.5);
        brightness *= 0.7 + 0.3 * sin(t * (random(vec2(seed, 6.0)) * 2.0 + 1.0));
        
        // 计算到亮点中心的距离
        float dist = distance(uv, center);
        
        // 柔和的亮点形状
        float spot = smoothstep(size, 0.0, dist) * brightness;
        
        // 添加到总亮点
        total_spots = max(total_spots, spot);
    }
    
    return min(total_spots * bright_spots, 1.0);
}

// 光照影响
float calculate_light(vec2 uv, vec2 light_pos, float radius, float intensity) {
    if (light_influence <= 0.0) return 1.0;
    
    float dist = distance(uv, light_pos);
    float light_factor = 1.0 - smoothstep(0.0, radius, dist);
    
    // 应用光照强度
    light_factor = pow(light_factor, 2.0) * intensity;
    
    return 1.0 + light_factor * light_influence;
}

// 计算阴影
float calculate_shadow(float fog_density, float height, float shadow_str) {
    if (shadow_strength <= 0.0) return 1.0;
    
    // 根据高度和密度计算阴影
    float shadow = min(fog_density * (1.0 - height), 1.0) * shadow_str;
    
    return 1.0 - shadow;
}

// 获取雾气颜色
vec4 get_fog_color(int type, float noise_val, vec4 base, vec4 deep, vec4 special) {
    vec4 color;
    
    // 基于雾气类型选择颜色
    if (type == 0) {  // 普通雾
        color = mix(deep, base, noise_val);
    }
    else if (type == 1) {  // 暗能雾
        // 深紫色调
        vec4 dark_energy_deep = vec4(0.05, 0.0, 0.1, deep.a);
        vec4 dark_energy_base = vec4(0.2, 0.0, 0.3, base.a);
        vec4 dark_energy_light = vec4(0.4, 0.1, 0.5, base.a * 0.9);
        
        color = mix(dark_energy_deep, mix(dark_energy_base, dark_energy_light, noise_val * 0.7), noise_val);
    }
    else if (type == 2) {  // 魔法雾
        // 蓝色调
        vec4 magic_deep = vec4(0.0, 0.05, 0.2, deep.a);
        vec4 magic_base = vec4(0.1, 0.2, 0.5, base.a);
        vec4 magic_light = vec4(0.3, 0.5, 0.9, base.a * 0.8);
        
        color = mix(magic_deep, mix(magic_base, magic_light, noise_val * 0.8), noise_val);
    }
    else {  // 迷幻雾
        vec4 special_deep = vec4(special.rgb * 0.5, deep.a);
        vec4 special_light = vec4(min(special.rgb * 1.5, vec3(1.0)), base.a * 0.8);
        
        color = mix(special_deep, mix(special, special_light, noise_val * 0.8), noise_val);
    }
    
    return color;
}

void fragment() {
    // 获取时间
    float t = TIME * time_factor;
    
    // 初始UV
    vec2 uv = UV;
    
    // 应用视差效果
    if (parallax > 0.0) {
        vec2 parallax_offset = vec2(0.0);
        
        for (int i = 0; i < parallax_layers; i++) {
            if (i >= 5) break; // 安全保障
            
            float depth = float(i) / float(parallax_layers);
            float layer_speed = mix(speed * 0.5, speed * 1.5, depth);
            vec2 layer_dir = vec2(cos(direction), sin(direction));
            
            vec2 layer_offset = layer_dir * t * layer_speed;
            float layer_noise = fbm(uv + layer_offset + vec2(float(i) * 100.0), 2);
            
            parallax_offset += layer_noise * parallax * (depth - 0.5) * 0.1;
        }
        
        uv += parallax_offset;
    }
    
    // 应用移动
    vec2 move_dir = vec2(cos(direction), sin(direction));
    vec2 moved_uv = uv + move_dir * t * speed;
    
    // 应用扭曲（如果启用）
    if (distortion > 0.0) {
        float dist_noise = fbm(moved_uv * 2.0 + t * distortion_speed, 2);
        vec2 distortion_offset = move_dir.yx * vec2(-1.0, 1.0) * dist_noise * distortion;
        moved_uv += distortion_offset;
    }
    
    // 应用涡流效果
    if (swirl > 0.0) {
        moved_uv = swirl_effect(moved_uv, t, swirl, swirl_size, swirl_speed);
    }
    
    // 应用涡旋点
    moved_uv = vortex_points(moved_uv, t, vortex_count, vortex_strength, vortex_size, vortex_rotation);
    
    // 添加随机抖动
    if (jitter > 0.0) {
        float jitter_noise = (random(uv + t) * 2.0 - 1.0) * jitter * 0.02;
        moved_uv += vec2(jitter_noise);
    }
    
    // 计算多层噪声
    float noise_value = 0.0;
    
    // 如果使用纹理
    if (use_texture) {
        noise_value = texture(fog_texture, moved_uv).r;
    } else {
        // 使用分形噪声
        noise_value = fbm(moved_uv * noise_scale, detail_levels);
        
        // 添加颗粒效果
        if (graininess > 0.0) {
            float grain = random(uv + t) * graininess * 0.2;
            noise_value = max(0.0, min(noise_value - grain, 1.0));
        }
    }
    
    // 应用脉动效果
    if (pulse > 0.0) {
        float pulse_val = sin(t * pulse_speed) * 0.5 + 0.5;
        noise_value = mix(noise_value, noise_value * pulse_val, pulse * 0.3);
    }
    
    // 应用高度影响
    if (height_influence > 0.0) {
        float height_factor = mix(1.0, 1.0 - UV.y, height_influence);
        noise_value *= height_factor;
    }
    
    // 应用深度影响（如果启用）
    float depth_factor_final = 1.0;
    if (use_depth && depth_influence > 0.0) {
        float depth = texture(depth_texture, SCREEN_UV).r;
        depth_factor_final = mix(1.0, depth * depth_factor, depth_influence);
        noise_value *= depth_factor_final;
    }
    
    // 计算闪烁效果
    if (flicker > 0.0) {
        float flicker_val = sin(t * flicker_speed + noise_value * 10.0) * 0.5 + 0.5;
        noise_value = mix(noise_value, noise_value * flicker_val, flicker * 0.2);
    }
    
    // 计算亮点
    float spots = calculate_bright_spots(uv, t, bright_spot_amount, bright_spot_size);
    
    // 计算光照影响
    float light_factor = calculate_light(uv, light_position, light_radius, light_intensity);
    
    // 计算阴影
    float shadow_factor = calculate_shadow(noise_value, UV.y, shadow_strength);
    
    // 应用遮罩（如果启用）
    if (use_mask) {
        float mask_value = texture(mask_texture, UV).r;
        if (invert_mask) mask_value = 1.0 - mask_value;
        
        // 应用边缘柔和度
        mask_value = smoothstep(0.5 - edge_softness, 0.5 + edge_softness, mask_value);
        noise_value *= mask_value;
    }
    
    // 根据密度调整透明度
    float fog_density = noise_value * density;
    
    // 获取雾气颜色
    vec4 color = get_fog_color(fog_type, noise_value, fog_color, deep_fog_color, special_fog_color);
    
    // 应用光照和阴影
    color.rgb *= light_factor * shadow_factor;
    
    // 添加亮点
    if (spots > 0.0) {
        color.rgb = mix(color.rgb, min(color.rgb * 2.0, vec3(1.0)), spots);
    }
    
    // 最终颜色
    COLOR = vec4(color.rgb, fog_density * color.a);
} 