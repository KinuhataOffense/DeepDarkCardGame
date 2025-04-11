shader_type canvas_item;
render_mode blend_mix;

// 血液效果着色器
// 用于实现游戏中的血液、污渍和流体效果

// 基础参数
uniform vec4 blood_color : source_color = vec4(0.6, 0.0, 0.0, 0.9);
uniform vec4 dark_color : source_color = vec4(0.3, 0.0, 0.0, 0.95);
uniform vec4 highlight_color : source_color = vec4(0.9, 0.2, 0.2, 0.8);
// 血液类型：0=新鲜血液, 1=陈旧血液, 2=腐化血液, 3=特殊血液
uniform int blood_type : hint_range(0, 3) = 0;
// 特殊血液自定义颜色
uniform vec4 special_blood_color : source_color = vec4(0.3, 0.0, 0.5, 0.9);
// 湿润度 (0-干燥，1-湿润)
uniform float wetness : hint_range(0.0, 1.0) = 0.8;
// 粘稠度
uniform float viscosity : hint_range(0.0, 1.0) = 0.6;
// 表面反光强度
uniform float specular : hint_range(0.0, 1.0) = 0.4;
// 血液纹理缩放
uniform float texture_scale : hint_range(0.1, 10.0) = 1.0;
// 流动速度
uniform float flow_speed : hint_range(0.0, 2.0) = 0.2;
// 流动方向 (弧度)
uniform float flow_direction : hint_range(0.0, 6.28) = 1.57;
// 流动强度
uniform float flow_intensity : hint_range(0.0, 1.0) = 0.5;
// 滴落效果
uniform float drip_amount : hint_range(0.0, 10.0) = 3.0;
// 滴落大小
uniform float drip_size : hint_range(0.01, 0.2) = 0.05;
// 滴落速度
uniform float drip_speed : hint_range(0.1, 5.0) = 1.0;
// 血液噪声细节
uniform float noise_detail : hint_range(0.1, 5.0) = 2.0;
// 边缘细节
uniform float edge_detail : hint_range(0.0, 1.0) = 0.5;
// 表面干涸程度
uniform float dryness : hint_range(0.0, 1.0) = 0.2;
// 表面不均匀度
uniform float roughness : hint_range(0.0, 1.0) = 0.6;
// 噪声纹理
uniform sampler2D noise_texture;
// 是否使用自定义贴图
uniform bool use_custom_texture = false;
// 自定义贴图
uniform sampler2D custom_texture;
// 血迹溅落参数
uniform float splatter_amount : hint_range(0.0, 1.0) = 0.3;
// 溅落尺寸
uniform float splatter_size : hint_range(0.01, 0.2) = 0.05;
// 暗化边缘
uniform float darken_edges : hint_range(0.0, 1.0) = 0.3;
// 脉动效果
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.0;
// 脉动速度
uniform float pulse_speed : hint_range(0.1, 5.0) = 1.0;
// 是否启用气泡效果
uniform bool enable_bubbles = false;
// 气泡数量
uniform float bubble_amount : hint_range(0.0, 20.0) = 5.0;
// 气泡大小
uniform float bubble_size : hint_range(0.01, 0.1) = 0.03;
// 气泡速度
uniform float bubble_speed : hint_range(0.1, 3.0) = 1.0;
// 涂抹扭曲强度
uniform float smear_intensity : hint_range(0.0, 1.0) = 0.2;
// 涂抹方向
uniform float smear_direction : hint_range(0.0, 6.28) = 0.0;
// 是否启用凝结效果
uniform bool enable_clotting = false;
// 凝结程度
uniform float clotting_amount : hint_range(0.0, 1.0) = 0.3;
// 使用遮罩纹理控制血液形状
uniform bool use_mask = false;
// 遮罩纹理
uniform sampler2D mask_texture;
// 遮罩反转
uniform bool invert_mask = false;
// 遮罩软化
uniform float mask_softness : hint_range(0.0, 1.0) = 0.1;

// 随机函数
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

// 生成噪声
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

// 计算滴落效果
float calculate_drips(vec2 uv, float time, float amount, float drip_sz, float speed) {
    if (amount <= 0.0) return 0.0;
    
    float total_drips = 0.0;
    
    // 水平方向偏移计算
    float x_offset = floor(uv.x * amount) / amount;
    
    for (float i = 0.0; i < amount; i++) {
        // 为每个滴落设置随机种子
        float seed = i * 1234.5678;
        
        // 随机位置
        vec2 pos = vec2(
            x_offset + random(vec2(seed, 0.0)) / amount,
            0.0
        );
        
        // 随机速度
        float drip_vel = (random(vec2(seed, 1.0)) * 0.5 + 0.5) * speed;
        
        // 计算滴落位置
        float y_pos = fract(pos.y + time * drip_vel);
        
        // 拉长滴落形状
        float drip_length = (random(vec2(seed, 2.0)) * 0.5 + 0.5) * 0.3 * viscosity;
        float drip_head = smoothstep(y_pos, y_pos + drip_length, uv.y);
        
        // 计算到水平位置的距离
        float x_dist = abs(uv.x - pos.x);
        float drip_width = drip_sz * (1.0 - y_pos * 0.6); // 滴落变细
        
        // 添加滴落贡献
        if (x_dist < drip_width) {
            float drip_value = (1.0 - smoothstep(0.0, drip_width, x_dist)) * drip_head;
            total_drips = max(total_drips, drip_value);
        }
    }
    
    return total_drips;
}

// 计算飞溅效果
float calculate_splatter(vec2 uv, float amount, float splatter_sz) {
    if (amount <= 0.0) return 0.0;
    
    float total_splatter = 0.0;
    int splatter_count = int(30.0 * amount);
    
    for (int i = 0; i < splatter_count; i++) {
        // 为每个飞溅点设置随机种子
        float seed = float(i) * 5678.1234;
        
        // 随机位置
        vec2 pos = vec2(
            random(vec2(seed, 0.0)),
            random(vec2(seed, 1.0))
        );
        
        // 随机大小
        float size = (random(vec2(seed, 2.0)) * 0.8 + 0.2) * splatter_sz;
        
        // 计算到飞溅点的距离
        float dist = distance(uv, pos);
        
        // 飞溅形状 (更不规则)
        float shape = size / (dist + 0.01) * random(vec2(seed, 3.0));
        shape = smoothstep(0.4, 1.0, shape);
        
        // 添加到总飞溅
        total_splatter = max(total_splatter, shape);
    }
    
    return min(total_splatter, 1.0);
}

// 计算气泡效果
float calculate_bubbles(vec2 uv, float time, float amount, float bubble_sz, float speed) {
    if (!enable_bubbles || amount <= 0.0) return 0.0;
    
    float total_bubbles = 0.0;
    
    for (int i = 0; i < int(amount); i++) {
        // 为每个气泡设置随机种子
        float seed = float(i) * 9876.5432;
        
        // 随机位置
        vec2 pos = vec2(
            random(vec2(seed, 0.0)),
            random(vec2(seed, 1.0))
        );
        
        // 随机大小
        float size = (random(vec2(seed, 2.0)) * 0.8 + 0.2) * bubble_sz;
        
        // 添加一些随机运动
        pos.x += sin(time * speed * (random(vec2(seed, 3.0)) * 0.5 + 0.5) + seed) * 0.02;
        pos.y += cos(time * speed * (random(vec2(seed, 4.0)) * 0.5 + 0.5) + seed) * 0.02;
        
        // 计算到气泡的距离
        float dist = distance(uv, pos);
        
        // 添加气泡形状
        float bubble = 1.0 - smoothstep(0.0, size, dist);
        
        // 添加气泡边缘
        float bubble_edge = 1.0 - smoothstep(size * 0.8, size, dist);
        bubble_edge -= 1.0 - smoothstep(size * 0.7, size * 0.9, dist);
        
        // 组合气泡和边缘
        float final_bubble = max(bubble * 0.5, bubble_edge);
        
        // 添加到总气泡
        total_bubbles = max(total_bubbles, final_bubble);
    }
    
    return total_bubbles;
}

// 获取凝结效果
float get_clotting(vec2 uv, float amount) {
    if (!enable_clotting || amount <= 0.0) return 0.0;
    
    // 使用噪声创建凝结区域
    float clot_noise = fbm(uv * 15.0, 3);
    float clot_value = smoothstep(0.5 - amount * 0.5, 0.5 + amount * 0.5, clot_noise);
    
    return clot_value * amount;
}

// 流动函数
vec2 flow_uv(vec2 uv, float time, float intensity, float direction) {
    // 创建流动向量
    vec2 flow_vector = vec2(cos(direction), sin(direction));
    
    // 添加扰动
    float flow_noise = noise(uv * 5.0 + time * 0.1) * 2.0 - 1.0;
    flow_vector += vec2(flow_noise) * 0.2;
    
    // 应用流动
    vec2 flow_offset = flow_vector * time * flow_speed * intensity;
    
    return uv + flow_offset;
}

// 血液颜色函数
vec4 get_blood_color(int type, float noise_val, float clotting, vec4 base, vec4 dark, vec4 highlight, vec4 special) {
    vec4 color;
    
    // 基于血液类型选择颜色
    if (type == 0) {  // 新鲜血液
        color = mix(dark, mix(base, highlight, noise_val * 0.7), noise_val);
    }
    else if (type == 1) {  // 陈旧血液
        // 褐色调
        vec4 old_dark = vec4(0.2, 0.05, 0.0, dark.a);
        vec4 old_base = vec4(0.4, 0.1, 0.05, base.a);
        vec4 old_highlight = vec4(0.55, 0.2, 0.1, highlight.a);
        
        color = mix(old_dark, mix(old_base, old_highlight, noise_val * 0.5), noise_val);
    }
    else if (type == 2) {  // 腐化血液
        // 绿黑色调
        vec4 corrupt_dark = vec4(0.05, 0.1, 0.05, dark.a);
        vec4 corrupt_base = vec4(0.1, 0.25, 0.1, base.a);
        vec4 corrupt_highlight = vec4(0.2, 0.4, 0.15, highlight.a * 0.9);
        
        color = mix(corrupt_dark, mix(corrupt_base, corrupt_highlight, noise_val * 0.4), noise_val);
    }
    else {  // 特殊血液
        vec4 special_dark = vec4(special.rgb * 0.5, special.a);
        vec4 special_highlight = vec4(min(special.rgb * 1.5, vec3(1.0)), special.a * 0.9);
        
        color = mix(special_dark, mix(special, special_highlight, noise_val * 0.6), noise_val);
    }
    
    // 应用凝结效果
    if (enable_clotting && clotting > 0.0) {
        vec4 clot_color;
        
        if (type == 0) {
            clot_color = vec4(0.3, 0.0, 0.0, color.a);
        }
        else if (type == 1) {
            clot_color = vec4(0.25, 0.08, 0.02, color.a);
        }
        else if (type == 2) {
            clot_color = vec4(0.08, 0.15, 0.05, color.a);
        }
        else {
            clot_color = vec4(special.rgb * 0.4, color.a);
        }
        
        color = mix(color, clot_color, clotting);
    }
    
    return color;
}

void fragment() {
    // 获取时间
    float time = TIME;
    
    // 应用UV缩放
    vec2 scaled_uv = UV * texture_scale;
    
    // 应用流动效果
    vec2 flow_texcoord = scaled_uv;
    if (flow_intensity > 0.0) {
        flow_texcoord = flow_uv(scaled_uv, time, flow_intensity, flow_direction);
    }
    
    // 应用涂抹效果
    if (smear_intensity > 0.0) {
        vec2 smear_dir = vec2(cos(smear_direction), sin(smear_direction));
        float smear_noise = noise(scaled_uv * 2.0) * 2.0 - 1.0;
        vec2 smear_offset = smear_dir * smear_noise * smear_intensity;
        flow_texcoord += smear_offset;
    }
    
    // 获取基础噪声 (血液质地)
    float base_noise;
    
    if (use_custom_texture) {
        // 使用自定义贴图
        base_noise = texture(custom_texture, flow_texcoord).r;
    } else {
        // 使用程序生成的噪声
        base_noise = fbm(flow_texcoord * noise_detail, 4);
        
        // 添加不均匀性
        if (roughness > 0.0) {
            float rough_noise = fbm(flow_texcoord * noise_detail * 3.0, 2);
            base_noise = mix(base_noise, rough_noise, roughness * 0.4);
        }
    }
    
    // 计算滴落效果
    float drips = calculate_drips(UV, time, drip_amount, drip_size, drip_speed);
    
    // 计算溅落效果
    float splatter = calculate_splatter(UV, splatter_amount, splatter_size);
    
    // 计算气泡效果
    float bubbles = calculate_bubbles(UV, time, bubble_amount, bubble_size, bubble_speed);
    
    // 计算凝结效果
    float clotting = get_clotting(flow_texcoord, clotting_amount);
    
    // 组合所有效果创建血液形状
    float blood_shape = max(max(base_noise, drips), splatter);
    
    // 应用干燥效果
    if (dryness > 0.0) {
        // 边缘干燥
        float edge_noise = fbm(flow_texcoord * 8.0, 2);
        float edge_mask = smoothstep(0.3, 0.7, blood_shape);
        blood_shape = mix(blood_shape, blood_shape * edge_noise, dryness * (1.0 - edge_mask));
    }
    
    // 应用脉动效果
    float pulse_factor = 1.0;
    if (pulse_intensity > 0.0) {
        pulse_factor = sin(time * pulse_speed) * pulse_intensity * 0.2 + 1.0;
        // 应用到血液形状
        blood_shape *= pulse_factor;
    }
    
    // 应用边缘细节
    if (edge_detail > 0.0) {
        float edge_noise = fbm(flow_texcoord * 10.0, 3);
        float edge_mask = smoothstep(0.4, 0.6, blood_shape);
        blood_shape = mix(blood_shape * edge_noise, blood_shape, edge_mask);
    }
    
    // 应用遮罩（如果启用）
    if (use_mask) {
        float mask_value = texture(mask_texture, UV).r;
        if (invert_mask) mask_value = 1.0 - mask_value;
        
        // 添加软化效果
        float soft_factor = smoothstep(0.5 - mask_softness, 0.5 + mask_softness, mask_value);
        blood_shape *= soft_factor;
    }
    
    // 阈值化创建血液形状
    float blood_alpha = smoothstep(0.4 - wetness * 0.2, 0.6, blood_shape);
    
    // 获取血液颜色
    vec4 color = get_blood_color(blood_type, base_noise, clotting, 
                                blood_color, dark_color, highlight_color, special_blood_color);
    
    // 应用边缘暗化
    if (darken_edges > 0.0) {
        float edge = 1.0 - smoothstep(0.0, 0.4, blood_shape);
        color.rgb = mix(color.rgb, dark_color.rgb, edge * darken_edges);
    }
    
    // 添加高光效果
    if (specular > 0.0 && wetness > 0.5) {
        float spec_noise = pow(base_noise, 2.0) * wetness;
        color.rgb = mix(color.rgb, highlight_color.rgb, spec_noise * specular);
    }
    
    // 添加气泡效果到颜色
    if (bubbles > 0.0) {
        color.rgb = mix(color.rgb, highlight_color.rgb * 1.2, bubbles * 0.7);
    }
    
    // 最终颜色
    COLOR = vec4(color.rgb, blood_alpha * color.a);
} 