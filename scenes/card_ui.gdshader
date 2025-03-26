shader_type canvas_item;  

uniform vec4 glow_color : hint_color = vec4(1.0, 1.0, 0.0, 1.0); // 发光颜色  
uniform float glow_width : hint_range(0.0, 10.0) = 2.0; // 发光宽度  

void fragment() {  
    vec4 tex_color = texture(TEXTURE, UV);  
    float alpha = tex_color.a;  
    
    // 计算边缘发光  
    float glow = smoothstep(0.0, glow_width, alpha);  
    vec4 glow_effect = glow_color * glow;  
    
    COLOR = mix(tex_color, glow_effect, glow);  
}  