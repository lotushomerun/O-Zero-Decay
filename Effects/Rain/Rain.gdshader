shader_type canvas_item;

uniform float rain_speed : hint_range(0.0, 1000) = 0.0;
uniform vec4 rain_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float horizontal_shift : hint_range(-3.33, 3.33) = 0.0;

void fragment() {
	vec2 uv = UV;
	uv.y += TIME * rain_speed * -0.01;
	uv.x += TIME * -horizontal_shift;
	COLOR = texture(TEXTURE, uv) * rain_color;
}
