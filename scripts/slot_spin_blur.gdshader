shader_type canvas_item;

uniform float blur_strength : hint_range(0.0, 5.0) = 0.0;

void fragment() {
	vec2 vertical = vec2(0.0, TEXTURE_PIXEL_SIZE.y * blur_strength);
	vec4 color = texture(TEXTURE, UV) * 0.227027;
	color += texture(TEXTURE, UV + vertical * 1.3846153846) * 0.3162162162;
	color += texture(TEXTURE, UV - vertical * 1.3846153846) * 0.3162162162;
	color += texture(TEXTURE, UV + vertical * 3.2307692308) * 0.0702702703;
	color += texture(TEXTURE, UV - vertical * 3.2307692308) * 0.0702702703;
	COLOR = color;
}
