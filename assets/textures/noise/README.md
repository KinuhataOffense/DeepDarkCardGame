# 噪点纹理资源

本目录包含游戏中各种着色器使用的噪点纹理资源。

## 纹理列表

### 基础噪点纹理
- `noise_basic.png` - 基础噪点纹理，用于卡牌老旧效果
  - 分辨率：512x512
  - 类型：灰度噪点
  - 用途：模拟纸张不规则磨损

### 扭曲噪点纹理
- `noise_distortion.png` - 扭曲噪点纹理，用于卡牌发光效果中的扭曲
  - 分辨率：512x512
  - 类型：RGB噪点
  - 用途：提供UV扭曲的向量场

### 火焰噪点纹理
- `noise_fire.png` - 火焰噪点纹理，用于火焰粒子效果
  - 分辨率：512x512
  - 类型：分形噪点
  - 用途：模拟火焰的不规则形状和动态变化

### 灰尘噪点纹理
- `noise_dust.png` - 灰尘噪点纹理，用于全局后处理效果
  - 分辨率：1024x1024
  - 类型：点状噪点
  - 用途：模拟空气中的灰尘和微粒

### 损坏效果纹理
- `noise_damage.png` - 损坏效果纹理，用于模拟老旧边缘
  - 分辨率：512x512
  - 类型：非均匀噪点
  - 用途：模拟纸张边缘的撕裂和损坏

## 生成说明

这些噪点纹理可以通过以下方式获取：

1. 使用图像编辑软件（如Photoshop、GIMP）手动创建
2. 使用专业噪点生成工具，如：
   - [Noise Generator](https://cpetry.github.io/NormalMap-Online/)
   - [FilterForge](https://filterforge.com/)
   - [NoiseTextureMaker](https://cpetry.github.io/TextureGenerator-Online/)
3. 使用代码程序化生成，例如Godot的GDScript或着色器

为保证噪点纹理的无缝平铺效果，建议在生成时启用"Tileable"选项。

## 应用方法

这些噪点纹理在着色器中的典型使用方法：

```gdshader
// 在着色器中定义噪点纹理
uniform sampler2D noise_texture;

// 在片段着色器中使用
void fragment() {
    // 获取噪点值
    vec4 noise = texture(noise_texture, UV);
    
    // 使用噪点值调整效果
    // ...
}
```

预期在使用噪点纹理时，需要在材质属性中指定对应的纹理资源。 