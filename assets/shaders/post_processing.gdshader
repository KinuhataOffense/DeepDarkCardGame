shader_type canvas_item;
render_mode unshaded;

// 全局后处理效果着色器 - 黑暗之魂风格氛围
// 参数定义
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4; // 暗角效果强度
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5; // 暗角不透明度
uniform vec4 vignette_rgb : source_color = vec4(0.1, 0.1, 0.1, 1.0); // 暗角颜色
uniform float dust_amount : hint_range(0.0, 1.0) = 0.2; // 灰尘颗粒数量
uniform sampler2D dust_texture : filter_linear_mipmap, repeat_enable; // 噪点纹理用于灰尘效果
uniform float grain_amount : hint_range(0.0, 1.0) = 0.05; // 胶片颗粒效果
uniform bool enable_color_shift = true; // 是否启用色彩偏移
uniform float color_depth : hint_range(1.0, 32.0) = 32.0; // 色彩深度降低，增加复古感
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
// 色调映射函数
vec3 tone_mapping(vec3 color) {
    // 类似ACES但更暗的色调映射，适合暗黑风格
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((color * (a * color + b)) / (color * (c * color + d) + e), 0.0, 1.0);
}

// 随机数生成
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

// 生成噪点
float noise(vec2 uv) {
    vec2 uv_index = floor(uv);
    vec2 uv_fract = fract(uv);
    
    // 四角随机值
    float a = random(uv_index);
    float b = random(uv_index + vec2(1.0, 0.0));
    float c = random(uv_index + vec2(0.0, 1.0));
    float d = random(uv_index + vec2(1.0, 1.0));
    
    // 平滑插值
    vec2 blur = smoothstep(0.0, 1.0, uv_fract);
    
    return mix(mix(a, b, blur.x), mix(c, d, blur.x), blur.y);
}

// 胶片颗粒效果
float grain(vec2 uv, float time) {
    float grain_noise = random(uv + vec2(time)) * 2.0 - 1.0;
    return grain_noise;
}

// 量化色彩函数
vec3 quantize_color(vec3 color, float steps) {
    return floor(color * steps) / steps;
}

// 老式电影色彩偏移效果
vec3 old_movie_color(vec3 color) {
    // 略微偏向棕褐色调
    vec3 sepia = vec3(
        dot(color, vec3(0.393, 0.769, 0.189)),
        dot(color, vec3(0.349, 0.686, 0.168)),
        dot(color, vec3(0.272, 0.534, 0.131))
    );
    
    // 减少蓝色通道
    color.b *= 0.9;
    
    // 混合原色和棕褐色调
    return mix(color, sepia, 0.2);
}

void fragment() {
    // 获取原始屏幕颜色
    vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);
    
    // 应用色调映射
    color.rgb = tone_mapping(color.rgb);
    
    // 色彩深度降低
    if (enable_color_shift) {
        color.rgb = quantize_color(color.rgb, color_depth);
        color.rgb = old_movie_color(color.rgb);
    }
    
    // 计算暗角效果（屏幕边缘变暗）
    float vignette = smoothstep(0.0, vignette_intensity, 
                               distance(SCREEN_UV, vec2(0.5, 0.5)));
    color.rgb = mix(color.rgb, vignette_rgb.rgb, vignette * vignette_opacity);
    
    // 添加灰尘效果
    if (dust_amount > 0.0) {
        float t = TIME * 0.05;  // 缓慢移动灰尘
        vec2 dust_uv = SCREEN_UV + vec2(sin(t * 0.1), cos(t * 0.2)) * 0.01;
        vec4 dust = texture(dust_texture, dust_uv);
        float dust_factor = dust.r * dust_amount;
        color.rgb = mix(color.rgb, color.rgb + vec3(dust_factor), dust_factor * 0.5);
    }
    
    // 添加胶片颗粒
    if (grain_amount > 0.0) {
        float grain_noise = grain(SCREEN_UV, TIME) * grain_amount;
        color.rgb += vec3(grain_noise);
    }
    
    // 微调亮度和对比度，整体偏暗
    color.rgb = color.rgb * 0.9; // 略微降低亮度
    color.rgb = (color.rgb - 0.5) * 1.1 + 0.5; // 增加对比度
    
    // 输出最终颜色
    COLOR = color;
}

// 顶点着色器 - 保持不变
void vertex() {
    // 不做任何处理
} 