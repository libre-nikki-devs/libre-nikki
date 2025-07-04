shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform int amount = 1;

void fragment() {
	if (amount > 0) {
		vec2 pixel_size = SCREEN_PIXEL_SIZE * float(amount);
		vec2 texture_uv = floor(SCREEN_UV / pixel_size);
		vec2 target = texture_uv * pixel_size + pixel_size * 0.5;
		COLOR.rgb = textureLod(screen_texture, target, 0.0).rgb;
	} else {
		COLOR.rgb = texture(screen_texture, SCREEN_UV).rgb;
	}
}
