shader_type canvas_item;

uniform vec4 rain_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec2 uv = UV;
	vec4 transparent_rain_color = vec4(rain_color.r, rain_color.g, rain_color.b, clamp(rain_color.a - .2, .0, .75));
	COLOR = texture(TEXTURE, uv) * transparent_rain_color;
}
