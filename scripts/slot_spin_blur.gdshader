shader_type canvas_item;

uniform float blur_strength : hint_range(0.0, 2.0) = 0.0;

void fragment() {
	vec2 horizontal = vec2(TEXTURE_PIXEL_SIZE.x * blur_strength, 0.0);
	vec4 color = texture(TEXTURE, UV) * 0.34;
	color += texture(TEXTURE, UV + horizontal) * 0.22;
	color += texture(TEXTURE, UV - horizontal) * 0.22;
	color += texture(TEXTURE, UV + horizontal * 2.0) * 0.11;
	color += texture(TEXTURE, UV - horizontal * 2.0) * 0.11;
	COLOR = color;
}
