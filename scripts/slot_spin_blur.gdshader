shader_type canvas_item;

uniform float blur_strength : hint_range(0.0, 5.0) = 0.0;

void fragment() {
	vec2 vertical = vec2(0.0, TEXTURE_PIXEL_SIZE.y * blur_strength * 2.0);
	vec4 color = texture(TEXTURE, UV) * 0.16;
	color += texture(TEXTURE, UV + vertical * 1.0) * 0.15;
	color += texture(TEXTURE, UV - vertical * 1.0) * 0.15;
	color += texture(TEXTURE, UV + vertical * 2.0) * 0.12;
	color += texture(TEXTURE, UV - vertical * 2.0) * 0.12;
	color += texture(TEXTURE, UV + vertical * 3.0) * 0.09;
	color += texture(TEXTURE, UV - vertical * 3.0) * 0.09;
	color += texture(TEXTURE, UV + vertical * 4.0) * 0.05;
	color += texture(TEXTURE, UV - vertical * 4.0) * 0.05;
	color += texture(TEXTURE, UV + vertical * 5.0) * 0.01;
	color += texture(TEXTURE, UV - vertical * 5.0) * 0.01;
	COLOR = color;
}
