shader_type canvas_item;

uniform sampler2D noise_tex;
uniform float sea_level;
uniform float sand_threshold;

void fragment() {
    // Sample noise (Texture is 0.0-1.0 already)
    float val = texture(noise_tex, UV).r;
    
    // Normalize height above sea level
    float adjusted_v = (val - sea_level) / (1.0 - sea_level);
    adjusted_v = clamp(adjusted_v, 0.0, 1.0);
    
    if (adjusted_v < sand_threshold) {
        COLOR = vec4(0.94, 0.82, 0.6, 1.0); // Sand
    } else {
        float t = (adjusted_v - sand_threshold) / (1.0 - sand_threshold);
        vec3 light_green = vec3(0.41, 0.82, 0.10);
        vec3 dark_green = vec3(0.05, 0.3, 0.05);
        COLOR = vec4(mix(light_green, dark_green, clamp(t, 0.0, 1.0)), 1.0);
    }
}
