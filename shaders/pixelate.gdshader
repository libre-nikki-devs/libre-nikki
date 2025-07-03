shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform int amount = 1;

void fragment() {
	if (amount != 0) {
		vec2 correction = SCREEN_PIXEL_SIZE * vec2(float(amount), float(amount)) / vec2(2.0);
		vec2 texture_uv = floor(SCREEN_UV / SCREEN_PIXEL_SIZE);
		vec2 offset = vec2(float(int(texture_uv.x) % amount), float(int(texture_uv.y) % amount));
		vec2 target = (texture_uv - offset) * SCREEN_PIXEL_SIZE;
		COLOR.rgb = textureLod(screen_texture, target + correction, 0.0).rgb;
	}
}
