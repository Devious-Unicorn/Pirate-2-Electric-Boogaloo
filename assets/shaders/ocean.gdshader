shader_type canvas_item;

uniform sampler2D noise_img : repeat_enable;
uniform vec4 color_shallow : source_color;    // The light blue water color.
uniform vec4 color_deep : source_color;       // The dark blue water color.
uniform float pixel_size = 4.0;               // The size of the pixel art blocks.
uniform vec2 wind_direction;

varying vec2 world_pos;

void vertex() {
    // This grabs the global position of the pixel in the game world.
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    // snap world pos to a grid based off pixel size
    vec2 grid_pos = round(world_pos / pixel_size) * pixel_size;
    
    vec2 noise_uv = grid_pos / vec2(textureSize(noise_img, 0));
    
	// create two noise textures that move at slightly different speeds to make a parralax-like effect
    float noise_val = texture(noise_img, noise_uv + wind_direction).r; 
    float noise_val2 = texture(noise_img, (noise_uv * 0.5) + (wind_direction * 0.7)).r; 
    
    // avg the noise values and snap to 4 different color bands between color_shallow and color_deep
    float combined = (noise_val + noise_val2) / 2.0;
    float quantized = floor(combined * 4.0) / 4.0; 
    
    COLOR = mix(color_deep, color_shallow, clamp(quantized, 0.0, 1.0));
}
