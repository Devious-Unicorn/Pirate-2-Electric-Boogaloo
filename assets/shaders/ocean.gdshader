shader_type canvas_item; // Defines this as a 2D canvas shader.

uniform sampler2D noise_img : repeat_enable; // The texture for waves (MUST have 'Repeat' enabled in Import).
uniform vec4 color_shallow : source_color;    // The light blue water color.
uniform vec4 color_deep : source_color;       // The dark blue water color.
uniform float pixel_size = 4.0;               // The size of the pixel art blocks.
uniform vec2 wind_direction;                  // The total movement offset from GDScript.

varying vec2 world_pos; // A variable to pass the world-space position from vertex to fragment.

void vertex() {
    // This grabs the global position of the pixel in the game world.
    // Since the ColorRect doesn't move, this stays perfectly locked to your map.
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    // 1. World-Space Pixelation
    // We snap the world position to a grid based on pixel_size.
    vec2 grid_pos = round(world_pos / pixel_size) * pixel_size;
    
    // 2. Texture Sampling
    // We divide the grid position by the texture size to get a 0-1 UV coordinate.
    vec2 noise_uv = grid_pos / vec2(textureSize(noise_img, 0));
    
    // 3. Layered Movement (Both layers follow the wind)
    // First layer: Moves exactly with the wind direction (current_offset).
    float noise_val = texture(noise_img, noise_uv + wind_direction).r; 
    // Second layer: Moves slightly slower (0.7) for a sense of depth and variety.
    float noise_val2 = texture(noise_img, (noise_uv * 0.5) + (wind_direction * 0.7)).r; 
    
    // 4. Combining & Quantization
    // Average the noise layers and snap to 3 color bands for a pixel-art look.
    float combined = (noise_val + noise_val2) / 2.0;
    float quantized = floor(combined * 3.0) / 3.0; 
    
    // 5. Final Color
    // Mix the colors. Because we use world_pos, the pattern stays still when the camera moves.
    COLOR = mix(color_deep, color_shallow, clamp(quantized, 0.0, 1.0));
}
