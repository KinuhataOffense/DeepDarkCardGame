shader_type canvas_item;

// UI面板着色器 - 《无火的牌局》UI风格
// 哥特式暗黑UI面板效果

// 参数设置
uniform vec4 base_color : source_color = vec4(0.12, 0.1, 0.08, 0.95); // 基础颜色
uniform vec4 border_color : source_color = vec4(0.35, 0.28, 0.2, 1.0); // 边框颜色
uniform float border_width : hint_range(0.0, 0.1) = 0.03; // 边框宽度
uniform float corner_radius : hint_range(0.0, 0.5) = 0.05; // 圆角半径
uniform sampler2D pattern_texture : filter_linear_mipmap, repeat_enable; // 花纹纹理
uniform float pattern_opacity : hint_range(0.0, 1.0) = 0.15; // 花纹不透明度
uniform float pattern_scale : hint_range(0.5, 5.0) = 1.0; // 花纹缩放
uniform bool use_inner_shadow = true; // 使用内阴影
uniform float inner_shadow_size : hint_range(0.0, 0.5) = 0.1; // 内阴影大小
uniform float inner_shadow_opacity : hint_range(0.0, 1.0) = 0.6; // 内阴影不透明度
uniform vec4 accent_color : source_color = vec4(0.5, 0.4, 0.1, 1.0); // 强调色用于细节
uniform bool animate_pattern = false; // 是否动画花纹
uniform float animation_speed : hint_range(0.0, 1.0) = 0.05; // 动画速度

// 圆角矩形距离函数
float rounded_rect(vec2 uv, vec2 size, float radius) {
    vec2 d = abs(uv - vec2(0.5)) - size * 0.5 + radius;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - radius;
}

// 柔和边缘函数，用于创建平滑过渡
float smooth_edge(float edge, float smooth_amount) {
    return smoothstep(0.0, smooth_amount, edge);
}

void fragment() {
    // 创建基础矩形形状（带圆角）
    vec2 uv = UV;
    float rect = rounded_rect(uv, vec2(1.0, 1.0), corner_radius);
    
    // 创建边框
    float border = abs(rect) < border_width ? 1.0 : 0.0;
    border = smooth_edge(border_width - abs(rect), 0.005) * step(rect, 0.0);
    
    // 创建内阴影
    float inner_shadow = 0.0;
    if (use_inner_shadow) {
        inner_shadow = (1.0 - smooth_edge(inner_shadow_size - abs(rect), inner_shadow_size)) * 
                     step(rect, 0.0) * inner_shadow_opacity;
    }
    
    // 计算模式UV（可动画）
    vec2 pattern_uv = uv * pattern_scale;
    if (animate_pattern) {
        pattern_uv += vec2(TIME * animation_speed, TIME * animation_speed * 0.7);
    }
    
    // 获取图案纹理并调整不透明度
    vec4 pattern = texture(pattern_texture, pattern_uv);
    pattern.a *= pattern_opacity;
    
    // 主体填充颜色
    vec4 fill_color = base_color;
    
    // 在边缘添加细微的装饰元素（点状装饰）
    float decoration = 0.0;
    if (abs(rect) < border_width * 1.5 && abs(rect) > border_width * 0.5) {
        // 计算角度
        float angle = atan(uv.y - 0.5, uv.x - 0.5);
        // 创建周期性的点状装饰
        float period = 3.14159 / 8.0; // 8个点
        decoration = smoothstep(0.1, 0.0, abs(mod(angle, period) - period * 0.5)) * 0.5;
    }
    
    // 组合所有元素
    vec4 final_color = fill_color;
    
    // 添加图案 - 只在面板内部
    if (rect < 0.0) {
        final_color = mix(final_color, pattern, pattern.a);
    }
    
    // 添加边框
    final_color = mix(final_color, border_color, border);
    
    // 添加装饰元素
    final_color = mix(final_color, accent_color, decoration);
    
    // 添加内阴影 - 使内部更暗
    final_color.rgb *= (1.0 - inner_shadow);
    
    // 应用透明度掩码
    final_color.a *= step(rect, 0.0);
    
    // 输出最终颜色
    COLOR = final_color;
} 