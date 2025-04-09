shader_type canvas_item;

// 卡牌老旧效果着色器 - 黑暗之魂风格的羊皮纸质感
// 参数定义
uniform float wear_amount : hint_range(0.0, 1.0) = 0.3; // 磨损程度，值越大磨损越明显
uniform sampler2D noise_texture; // 噪点纹理，用于模拟纸张不规则磨损
uniform vec4 tint_color : source_color = vec4(0.9, 0.8, 0.6, 1.0); // 发黄色调，模拟老旧羊皮纸
uniform float edge_darkness : hint_range(0.0, 1.0) = 0.4; // 边缘暗化程度
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.3; // 晕影效果强度

void fragment() {
    // 获取原始颜色
    vec4 color = texture(TEXTURE, UV);
    vec4 noise = texture(noise_texture, UV);
    
    // 创建边缘蒙版，使边缘更容易磨损
    float edge_mask = (1.0 - smoothstep(0.1, 0.3, min(UV.x, 1.0-UV.x)) * 
                      smoothstep(0.1, 0.3, min(UV.y, 1.0-UV.y)));
    
    // 根据噪点纹理和边缘蒙版计算磨损效果
    float wear = noise.r * edge_mask * wear_amount;
    
    // 添加晕影效果，使边缘更暗
    float vignette = edge_mask * vignette_intensity;
    
    // 调整颜色，使其略微发黄（老旧羊皮纸效果）
    color.rgb = mix(color.rgb, tint_color.rgb, 0.2);
    
    // 在磨损区域添加暗色
    color.rgb = mix(color.rgb, vec3(0.3, 0.3, 0.3), wear);
    
    // 应用晕影效果
    color.rgb = mix(color.rgb, color.rgb * (1.0 - vignette), edge_darkness);
    
    // 输出最终颜色
    COLOR = color;
} 